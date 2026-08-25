import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'insta_walk_firestore_helper.dart';
import 'insta_walk_request_state.dart';
import 'insta_walk_search_result.dart';

class InstaWalkSearchService {
  InstaWalkSearchService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _helper = InstaWalkFirestoreHelper(
          firestore: firestore ?? FirebaseFirestore.instance,
        );

  // ==========================================================
  // FIREBASE
  // ==========================================================

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final InstaWalkFirestoreHelper _helper;

  // ==========================================================
  // COLLECTIONS
  // ==========================================================

  static const String walkRequestsCollection =
      'walk_requests';

  static const String ownerProfilesCollection =
      'ownerProfiles';

  // ==========================================================
  // SEARCH CONFIG
  // ==========================================================

  static const double searchRadiusKm = 3.5;

  // ==========================================================
  // ACTIVE REQUEST
  // ==========================================================

  String? _activeRequestId;

  String? get activeRequestId => _activeRequestId;

  bool get hasActiveRequest =>
      _activeRequestId != null &&
      _activeRequestId!.trim().isNotEmpty;

  User? get currentUser => _auth.currentUser;

  // ==========================================================
  // SUBSCRIPTION
  // ==========================================================

  StreamSubscription<
      DocumentSnapshot<Map<String, dynamic>>>?
      _requestSubscription;

  // ==========================================================
  // START SEARCH
  // ==========================================================

  Future<InstaWalkSearchResult> startSearch({
    required String ownerId,
    required String ownerName,
    required String address,
    required GeoPoint ownerLocation,
  }) async {
    final User? user = _auth.currentUser;

    // --------------------------------------------------------
    // AUTH CHECK
    // --------------------------------------------------------

    if (user == null) {
      return const InstaWalkSearchResult.failure(
        message: 'Please login first.',
        errorCode: 'unauthenticated',
      );
    }

    // --------------------------------------------------------
    // CLEAN VALUES
    // --------------------------------------------------------

    final String cleanOwnerId = ownerId.trim();

    final String cleanOwnerName =
        ownerName.trim().isEmpty
            ? 'Dog Owner'
            : ownerName.trim();

    final String cleanAddress = address.trim();

    // --------------------------------------------------------
    // VALIDATION
    // --------------------------------------------------------

    if (cleanOwnerId.isEmpty) {
      return const InstaWalkSearchResult.failure(
        message: 'Owner ID missing.',
        errorCode: 'missing-owner-id',
      );
    }

    if (cleanAddress.isEmpty) {
      return const InstaWalkSearchResult.failure(
        message: 'Address missing.',
        errorCode: 'missing-address',
      );
    }

    try {
      // ------------------------------------------------------
      // CREATE WALK REQUEST
      // ------------------------------------------------------

      final DocumentReference<
          Map<String, dynamic>> requestRef =
          await _helper.createRequest(
        data: <String, dynamic>{
          // --------------------------------------------------
          // REQUEST STATUS
          // --------------------------------------------------

          'status': 'searching',

          // --------------------------------------------------
          // REQUEST TYPE
          // --------------------------------------------------

          'searchType': 'insta_walk',

          // --------------------------------------------------
          // SENDER
          // --------------------------------------------------

          'senderRole': 'owner',

          'senderUid': user.uid,

          // --------------------------------------------------
          // OWNER AUTH
          // --------------------------------------------------

          'ownerAuthUid': user.uid,

          // --------------------------------------------------
          // OWNER IDENTIFIERS
          // --------------------------------------------------

          'ownerId': cleanOwnerId,

          'businessId': cleanOwnerId,

          // --------------------------------------------------
          // OWNER INFORMATION
          // --------------------------------------------------

          'ownerName': cleanOwnerName,

          'address': cleanAddress,

          // --------------------------------------------------
          // LOCATION
          // --------------------------------------------------

          'ownerLocation': ownerLocation,

          'ownerLocationType': 'search_snapshot',

          // --------------------------------------------------
          // SEARCH RADIUS
          // --------------------------------------------------

          'searchRadiusKm': searchRadiusKm,

          // --------------------------------------------------
          // WALKER
          // --------------------------------------------------

          'walkerUid': null,

          'walkerId': null,

          'walkerName': null,

          // --------------------------------------------------
          // ACCEPTANCE
          // --------------------------------------------------

          'acceptedBy': null,

          'acceptedAt': null,

          // --------------------------------------------------
          // TIMESTAMP
          // --------------------------------------------------

          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      // ------------------------------------------------------
      // SAVE ACTIVE REQUEST
      // ------------------------------------------------------

      _activeRequestId = requestRef.id;

      return InstaWalkSearchResult.success(
        requestId: requestRef.id,
      );
    } on FirebaseException catch (e) {
      return InstaWalkSearchResult.failure(
        message: e.message ?? 'Firestore error.',
        errorCode: e.code,
      );
    } catch (e) {
      return InstaWalkSearchResult.failure(
        message: 'Unable to start search.',
        errorCode: e.toString(),
      );
    }
  }

  // ==========================================================
  // LISTEN FOR REQUEST
  // ==========================================================

  Stream<InstaWalkRequestState> listenForRequest(
    String requestId,
  ) {
    final String cleanRequestId = requestId.trim();

    if (cleanRequestId.isEmpty) {
      return Stream<InstaWalkRequestState>.value(
        InstaWalkRequestState.notFound(),
      );
    }

    // Cancel previous listener.
    _requestSubscription?.cancel();
    _requestSubscription = null;

    _activeRequestId = cleanRequestId;

    return _firestore
        .collection(walkRequestsCollection)
        .doc(cleanRequestId)
        .snapshots()
        .map(
          (
            DocumentSnapshot<Map<String, dynamic>> snapshot,
          ) {
            if (!snapshot.exists) {
              return InstaWalkRequestState.notFound(
                requestId: cleanRequestId,
              );
            }

            return InstaWalkRequestState.fromDocument(
              snapshot,
            );
          },
        );
  }

  // ==========================================================
  // GET REQUEST STATE
  // ==========================================================

  Future<InstaWalkRequestState> getRequestState(
    String requestId,
  ) async {
    final String cleanRequestId = requestId.trim();

    if (cleanRequestId.isEmpty) {
      return InstaWalkRequestState.notFound();
    }

    try {
      final DocumentSnapshot<
          Map<String, dynamic>> snapshot =
          await _firestore
              .collection(walkRequestsCollection)
              .doc(cleanRequestId)
              .get();

      if (!snapshot.exists) {
        return InstaWalkRequestState.notFound(
          requestId: cleanRequestId,
        );
      }

      return InstaWalkRequestState.fromDocument(
        snapshot,
      );
    } on FirebaseException catch (e) {
      // Keep service safe for UI.
      print(
        'getRequestState Firebase error: '
        '${e.code} - ${e.message}',
      );

      rethrow;
    }
  }

  // ==========================================================
  // FIND OWNER PROFILE
  //
  // FIRESTORE:
  //
  // ownerProfiles/{documentId}
  //
  // WHERE:
  // authUid == currentUser.uid
  // ==========================================================

  Future<DocumentSnapshot<Map<String, dynamic>>?>
      findOwnerProfile() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    try {
      final QuerySnapshot<
          Map<String, dynamic>> snapshot =
          await _firestore
              .collection(ownerProfilesCollection)
              .where(
                'authUid',
                isEqualTo: user.uid,
              )
              .limit(1)
              .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return snapshot.docs.first;
    } on FirebaseException catch (e) {
      print(
        'findOwnerProfile Firebase error: '
        '${e.code} - ${e.message}',
      );

      rethrow;
    } catch (e) {
      print(
        'findOwnerProfile error: $e',
      );

      rethrow;
    }
  }

  // ==========================================================
  // FIND ACTIVE REQUEST
  //
  // OWNER SIDE
  //
  // ownerAuthUid == currentUser.uid
  // status == searching
  // ==========================================================

  Future<InstaWalkRequestState?> findActiveRequest({
    required String ownerId,
  }) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    final String cleanOwnerId = ownerId.trim();

    if (cleanOwnerId.isEmpty) {
      return null;
    }

    try {
      final QuerySnapshot<
          Map<String, dynamic>> snapshot =
          await _firestore
              .collection(walkRequestsCollection)
              .where(
                'ownerAuthUid',
                isEqualTo: user.uid,
              )
              .where(
                'ownerId',
                isEqualTo: cleanOwnerId,
              )
              .where(
                'status',
                isEqualTo: 'searching',
              )
              .limit(1)
              .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final QueryDocumentSnapshot<
          Map<String, dynamic>> doc =
          snapshot.docs.first;

      _activeRequestId = doc.id;

      return InstaWalkRequestState.fromDocument(
        doc,
      );
    } on FirebaseException catch (e) {
      print(
        'findActiveRequest Firebase error: '
        '${e.code} - ${e.message}',
      );

      rethrow;
    }
  }

  // ==========================================================
  // FIND ACTIVE REQUEST BY AUTH UID
  //
  // USEFUL DURING APP RESTART
  // ==========================================================

  Future<InstaWalkRequestState?> findActiveRequestForCurrentUser()
      async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    try {
      final QuerySnapshot<
          Map<String, dynamic>> snapshot =
          await _firestore
              .collection(walkRequestsCollection)
              .where(
                'ownerAuthUid',
                isEqualTo: user.uid,
              )
              .where(
                'status',
                isEqualTo: 'searching',
              )
              .limit(1)
              .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final QueryDocumentSnapshot<
          Map<String, dynamic>> doc =
          snapshot.docs.first;

      _activeRequestId = doc.id;

      return InstaWalkRequestState.fromDocument(
        doc,
      );
    } on FirebaseException catch (e) {
      print(
        'findActiveRequestForCurrentUser Firebase error: '
        '${e.code} - ${e.message}',
      );

      rethrow;
    }
  }

  // ==========================================================
  // CANCEL SEARCH
  // ==========================================================

  Future<bool> cancelSearch({
    required String requestId,
  }) async {
    final String cleanRequestId =
        requestId.trim();

    if (cleanRequestId.isEmpty) {
      return false;
    }

    final User? user = _auth.currentUser;

    if (user == null) {
      return false;
    }

    try {
      final DocumentReference<
          Map<String, dynamic>> requestRef =
          _firestore
              .collection(walkRequestsCollection)
              .doc(cleanRequestId);

      final bool cancelled =
          await _firestore.runTransaction<bool>(
        (
          Transaction transaction,
        ) async {
          final DocumentSnapshot<
              Map<String, dynamic>> snapshot =
              await transaction.get(
            requestRef,
          );

          // --------------------------------------------------
          // DOCUMENT DOES NOT EXIST
          // --------------------------------------------------

          if (!snapshot.exists) {
            return true;
          }

          final Map<String, dynamic> data =
              snapshot.data() ??
                  <String, dynamic>{};

          // --------------------------------------------------
          // CURRENT STATUS
          // --------------------------------------------------

          final String status =
              (data['status'] ?? '')
                  .toString()
                  .trim()
                  .toLowerCase();

          // --------------------------------------------------
          // ALREADY CLOSED
          // --------------------------------------------------

          if (status == 'cancelled' ||
              status == 'expired' ||
              status == 'completed') {
            return true;
          }

          // --------------------------------------------------
          // ACCEPTED REQUEST CANNOT BE CANCELLED
          // --------------------------------------------------

          if (status == 'accepted') {
            return false;
          }

          // --------------------------------------------------
          // ONLY SEARCHING REQUEST CAN BE CANCELLED
          // --------------------------------------------------

          if (status != 'searching') {
            return false;
          }

          // --------------------------------------------------
          // OWNER SECURITY CHECK
          // --------------------------------------------------

          final String ownerAuthUid =
              (data['ownerAuthUid'] ?? '')
                  .toString()
                  .trim();

          if (ownerAuthUid != user.uid) {
            return false;
          }

          // --------------------------------------------------
          // CANCEL
          // --------------------------------------------------

          transaction.update(
            requestRef,
            <String, dynamic>{
              'status': 'cancelled',
              'cancelledAt':
                  FieldValue.serverTimestamp(),
            },
          );

          return true;
        },
      );

      // ------------------------------------------------------
      // CLEAR ACTIVE REQUEST
      // ------------------------------------------------------

      if (cancelled &&
          _activeRequestId ==
              cleanRequestId) {
        _activeRequestId = null;
      }

      return cancelled;
    } on FirebaseException catch (e) {
      print(
        'cancelSearch Firebase error: '
        '${e.code} - ${e.message}',
      );

      return false;
    } catch (e) {
      print(
        'cancelSearch error: $e',
      );

      return false;
    }
  }

  // ==========================================================
  // CLEAR ACTIVE REQUEST
  // ==========================================================

  void clearActiveRequest() {
    _activeRequestId = null;
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  void dispose() {
    _requestSubscription?.cancel();
    _requestSubscription = null;
    _activeRequestId = null;
  }
}
