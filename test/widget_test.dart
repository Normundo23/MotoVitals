import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moto_vitals/widgets/health_ring.dart';

void main() {
  testWidgets('HealthRing renders properly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: HealthRing(
          currentOdo: 1500,
          lastOilChangeOdo: 1000,
        ),
      ),
    ));

    // Wait for the animation to complete
    await tester.pumpAndSettle();

    // Verify that the health ring text displays the correct calculation.
    // distance driven = 1500 - 1000 = 500.
    // remaining = 1500 - 500 = 1000.
    // percent = 1000 / 1500 = 66.66% -> rounded to 67%
    expect(find.text('67%'), findsOneWidget);
    expect(find.text('Oil Health'), findsOneWidget);
    expect(find.text('1000 km left'), findsOneWidget);
    expect(find.text('Good'), findsOneWidget);
  });
}
