import 'package:cloud_firestore/cloud_firestore.dart';


// ============================================================
// INSTA WALK FIRESTORE HELPER
// ============================================================

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
  // GET REQUEST DOCUMENT
  // ==========================================================

  Future<DocumentSnapshot<Map<String, dynamic>>>
      getRequest(
    String requestId,
  ) async {

    return await _firestore
        .collection(
          walkRequestsCollection,
        )
        .doc(
          requestId,
        )
        .get();
  }



  // ==========================================================
  // CREATE REQUEST
  // ==========================================================

  Future<DocumentReference<Map<String, dynamic>>>
      createRequest({
    required Map<String, dynamic> data,
  }) async {

    final DocumentReference<Map<String, dynamic>>
        ref =
        _firestore
            .collection(
              walkRequestsCollection,
            )
            .doc();


    await ref.set({
      ...data,
      'requestId': ref.id,
    });


    return ref;
  }



  // ==========================================================
  // UPDATE REQUEST
  // ==========================================================

  Future<void> updateRequest({
    required String requestId,
    required Map<String, dynamic> data,
  }) async {

    await _firestore
        .collection(
          walkRequestsCollection,
        )
        .doc(
          requestId,
        )
        .update(data);
  }



  // ==========================================================
  // REQUEST STREAM
  // ==========================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      watchRequest(
    String requestId,
  ) {

    return _firestore
        .collection(
          walkRequestsCollection,
        )
        .doc(
          requestId,
        )
        .snapshots();
  }



  // ==========================================================
  // ADD REQUEST ID IF MISSING
  // ==========================================================

  Map<String, dynamic> withRequestId(
    String documentId,
    Map<String, dynamic> data,
  ) {

    final Map<String, dynamic> result =
        Map<String, dynamic>.from(data);


    final String existing =
        result['requestId']
                ?.toString()
                .trim() ??
            '';


    if (existing.isEmpty &&
        documentId.trim().isNotEmpty) {

      result['requestId'] =
          documentId.trim();
    }


    return result;
  }
}
