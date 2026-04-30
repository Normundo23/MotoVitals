import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:moto_vitals/models/vehicle.dart';
import 'package:moto_vitals/models/maintenance_part.dart';

void main() {
  group('Vehicle Tests', () {
    test('Serialization to/from JSON works correctly', () {
      final purchaseDate = DateTime(2023, 1, 1);
      final vehicle = Vehicle(
        id: 'v123',
        ownerId: 'u456',
        make: 'Honda',
        modelType: VehicleModelType.hondaWinnerX,
        modelName: 'Winner X 150',
        odo: 5000.0,
        purchaseDate: purchaseDate,
        parts: [
          MaintenancePart(name: 'Engine Oil', interval: 1500.0, lastServiceOdo: 4500.0),
        ],
      );

      final json = vehicle.toJson();
      expect(json['ownerId'], 'u456');
      expect(json['make'], 'Honda');
      expect(json['modelType'], 'hondaWinnerX');
      expect(json['modelName'], 'Winner X 150');
      expect(json['odo'], 5000.0);
      expect(json['purchaseDate'], isA<Timestamp>()); // Handled internally
      expect(json['parts'], isA<List>());
      expect((json['parts'] as List).length, 1);

      final newVehicle = Vehicle.fromJson(json, 'v123');
      expect(newVehicle.id, 'v123');
      expect(newVehicle.ownerId, 'u456');
      expect(newVehicle.make, 'Honda');
      expect(newVehicle.modelType, VehicleModelType.hondaWinnerX);
      expect(newVehicle.modelName, 'Winner X 150');
      expect(newVehicle.odo, 5000.0);
      expect(newVehicle.purchaseDate, purchaseDate);
      expect(newVehicle.parts.length, 1);
      expect(newVehicle.parts.first.name, 'Engine Oil');
    });

    test('Handles missing fields correctly in fromJson', () {
      final json = {
        'ownerId': 'u456',
        'odo': 100.0,
        // Missing make, modelType, modelName, purchaseDate, parts
      };

      final vehicle = Vehicle.fromJson(json, 'v123');
      expect(vehicle.id, 'v123');
      expect(vehicle.ownerId, 'u456');
      expect(vehicle.make, 'Unknown Make');
      expect(vehicle.modelType, VehicleModelType.other); // Fallback
      expect(vehicle.modelName, '');
      expect(vehicle.odo, 100.0);
      expect(vehicle.purchaseDate, isNull);
      expect(vehicle.parts, isEmpty);
    });
  });
}
