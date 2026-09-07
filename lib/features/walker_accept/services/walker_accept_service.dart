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
  // DOJO WALK ID VALIDATION
  //
  // FINAL FORMAT:
  //
  // DW000001
  // DW000002
  // DW123456
  //
  // Same ID is used for:
  //
  // walk_request/DW000001
  // liveWalkSessions/DW000001
  // walk_history/DW000001
  // ==========================================================

  static final RegExp _requestIdPattern =
      RegExp(r'^DW\d{6}$');

  bool _isValidRequestId(String requestId) {
    return _requestIdPattern.hasMatch(
      requestId.trim(),
    );
  }

  String _cleanRequestId(String requestId) {
    final String id = requestId.trim();

    if (id.isEmpty) {
      throw ArgumentError(
        'requestId cannot be empty.',
      );
    }

    if (!_isValidRequestId(id)) {
      throw ArgumentError(
        'Invalid Dojo Walk ID: $id. '
        'Expected format DW000001.',
      );
    }

    return id;
  }

  // ==========================================================
  // WATCH ACCEPTED WALK REQUEST
  // ==========================================================

  Stream<WalkerAcceptData?> watchRequest(
    String requestId,
  ) {
    final String id = requestId.trim();

    if (id.isEmpty) {
      return Stream.value(null);
    }

    if (!_isValidRequestId(id)) {
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
    final String id = requestId.trim();

    if (id.isEmpty) {
      return null;
    }

    if (!_isValidRequestId(id)) {
      return null;
    }

    final DocumentSnapshot<
        Map<String, dynamic>> snapshot =
        await _firestore
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
  //
  // This updates ONLY:
  //
  // walk_request/{requestId}
  //
  // The Reach → Live Walk service is responsible
  // for creating:
  //
  // liveWalkSessions/{requestId}
  // ==========================================================

  Future<void> markReached(
    String requestId,
  ) async {
    final String id =
        _cleanRequestId(requestId);

    await _firestore
        .collection(collectionName)
        .doc(id)
        .update({
      'reached': true,
      'status': 'reached',
      'reachedAt':
          FieldValue.serverTimestamp(),
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  // ==========================================================
  // UPDATE WALKER LOCATION
  //
  // Walker app uses this while travelling
  // to the Owner.
  // ==========================================================

  Future<void> updateWalkerLocation({
    required String requestId,
    required GeoPoint location,
    double? heading,
    double? speed,
  }) async {
    final String id =
        _cleanRequestId(requestId);

    final Map<String, dynamic> updates =
        <String, dynamic>{
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
    final String id =
        _cleanRequestId(requestId);

    await _firestore
        .collection(collectionName)
        .doc(id)
        .update({
      'arrivalDistanceKm': distanceKm,
      'arrivalDistanceMeters':
          distanceMeters,
      'arrivalDurationMinutes':
          durationMinutes,
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  // ==========================================================
  // DELETE REQUEST
  // ==========================================================

  Future<void> deleteRequest(
    String requestId,
  ) async {
    final String id = requestId.trim();

    if (id.isEmpty) {
      return;
    }

    if (!_isValidRequestId(id)) {
      return;
    }

    await _firestore
        .collection(collectionName)
        .doc(id)
        .delete();
  }
}
