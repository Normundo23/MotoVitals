import 'package:flutter_test/flutter_test.dart';
import 'package:moto_vitals/models/part.dart';

void main() {
  group('Part', () {
    test('fromJson creates a valid Part', () {
      final json = {
        'name': 'Exhaust',
        'price': 1500.0,
        'affiliateUrl': 'http://buy.this',
        'category': 'upgrade',
        'image': 'exhaust.png',
      };

      final part = Part.fromJson(json, 'part123');

      expect(part.id, 'part123');
      expect(part.name, 'Exhaust');
      expect(part.price, 1500.0);
      expect(part.affiliateUrl, 'http://buy.this');
      expect(part.category, PartCategory.upgrade);
      expect(part.image, 'exhaust.png');
    });

    test('fromJson handles missing category with default', () {
      final json = {
        'name': 'Brakes',
        'price': 200.0,
      };

      final part = Part.fromJson(json, 'part456');

      expect(part.category, PartCategory.essential);
    });

    test('toJson returns a valid map', () {
      final part = Part(
        id: 'part123',
        name: 'Exhaust',
        price: 1500.0,
        affiliateUrl: 'http://buy.this',
        category: PartCategory.upgrade,
        image: 'exhaust.png',
      );

      final json = part.toJson();

      expect(json['name'], 'Exhaust');
      expect(json['price'], 1500.0);
      expect(json['affiliateUrl'], 'http://buy.this');
      expect(json['category'], 'upgrade');
      expect(json['image'], 'exhaust.png');
    });
  });
}
