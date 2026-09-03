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

  // ============================================================
  // CURRENT USER UID
  // ============================================================

  String? get currentUid => _auth.currentUser?.uid;

  // ============================================================
  // WATCH SESSION
  //
  // Owner:
  //   Reads session using ownerUid == Firebase Auth UID
  //
  // Walker:
  //   Reads session using walkerUid == Firebase Auth UID
  //
  // The supplied id can be:
  //   - Firestore document ID
  //   - walkId
  //   - walkRequestId
  //   - sessionId
  // ============================================================

  Stream<LiveWalkSession?> watchSession(
    String id, {
    bool isWalker = false,
  }) {
    final String value = id.trim();

    if (value.isEmpty) {
      return Stream<LiveWalkSession?>.value(null);
    }

    final String? uid = currentUid;

    if (uid == null || uid.isEmpty) {
      return Stream<LiveWalkSession?>.error(
        StateError('User is not authenticated.'),
      );
    }

    final CollectionReference<Map<String, dynamic>> collection =
        _firestore.collection(collectionName);

    final String userField = isWalker ? 'walkerUid' : 'ownerUid';

    // ==========================================================
    // IMPORTANT
    //
    // We DO NOT perform:
    //
    // collection.doc(value).get()
    //
    // first.
    //
    // Instead we query using the authenticated user's UID.
    // This allows Firestore security rules to verify ownership.
    // ==========================================================

    return collection
        .where(userField, isEqualTo: uid)
        .snapshots()
        .asyncMap(
      (QuerySnapshot<Map<String, dynamic>> snapshot) async {
        if (snapshot.docs.isEmpty) {
          return null;
        }

        // ------------------------------------------------------
        // 1. Exact Firestore document ID
        // ------------------------------------------------------

        for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
            in snapshot.docs) {
          if (doc.id == value) {
            return LiveWalkSession.fromFirestore(doc);
          }
        }

        // ------------------------------------------------------
        // 2. walkId
        // ------------------------------------------------------

        for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
            in snapshot.docs) {
          final Map<String, dynamic> data = doc.data();

          final dynamic walkId = data['walkId'];

          if (walkId != null && walkId.toString() == value) {
            return LiveWalkSession.fromFirestore(doc);
          }
        }

        // ------------------------------------------------------
        // 3. walkRequestId
        // ------------------------------------------------------

        for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
            in snapshot.docs) {
          final Map<String, dynamic> data = doc.data();

          final dynamic requestId = data['walkRequestId'];

          if (requestId != null && requestId.toString() == value) {
            return LiveWalkSession.fromFirestore(doc);
          }
        }

        // ------------------------------------------------------
        // 4. sessionId
        // ------------------------------------------------------

        for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
            in snapshot.docs) {
          final Map<String, dynamic> data = doc.data();

          final dynamic sessionId = data['sessionId'];

          if (sessionId != null && sessionId.toString() == value) {
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
  // This is useful when Owner should automatically open Live Walk
  // after Walker creates/starts the session.
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
        .where('ownerUid', isEqualTo: uid)
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
  // Uses authenticated user's ownership instead of unrestricted
  // direct document reads.
  // ============================================================

  Future<DocumentReference<Map<String, dynamic>>?> findSession(
    String id, {
    bool isWalker = false,
  }) async {
    final String value = id.trim();

    if (value.isEmpty) {
      return null;
    }

    final String? uid = currentUid;

    if (uid == null || uid.isEmpty) {
      return null;
    }

    final String userField = isWalker ? 'walkerUid' : 'ownerUid';

    final CollectionReference<Map<String, dynamic>> collection =
        _firestore.collection(collectionName);

    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await collection
            .where(userField, isEqualTo: uid)
            .get();

    // ----------------------------------------------------------
    // 1. Document ID
    // ----------------------------------------------------------

    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in snapshot.docs) {
      if (doc.id == value) {
        return doc.reference;
      }
    }

    // ----------------------------------------------------------
    // 2. walkId
    // ----------------------------------------------------------

    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in snapshot.docs) {
      final dynamic walkId = doc.data()['walkId'];

      if (walkId != null && walkId.toString() == value) {
        return doc.reference;
      }
    }

    // ----------------------------------------------------------
    // 3. walkRequestId
    // ----------------------------------------------------------

    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in snapshot.docs) {
      final dynamic walkRequestId = doc.data()['walkRequestId'];

      if (walkRequestId != null &&
          walkRequestId.toString() == value) {
        return doc.reference;
      }
    }

    // ----------------------------------------------------------
    // 4. sessionId
    // ----------------------------------------------------------

    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in snapshot.docs) {
      final dynamic sessionId = doc.data()['sessionId'];

      if (sessionId != null && sessionId.toString() == value) {
        return doc.reference;
      }
    }

    return null;
  }

  // ============================================================
  // COMPLETE WALK
  //
  // Walker completes the live session.
  // ============================================================

  Future<void> completeWalk({
    required LiveWalkSession session,
  }) async {
    final String? uid = currentUid;

    if (uid == null || uid.isEmpty) {
      throw StateError('User is not authenticated.');
    }

    final DocumentReference<Map<String, dynamic>> sessionRef =
        _firestore
            .collection(collectionName)
            .doc(session.documentId);

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

    // ----------------------------------------------------------
    // Update live session
    // ----------------------------------------------------------

    final Map<String, dynamic> sessionUpdates =
        <String, dynamic>{
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

    await sessionRef.update(sessionUpdates);

    // ----------------------------------------------------------
    // Save history
    // ----------------------------------------------------------

    final Map<String, dynamic> history =
        <String, dynamic>{
      'walkId': session.walkId,
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

    await _firestore
        .collection(historyCollection)
        .doc(session.walkId)
        .set(
          history,
          SetOptions(merge: true),
        );
  }
}
