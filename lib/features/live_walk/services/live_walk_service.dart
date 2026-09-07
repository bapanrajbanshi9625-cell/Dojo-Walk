import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/live_walk_session.dart';

class LiveWalkService {
  LiveWalkService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const String collectionName = 'liveWalkSessions';
  static const String historyCollection = 'walk_history';
  static const String requestCollection = 'walk_request';

  // ============================================================
  // CURRENT USER UID
  // ============================================================

  String? get currentUid => _auth.currentUser?.uid;

  // ============================================================
  // WALK ID VALIDATION
  //
  // FINAL ARCHITECTURE:
  //
  // DW000001
  //   ├── walk_request/DW000001
  //   ├── liveWalkSessions/DW000001
  //   └── walk_history/DW000001
  //
  // No separate walkId.
  // No Firebase Auto-ID.
  // ============================================================

  bool _isValidRequestId(String value) {
    return RegExp(r'^DW\d{6}$').hasMatch(value);
  }

  // ============================================================
  // WATCH SESSION
  //
  // The supplied requestId is the SAME ID as the
  // liveWalkSessions document ID.
  //
  // Owner:
  //   ownerUid == Firebase Auth UID
  //
  // Walker:
  //   walkerUid == Firebase Auth UID
  // ============================================================

  Stream<LiveWalkSession?> watchSession(
    String requestId, {
    bool isWalker = false,
  }) {
    final String value = requestId.trim();

    if (value.isEmpty) {
      return Stream<LiveWalkSession?>.value(null);
    }

    if (!_isValidRequestId(value)) {
      return Stream<LiveWalkSession?>.error(
        FormatException(
          'Invalid Walk ID. Expected DW000001 format.',
        ),
      );
    }

    final String? uid = currentUid;

    if (uid == null || uid.isEmpty) {
      return Stream<LiveWalkSession?>.error(
        StateError('User is not authenticated.'),
      );
    }

    final CollectionReference<Map<String, dynamic>> collection =
        _firestore.collection(collectionName);

    final String userField =
        isWalker ? 'walkerUid' : 'ownerUid';

    // ==========================================================
    // IMPORTANT
    //
    // We query only sessions belonging to the authenticated user.
    // Then we select the exact FINAL request ID.
    //
    // No walkId / walkRequestId / sessionId fallback.
    // ==========================================================

    return collection
        .where(
          userField,
          isEqualTo: uid,
        )
        .snapshots()
        .map(
      (QuerySnapshot<Map<String, dynamic>> snapshot) {
        for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
            in snapshot.docs) {
          if (doc.id == value) {
            return LiveWalkSession.fromFirestore(doc);
          }
        }

        return null;
      },
    );
  }

  // ============================================================
  // WATCH ACTIVE OWNER SESSION
  //
  // Automatically finds the current live session belonging
  // to the authenticated Owner.
  // ============================================================

  Stream<LiveWalkSession?> watchOwnerActiveSession() {
    final String? uid = currentUid;

    if (uid == null || uid.isEmpty) {
      return Stream<LiveWalkSession?>.error(
        StateError('User is not authenticated.'),
      );
    }

    return _firestore
        .collection(collectionName)
        .where(
          'ownerUid',
          isEqualTo: uid,
        )
        .snapshots()
        .map(
      (QuerySnapshot<Map<String, dynamic>> snapshot) {
        LiveWalkSession? latestSession;

        for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
            in snapshot.docs) {
          final LiveWalkSession session =
              LiveWalkSession.fromFirestore(doc);

          if (session.isCompleted) {
            continue;
          }

          if (!session.isLive) {
            continue;
          }

          latestSession = session;
        }

        return latestSession;
      },
    );
  }

  // ============================================================
  // FIND SESSION
  //
  // Uses the FINAL request ID as the live session document ID.
  // ============================================================

  Future<DocumentReference<Map<String, dynamic>>?> findSession(
    String requestId, {
    bool isWalker = false,
  }) async {
    final String value = requestId.trim();

    if (value.isEmpty) {
      return null;
    }

    if (!_isValidRequestId(value)) {
      return null;
    }

    final String? uid = currentUid;

    if (uid == null || uid.isEmpty) {
      return null;
    }

    final String userField =
        isWalker ? 'walkerUid' : 'ownerUid';

    final CollectionReference<Map<String, dynamic>> collection =
        _firestore.collection(collectionName);

    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await collection
            .where(
              userField,
              isEqualTo: uid,
            )
            .get();

    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in snapshot.docs) {
      if (doc.id == value) {
        return doc.reference;
      }
    }

    return null;
  }

  // ============================================================
  // COMPLETE WALK
  //
  // Final ID is used everywhere:
  //
  // liveWalkSessions/DW000001
  // walk_history/DW000001
  // walk_request/DW000001
  // ============================================================

  Future<void> completeWalk({
    required LiveWalkSession session,
  }) async {
    final String? uid = currentUid;

    if (uid == null || uid.isEmpty) {
      throw StateError('User is not authenticated.');
    }

    // ==========================================================
    // FINAL REQUEST / WALK ID
    // ==========================================================

    final String requestId = session.documentId.trim();

    if (!_isValidRequestId(requestId)) {
      throw FormatException(
        'Invalid Walk ID. Expected DW000001 format.',
      );
    }

    // ==========================================================
    // SESSION REFERENCE
    // ==========================================================

    final DocumentReference<Map<String, dynamic>> sessionRef =
        _firestore
            .collection(collectionName)
            .doc(requestId);

    // ==========================================================
    // REQUEST REFERENCE
    // ==========================================================

    final DocumentReference<Map<String, dynamic>> requestRef =
        _firestore
            .collection(requestCollection)
            .doc(requestId);

    // ==========================================================
    // HISTORY REFERENCE
    // ==========================================================

    final DocumentReference<Map<String, dynamic>> historyRef =
        _firestore
            .collection(historyCollection)
            .doc(requestId);

    // ==========================================================
    // FINAL ROUTE
    // ==========================================================

    final List<GeoPoint> finalRoute = session.routePoints
        .map(
          (point) => GeoPoint(
            point.latitude,
            point.longitude,
          ),
        )
        .toList();

    // ----------------------------------------------------------
    // Add final walker location
    // ----------------------------------------------------------

    if (session.walkerLocation != null) {
      final GeoPoint finalPoint = GeoPoint(
        session.walkerLocation!.latitude,
        session.walkerLocation!.longitude,
      );

      if (finalRoute.isEmpty ||
          finalRoute.last.latitude != finalPoint.latitude ||
          finalRoute.last.longitude != finalPoint.longitude) {
        finalRoute.add(finalPoint);
      }
    }

    // ==========================================================
    // UPDATE LIVE SESSION
    // ==========================================================

    final Map<String, dynamic> sessionUpdates =
        <String, dynamic>{
      'requestId': requestId,
      'sessionId': requestId,

      'status': 'completed',
      'trackingEnded': true,
      'walkEnded': true,

      'endedAt': FieldValue.serverTimestamp(),
      'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),

      'elapsedSeconds': session.elapsedSeconds,
      'distanceKm': session.distanceKm,
      'steps': session.steps,
      'peeCount': session.peeCount,
      'poopCount': session.poopCount,

      'routeCoordinates': finalRoute,
    };

    if (session.walkerLocation != null) {
      sessionUpdates['currentLocation'] = GeoPoint(
        session.walkerLocation!.latitude,
        session.walkerLocation!.longitude,
      );
    }

    // ==========================================================
    // UPDATE WALK REQUEST
    // ==========================================================

    final Map<String, dynamic> requestUpdates =
        <String, dynamic>{
      'requestId': requestId,
      'status': 'completed',
      'walkEnded': true,
      'trackingEnded': true,
      'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // ==========================================================
    // HISTORY
    // ==========================================================

    final Map<String, dynamic> history =
        <String, dynamic>{
      'requestId': requestId,
      'sessionId': requestId,

      'status': 'completed',

      'ownerId': session.ownerId,
      'ownerUid': session.ownerUid,
      'ownerName': session.ownerName,
      'ownerPhone': session.ownerPhone,

      'walkerId': session.walkerId,
      'walkerUid': session.walkerUid,
      'walkerName': session.walkerName,
      'walkerPhone': session.walkerPhone,

      'dogName': session.dogName,
      'dogBreed': session.dogBreed,

      'duration': session.durationLabel,
      'elapsedSeconds': session.elapsedSeconds,
      'distanceKm': session.distanceKm,
      'steps': session.steps,
      'peeCount': session.peeCount,
      'poopCount': session.poopCount,

      'routeCoordinates': finalRoute,

      'endedAt': FieldValue.serverTimestamp(),
      'completedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (session.startedAt != null) {
      history['startedAt'] =
          Timestamp.fromDate(session.startedAt!);
    }

    // ==========================================================
    // BATCH WRITE
    //
    // All three collections are updated together.
    // ==========================================================

    final WriteBatch batch = _firestore.batch();

    batch.update(
      sessionRef,
      sessionUpdates,
    );

    batch.set(
      requestRef,
      requestUpdates,
      SetOptions(merge: true),
    );

    batch.set(
      historyRef,
      history,
      SetOptions(merge: true),
    );

    await batch.commit();
  }
}
