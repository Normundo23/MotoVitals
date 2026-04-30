import 'package:flutter_test/flutter_test.dart';
import 'package:moto_vitals/models/maintenance_part.dart';

void main() {
  group('MaintenancePart Tests', () {
    test('Calculates remaining life percentage correctly (normal usage)', () {
      final part = MaintenancePart(
        name: 'Engine Oil',
        interval: 1500.0,
        lastServiceOdo: 1000.0,
      );

      // Current odo is 1750, meaning 750 driven since last service.
      // Remaining life: 1500 - 750 = 750. Percentage: 750 / 1500 = 0.5
      final percentage = part.getRemainingLifePercentage(1750.0);
      expect(percentage, 0.5);
    });

    test('Calculates remaining life percentage correctly (overdue)', () {
      final part = MaintenancePart(
        name: 'Engine Oil',
        interval: 1500.0,
        lastServiceOdo: 1000.0,
      );

      // Current odo is 3000, meaning 2000 driven.
      // Remaining life should clamp to 0. Percentage: 0.0
      final percentage = part.getRemainingLifePercentage(3000.0);
      expect(percentage, 0.0);
    });

    test('Guards against negative distance driven', () {
      final part = MaintenancePart(
        name: 'Engine Oil',
        interval: 1500.0,
        lastServiceOdo: 1000.0,
      );

      // Current odo is 500 (somehow less than last service, e.g. typo/revert).
      // Distance driven should clamp to 0. Remaining life: 1500. Percentage: 1.0
      final percentage = part.getRemainingLifePercentage(500.0);
      expect(percentage, 1.0);
    });

    test('Serialization to/from JSON works correctly', () {
      final part = MaintenancePart(
        name: 'Brake Pads',
        interval: 5000.0,
        lastServiceOdo: 2500.0,
      );

      final json = part.toJson();
      expect(json['name'], 'Brake Pads');
      expect(json['interval'], 5000.0);
      expect(json['lastServiceOdo'], 2500.0);

      final newPart = MaintenancePart.fromJson(json);
      expect(newPart.name, 'Brake Pads');
      expect(newPart.interval, 5000.0);
      expect(newPart.lastServiceOdo, 2500.0);
    });
  });
}
