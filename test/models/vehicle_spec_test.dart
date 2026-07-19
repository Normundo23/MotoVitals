import 'package:flutter_test/flutter_test.dart';
import 'package:moto_vitals/models/vehicle_spec.dart';

void main() {
  group('VehicleSpec', () {
    const oilSpec = OilSpec(
      type: '10W-40',
      volumeLiters: 1.1,
      grade: 'MA2',
      recommended: 'Motul',
    );

    const sparkPlugSpec = SparkPlugSpec(
      partNumber: 'NGK123',
      gap: '0.8mm',
      intervalKm: 8000,
    );

    const chainSpec = ChainSpec(
      size: '520',
      links: 110,
      slackMm: 25.0,
      lubeIntervalKm: 500,
      replaceIntervalKm: 20000,
    );

    const brakeSpec = BrakeSpec(
      frontType: 'Disc',
      rearType: 'Disc',
      frontThicknessMm: 1.5,
      rearThicknessMm: 1.5,
      inspectIntervalKm: 4000,
    );

    const tireSpec = TireSpec(
      frontSize: '120/70',
      rearSize: '160/60',
      frontPressurePsi: 32,
      rearPressurePsi: 36,
      rearPressurePsiLoaded: 42,
      type: 'Tubeless',
    );

    const airFilterSpec = AirFilterSpec(
      filterType: 'Paper',
      cleanIntervalKm: 4000,
      replaceIntervalKm: 12000,
    );

    const coolantSpec = CoolantSpec(
      type: 'Green',
      volumeLiters: 1.5,
      color: 'Green',
      flushIntervalKm: 24000,
    );

    test('maintenanceIntervals returns correct list for liquid-cooled vehicle', () {
      const spec = VehicleSpec(
        modelId: 'test_bike',
        make: 'Test',
        modelName: 'Bike',
        engineCc: 500,
        engineType: 'Liquid-cooled',
        isCoolant: true,
        oil: oilSpec,
        oilChangeIntervalKm: 5000,
        sparkPlug: sparkPlugSpec,
        chain: chainSpec,
        brakes: brakeSpec,
        tires: tireSpec,
        airFilter: airFilterSpec,
        coolant: coolantSpec,
      );

      final intervals = spec.maintenanceIntervals;

      expect(intervals.length, 7);
      expect(intervals[0].name, 'Engine Oil');
      expect(intervals[1].name, 'Spark Plug');
      expect(intervals[2].name, 'Air Filter (Clean)');
      expect(intervals[3].name, 'Air Filter (Replace)');
      expect(intervals[4].name, 'Chain Lubrication');
      expect(intervals[5].name, 'Brake Inspection');
      expect(intervals[6].name, 'Coolant Flush');
    });

    test('maintenanceIntervals returns correct list for air-cooled vehicle', () {
      const spec = VehicleSpec(
        modelId: 'test_bike_air',
        make: 'Test',
        modelName: 'Bike Air',
        engineCc: 200,
        engineType: 'Air-cooled',
        isCoolant: false,
        oil: oilSpec,
        oilChangeIntervalKm: 3000,
        sparkPlug: sparkPlugSpec,
        chain: chainSpec,
        brakes: brakeSpec,
        tires: tireSpec,
        airFilter: airFilterSpec,
        coolant: null,
      );

      final intervals = spec.maintenanceIntervals;

      expect(intervals.length, 6);
      expect(intervals.any((i) => i.name == 'Coolant Flush'), false);
    });
  });
}
