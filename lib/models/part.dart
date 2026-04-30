enum PartCategory { upgrade, essential }

class Part {
  final String id;
  final String name;
  final double price;
  final String affiliateUrl;
  final PartCategory category;
  final String image;

  Part({
    required this.id,
    required this.name,
    required this.price,
    required this.affiliateUrl,
    required this.category,
    required this.image,
  });

  factory Part.fromJson(Map<String, dynamic> json, String documentId) {
    return Part(
      id: documentId,
      name: json['name'] as String? ?? 'Unknown Part',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      affiliateUrl: json['affiliateUrl'] as String? ?? '',
      category: PartCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => PartCategory.essential,
      ),
      image: json['image'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'affiliateUrl': affiliateUrl,
      'category': category.name,
      'image': image,
    };
  }
}
