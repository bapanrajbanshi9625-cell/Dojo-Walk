import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/active_walk.dart';
import '../models/active_walk_mapper.dart';

class ActiveWalkService {
  ActiveWalkService({
    FirebaseFirestore? firestore,
  }) : _firestore =
            firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // ==========================================================
  // ACTIVE WALKS COLLECTION
  // ==========================================================

  CollectionReference<Map<String, dynamic>>
      get _activeWalks {
    return _firestore.collection('active_walks');
  }

  // ==========================================================
  // WATCH ACTIVE WALK
  // ==========================================================

  Stream<ActiveWalk?> watchActiveWalk(
    String activeWalkId,
  ) {
    return _activeWalks
        .doc(activeWalkId)
        .snapshots()
        .map(
      (
        DocumentSnapshot<Map<String, dynamic>> snapshot,
      ) {
        if (!snapshot.exists) {
          return null;
        }

        return ActiveWalkMapper.fromDocument(
          snapshot,
        );
      },
    );
  }

  // ==========================================================
  // GET ACTIVE WALK
  // ==========================================================

  Future<ActiveWalk?> getActiveWalk(
    String activeWalkId,
  ) async {
    final DocumentSnapshot<Map<String, dynamic>>
        snapshot =
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

  // ==========================================================
  // MARK WALK AS REACHED
  //
  // Walker reaches owner's location.
  // This is NOT the live-walk screen.
  // ==========================================================

  Future<void> markReached(
    String activeWalkId,
  ) async {
    await _activeWalks
        .doc(activeWalkId)
        .update({
      'status': 'reached',
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  // ==========================================================
  // START ACTUAL WALK
  //
  // After walker reaches owner/pickup location,
  // actual walking can start.
  // ==========================================================

  Future<void> startWalk(
    String activeWalkId,
  ) async {
    await _activeWalks
        .doc(activeWalkId)
        .update({
      'status': 'walking',
      'startedAt':
          FieldValue.serverTimestamp(),
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  // ==========================================================
  // UPDATE WALKER LOCATION
  //
  // Real OpenStreetMap screen reads this location.
  // ==========================================================

  Future<void> updateWalkerLocation({
    required String activeWalkId,
    required GeoPoint location,
  }) async {
    await _activeWalks
        .doc(activeWalkId)
        .update({
      'walkerLocation': location,
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  // ==========================================================
  // END WALK
  //
  // Only marks the active walk completed.
  // History transfer can be handled by the dedicated
  // walk-history flow.
  // ==========================================================

  Future<void> endWalk(
    String activeWalkId,
  ) async {
    final DocumentReference<Map<String, dynamic>>
        reference =
        _activeWalks.doc(activeWalkId);

    final DocumentSnapshot<Map<String, dynamic>>
        snapshot =
        await reference.get();

    if (!snapshot.exists) {
      throw Exception(
        'Active walk does not exist.',
      );
    }

    await reference.update({
      'status': 'completed',
      'endedAt':
          FieldValue.serverTimestamp(),
      'updatedAt':
          FieldValue.serverTimestamp(),
      'walkEnded': true,
      'trackingEnded': true,
    });
  }
}
