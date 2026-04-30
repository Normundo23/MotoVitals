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
    // 500 distance driven / 2000 service interval = 25%
    expect(find.text('25.0%'), findsOneWidget);
    expect(find.text('Oil Health'), findsOneWidget);
    expect(find.text('500 / 2000 km'), findsOneWidget);
  });
}
