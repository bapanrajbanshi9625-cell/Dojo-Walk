import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/live_walk_session.dart';

class LiveWalkService {
  LiveWalkService({
    FirebaseFirestore? firestore,
  }) : _firestore =
            firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String collectionName = 'liveWalkSessions';

  static const String historyCollection = 'walk_history';

  // ============================================================
  // WATCH LIVE WALK SESSION
  // ============================================================

  Stream<LiveWalkSession?> watchSession(
    String walkId,
  ) {
    final String id = walkId.trim();

    if (id.isEmpty) {
      return Stream.value(null);
    }

    return Stream<LiveWalkSession?>.multi(
      (MultiStreamController<LiveWalkSession?> controller) {
        StreamSubscription<
                QuerySnapshot<Map<String, dynamic>>>?
            walkIdSubscription;

        StreamSubscription<
                QuerySnapshot<Map<String, dynamic>>>?
            requestIdSubscription;

        String? lastDocumentId;

        void emitSnapshot(
          QuerySnapshot<Map<String, dynamic>> snapshot,
        ) {
          if (snapshot.docs.isEmpty) {
            return;
          }

          final QueryDocumentSnapshot<
                  Map<String, dynamic>>
              document = snapshot.docs.first;

          // Avoid duplicate emission when both queries
          // return the same liveWalkSessions document.
          if (lastDocumentId == document.id) {
            return;
          }

          lastDocumentId = document.id;

          controller.add(
            LiveWalkSession.fromFirestore(document),
          );
        }

        walkIdSubscription = _firestore
            .collection(collectionName)
            .where(
              'walkId',
              isEqualTo: id,
            )
            .limit(1)
            .snapshots()
            .listen(
          emitSnapshot,
          onError: controller.addError,
        );

        requestIdSubscription = _firestore
            .collection(collectionName)
            .where(
              'walkRequestId',
              isEqualTo: id,
            )
            .limit(1)
            .snapshots()
            .listen(
          emitSnapshot,
          onError: controller.addError,
        );

        controller.onCancel = () async {
          await walkIdSubscription?.cancel();
          await requestIdSubscription?.cancel();
        };
      },
    );
  }

  // ============================================================
  // FIND SESSION
  // ============================================================

  Future<DocumentReference<Map<String, dynamic>>?>
      findSession(
    String walkId,
  ) async {
    final String id = walkId.trim();

    if (id.isEmpty) {
      return null;
    }

    // ----------------------------------------------------------
    // First: search by walkId
    // ----------------------------------------------------------

    final QuerySnapshot<
            Map<String, dynamic>>
        walkIdSnapshot =
        await _firestore
            .collection(collectionName)
            .where(
              'walkId',
              isEqualTo: id,
            )
            .limit(1)
            .get();

    if (walkIdSnapshot.docs.isNotEmpty) {
      return walkIdSnapshot.docs.first.reference;
    }

    // ----------------------------------------------------------
    // Fallback: search by walkRequestId
    // ----------------------------------------------------------

    final QuerySnapshot<
            Map<String, dynamic>>
        requestIdSnapshot =
        await _firestore
            .collection(collectionName)
            .where(
              'walkRequestId',
              isEqualTo: id,
            )
            .limit(1)
            .get();

    if (requestIdSnapshot.docs.isNotEmpty) {
      return requestIdSnapshot.docs.first.reference;
    }

    return null;
  }

  // ============================================================
  // COMPLETE WALK
  // ============================================================

  Future<void> completeWalk({
    required LiveWalkSession session,
  }) async {
    final DocumentReference<
            Map<String, dynamic>>
        sessionRef =
        _firestore
            .collection(collectionName)
            .doc(session.documentId);

    // ----------------------------------------------------------
    // Build final route
    // ----------------------------------------------------------

    final List<GeoPoint> finalRoute =
        session.routePoints
            .map(
              (LatLngPoint) => GeoPoint(
                LatLngPoint.latitude,
                LatLngPoint.longitude,
              ),
            )
            .toList();

    // Add final valid walker location if it is not
    // already the last route point.
    if (session.walkerLocation != null) {
      final GeoPoint finalPoint = GeoPoint(
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

    // ----------------------------------------------------------
    // Mark live session completed
    // ----------------------------------------------------------

    final Map<String, dynamic> sessionUpdates =
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

    // Only write a valid location.
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

    // ----------------------------------------------------------
    // Save walk history
    // ----------------------------------------------------------

    final Map<String, dynamic> history =
        <String, dynamic>{
      'walkId':
          session.walkId,

      'status':
          'completed',

      'ownerId':
          session.ownerId,

      'ownerUid':
          session.ownerUid,

      'ownerName':
          session.ownerName,

      'ownerPhone':
          session.ownerPhone,

      'walkerId':
          session.walkerId,

      'walkerUid':
          session.walkerUid,

      'walkerName':
          session.walkerName,

      'walkerPhone':
          session.walkerPhone,

      'dogName':
          session.dogName,

      'dogBreed':
          session.dogBreed,

      'duration':
          session.durationLabel,

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
