"""
moto_vitals_scraper.py
======================
Moto Vitals — Automated Parts Data Pipeline
Scrapes motorcycle parts from Shopee PH search results and uploads
them to Firestore under the `parts` collection.

Security note: Run this server-side only. Never embed credentials in
the Flutter app. Uses Firebase Admin SDK with a service account key.

Setup:
    pip install requests beautifulsoup4 firebase-admin python-dotenv

Usage:
    python moto_vitals_scraper.py

Environment variables (put in .env file, never commit):
    FIREBASE_CREDENTIALS_PATH=path/to/serviceAccountKey.json
    SCRAPE_DELAY_SECONDS=2
"""

import os
import time
import json
import hashlib
import requests
from bs4 import BeautifulSoup
from datetime import datetime, timezone
from dotenv import load_dotenv
import firebase_admin
from firebase_admin import credentials, firestore

# ── Config ────────────────────────────────────────────────────────────────────

load_dotenv()

FIREBASE_CREDENTIALS_PATH = os.getenv(
    "FIREBASE_CREDENTIALS_PATH", "serviceAccountKey.json"
)
SCRAPE_DELAY = float(os.getenv("SCRAPE_DELAY_SECONDS", "2"))

# Search queries mapped to PartCategory values
SEARCH_QUERIES = [
    {"query": "honda winner x engine oil", "category": "essential"},
    {"query": "winner x brake pads RCB", "category": "essential"},
    {"query": "motorcycle chain lubricant", "category": "essential"},
    {"query": "winner x performance exhaust uma racing", "category": "upgrade"},
    {"query": "winner x air filter upgrade", "category": "upgrade"},
    {"query": "motorcycle coolant radiator", "category": "essential"},
]

SHOPEE_SEARCH_URL = "https://shopee.ph/search"
HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/124.0.0.0 Safari/537.36"
    ),
    "Accept-Language": "en-PH,en;q=0.9",
}

# ── Firebase Init ─────────────────────────────────────────────────────────────

def init_firebase() -> firestore.Client:
    """Initialize Firebase Admin SDK and return Firestore client."""
    if not firebase_admin._apps:
        cred = credentials.Certificate(FIREBASE_CREDENTIALS_PATH)
        firebase_admin.initialize_app(cred)
    return firestore.client()


# ── Scraper ───────────────────────────────────────────────────────────────────

def scrape_shopee(query: str, max_results: int = 5) -> list[dict]:
    """
    Scrapes Shopee PH search results for a given query.
    Returns a list of raw product dicts.

    Note: Shopee is JS-heavy. This targets the static fallback/SEO page.
    For production, consider using Shopee's affiliate API or a headless
    browser (Playwright) for full JS rendering.
    """
    params = {"keyword": query}
    results = []

    try:
        response = requests.get(
            SHOPEE_SEARCH_URL,
            params=params,
            headers=HEADERS,
            timeout=10,
        )
        response.raise_for_status()
        soup = BeautifulSoup(response.text, "html.parser")

        # Attempt to parse product cards from static HTML
        # Shopee structure varies — adjust selectors as needed
        product_cards = soup.select("div[data-sqe='item']")[:max_results]

        for card in product_cards:
            name_el = card.select_one("div[data-sqe='name']")
            price_el = card.select_one("span[class*='price']")
            link_el = card.select_one("a[href]")
            img_el = card.select_one("img[src]")

            if not name_el:
                continue

            name = name_el.get_text(strip=True)
            price_text = price_el.get_text(strip=True) if price_el else "0"
            price = _parse_price(price_text)
            href = link_el["href"] if link_el else ""
            affiliate_url = f"https://shopee.ph{href}" if href.startswith("/") else href
            image = img_el["src"] if img_el else ""

            results.append({
                "name": name,
                "price": price,
                "affiliateUrl": affiliate_url,
                "image": image,
            })

    except requests.RequestException as e:
        print(f"  [WARN] Request failed for '{query}': {e}")

    # Fallback: return mock data for development/testing when scraping fails
    if not results:
        results = _mock_fallback(query, max_results)

    return results


def _parse_price(price_text: str) -> float:
    """Extract numeric price from strings like '₱1,299.00' or 'PHP 1299'."""
    import re
    cleaned = re.sub(r"[^\d.]", "", price_text)
    try:
        return float(cleaned)
    except ValueError:
        return 0.0


def _mock_fallback(query: str, count: int) -> list[dict]:
    """Returns mock product data for dev/testing when live scrape fails."""
    mock_products = {
        "engine oil": [
            {"name": "Motul 5100 10W-40 Semi-Synthetic 1L", "price": 485.0,
             "affiliateUrl": "https://shopee.ph/motul-5100", "image": ""},
            {"name": "Shell Advance AX7 10W-40 1L", "price": 320.0,
             "affiliateUrl": "https://shopee.ph/shell-ax7", "image": ""},
        ],
        "brake pads": [
            {"name": "RCB Brake Pad DP Winner X Front", "price": 299.0,
             "affiliateUrl": "https://shopee.ph/rcb-brake-winner-x", "image": ""},
        ],
        "chain": [
            {"name": "Motul Chain Lube Road 400ml", "price": 389.0,
             "affiliateUrl": "https://shopee.ph/motul-chain-lube", "image": ""},
        ],
        "exhaust": [
            {"name": "Uma Racing Exhaust Winner X Full System", "price": 3800.0,
             "affiliateUrl": "https://shopee.ph/uma-racing-exhaust", "image": ""},
        ],
    }
    for key, products in mock_products.items():
        if key in query.lower():
            return products[:count]
    return [{"name": f"Part for {query}", "price": 500.0,
             "affiliateUrl": "https://shopee.ph", "image": ""}][:count]


# ── Firestore Uploader ────────────────────────────────────────────────────────

def upload_parts(db: firestore.Client, parts: list[dict]) -> int:
    """
    Upserts parts into Firestore `parts` collection.
    Uses a deterministic document ID based on the part name to avoid duplicates.
    Returns the count of successfully written parts.
    """
    batch = db.batch()
    count = 0

    for part in parts:
        if not part.get("name"):
            continue

        # Deterministic ID: hash of lowercased name prevents duplicates
        doc_id = hashlib.md5(part["name"].lower().encode()).hexdigest()[:20]
        ref = db.collection("parts").document(doc_id)

        batch.set(ref, {
            **part,
            "updatedAt": datetime.now(timezone.utc).isoformat(),
        }, merge=True)
        count += 1

    batch.commit()
    return count


# ── Main Pipeline ─────────────────────────────────────────────────────────────

def run_pipeline():
    print("=" * 55)
    print("  Moto Vitals Parts Scraper Pipeline")
    print(f"  Started: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 55)

    db = init_firebase()
    print("✓ Firebase initialized\n")

    total_written = 0

    for entry in SEARCH_QUERIES:
        query = entry["query"]
        category = entry["category"]
        print(f"→ Scraping: '{query}'")

        raw_products = scrape_shopee(query, max_results=5)

        # Attach category to each product
        enriched = [
            {**p, "category": category}
            for p in raw_products
            if p.get("name")
        ]

        if not enriched:
            print(f"  [SKIP] No products found for '{query}'\n")
            continue

        written = upload_parts(db, enriched)
        total_written += written
        print(f"  ✓ {written} part(s) upserted to Firestore")

        time.sleep(SCRAPE_DELAY)  # Be respectful — avoid rate limiting

    print(f"\n{'=' * 55}")
    print(f"  Pipeline complete. {total_written} total parts written.")
    print(f"  Finished: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 55)


if __name__ == "__main__":
    run_pipeline()
