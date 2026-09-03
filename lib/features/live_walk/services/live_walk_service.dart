import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/live_walk_session.dart';

class LiveWalkService {
  LiveWalkService({
    FirebaseFirestore? firestore,
  }) : _firestore =
            firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String collectionName =
      'liveWalkSessions';

  static const String historyCollection =
      'walk_history';

  Stream<LiveWalkSession?> watchSession(
    String walkId,
  ) {
    final String id = walkId.trim();

    if (id.isEmpty) {
      return Stream.value(null);
    }

    return _firestore
        .collection(collectionName)
        .where(
          'walkId',
          isEqualTo: id,
        )
        .limit(1)
        .snapshots()
        .map(
      (QuerySnapshot<Map<String, dynamic>>
          snapshot) {
        if (snapshot.docs.isEmpty) {
          return null;
        }

        return LiveWalkSession.fromFirestore(
          snapshot.docs.first,
        );
      },
    );
  }

  Future<DocumentReference<Map<String, dynamic>>?>
      findSession(
    String walkId,
  ) async {
    final String id = walkId.trim();

    if (id.isEmpty) {
      return null;
    }

    final QuerySnapshot<
            Map<String, dynamic>>
        snapshot =
        await _firestore
            .collection(collectionName)
            .where(
              'walkId',
              isEqualTo: id,
            )
            .limit(1)
            .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return snapshot.docs.first.reference;
  }

  Future<void> completeWalk({
    required LiveWalkSession session,
  }) async {
    final DocumentReference<
            Map<String, dynamic>>
        sessionRef =
        _firestore
            .collection(collectionName)
            .doc(session.documentId);

    final List<GeoPoint> finalRoute =
        session.routePoints
            .map(
              (point) => GeoPoint(
                point.latitude,
                point.longitude,
              ),
            )
            .toList();

    if (session.walkerLocation != null) {
      final GeoPoint finalPoint =
          GeoPoint(
        session.walkerLocation!.latitude,
        session.walkerLocation!.longitude,
      );

      if (finalRoute.isEmpty ||
          finalRoute.last.latitude !=
              finalPoint.latitude ||
          finalRoute.last.longitude !=
              finalPoint.longitude) {
        finalRoute.add(finalPoint);
      }
    }

    final Map<String, dynamic>
        sessionUpdates =
        <String, dynamic>{
      'status': 'completed',
      'trackingEnded': true,
      'walkEnded': true,
      'endedAt':
          FieldValue.serverTimestamp(),
      'completedAt':
          FieldValue.serverTimestamp(),
      'updatedAt':
          FieldValue.serverTimestamp(),
      'elapsedSeconds':
          session.elapsedSeconds,
      'distanceKm':
          session.distanceKm,
      'steps':
          session.steps,
      'peeCount':
          session.peeCount,
      'poopCount':
          session.poopCount,
      'routeCoordinates':
          finalRoute,
    };

    if (session.walkerLocation != null) {
      sessionUpdates['currentLocation'] =
          GeoPoint(
        session.walkerLocation!.latitude,
        session.walkerLocation!.longitude,
      );
    }

    await sessionRef.update(
      sessionUpdates,
    );

    final Map<String, dynamic>
        history =
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
      'elapsedSeconds':
          session.elapsedSeconds,
      'distanceKm':
          session.distanceKm,

      'steps': session.steps,
      'peeCount': session.peeCount,
      'poopCount': session.poopCount,

      'routeCoordinates':
          finalRoute,

      'endedAt':
          FieldValue.serverTimestamp(),
      'completedAt':
          FieldValue.serverTimestamp(),
      'createdAt':
          FieldValue.serverTimestamp(),
    };

    if (session.startedAt != null) {
      history['startedAt'] =
          Timestamp.fromDate(
        session.startedAt!,
      );
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
