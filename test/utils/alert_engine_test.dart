import 'package:flutter_test/flutter_test.dart';
import 'package:moto_vitals/models/maintenance_part.dart';
import 'package:moto_vitals/utils/alert_engine.dart';

void main() {
  group('AlertEngine', () {
    const double odo = 1000.0;

    test('generates critical alert when life is below 15%', () {
      final parts = [
        MaintenancePart(
          name: 'Engine Oil',
          interval: 1000.0,
          lastServiceOdo: 100.0, // Used: 900, Left: 100 (10%)
        ),
      ];

      final alerts = AlertEngine.generate(parts: parts, currentOdo: odo);

      expect(alerts.length, 1);
      expect(alerts[0].severity, AlertSeverity.critical);
      expect(alerts[0].remainingKm, 100.0);
      expect(alerts[0].remainingPercent, 0.1);
      expect(alerts[0].headline, contains('Engine Oil'));
      expect(alerts[0].suggestion, contains('Change oil now'));
    });

    test('generates warning alert when life is between 15% and 40%', () {
      
      // Let's redo math:
      // interval 1000.
      // currentOdo 1000.
      // lastServiceOdo 300.
      // used = 1000 - 300 = 700.
      // remaining = 1000 - 700 = 300.
      // percent = 300 / 1000 = 0.3 (30%) -> Warning.

      final warningParts = [
        MaintenancePart(
          name: 'Brake Pads',
          interval: 1000.0,
          lastServiceOdo: 300.0,
        ),
      ];

      final alerts = AlertEngine.generate(parts: warningParts, currentOdo: odo);

      expect(alerts.length, 1);
      expect(alerts[0].severity, AlertSeverity.warning);
      expect(alerts[0].remainingKm, 300.0);
      expect(alerts[0].remainingPercent, 0.3);
      expect(alerts[0].suggestion, contains('Brake inspection due'));
    });

    test('generates good alert when life is above 40%', () {
      final parts = [
        MaintenancePart(
          name: 'Chain Drive',
          interval: 1000.0,
          lastServiceOdo: 900.0, // Used: 100, Left: 900 (90%)
        ),
      ];

      final alerts = AlertEngine.generate(parts: parts, currentOdo: odo);

      expect(alerts.length, 1);
      expect(alerts[0].severity, AlertSeverity.good);
      expect(alerts[0].remainingKm, 900.0);
      expect(alerts[0].remainingPercent, 0.9);
      expect(alerts[0].suggestion, contains('Chain is well-lubricated'));
    });

    test('sorts alerts by severity (critical first)', () {
      // Let's use currentOdo 1000.0 and define parts correctly:
      // Critical: 10% left -> lastServiceOdo 100.0
      // Warning: 30% left -> lastServiceOdo 300.0
      // Good: 90% left -> lastServiceOdo 900.0
      final sortedParts = [
        MaintenancePart(name: 'Good', interval: 1000.0, lastServiceOdo: 900.0),
        MaintenancePart(name: 'Critical', interval: 1000.0, lastServiceOdo: 100.0),
        MaintenancePart(name: 'Warning', interval: 1000.0, lastServiceOdo: 300.0),
      ];

      final alerts = AlertEngine.generate(parts: sortedParts, currentOdo: 1000.0);

      expect(alerts[0].severity, AlertSeverity.critical);
      expect(alerts[1].severity, AlertSeverity.warning);
      expect(alerts[2].severity, AlertSeverity.good);
    });

    test('hasActiveAlerts returns true if any part is warning or critical', () {
      final goodParts = [
        MaintenancePart(name: 'Good', interval: 1000.0, lastServiceOdo: 1000.0),
      ];
      final warningParts = [
        MaintenancePart(name: 'Warning', interval: 1000.0, lastServiceOdo: 300.0),
      ];

      expect(AlertEngine.hasActiveAlerts(goodParts, 1000.0), isFalse);
      expect(AlertEngine.hasActiveAlerts(warningParts, 1000.0), isTrue);
    });
  });
}
