import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/part.dart';
import '../models/vehicle.dart';
import '../models/maintenance_part.dart';

class DatabaseService {
  bool get _isFirebaseInitialized {
    return Firebase.apps.isNotEmpty;
  }

  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  String? get currentUserId {
    if (!_isFirebaseInitialized) return null;
    try {
      return _auth?.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  // VEHICLE OPERATIONS
  
  /// Get current user's vehicle stream
  Stream<Vehicle?> get userVehicleStream {
    if (!_isFirebaseInitialized) return Stream.value(null);
    final uid = currentUserId;
    if (uid == null || _firestore == null) return Stream.value(null);

    return _firestore!
        .collection('vehicles')
        .where('ownerId', isEqualTo: uid)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return Vehicle.fromJson(snapshot.docs.first.data(), snapshot.docs.first.id);
      }
      return null;
    });
  }

  /// Create or update vehicle
  Future<void> saveVehicle(Vehicle vehicle) async {
    if (!_isFirebaseInitialized) throw Exception('Firebase not initialized');
    final uid = currentUserId;
    if (uid == null) throw Exception('Must be logged in to save vehicle');
    if (vehicle.ownerId != uid) throw Exception('Authorization error: UID mismatch');
    if (_firestore == null) throw Exception('Firestore not available');

    Vehicle vehicleToSave = vehicle;
    if (vehicleToSave.parts.isEmpty) {
      final List<MaintenancePart> defaultParts = [
        MaintenancePart(name: 'Engine Oil', interval: 1500.0, lastServiceOdo: vehicle.odo),
        MaintenancePart(name: 'Brake Pads (Front/Rear)', interval: 5000.0, lastServiceOdo: vehicle.odo),
        MaintenancePart(name: 'Chain Drive', interval: 500.0, lastServiceOdo: vehicle.odo),
        MaintenancePart(name: 'Coolant', interval: 10000.0, lastServiceOdo: vehicle.odo),
      ];
      vehicleToSave = Vehicle(
        id: vehicle.id,
        ownerId: vehicle.ownerId,
        make: vehicle.make,
        modelType: vehicle.modelType,
        modelName: vehicle.modelName,
        odo: vehicle.odo,
        purchaseDate: vehicle.purchaseDate,
        parts: defaultParts,
      );
    }

    await _firestore!.collection('vehicles').doc(vehicleToSave.id).set(vehicleToSave.toJson(), SetOptions(merge: true));
  }

  // MARKETPLACE PART OPERATIONS

  /// Fetch a paginated list of parts to ensure UI stays within free Firestore daily limits.
  /// Pass [lastDocument] to get the next page.
  Future<List<Part>> getPartsPaginated({
    int limit = 10,
    DocumentSnapshot? lastDocument,
  }) async {
    if (!_isFirebaseInitialized || _firestore == null) return [];
    Query query = _firestore!.collection('parts').orderBy('name').limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final querySnapshot = await query.get();

    return querySnapshot.docs.map((doc) {
      return Part.fromJson(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
  }

  /// Fetch references for the pagination cursors using standard query
  Future<QuerySnapshot> getRawPartDocuments({
    int limit = 10,
    DocumentSnapshot? lastDocument,
  }) async {
    if (!_isFirebaseInitialized || _firestore == null) throw Exception('Firebase not initialized');
    Query query = _firestore!.collection('parts').orderBy('name').limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }
    return query.get();
  }
}
