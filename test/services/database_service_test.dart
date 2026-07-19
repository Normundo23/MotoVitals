import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:moto_vitals/services/database_service.dart';
import 'package:moto_vitals/models/vehicle.dart';

void main() {
  group('DatabaseService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth mockAuth;
    late DatabaseService databaseService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockAuth = MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'user123'));
      databaseService = DatabaseService(firestore: fakeFirestore, auth: mockAuth);
    });

    test('saveVehicle saves vehicle data to Firestore', () async {
      final vehicle = Vehicle(
        id: 'veh123',
        ownerId: 'user123',
        make: 'Honda',
        modelType: VehicleModelType.hondaWinnerX,
        modelName: 'Winner X',
        odo: 12000,
        purchaseDate: DateTime(2024, 1, 1),
      );

      await databaseService.saveVehicle(vehicle);

      final doc = await fakeFirestore.collection('vehicles').doc('veh123').get();
      expect(doc.exists, true);
      expect(doc.data()?['make'], 'Honda');
      expect(doc.data()?['modelName'], 'Winner X');
      // Should also have seeded parts
      expect(doc.data()?['parts'], isNotEmpty);
    });

    test('saveVehicle throws error if user ID mismatch', () async {
      final vehicle = Vehicle(
        id: 'veh123',
        ownerId: 'otherUser',
        make: 'Honda',
        modelType: VehicleModelType.hondaWinnerX,
        modelName: 'Winner X',
        odo: 12000,
        purchaseDate: DateTime(2024, 1, 1),
      );

      expect(() => databaseService.saveVehicle(vehicle), throwsException);
    });
  });
}
