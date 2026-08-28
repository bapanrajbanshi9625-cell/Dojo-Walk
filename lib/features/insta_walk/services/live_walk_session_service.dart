import 'package:cloud_firestore/cloud_firestore.dart';

class LiveWalkSessionService {
  LiveWalkSessionService({
    FirebaseFirestore? firestore,
  }) : _firestore =
            firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String collectionName =
      'liveWalkSessions';

  CollectionReference<Map<String, dynamic>>
      get _collection =>
          _firestore.collection(collectionName);

  // ==========================================================
  // CREATE LIVE SESSION
  // ==========================================================

  Future<DocumentReference<Map<String, dynamic>>>
      createSession({
    required String walkId,
    required String ownerId,
    required String ownerUid,
    required String ownerName,
    required String ownerPhone,
    required String walkerId,
    required String walkerUid,
    required String walkerName,
    required String dogName,
    required String dogBreed,
    GeoPoint? currentLocation,
    GeoPoint? destinationLocation,
  }) async {
    final DocumentReference<Map<String, dynamic>>
        sessionRef =
        _collection.doc();

    final DateTime now = DateTime.now();

    await sessionRef.set({
      // ======================================================
      // IDENTIFICATION
      // ======================================================

      'walkId': walkId,

      // ======================================================
      // OWNER
      // ======================================================

      'ownerId': ownerId,
      'ownerUid': ownerUid,
      'ownerName': ownerName,
      'ownerPhone': ownerPhone,

      // ======================================================
      // WALKER
      // ======================================================

      'walkerId': walkerId,
      'walkerUid': walkerUid,
      'walkerName': walkerName,

      // ======================================================
      // DOG
      // ======================================================

      'dogName': dogName,
      'dogBreed': dogBreed,

      // ======================================================
      // STATUS
      // ======================================================

      'status': 'active',

      // ======================================================
      // TRACKING
      // ======================================================

      'trackingStarted': false,
      'trackingEnded': false,

      'walkStarted': false,
      'walkEnded': false,

      // ======================================================
      // LOCATION
      // ======================================================

      'currentLocation': currentLocation,

      'destinationLocation':
          destinationLocation,

      // ======================================================
      // STATS
      // ======================================================

      'distanceKm': 0.0,
      'elapsedSeconds': 0,
      'peeCount': 0,
      'poopCount': 0,
      'steps': 0,

      // ======================================================
      // ROUTE
      // ======================================================

      'routeCoordinates':
          <GeoPoint>[],

      // ======================================================
      // EVENTS
      // ======================================================

      'events': <String>[],

      // ======================================================
      // TIME
      // ======================================================

      'createdAt':
          Timestamp.fromDate(now),

      'startedAt':
          Timestamp.fromDate(now),

      'updatedAt':
          Timestamp.fromDate(now),

      'endedAt': null,
    });

    return sessionRef;
  }

  // ==========================================================
  // FIND SESSION BY WALK ID
  // ==========================================================

  Future<DocumentSnapshot<Map<String, dynamic>>?>
      findByWalkId(
    String walkId,
  ) async {
    final QuerySnapshot<Map<String, dynamic>>
        snapshot =
        await _collection
            .where(
              'walkId',
              isEqualTo: walkId,
            )
            .limit(1)
            .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return snapshot.docs.first;
  }

  // ==========================================================
  // START TRACKING
  // ==========================================================

  Future<void> startTracking(
    String sessionId,
  ) async {
    await _collection.doc(sessionId).update({
      'status': 'walking',
      'trackingStarted': true,
      'walkStarted': true,
      'trackingEnded': false,
      'walkEnded': false,
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  // ==========================================================
  // UPDATE LOCATION
  // ==========================================================

  Future<void> updateLocation({
    required String sessionId,
    required GeoPoint location,
    double? distanceKm,
    int? elapsedSeconds,
    int? steps,
  }) async {
    final Map<String, dynamic> update =
        <String, dynamic>{
      'currentLocation': location,
      'updatedAt':
          FieldValue.serverTimestamp(),
    };

    if (distanceKm != null) {
      update['distanceKm'] = distanceKm;
    }

    if (elapsedSeconds != null) {
      update['elapsedSeconds'] =
          elapsedSeconds;
    }

    if (steps != null) {
      update['steps'] = steps;
    }

    await _collection
        .doc(sessionId)
        .update(update);
  }

  // ==========================================================
  // UPDATE TOILET COUNTS
  // ==========================================================

  Future<void> updateToiletCounts({
    required String sessionId,
    required int peeCount,
    required int poopCount,
  }) async {
    await _collection.doc(sessionId).update({
      'peeCount': peeCount,
      'poopCount': poopCount,
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  // ==========================================================
  // ADD ROUTE POINT
  // ==========================================================

  Future<void> addRoutePoint({
    required String sessionId,
    required GeoPoint location,
  }) async {
    await _collection.doc(sessionId).update({
      'routeCoordinates':
          FieldValue.arrayUnion([
        location,
      ]),
      'currentLocation': location,
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  // ==========================================================
  // ADD EVENT
  // ==========================================================

  Future<void> addEvent({
    required String sessionId,
    required String event,
  }) async {
    final String cleanEvent =
        event.trim();

    if (cleanEvent.isEmpty) {
      return;
    }

    await _collection.doc(sessionId).update({
      'events':
          FieldValue.arrayUnion([
        cleanEvent,
      ]),
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  // ==========================================================
  // END SESSION
  // ==========================================================

  Future<void> endSession({
    required String sessionId,
    required int elapsedSeconds,
    required double distanceKm,
    required int peeCount,
    required int poopCount,
    required List<GeoPoint> routeCoordinates,
    GeoPoint? currentLocation,
  }) async {
    await _collection.doc(sessionId).update({
      'status': 'completed',

      'trackingEnded': true,
      'walkEnded': true,

      'endedAt':
          FieldValue.serverTimestamp(),

      'updatedAt':
          FieldValue.serverTimestamp(),

      'elapsedSeconds':
          elapsedSeconds,

      'distanceKm':
          distanceKm,

      'peeCount':
          peeCount,

      'poopCount':
          poopCount,

      'routeCoordinates':
          routeCoordinates,

      'currentLocation':
          currentLocation,
    });
  }
}
