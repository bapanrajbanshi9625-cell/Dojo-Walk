import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/active_walk.dart';
import '../models/active_walk_mapper.dart';

class ActiveWalkService {
  ActiveWalkService({
    FirebaseFirestore? firestore,
  }) : _firestore =
            firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<
      Map<String, dynamic>> get _activeWalks {
    return _firestore.collection(
      'active_walk',
    );
  }

  CollectionReference<
      Map<String, dynamic>> get _history {
    return _firestore.collection(
      'walk_history',
    );
  }

  Stream<ActiveWalk?> watchActiveWalk(
    String activeWalkId,
  ) {
    return _activeWalks
        .doc(activeWalkId)
        .snapshots()
        .map(
      (snapshot) {
        if (!snapshot.exists) {
          return null;
        }

        return ActiveWalkMapper.fromDocument(
          snapshot,
        );
      },
    );
  }

  Future<ActiveWalk?> getActiveWalk(
    String activeWalkId,
  ) async {
    final DocumentSnapshot<
        Map<String, dynamic>> snapshot =
        await _activeWalks
            .doc(activeWalkId)
            .get();

    if (!snapshot.exists) {
      return null;
    }

    return ActiveWalkMapper.fromDocument(
      snapshot,
    );
  }

  Future<void> endWalk(
    ActiveWalk walk,
  ) async {
    final DocumentReference<
        Map<String, dynamic>> activeRef =
        _activeWalks.doc(walk.id);

    final DocumentSnapshot<
        Map<String, dynamic>> snapshot =
        await activeRef.get();

    if (!snapshot.exists) {
      throw Exception(
        'Active walk does not exist.',
      );
    }

    final Map<String, dynamic> data =
        snapshot.data() ??
            <String, dynamic>{};

    final List<GeoPoint> routePoints =
        walk.routePoints
            .map(
              (point) => GeoPoint(
                point.latitude,
                point.longitude,
              ),
            )
            .toList();

    if (walk.walkerLocation != null) {
      final GeoPoint finalPoint =
          GeoPoint(
        walk.walkerLocation!.latitude,
        walk.walkerLocation!.longitude,
      );

      if (routePoints.isEmpty ||
          routePoints.last.latitude !=
              finalPoint.latitude ||
          routePoints.last.longitude !=
              finalPoint.longitude) {
        routePoints.add(finalPoint);
      }
    }

    final Map<String, dynamic> historyData =
        <String, dynamic>{
      ...data,

      'activeWalkId': walk.id,

      'status': 'completed',

      'endedAt':
          FieldValue.serverTimestamp(),

      'completedAt':
          FieldValue.serverTimestamp(),

      'distance': walk.distance,

      'steps': walk.steps,

      'peeCount': walk.peeCount,

      'poopCount': walk.poopCount,

      'routePoints': routePoints,
    };

    await _history
        .doc(walk.id)
        .set(
          historyData,
          SetOptions(merge: true),
        );

    await activeRef.update({
      'status': 'completed',
      'endedAt':
          FieldValue.serverTimestamp(),
      'completedAt':
          FieldValue.serverTimestamp(),
      'distance': walk.distance,
      'steps': walk.steps,
      'peeCount': walk.peeCount,
      'poopCount': walk.poopCount,
      'routePoints': routePoints,
    });
  }
}
