import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/live_walk_session.dart';

class LiveWalkService {
  LiveWalkService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String collectionName = 'liveWalkSessions';
  static const String historyCollection = 'walk_history';

  // ============================================================
  // WATCH SESSION
  // ============================================================

  Stream<LiveWalkSession?> watchSession(String id) async* {
    final String value = id.trim();

    if (value.isEmpty) {
      yield null;
      return;
    }

    final CollectionReference<Map<String, dynamic>> collection =
        _firestore.collection(collectionName);

    // ------------------------------------------------------------
    // 1. Direct document ID
    // ------------------------------------------------------------

    final DocumentReference<Map<String, dynamic>> directRef =
        collection.doc(value);

    final DocumentSnapshot<Map<String, dynamic>> directSnapshot =
        await directRef.get();

    if (directSnapshot.exists) {
      yield* directRef.snapshots().map(
        (snapshot) {
          if (!snapshot.exists) {
            return null;
          }

          return LiveWalkSession.fromFirestore(snapshot);
        },
      );

      return;
    }

    // ------------------------------------------------------------
    // 2. walkId
    // ------------------------------------------------------------

    final Query<Map<String, dynamic>> walkIdQuery = collection
        .where(
          'walkId',
          isEqualTo: value,
        )
        .limit(1);

    final QuerySnapshot<Map<String, dynamic>> walkIdSnapshot =
        await walkIdQuery.get();

    if (walkIdSnapshot.docs.isNotEmpty) {
      yield* walkIdQuery.snapshots().map(
        (snapshot) {
          if (snapshot.docs.isEmpty) {
            return null;
          }

          return LiveWalkSession.fromFirestore(
            snapshot.docs.first,
          );
        },
      );

      return;
    }

    // ------------------------------------------------------------
    // 3. walkRequestId
    // ------------------------------------------------------------

    final Query<Map<String, dynamic>> requestIdQuery = collection
        .where(
          'walkRequestId',
          isEqualTo: value,
        )
        .limit(1);

    final QuerySnapshot<Map<String, dynamic>> requestSnapshot =
        await requestIdQuery.get();

    if (requestSnapshot.docs.isNotEmpty) {
      yield* requestIdQuery.snapshots().map(
        (snapshot) {
          if (snapshot.docs.isEmpty) {
            return null;
          }

          return LiveWalkSession.fromFirestore(
            snapshot.docs.first,
          );
        },
      );

      return;
    }

    // ------------------------------------------------------------
    // 4. sessionId
    // ------------------------------------------------------------

    final Query<Map<String, dynamic>> sessionIdQuery = collection
        .where(
          'sessionId',
          isEqualTo: value,
        )
        .limit(1);

    yield* sessionIdQuery.snapshots().map(
      (snapshot) {
        if (snapshot.docs.isEmpty) {
          return null;
        }

        return LiveWalkSession.fromFirestore(
          snapshot.docs.first,
        );
      },
    );
  }

  // ============================================================
  // FIND SESSION
  // ============================================================

  Future<DocumentReference<Map<String, dynamic>>?> findSession(
    String id,
  ) async {
    final String value = id.trim();

    if (value.isEmpty) {
      return null;
    }

    final CollectionReference<Map<String, dynamic>> collection =
        _firestore.collection(collectionName);

    // 1. Document ID
    final DocumentReference<Map<String, dynamic>> directRef =
        collection.doc(value);

    final DocumentSnapshot<Map<String, dynamic>> directSnapshot =
        await directRef.get();

    if (directSnapshot.exists) {
      return directRef;
    }

    // 2. walkId
    final QuerySnapshot<Map<String, dynamic>> walkIdSnapshot =
        await collection
            .where(
              'walkId',
              isEqualTo: value,
            )
            .limit(1)
            .get();

    if (walkIdSnapshot.docs.isNotEmpty) {
      return walkIdSnapshot.docs.first.reference;
    }

    // 3. walkRequestId
    final QuerySnapshot<Map<String, dynamic>> requestSnapshot =
        await collection
            .where(
              'walkRequestId',
              isEqualTo: value,
            )
            .limit(1)
            .get();

    if (requestSnapshot.docs.isNotEmpty) {
      return requestSnapshot.docs.first.reference;
    }

    // 4. sessionId
    final QuerySnapshot<Map<String, dynamic>> sessionSnapshot =
        await collection
            .where(
              'sessionId',
              isEqualTo: value,
            )
            .limit(1)
            .get();

    if (sessionSnapshot.docs.isNotEmpty) {
      return sessionSnapshot.docs.first.reference;
    }

    return null;
  }

  // ============================================================
  // COMPLETE WALK
  // ============================================================

  Future<void> completeWalk({
    required LiveWalkSession session,
  }) async {
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
