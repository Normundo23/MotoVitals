import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/part.dart';
import '../models/vehicle.dart';
import '../models/maintenance_part.dart';
import '../models/service_log.dart';
import '../models/build_post.dart';
import '../models/fuel_log.dart';
import '../models/vehicle_spec.dart';
import '../data/vehicle_spec_database.dart';

/// Wrapper returned by paginated gallery fetches.
class GalleryPage {
  final List<BuildPost> posts;
  final DocumentSnapshot? lastDoc;
  const GalleryPage({required this.posts, this.lastDoc});
}

class DatabaseService {
  final FirebaseFirestore? _db;
  final FirebaseAuth? _authInstance;

  DatabaseService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore,
        _authInstance = auth;

  bool get _isFirebaseInitialized => _db != null || Firebase.apps.isNotEmpty;

  FirebaseFirestore? get _firestore {
    if (_db != null) return _db;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseAuth? get _auth {
    if (_authInstance != null) return _authInstance;
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  String? get currentUserId {
    if (!_isFirebaseInitialized) return null;
    try { return _auth?.currentUser?.uid; } catch (_) { return null; }
  }

  // ── VEHICLE ──────────────────────────────────────────────────────────────────

  Stream<List<Vehicle>> get userVehiclesStream {
    if (!_isFirebaseInitialized) return Stream.value([]);
    final uid = currentUserId;
    if (uid == null || _firestore == null) return Stream.value([]);
    return _firestore!
        .collection('vehicles')
        .where('ownerId', isEqualTo: uid)
        .snapshots()
        .map((s) => s.docs.map((d) => Vehicle.fromJson(d.data(), d.id)).toList());
  }

  Future<void> saveVehicle(Vehicle vehicle) async {
    if (!_isFirebaseInitialized) throw Exception('Firebase not initialized');
    final uid = currentUserId;
    if (uid == null) throw Exception('Must be logged in');
    if (vehicle.ownerId != uid) throw Exception('UID mismatch');
    if (_firestore == null) throw Exception('Firestore unavailable');

    Vehicle v = vehicle;

    // ── Spec-aware part seeding ──────────────────────────────────────────────
    // Only seeds parts on first save (parts list is empty).
    // If the vehicle has a known specModelId, use the manufacturer's exact
    // intervals. Otherwise fall back to generic intervals.
    if (v.parts.isEmpty) {
      final spec = v.specModelId != null
          ? VehicleSpecDatabase.findById(v.specModelId!)
          : null;

      final List<MaintenancePart> seedParts = spec != null
          ? spec.maintenanceIntervals
              .map((i) => MaintenancePart(
                    name: i.name,
                    interval: i.intervalKm.toDouble(),
                    lastServiceOdo: v.odo,
                  ))
              .toList()
          : _genericFallbackParts(v.odo);

      v = Vehicle(
        id: v.id,
        ownerId: v.ownerId,
        make: v.make,
        modelType: v.modelType,
        modelName: v.modelName,
        odo: v.odo,
        purchaseDate: v.purchaseDate,
        specModelId: v.specModelId,
        parts: seedParts,
      );
    }

    await _firestore!
        .collection('vehicles')
        .doc(v.id)
        .set(v.toJson(), SetOptions(merge: true));
  }

  /// Generic maintenance parts for "Other" models with no spec data.
  List<MaintenancePart> _genericFallbackParts(double currentOdo) => [
    MaintenancePart(name: 'Engine Oil', interval: 2000, lastServiceOdo: currentOdo),
    MaintenancePart(name: 'Brake Inspection', interval: 5000, lastServiceOdo: currentOdo),
    MaintenancePart(name: 'Chain Lubrication', interval: 500, lastServiceOdo: currentOdo),
    MaintenancePart(name: 'Air Filter (Clean)', interval: 4000, lastServiceOdo: currentOdo),
    MaintenancePart(name: 'Spark Plug', interval: 8000, lastServiceOdo: currentOdo),
  ];

  // ── SERVICE LOG ──────────────────────────────────────────────────────────────

  Future<void> addServiceLog(ServiceLog log) async {
    if (!_isFirebaseInitialized || _firestore == null) throw Exception('Firebase not initialized');
    final ref = _firestore!
        .collection('vehicles')
        .doc(log.vehicleId)
        .collection('serviceLogs')
        .doc();
    await ref.set({...log.toJson(), 'id': ref.id});
  }

  Stream<List<ServiceLog>> serviceLogStream(String vehicleId) {
    if (!_isFirebaseInitialized || _firestore == null) return Stream.value([]);
    return _firestore!
        .collection('vehicles')
        .doc(vehicleId)
        .collection('serviceLogs')
        .orderBy('serviceDate', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => ServiceLog.fromJson(d.data(), d.id))
            .toList());
  }

  // ── FUEL LOG ─────────────────────────────────────────────────────────────────

  Future<void> addFuelLog(FuelLog log) async {
    if (!_isFirebaseInitialized || _firestore == null) throw Exception('Firebase not initialized');
    final ref = _firestore!
        .collection('vehicles')
        .doc(log.vehicleId)
        .collection('fuelLogs')
        .doc();
    await ref.set({...log.toJson(), 'id': ref.id});
  }

  Stream<List<FuelLog>> fuelLogStream(String vehicleId) {
    if (!_isFirebaseInitialized || _firestore == null) return Stream.value([]);
    return _firestore!
        .collection('vehicles')
        .doc(vehicleId)
        .collection('fuelLogs')
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => FuelLog.fromJson(d.data(), d.id))
            .toList());
  }

  // ── BUILD GALLERY (paginated — no real-time stream) ───────────────────────────

  Future<GalleryPage> getBuildPostsPaginated({
    int limit = 10,
    DocumentSnapshot? lastDocument,
  }) async {
    if (!_isFirebaseInitialized || _firestore == null) {
      return const GalleryPage(posts: []);
    }
    Query q = _firestore!
        .collection('buildPosts')
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (lastDocument != null) q = q.startAfterDocument(lastDocument);
    final snap = await q.get();
    final posts = snap.docs
        .map((d) => BuildPost.fromJson(d.data() as Map<String, dynamic>, d.id))
        .toList();
    return GalleryPage(
      posts: posts,
      lastDoc: snap.docs.isNotEmpty ? snap.docs.last : null,
    );
  }

  Future<void> createBuildPost(BuildPost post) async {
    if (!_isFirebaseInitialized || _firestore == null) throw Exception('Firebase not initialized');
    if (currentUserId == null) throw Exception('Must be logged in');
    final ref = _firestore!.collection('buildPosts').doc();
    await ref.set({...post.toJson(), 'id': ref.id});
  }

  Future<void> toggleLike(String postId, bool isLiked) async {
    if (!_isFirebaseInitialized || _firestore == null) return;
    final uid = currentUserId;
    if (uid == null) return;
    final postRef = _firestore!.collection('buildPosts').doc(postId);
    final likeRef = postRef.collection('likes').doc(uid);
    await _firestore!.runTransaction((tx) async {
      final snap = await tx.get(likeRef);
      if (snap.exists) {
        tx.delete(likeRef);
        tx.update(postRef, {'likeCount': FieldValue.increment(-1)});
      } else {
        tx.set(likeRef, {'uid': uid});
        tx.update(postRef, {'likeCount': FieldValue.increment(1)});
      }
    });
  }

  Future<bool> hasLiked(String postId) async {
    if (!_isFirebaseInitialized || _firestore == null) return false;
    final uid = currentUserId;
    if (uid == null) return false;
    final doc = await _firestore!
        .collection('buildPosts')
        .doc(postId)
        .collection('likes')
        .doc(uid)
        .get();
    return doc.exists;
  }

  Future<void> deleteBuildPost(String postId) async {
    if (!_isFirebaseInitialized || _firestore == null) return;
    if (currentUserId == null) throw Exception('Must be logged in');
    await _firestore!.collection('buildPosts').doc(postId).delete();
  }

  // ── MARKETPLACE ──────────────────────────────────────────────────────────────

  Future<QuerySnapshot> getRawPartDocuments({
    int limit = 8,
    DocumentSnapshot? lastDocument,
  }) async {
    if (!_isFirebaseInitialized || _firestore == null) throw Exception('Firebase not initialized');
    Query q = _firestore!.collection('parts').orderBy('name').limit(limit);
    if (lastDocument != null) q = q.startAfterDocument(lastDocument);
    return q.get();
  }

  Future<List<Part>> getPartsByIds(List<String> ids) async {
    if (!_isFirebaseInitialized || _firestore == null || ids.isEmpty) return [];
    final docs = await Future.wait(
        ids.map((id) => _firestore!.collection('parts').doc(id).get()));
    return docs
        .where((d) => d.exists)
        .map((d) => Part.fromJson(d.data() as Map<String, dynamic>, d.id))
        .toList();
  }
}
