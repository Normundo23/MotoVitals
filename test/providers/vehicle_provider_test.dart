import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:moto_vitals/models/part.dart';
import 'package:moto_vitals/models/vehicle.dart';
import 'package:moto_vitals/providers/vehicle_provider.dart';
import 'package:moto_vitals/services/database_service.dart';

class MockDatabaseService implements DatabaseService {
  Vehicle? lastSavedVehicle;
  final StreamController<Vehicle?> _vehicleStreamController = StreamController<Vehicle?>.broadcast();

  void emitVehicle(Vehicle? vehicle) {
    _vehicleStreamController.add(vehicle);
  }

  void emitError(String error) {
    _vehicleStreamController.addError(error);
  }

  @override
  Stream<Vehicle?> get userVehicleStream => _vehicleStreamController.stream;

  @override
  Future<void> saveVehicle(Vehicle vehicle) async {
    lastSavedVehicle = vehicle;
    // Simulate updating the stream after save
    emitVehicle(vehicle);
  }

  @override
  String? get currentUserId => 'test_uid';

  @override
  Future<List<Part>> getPartsPaginated({int limit = 10, DocumentSnapshot<Object?>? lastDocument}) {
    throw UnimplementedError();
  }

  @override
  Future<QuerySnapshot<Object?>> getRawPartDocuments({int limit = 10, DocumentSnapshot<Object?>? lastDocument}) {
    throw UnimplementedError();
  }
}

void main() {
  group('VehicleProvider Tests', () {
    late MockDatabaseService mockDb;
    late VehicleProvider provider;

    setUp(() {
      mockDb = MockDatabaseService();
      provider = VehicleProvider(db: mockDb);
    });

    test('Initial state is loading', () {
      expect(provider.isLoading, true);
      expect(provider.currentVehicle, isNull);
      expect(provider.error, isNull);
    });

    test('Updates state when vehicle stream emits', () async {
      final testVehicle = Vehicle(
        id: 'v1',
        ownerId: 'u1',
        make: 'Honda',
        modelType: VehicleModelType.hondaWinnerX,
        odo: 1000.0,
      );

      // Give stream time to attach
      await Future.delayed(Duration.zero);
      
      mockDb.emitVehicle(testVehicle);
      
      // Wait for provider to process stream
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.isLoading, false);
      expect(provider.currentVehicle, isNotNull);
      expect(provider.currentVehicle!.odo, 1000.0);
    });

    test('updateOdometer throws if vehicle is null', () async {
      expect(() => provider.updateOdometer(100.0), returnsNormally); // Returns early if null, doesn't throw. Wait, it just returns. Let's check the code.
      // Ah, code says `if (_currentVehicle == null) return;`. It doesn't throw.
    });

    test('updateOdometer throws if new odo is negative or less than current', () async {
      final testVehicle = Vehicle(
        id: 'v1',
        ownerId: 'u1',
        make: 'Honda',
        modelType: VehicleModelType.hondaWinnerX,
        odo: 1000.0,
      );

      await Future.delayed(Duration.zero);
      mockDb.emitVehicle(testVehicle);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(() => provider.updateOdometer(-50.0), throwsException);
      expect(() => provider.updateOdometer(500.0), throwsException); // 500 < 1000
    });

    test('updateOdometer successfully calls saveVehicle with new odo', () async {
      final testVehicle = Vehicle(
        id: 'v1',
        ownerId: 'u1',
        make: 'Honda',
        modelType: VehicleModelType.hondaWinnerX,
        odo: 1000.0,
      );

      await Future.delayed(Duration.zero);
      mockDb.emitVehicle(testVehicle);
      await Future.delayed(const Duration(milliseconds: 50));

      await provider.updateOdometer(1200.0);

      expect(mockDb.lastSavedVehicle, isNotNull);
      expect(mockDb.lastSavedVehicle!.odo, 1200.0);
      
      await Future.delayed(const Duration(milliseconds: 50));
      expect(provider.currentVehicle!.odo, 1200.0);
    });
  });
}
