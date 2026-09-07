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
  // FINAL ARCHITECTURE:
  //
  // walk_request/DW000001
  // walk_request/DW000002
  // walk_request/DW000003
  //
  // SAME ID is used everywhere.
  //
  // NO Firebase Auto-ID.
  // NO separate walkId.
  //
  // Final format:
  //
  // DW000001
  // DW000002
  // DW000003
  //
  // Serial number is generated inside a Firestore
  // transaction so two Walks cannot receive the same number.
  //
  // ==========================================================

  Future<DocumentReference<Map<String, dynamic>>>
      createRequest({
    required Map<String, dynamic> data,
  }) async {
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

    String? generatedRequestId;

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
        // FINAL DOJO WALK ID
        // ======================================================
        //
        // 1       -> DW000001
        // 2       -> DW000002
        // 10      -> DW000010
        // 100     -> DW000100
        // 1245    -> DW001245
        //
        // ======================================================

        final String walkRequestId =
            'DW${nextNumber.toString().padLeft(6, '0')}';

        generatedRequestId =
            walkRequestId;

        // ======================================================
        // REQUEST DATA
        // ======================================================
        //
        // requestId itself is the Dojo Walk ID.
        //
        // NO walkId field.
        //
        // ======================================================

        requestData['requestId'] =
            walkRequestId;

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
        // REQUEST DOCUMENT
        // ======================================================
        //
        // walk_request/DW000001
        //
        // ======================================================

        final DocumentReference<Map<String, dynamic>>
            requestRef =
            _firestore
                .collection(
                  walkRequestsCollection,
                )
                .doc(walkRequestId);

        transaction.set(
          requestRef,
          requestData,
        );
      },
    );

    // ==========================================================
    // SAFETY CHECK
    // ==========================================================

    final String requestId =
        generatedRequestId ?? '';

    if (requestId.isEmpty) {
      throw StateError(
        'Unable to generate Walk Request ID.',
      );
    }

    // ==========================================================
    // RETURN REQUEST REFERENCE
    //
    // Document ID:
    //
    // DW000001
    //
    // ==========================================================

    return _firestore
        .collection(walkRequestsCollection)
        .doc(requestId);
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
