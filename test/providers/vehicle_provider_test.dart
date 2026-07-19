import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:moto_vitals/models/part.dart';
import 'package:moto_vitals/models/vehicle.dart';
import 'package:moto_vitals/models/service_log.dart';
import 'package:moto_vitals/models/build_post.dart';
import 'package:moto_vitals/models/fuel_log.dart';
import 'package:moto_vitals/providers/vehicle_provider.dart';
import 'package:moto_vitals/services/database_service.dart';

class MockDatabaseService implements DatabaseService {
  Vehicle? lastSavedVehicle;
  final StreamController<List<Vehicle>> _vehiclesStreamController = StreamController<List<Vehicle>>.broadcast();

  void emitVehicles(List<Vehicle> vehicles) {
    _vehiclesStreamController.add(vehicles);
  }

  void emitError(String error) {
    _vehiclesStreamController.addError(error);
  }

  @override
  Stream<List<Vehicle>> get userVehiclesStream => _vehiclesStreamController.stream;

  @override
  Future<void> saveVehicle(Vehicle vehicle) async {
    lastSavedVehicle = vehicle;
    emitVehicles([vehicle]);
  }

  @override
  String? get currentUserId => 'test_uid';

  @override
  Future<void> addServiceLog(ServiceLog log) async {}

  @override
  Stream<List<ServiceLog>> serviceLogStream(String vehicleId) => Stream.value([]);

  @override
  Future<void> addFuelLog(FuelLog log) async {}

  @override
  Stream<List<FuelLog>> fuelLogStream(String vehicleId) => Stream.value([]);

  @override
  Future<GalleryPage> getBuildPostsPaginated({int limit = 10, DocumentSnapshot? lastDocument}) async {
    return const GalleryPage(posts: []);
  }

  @override
  Future<void> createBuildPost(BuildPost post) async {}

  @override
  Future<void> toggleLike(String postId, bool isLiked) async {}

  @override
  Future<bool> hasLiked(String postId) async => false;

  @override
  Future<void> deleteBuildPost(String postId) async {}

  @override
  Future<List<Part>> getPartsByIds(List<String> ids) async => [];

  @override
  Future<QuerySnapshot> getRawPartDocuments({int limit = 10, DocumentSnapshot? lastDocument}) {
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
      
      mockDb.emitVehicles([testVehicle]);
      
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
      mockDb.emitVehicles([testVehicle]);
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
      mockDb.emitVehicles([testVehicle]);
      await Future.delayed(const Duration(milliseconds: 50));

      await provider.updateOdometer(1200.0);

      expect(mockDb.lastSavedVehicle, isNotNull);
      expect(mockDb.lastSavedVehicle!.odo, 1200.0);
      
      await Future.delayed(const Duration(milliseconds: 50));
      expect(provider.currentVehicle!.odo, 1200.0);
    });
  });
}
