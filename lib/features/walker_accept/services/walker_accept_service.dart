import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/walker_accept_data.dart';

class WalkerAcceptService {
  WalkerAcceptService({
    FirebaseFirestore? firestore,
  }) : _firestore =
            firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // ==========================================================
  // COLLECTION
  // ==========================================================

  static const String collectionName = 'walk_request';

  // ==========================================================
  // WATCH ACCEPTED WALK REQUEST
  // ==========================================================

  Stream<WalkerAcceptData?> watchRequest(
    String requestId,
  ) {
    final id = requestId.trim();

    if (id.isEmpty) {
      return Stream.value(null);
    }

    return _firestore
        .collection(collectionName)
        .doc(id)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }

      return WalkerAcceptData.fromFirestore(
        snapshot,
      );
    });
  }

  // ==========================================================
  // GET REQUEST ONCE
  // ==========================================================

  Future<WalkerAcceptData?> getRequest(
    String requestId,
  ) async {
    final id = requestId.trim();

    if (id.isEmpty) {
      return null;
    }

    final snapshot = await _firestore
        .collection(collectionName)
        .doc(id)
        .get();

    if (!snapshot.exists) {
      return null;
    }

    return WalkerAcceptData.fromFirestore(
      snapshot,
    );
  }

  // ==========================================================
  // MARK REACHED
  //
  // IMPORTANT:
  // This only updates walk_request.
  // liveWalkSessions will be created by the
  // Reach → Live Walk flow.
  // ==========================================================

  Future<void> markReached(
    String requestId,
  ) async {
    final id = requestId.trim();

    if (id.isEmpty) {
      throw ArgumentError(
        'requestId cannot be empty.',
      );
    }

    await _firestore
        .collection(collectionName)
        .doc(id)
        .update({
      'reached': true,
      'status': 'reached',
      'reachedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ==========================================================
  // UPDATE WALKER LOCATION
  //
  // This will be used by Walker app while coming
  // to the Owner.
  // ==========================================================

  Future<void> updateWalkerLocation({
    required String requestId,
    required GeoPoint location,
    double? heading,
    double? speed,
  }) async {
    final id = requestId.trim();

    if (id.isEmpty) {
      throw ArgumentError(
        'requestId cannot be empty.',
      );
    }

    final Map<String, dynamic> updates = {
      'walkerLocation': location,
      'locationUpdatedAt':
          FieldValue.serverTimestamp(),
      'updatedAt':
          FieldValue.serverTimestamp(),
    };

    if (heading != null) {
      updates['walkerHeading'] = heading;
    }

    if (speed != null) {
      updates['walkerSpeed'] = speed;
    }

    await _firestore
        .collection(collectionName)
        .doc(id)
        .update(updates);
  }

  // ==========================================================
  // UPDATE ARRIVAL INFORMATION
  //
  // Distance = meters remaining
  // ETA = minutes remaining
  // ==========================================================

  Future<void> updateArrivalInfo({
    required String requestId,
    required double distanceKm,
    required int distanceMeters,
    required int durationMinutes,
  }) async {
    final id = requestId.trim();

    if (id.isEmpty) {
      throw ArgumentError(
        'requestId cannot be empty.',
      );
    }

    await _firestore
        .collection(collectionName)
        .doc(id)
        .update({
      'arrivalDistanceKm': distanceKm,
      'arrivalDistanceMeters': distanceMeters,
      'arrivalDurationMinutes': durationMinutes,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ==========================================================
  // CLOSE SERVICE
  // ==========================================================

  Future<void> deleteRequest(
    String requestId,
  ) async {
    final id = requestId.trim();

    if (id.isEmpty) {
      return;
    }

    await _firestore
        .collection(collectionName)
        .doc(id)
        .delete();
  }
}
