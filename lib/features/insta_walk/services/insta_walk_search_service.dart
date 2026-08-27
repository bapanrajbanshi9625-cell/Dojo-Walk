import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'insta_walk_firestore_helper.dart';
import 'insta_walk_request_state.dart';
import 'insta_walk_search_result.dart';

class InstaWalkSearchService {
  // ==========================================================
  // CONSTRUCTOR
  // ==========================================================

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

  static const String walkRequestsCollection = 'walk_requests';

  // IMPORTANT:
  // Owner profiles are now stored in:
  // owners/{documentId}
  static const String ownersCollection = 'owners';

  // ==========================================================
  // SEARCH CONFIG
  // ==========================================================

  static const double searchRadiusKm = 3.5;

  // ==========================================================
  // LISTENER
  // ==========================================================

  StreamSubscription<InstaWalkRequestState>? _requestSubscription;

  // ==========================================================
  // ACTIVE REQUEST
  // ==========================================================

  String? _activeRequestId;

  String? get activeRequestId => _activeRequestId;

  bool get hasActiveRequest =>
      _activeRequestId != null &&
      _activeRequestId!.trim().isNotEmpty;

  // ==========================================================
  // CURRENT USER
  // ==========================================================

  User? get currentUser => _auth.currentUser;

  // ==========================================================
  // FIND OWNER PROFILE
  //
  // FIRESTORE:
  //
  // owners/{documentId}
  //
  // Match:
  // authUid == FirebaseAuth.currentUser.uid
  //
  // Expected fields:
  // profileCompleted: true/false
  // authUid: Firebase UID
  // ownerId: Owner ID
  // ownerName: Owner name
  // ==========================================================

  Future<DocumentSnapshot<Map<String, dynamic>>?>
      findOwnerProfile() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _firestore
              .collection(ownersCollection)
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
      print('findOwnerProfile error: $e');
      rethrow;
    }
  }

  // ==========================================================
  // CHECK OWNER PROFILE COMPLETION
  //
  // Returns:
  // true  = profile exists and profileCompleted == true
  // false = profile missing or incomplete
  // ==========================================================

  Future<bool> isOwnerProfileCompleted() async {
    final DocumentSnapshot<Map<String, dynamic>>? profile =
        await findOwnerProfile();

    if (profile == null || !profile.exists) {
      return false;
    }

    final Map<String, dynamic> data =
        profile.data() ?? <String, dynamic>{};

    return data['profileCompleted'] == true;
  }

  // ==========================================================
  // START SEARCH
  // ==========================================================

  Future<InstaWalkSearchResult> startSearch({
    required String ownerId,
    required String ownerName,
    required String address,
    required GeoPoint ownerLocation,
  }) async {
    // ========================================================
    // AUTH
    // ========================================================

    final User? user = _auth.currentUser;

    if (user == null) {
      return const InstaWalkSearchResult.failure(
        message: 'Please login first.',
        errorCode: 'unauthenticated',
      );
    }

    // ========================================================
    // CLEAN DATA
    // ========================================================

    final String cleanOwnerId = ownerId.trim();

    final String cleanOwnerName =
        ownerName.trim().isEmpty
            ? 'Dog Owner'
            : ownerName.trim();

    final String cleanAddress = address.trim();

    // ========================================================
    // VALIDATION
    // ========================================================

    if (cleanOwnerId.isEmpty) {
      return const InstaWalkSearchResult.failure(
        message: 'Owner ID missing.',
        errorCode: 'missing-owner-id',
      );
    }

    if (cleanAddress.isEmpty) {
      return const InstaWalkSearchResult.failure(
        message: 'Owner address missing.',
        errorCode: 'missing-address',
      );
    }

    try {
      // ======================================================
      // VERIFY OWNER PROFILE
      //
      // IMPORTANT:
      // Reads from owners collection.
      // ======================================================

      final DocumentSnapshot<Map<String, dynamic>>? profile =
          await findOwnerProfile();

      if (profile == null || !profile.exists) {
        return const InstaWalkSearchResult.failure(
          message: 'Owner profile not found.',
          errorCode: 'owner-profile-not-found',
        );
      }

      final Map<String, dynamic> profileData =
          profile.data() ?? <String, dynamic>{};

      final bool profileCompleted =
          profileData['profileCompleted'] == true;

      if (!profileCompleted) {
        return const InstaWalkSearchResult.failure(
          message: 'Owner profile is not completed.',
          errorCode: 'profile-not-completed',
        );
      }

      // ======================================================
      // PREVENT DUPLICATE ACTIVE REQUEST
      // ======================================================

      final InstaWalkRequestState? existing =
          await findActiveRequest(
        ownerId: cleanOwnerId,
      );

      if (existing != null && existing.isSearching) {
        _activeRequestId = existing.requestId;

        return InstaWalkSearchResult.success(
          requestId: existing.requestId,
        );
      }

      // ======================================================
      // CREATE REQUEST
      // ======================================================

      final DocumentReference<Map<String, dynamic>> ref =
          await _helper.createRequest(
        data: <String, dynamic>{
          // --------------------------------------------------
          // REQUEST
          // --------------------------------------------------

          'status': 'searching',

          'searchType': 'insta_walk',

          'senderRole': 'owner',

          // --------------------------------------------------
          // AUTH
          // --------------------------------------------------

          'senderUid': user.uid,

          'ownerAuthUid': user.uid,

          // --------------------------------------------------
          // OWNER
          // --------------------------------------------------

          'ownerId': cleanOwnerId,

          'businessId': cleanOwnerId,

          'ownerName': cleanOwnerName,

          'address': cleanAddress,

          // --------------------------------------------------
          // LOCATION
          // --------------------------------------------------

          'ownerLocation': ownerLocation,

          'ownerLocationType': 'search_snapshot',

          'searchRadiusKm': searchRadiusKm,

          // --------------------------------------------------
          // WALKER
          // --------------------------------------------------

          'walkerUid': null,

          'walkerId': null,

          'walkerName': null,

          'walkerPhone': null,

          // --------------------------------------------------
          // ACCEPTED
          // --------------------------------------------------

          'acceptedBy': null,

          'acceptedAt': null,

          // --------------------------------------------------
          // CREATED
          // --------------------------------------------------

          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      // ======================================================
      // SAVE ACTIVE REQUEST ID
      // ======================================================

      _activeRequestId = ref.id;

      return InstaWalkSearchResult.success(
        requestId: ref.id,
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

    // ========================================================
    // CANCEL PREVIOUS LOCAL LISTENER
    // ========================================================

    _requestSubscription?.cancel();
    _requestSubscription = null;

    _activeRequestId = cleanRequestId;

    // ========================================================
    // FIRESTORE STREAM
    // ========================================================

    final Stream<DocumentSnapshot<Map<String, dynamic>>> stream =
        _firestore
            .collection(walkRequestsCollection)
            .doc(cleanRequestId)
            .snapshots();

    // ========================================================
    // MAP STATE
    // ========================================================

    return stream.map(
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
  // LISTEN AND STORE SUBSCRIPTION
  // ==========================================================

  void listenAndStore(
    String requestId, {
    required void Function(
      InstaWalkRequestState state,
    ) onData,
    void Function(Object error)? onError,
  }) {
    _requestSubscription?.cancel();

    _requestSubscription = listenForRequest(
      requestId,
    ).listen(
      onData,
      onError: onError,
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
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
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
    } on FirebaseException {
      rethrow;
    }
  }

  // ==========================================================
  // FIND ACTIVE REQUEST
  //
  // Firestore:
  //
  // walk_requests
  //
  // ownerAuthUid == currentUser.uid
  //
  // status:
  // searching OR accepted
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
      // ======================================================
      // FIRST:
      // SEARCHING
      // ======================================================

      final QuerySnapshot<Map<String, dynamic>>
          searchingSnapshot =
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

      if (searchingSnapshot.docs.isNotEmpty) {
        final QueryDocumentSnapshot<Map<String, dynamic>> doc =
            searchingSnapshot.docs.first;

        _activeRequestId = doc.id;

        return InstaWalkRequestState.fromDocument(
          doc,
        );
      }

      // ======================================================
      // SECOND:
      // ACCEPTED
      // ======================================================

      final QuerySnapshot<Map<String, dynamic>>
          acceptedSnapshot =
          await _firestore
              .collection(walkRequestsCollection)
              .where(
                'ownerAuthUid',
                isEqualTo: user.uid,
              )
              .where(
                'status',
                isEqualTo: 'accepted',
              )
              .limit(1)
              .get();

      if (acceptedSnapshot.docs.isNotEmpty) {
        final QueryDocumentSnapshot<Map<String, dynamic>> doc =
            acceptedSnapshot.docs.first;

        _activeRequestId = doc.id;

        return InstaWalkRequestState.fromDocument(
          doc,
        );
      }

      return null;
    } on FirebaseException catch (e) {
      print(
        'findActiveRequest Firebase error: '
        '${e.code} - ${e.message}',
      );

      rethrow;
    } catch (e) {
      print('findActiveRequest error: $e');
      rethrow;
    }
  }

  // ==========================================================
  // CANCEL SEARCH
  //
  // ONLY OWNER CAN CANCEL OWN SEARCH
  //
  // Accepted request cannot be cancelled here.
  // ==========================================================

  Future<bool> cancelSearch({
    required String requestId,
  }) async {
    final String cleanRequestId = requestId.trim();

    if (cleanRequestId.isEmpty) {
      return false;
    }

    final User? user = _auth.currentUser;

    if (user == null) {
      return false;
    }

    try {
      final DocumentReference<Map<String, dynamic>> requestRef =
          _firestore
              .collection(walkRequestsCollection)
              .doc(cleanRequestId);

      final bool cancelled =
          await _firestore.runTransaction<bool>(
        (
          Transaction transaction,
        ) async {
          final DocumentSnapshot<Map<String, dynamic>> snapshot =
              await transaction.get(
            requestRef,
          );

          // ==================================================
          // DOCUMENT DOES NOT EXIST
          // ==================================================

          if (!snapshot.exists) {
            return true;
          }

          final Map<String, dynamic> data =
              snapshot.data() ?? <String, dynamic>{};

          // ==================================================
          // STATUS
          // ==================================================

          final String status =
              (data['status'] ?? '')
                  .toString()
                  .trim()
                  .toLowerCase();

          // ==================================================
          // ALREADY FINISHED
          // ==================================================

          if (status == 'cancelled' ||
              status == 'expired' ||
              status == 'completed') {
            return true;
          }

          // ==================================================
          // ACCEPTED
          //
          // Do not cancel accepted request from search UI.
          // ==================================================

          if (status == 'accepted') {
            return false;
          }

          // ==================================================
          // ONLY SEARCHING CAN BE CANCELLED
          // ==================================================

          if (status != 'searching') {
            return false;
          }

          // ==================================================
          // OWNER AUTH CHECK
          // ==================================================

          final String ownerAuthUid =
              (data['ownerAuthUid'] ?? '')
                  .toString()
                  .trim();

          if (ownerAuthUid != user.uid) {
            return false;
          }

          // ==================================================
          // UPDATE
          // ==================================================

          transaction.update(
            requestRef,
            <String, dynamic>{
              'status': 'cancelled',
              'cancelledAt': FieldValue.serverTimestamp(),
              'cancelledBy': user.uid,
            },
          );

          return true;
        },
      );

      // ======================================================
      // CLEAR LOCAL REQUEST
      // ======================================================

      if (cancelled &&
          _activeRequestId == cleanRequestId) {
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
      print('cancelSearch error: $e');
      return false;
    }
  }

  // ==========================================================
  // CLEAR LOCAL REQUEST
  //
  // IMPORTANT:
  // Does NOT modify Firestore.
  // ==========================================================

  void clearLocalRequest() {
    _activeRequestId = null;
  }

  // ==========================================================
  // DISPOSE
  //
  // IMPORTANT:
  // This only removes the local listener.
  //
  // It DOES NOT:
  // - cancel Firestore request
  // - delete document
  // - change status
  // ==========================================================

  void dispose() {
    _requestSubscription?.cancel();
    _requestSubscription = null;
  }
}
