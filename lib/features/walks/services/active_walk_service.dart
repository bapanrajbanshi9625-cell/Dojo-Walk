import 'package:cloud_firestore/cloud_firestore.dart';

class ActiveWalkService {
  ActiveWalkService._();

  // ==========================================================
  // SINGLETON
  // ==========================================================

  static final ActiveWalkService instance =
      ActiveWalkService._();

  // ==========================================================
  // FIRESTORE
  // ==========================================================

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ==========================================================
  // ACTIVE WALK COLLECTION
  //
  // active_walk = walker is on the way.
  //
  // This collection does NOT contain:
  // peeCount
  // poopCount
  // routeCoordinates
  // events
  // elapsedSeconds
  // ==========================================================

  CollectionReference<Map<String, dynamic>>
      get _activeWalks =>
          _firestore.collection('active_walk');

  // ==========================================================
  // WATCH ACTIVE WALKS FOR OWNER
  // ==========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      watchActiveWalks({
    required String ownerId,
  }) {
    return _activeWalks
        .where(
          'ownerId',
          isEqualTo: ownerId,
        )
        .where(
          'status',
          isEqualTo: 'active',
        )
        .snapshots();
  }

  // ==========================================================
  // WATCH ONE ACTIVE WALK
  // ==========================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      watchActiveWalk({
    required String documentId,
  }) {
    return _activeWalks
        .doc(documentId)
        .snapshots();
  }

  // ==========================================================
  // WATCH ACTIVE WALK BY WALK ID
  //
  // IMPORTANT:
  // Firestore field is exactly "Walkid"
  // ==========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      watchActiveWalkByWalkId({
    required String walkId,
  }) {
    return _activeWalks
        .where(
          'Walkid',
          isEqualTo: walkId,
        )
        .where(
          'status',
          isEqualTo: 'active',
        )
        .limit(1)
        .snapshots();
  }

  // ==========================================================
  // GET ACTIVE WALK ONCE
  // ==========================================================

  Future<QuerySnapshot<Map<String, dynamic>>>
      getActiveWalk({
    required String ownerId,
  }) {
    return _activeWalks
        .where(
          'ownerId',
          isEqualTo: ownerId,
        )
        .where(
          'status',
          isEqualTo: 'active',
        )
        .limit(1)
        .get();
  }

  // ==========================================================
  // GET ACTIVE WALK BY DOCUMENT ID ONCE
  // ==========================================================

  Future<DocumentSnapshot<Map<String, dynamic>>>
      getActiveWalkByDocumentId({
    required String documentId,
  }) {
    return _activeWalks
        .doc(documentId)
        .get();
  }

  // ==========================================================
  // CLOSE ACTIVE WALK
  //
  // active_walk only changes its status.
  //
  // It does NOT modify:
  // liveWalkSessions
  // ==========================================================

  Future<void> closeActiveWalk({
    required String documentId,
  }) async {
    await _activeWalks
        .doc(documentId)
        .update({
      'status': 'closed',
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  // ==========================================================
  // DELETE ACTIVE WALK
  // ==========================================================

  Future<void> deleteActiveWalk({
    required String documentId,
  }) async {
    await _activeWalks
        .doc(documentId)
        .delete();
  }
}
