import 'package:cloud_firestore/cloud_firestore.dart';

class InstaWalkFirestoreHelper {
  InstaWalkFirestoreHelper({
    FirebaseFirestore? firestore,
  }) : _firestore =
            firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // ==========================================================
  // COLLECTIONS
  // ==========================================================

  static const String walkRequestsCollection =
      'walk_request';

  static const String walkIdCounterCollection =
      'walk_counters';

  static const String walkIdCounterDocument =
      'walk_id';

  // ==========================================================
  // CREATE REQUEST
  // ==========================================================
  //
  // Creates:
  //
  // walk_request/{firebaseAutoId}
  //
  // with:
  //
  // walkId = DW-000001
  // walkId = DW-000002
  // walkId = DW-000003
  //
  // The serial number is generated inside a Firestore
  // transaction so two Walks cannot receive the same number.
  //
  // IMPORTANT:
  // Firebase auto document ID remains the internal request ID.
  //
  // walkId is the professional Dojo Walk ID.
  //
  // FINAL FORMAT:
  //
  // DW-000001
  // DW-000002
  // DW-000003
  //
  // ==========================================================

  Future<DocumentReference<Map<String, dynamic>>>
      createRequest({
    required Map<String, dynamic> data,
  }) async {
    final CollectionReference<Map<String, dynamic>>
        requests =
        _firestore.collection(
      walkRequestsCollection,
    );

    final DocumentReference<Map<String, dynamic>>
        requestRef =
        requests.doc();

    final DocumentReference<Map<String, dynamic>>
        counterRef =
        _firestore
            .collection(
              walkIdCounterCollection,
            )
            .doc(
              walkIdCounterDocument,
            );

    final Map<String, dynamic> requestData =
        Map<String, dynamic>.from(data);

    await _firestore.runTransaction(
      (transaction) async {
        // ======================================================
        // READ CURRENT COUNTER
        // ======================================================

        final DocumentSnapshot<Map<String, dynamic>>
            counterSnapshot =
            await transaction.get(counterRef);

        int lastNumber = 0;

        if (counterSnapshot.exists) {
          final Map<String, dynamic> counterData =
              counterSnapshot.data() ??
                  <String, dynamic>{};

          final dynamic value =
              counterData['lastNumber'];

          if (value is num) {
            lastNumber = value.toInt();
          } else {
            lastNumber =
                int.tryParse(
                      value?.toString() ?? '',
                    ) ??
                    0;
          }
        }

        // ======================================================
        // NEXT UNIQUE SERIAL NUMBER
        // ======================================================

        final int nextNumber =
            lastNumber + 1;

        // ======================================================
        // 6-DIGIT LIMIT
        // ======================================================

        if (nextNumber > 999999) {
          throw StateError(
            'Walk ID limit reached.',
          );
        }

        // ======================================================
        // FORMAT
        // ======================================================
        //
        // 1       -> DW-000001
        // 2       -> DW-000002
        // 10      -> DW-000010
        // 100     -> DW-000100
        // 1245    -> DW-001245
        //
        // ======================================================

        final String walkId =
            'DW-${nextNumber.toString().padLeft(6, '0')}';

        // ======================================================
        // REQUEST DATA
        // ======================================================

        requestData['walkId'] = walkId;

        // ======================================================
        // INTERNAL REQUEST ID
        // ======================================================

        requestData['requestId'] =
            requestRef.id;

        // ======================================================
        // COUNTER UPDATE
        // ======================================================

        transaction.set(
          counterRef,
          <String, dynamic>{
            'lastNumber': nextNumber,
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(
            merge: true,
          ),
        );

        // ======================================================
        // CREATE WALK REQUEST
        // ======================================================

        transaction.set(
          requestRef,
          requestData,
        );
      },
    );

    return requestRef;
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
