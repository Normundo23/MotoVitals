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
              currentOdo: 1800.0,
              lastOilChangeOdo: 1000.0,
              serviceInterval: 2000.0, // Used: 800. Remaining: 1200 (60%)
            ),
          ),
        ),
      );

      expect(find.text('60%'), findsOneWidget);
      expect(find.text('1200 km left'), findsOneWidget);
      expect(find.text('Good'), findsOneWidget);
    });

    testWidgets('Renders correct percentage text (overdue clamps to 0%)', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HealthRing(
              currentOdo: 4000.0,
              lastOilChangeOdo: 1000.0,
              serviceInterval: 2000.0, // Used: 3000. Remaining: 0 (0%)
            ),
          ),
        ),
      );

      expect(find.text('0%'), findsOneWidget);
      expect(find.text('0 km left'), findsOneWidget);
      expect(find.text('Overdue!'), findsOneWidget);
    });

    testWidgets('Renders correct percentage text (new oil)', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HealthRing(
              currentOdo: 1000.0,
              lastOilChangeOdo: 1000.0,
              serviceInterval: 2000.0, // Used: 0. Remaining: 2000 (100%)
            ),
          ),
        ),
      );

      expect(find.text('100%'), findsOneWidget);
      expect(find.text('2000 km left'), findsOneWidget);
      expect(find.text('Good'), findsOneWidget);
    });
  });
}
