import 'package:cloud_firestore/cloud_firestore.dart';

class InstaWalkFirestoreHelper {
  InstaWalkFirestoreHelper({
    FirebaseFirestore? firestore,
  }) : _firestore =
            firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // ==========================================================
  // COLLECTION
  // ==========================================================

  static const String walkRequestsCollection =
      'walk_requests';

  // ==========================================================
  // CREATE REQUEST
  // ==========================================================

  Future<DocumentReference<Map<String, dynamic>>>
      createRequest({
    required Map<String, dynamic> data,
  }) async {
    final CollectionReference<
        Map<String, dynamic>> collection =
        _firestore.collection(
      walkRequestsCollection,
    );

    return collection.add(data);
  }

  // ==========================================================
  // GET REQUEST
  // ==========================================================

  Future<DocumentSnapshot<Map<String, dynamic>>>
      getRequest({
    required String requestId,
  }) async {
    final String cleanRequestId =
        requestId.trim();

    if (cleanRequestId.isEmpty) {
      throw ArgumentError(
        'requestId cannot be empty.',
      );
    }

    return _firestore
        .collection(walkRequestsCollection)
        .doc(cleanRequestId)
        .get();
  }

  // ==========================================================
  // UPDATE REQUEST
  // ==========================================================

  Future<void> updateRequest({
    required String requestId,
    required Map<String, dynamic> data,
  }) async {
    final String cleanRequestId =
        requestId.trim();

    if (cleanRequestId.isEmpty) {
      throw ArgumentError(
        'requestId cannot be empty.',
      );
    }

    await _firestore
        .collection(walkRequestsCollection)
        .doc(cleanRequestId)
        .update(data);
  }

  // ==========================================================
  // SET REQUEST
  // ==========================================================

  Future<void> setRequest({
    required String requestId,
    required Map<String, dynamic> data,
    bool merge = true,
  }) async {
    final String cleanRequestId =
        requestId.trim();

    if (cleanRequestId.isEmpty) {
      throw ArgumentError(
        'requestId cannot be empty.',
      );
    }

    await _firestore
        .collection(walkRequestsCollection)
        .doc(cleanRequestId)
        .set(
          data,
          SetOptions(
            merge: merge,
          ),
        );
  }

  // ==========================================================
  // DELETE REQUEST
  // ==========================================================

  Future<void> deleteRequest({
    required String requestId,
  }) async {
    final String cleanRequestId =
        requestId.trim();

    if (cleanRequestId.isEmpty) {
      throw ArgumentError(
        'requestId cannot be empty.',
      );
    }

    await _firestore
        .collection(walkRequestsCollection)
        .doc(cleanRequestId)
        .delete();
  }
}
