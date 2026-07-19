import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vehicle_provider.dart';
import '../utils/alert_engine.dart';
import '../services/remote_config_service.dart';
import 'dashboard_screen.dart';
import 'marketplace_screen.dart';
import 'build_gallery_screen.dart';
import 'alerts_screen.dart';
import 'profile_screen.dart';
import 'ai_assistant_screen.dart';

class MainLayout extends StatefulWidget {
  final bool firebaseConfigured;
  const MainLayout({super.key, this.firebaseConfigured = false});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  void _switchToTab(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    final vehicle = context.watch<VehicleProvider>().currentVehicle;
    final hasAlerts = vehicle != null &&
        AlertEngine.hasActiveAlerts(vehicle.parts, vehicle.odo);
    final rc = RemoteConfigService();

    // ── Build tab list dynamically from feature flags ──────────────────────
    // Adding a new tab in the future = flip a Remote Config flag, no redeploy.
    final tabs = <_TabEntry>[
      _TabEntry(
        page: DashboardScreen(onGoToMarketplace: () => _switchToTab(
            _indexOf('market', rc))),
        icon: const Icon(Icons.speed_rounded),
        label: 'Dashboard',
        key: 'dashboard',
        enabled: true, // always on
      ),
      _TabEntry(
        page: const MarketplaceScreen(),
        icon: const Icon(Icons.shopping_bag_rounded),
        label: 'Market',
        key: 'market',
        enabled: rc.marketplaceEnabled,
      ),
      _TabEntry(
        page: const BuildGalleryScreen(),
        icon: const Icon(Icons.photo_library_rounded),
        label: 'Gallery',
        key: 'gallery',
        enabled: rc.galleryEnabled,
      ),
      _TabEntry(
        page: const AIAssistantScreen(),
        icon: const Icon(Icons.smart_toy_rounded),
        label: 'AI Mechanic',
        key: 'ai',
        enabled: true, // we can make this remote configurable later
      ),
      _TabEntry(
        page: AlertsScreen(onGoToMarketplace: () => _switchToTab(
            _indexOf('market', rc))),
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_rounded),
            if (hasAlerts)
              Positioned(
                top: -2, right: -2,
                child: Container(
                  width: 9, height: 9,
                  decoration: const BoxDecoration(
                      color: Colors.redAccent, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
        label: 'Alerts',
        key: 'alerts',
        enabled: rc.alertsEnabled,
      ),
      _TabEntry(
        page: ProfileScreen(firebaseConfigured: widget.firebaseConfigured),
        icon: const Icon(Icons.person_rounded),
        label: 'Profile',
        key: 'profile',
        enabled: true, // always on
      ),
    ].where((t) => t.enabled).toList();

    // Clamp index if tabs were removed by a flag flip
    final safeIndex = _currentIndex.clamp(0, tabs.length - 1);

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: tabs.map((t) => t.page).toList(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1A1A24),
        selectedItemColor: Colors.deepPurpleAccent,
        unselectedItemColor: Colors.grey,
        currentIndex: safeIndex,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        onTap: (i) => setState(() => _currentIndex = i),
        items: tabs
            .map((t) => BottomNavigationBarItem(icon: t.icon, label: t.label))
            .toList(),
      ),
    );
  }

  /// Returns the visible tab index for a given key, or 0 if not found.
  int _indexOf(String key, RemoteConfigService rc) {
    final tabs = ['dashboard', 'market', 'gallery', 'ai', 'alerts', 'profile']
        .where((k) {
          if (k == 'market') return rc.marketplaceEnabled;
          if (k == 'gallery') return rc.galleryEnabled;
          if (k == 'alerts') return rc.alertsEnabled;
          return true;
        })
        .toList();
    final i = tabs.indexOf(key);
    return i < 0 ? 0 : i;
  }
}

class _TabEntry {
  final Widget page;
  final Widget icon;
  final String label;
  final String key;
  final bool enabled;
  const _TabEntry({
    required this.page,
    required this.icon,
    required this.label,
    required this.key,
    required this.enabled,
  });
}
