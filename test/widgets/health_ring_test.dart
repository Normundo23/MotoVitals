import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moto_vitals/widgets/health_ring.dart';

void main() {
  group('HealthRing Widget Tests', () {
    testWidgets('Renders correct percentage text (normal usage)', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HealthRing(
              currentOdo: 2000.0,
              lastOilChangeOdo: 1000.0,
              serviceInterval: 2000.0, // Defaults to 2000, 1000 driven = 50%
            ),
          ),
        ),
      );

      // Distance driven = 1000. Progress = 1000/2000 = 0.5 (50.0%)
      expect(find.text('50.0%'), findsOneWidget);
      expect(find.text('1000 / 2000 km'), findsOneWidget);
    });

    testWidgets('Renders correct percentage text (overdue clamps to 100%)', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HealthRing(
              currentOdo: 4000.0,
              lastOilChangeOdo: 1000.0,
              serviceInterval: 2000.0, // Distance driven = 3000. Progress clamps to 1.0 (100.0%)
            ),
          ),
        ),
      );

      expect(find.text('100.0%'), findsOneWidget);
      expect(find.text('3000 / 2000 km'), findsOneWidget);
    });

    testWidgets('Renders correct percentage text (new oil)', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HealthRing(
              currentOdo: 1000.0,
              lastOilChangeOdo: 1000.0,
              serviceInterval: 2000.0, // Distance driven = 0. Progress = 0.0%
            ),
          ),
        ),
      );

      expect(find.text('0.0%'), findsOneWidget);
      expect(find.text('0 / 2000 km'), findsOneWidget);
    });
  });
}
