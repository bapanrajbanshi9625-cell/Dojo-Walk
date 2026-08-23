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
  // ACTIVE WALK
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
  // WATCH BY WALK ID
  //
  // Firestore field:
  // "Walkid"
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
  // GET BY DOCUMENT ID
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
