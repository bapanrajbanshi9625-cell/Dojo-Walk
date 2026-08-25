import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InstaWalkSearchService {
  InstaWalkSearchService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // ============================================================
  // COLLECTIONS
  // ============================================================

  static const String walkRequestsCollection = 'walk_requests';
  static const String ownerProfilesCollection = 'ownerProfiles';

  // ============================================================
  // SEARCH CONFIG
  // ============================================================

  static const double searchRadiusKm = 3.0;

  // ============================================================
  // INTERNAL STATE
  // ============================================================

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _requestSubscription;

  String? _activeRequestId;

  // ============================================================
  // GETTERS
  // ============================================================

  String? get activeRequestId => _activeRequestId;

  bool get hasActiveRequest =>
      _activeRequestId != null &&
      _activeRequestId!.trim().isNotEmpty;

  User? get currentUser => _auth.currentUser;

  // ============================================================
  // DISPOSE
  // ============================================================

  Future<void> dispose() async {
    await clearActiveRequest();
  }

  // ============================================================
  // START SEARCH
  //
  // IMPORTANT:
  //
  // NO TIMER
  // NO COUNTDOWN
  // NO expiresAt
  // NO AUTOMATIC EXPIRY
  //
  // Firestore status is the source of truth.
  // ============================================================

  Future<InstaWalkSearchResult> startSearch({
    required String ownerId,
    required String ownerName,
    required String address,
    required GeoPoint ownerLocation,
  }) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return const InstaWalkSearchResult.failure(
        message: 'Please login first.',
        errorCode: 'unauthenticated',
      );
    }

    final String businessId = ownerId.trim();

    final String cleanOwnerName =
        ownerName.trim().isEmpty
            ? 'Dog Owner'
            : ownerName.trim();

    final String cleanAddress = address.trim();

    if (businessId.isEmpty) {
      return const InstaWalkSearchResult.failure(
        message: 'Business ID is missing.',
        errorCode: 'missing-business-id',
      );
    }

    if (cleanAddress.isEmpty) {
      return const InstaWalkSearchResult.failure(
        message: 'Owner address is missing.',
        errorCode: 'missing-address',
      );
    }

    // ==========================================================
    // CHECK LOCAL ACTIVE REQUEST
    // ==========================================================

    if (hasActiveRequest) {
      final String activeId =
          _activeRequestId!.trim();

      final InstaWalkRequestState state =
          await getRequestState(activeId);

      if (state.isSearching ||
          state.isAccepted) {
        return InstaWalkSearchResult.success(
          requestId: activeId,
        );
      }

      await clearActiveRequest();
    }

    // ==========================================================
    // CHECK FIRESTORE ACTIVE REQUEST
    //
    // This prevents duplicate Insta Walk requests.
    // ==========================================================

    final InstaWalkRequestState? existing =
        await findActiveRequest(
      ownerId: businessId,
    );

    if (existing != null &&
        (existing.isSearching ||
            existing.isAccepted)) {
      final String? existingId =
          existing.requestId;

      if (existingId != null &&
          existingId.trim().isNotEmpty) {
        _activeRequestId =
            existingId.trim();

        return InstaWalkSearchResult.success(
          requestId: existingId.trim(),
        );
      }
    }

    // ==========================================================
    // STOP OLD LISTENER
    // ==========================================================

    await _requestSubscription?.cancel();
    _requestSubscription = null;

    try {
      // ========================================================
      // CREATE NEW REQUEST
      // ========================================================

      final DocumentReference<
          Map<String, dynamic>> ref =
          _firestore
              .collection(
                walkRequestsCollection,
              )
              .doc();

      await ref.set({
        // ======================================================
        // REQUEST
        // ======================================================

        'requestId': ref.id,

        // ======================================================
        // STATUS
        // ======================================================

        'status': 'searching',

        // ======================================================
        // TYPE
        // ======================================================

        'searchType': 'insta_walk',
        'senderRole': 'owner',

        // ======================================================
        // AUTH
        // ======================================================

        'senderUid': user.uid,
        'ownerAuthUid': user.uid,

        // ======================================================
        // BUSINESS
        // ======================================================

        'businessId': businessId,
        'ownerId': businessId,

        // ======================================================
        // OWNER
        // ======================================================

        'ownerName': cleanOwnerName,
        'address': cleanAddress,

        // ======================================================
        // SEARCH
        // ======================================================

        'searchRadiusKm': searchRadiusKm,

        // ======================================================
        // LOCATION
        //
        // Recovery uses ownerLocation.
        // ======================================================

        'ownerLocation': ownerLocation,
        'ownerLocationType': 'search_snapshot',

        // ======================================================
        // WALKER
        // ======================================================

        'walkerUid': null,
        'walkerId': null,
        'walkerName': null,

        'acceptedBy': null,
        'acceptedAt': null,

        // ======================================================
        // CREATED
        // ======================================================

        'createdAt': FieldValue.serverTimestamp(),
      });

      _activeRequestId = ref.id;

      return InstaWalkSearchResult.success(
        requestId: ref.id,
      );
    } on FirebaseException catch (e) {
      _logFirebaseError(
        'startSearch',
        e,
      );

      return InstaWalkSearchResult.failure(
        message: _firebaseErrorMessage(e),
        errorCode: e.code,
      );
    } catch (e) {
      _logError(
        'startSearch',
        e,
      );

      return const InstaWalkSearchResult.failure(
        message:
            'Unable to start Insta Walk search.',
      );
    }
  }

  // ============================================================
  // FIND OWNER PROFILE
  // ============================================================

  Future<QueryDocumentSnapshot<
      Map<String, dynamic>>?> findOwnerProfile() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    try {
      final QuerySnapshot<
          Map<String, dynamic>> snapshot =
          await _firestore
              .collection(
                ownerProfilesCollection,
              )
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
      _logFirebaseError(
        'findOwnerProfile',
        e,
      );

      rethrow;
    } catch (e) {
      _logError(
        'findOwnerProfile',
        e,
      );

      rethrow;
    }
  }

  // ============================================================
  // FIND ACTIVE REQUEST
  //
  // IMPORTANT:
  //
  // No expiresAt check.
  //
  // searching = active
  // accepted = active
  //
  // There is NO automatic expiry.
  // ============================================================

  Future<InstaWalkRequestState?> findActiveRequest({
    required String ownerId,
  }) async {
    final User? user = _auth.currentUser;

    final String businessId =
        ownerId.trim();

    if (user == null ||
        businessId.isEmpty) {
      return null;
    }

    try {
      // ========================================================
      // IMPORTANT
      //
      // No orderBy().
      //
      // This avoids unnecessary composite-index dependency.
      // ========================================================

      final QuerySnapshot<
          Map<String, dynamic>> snapshot =
          await _firestore
              .collection(
                walkRequestsCollection,
              )
              .where(
                'businessId',
                isEqualTo: businessId,
              )
              .where(
                'searchType',
                isEqualTo: 'insta_walk',
              )
              .limit(20)
              .get();

      if (snapshot.docs.isEmpty) {
        _activeRequestId = null;
        return null;
      }

      // ========================================================
      // FIND ACTIVE REQUEST
      //
      // First priority:
      // searching
      //
      // Second priority:
      // accepted
      // ========================================================

      InstaWalkRequestState? acceptedState;

      for (
        final QueryDocumentSnapshot<
            Map<String, dynamic>> doc
        in snapshot.docs
      ) {
        final Map<String, dynamic> data =
            doc.data();

        final String status =
            _statusFromData(data);

        // ======================================================
        // SEARCHING
        // ======================================================

        if (status == 'searching') {
          _activeRequestId = _requestIdFromDoc(
            doc,
            data,
          );

          return InstaWalkRequestState(
            status:
                InstaWalkRequestStatus.searching,
            data: _withRequestId(
              doc.id,
              data,
            ),
          );
        }

        // ======================================================
        // ACCEPTED
        // ======================================================

        if (status == 'accepted') {
          acceptedState =
              InstaWalkRequestState(
            status:
                InstaWalkRequestStatus.accepted,
            data: _withRequestId(
              doc.id,
              data,
            ),
          );
        }
      }

      // ========================================================
      // RETURN ACCEPTED IF NO SEARCHING REQUEST EXISTS
      // ========================================================

      if (acceptedState != null) {
        _activeRequestId =
            acceptedState.requestId;

        return acceptedState;
      }

      _activeRequestId = null;

      return null;
    } on FirebaseException catch (e) {
      _logFirebaseError(
        'findActiveRequest',
        e,
      );

      return null;
    } catch (e) {
      _logError(
        'findActiveRequest',
        e,
      );

      return null;
    }
  }

  // ============================================================
  // LISTEN FOR REQUEST
  //
  // FIRESTORE REALTIME LISTENER
  //
  // searching:
  //     keep waiting
  //
  // accepted:
  //     walker found
  //
  // expired:
  //     only if Firestore was manually changed
  //
  // cancelled:
  //     owner/walker cancellation
  // ============================================================

  Future<void> listenForRequest({
    required String requestId,
    required void Function(
      InstaWalkAcceptedData data,
    ) onAccepted,
    void Function()? onExpired,
    void Function()? onCancelled,
    void Function(Object error)? onError,
  }) async {
    final String id =
        requestId.trim();

    if (id.isEmpty) {
      return;
    }

    await _requestSubscription?.cancel();
    _requestSubscription = null;

    _activeRequestId = id;

    bool acceptedSent = false;
    bool expiredSent = false;
    bool cancelledSent = false;

    final DocumentReference<
        Map<String, dynamic>> ref =
        _firestore
            .collection(
              walkRequestsCollection,
            )
            .doc(id);

    _requestSubscription =
        ref.snapshots().listen(
      (
        DocumentSnapshot<
            Map<String, dynamic>> snapshot,
      ) {
        if (!snapshot.exists) {
          return;
        }

        final Map<String, dynamic>? rawData =
            snapshot.data();

        if (rawData == null) {
          return;
        }

        final Map<String, dynamic> data =
            _withRequestId(
          snapshot.id,
          rawData,
        );

        final String status =
            _statusFromData(data);

        // ======================================================
        // SEARCHING
        //
        // DO NOTHING.
        //
        // This is intentional.
        // ======================================================

        if (status == 'searching') {
          return;
        }

        // ======================================================
        // ACCEPTED
        // ======================================================

        if (status == 'accepted') {
          if (acceptedSent) {
            return;
          }

          acceptedSent = true;

          onAccepted(
            InstaWalkAcceptedData.fromMap(
              data,
            ),
          );

          return;
        }

        // ======================================================
        // EXPIRED
        //
        // Only manual/legacy state.
        // ======================================================

        if (status == 'expired') {
          if (expiredSent) {
            return;
          }

          expiredSent = true;

          onExpired?.call();

          return;
        }

        // ======================================================
        // CANCELLED
        // ======================================================

        if (status == 'cancelled' ||
            status == 'owner_cancelled' ||
            status == 'walker_cancelled') {
          if (cancelledSent) {
            return;
          }

          cancelledSent = true;

          onCancelled?.call();

          return;
        }
      },
      onError: (
        Object error,
      ) {
        // ======================================================
        // IMPORTANT
        //
        // Listener error does NOT change Firestore status.
        // ======================================================

        onError?.call(error);
      },
    );
  }

  // ============================================================
  // GET REQUEST STATE
  // ============================================================

  Future<InstaWalkRequestState> getRequestState(
    String requestId,
  ) async {
    final String id =
        requestId.trim();

    if (id.isEmpty) {
      return const InstaWalkRequestState(
        status:
            InstaWalkRequestStatus.notFound,
      );
    }

    try {
      final DocumentSnapshot<
          Map<String, dynamic>> snapshot =
          await _firestore
              .collection(
                walkRequestsCollection,
              )
              .doc(id)
              .get();

      if (!snapshot.exists ||
          snapshot.data() == null) {
        if (_activeRequestId == id) {
          _activeRequestId = null;
        }

        return const InstaWalkRequestState(
          status:
              InstaWalkRequestStatus.notFound,
        );
      }

      final Map<String, dynamic> data =
          _withRequestId(
        snapshot.id,
        snapshot.data()!,
      );

      final String status =
          _statusFromData(data);

      // ========================================================
      // SEARCHING
      // ========================================================

      if (status == 'searching') {
        _activeRequestId = id;

        return InstaWalkRequestState(
          status:
              InstaWalkRequestStatus.searching,
          data: data,
        );
      }

      // ========================================================
      // ACCEPTED
      // ========================================================

      if (status == 'accepted') {
        _activeRequestId = id;

        return InstaWalkRequestState(
          status:
              InstaWalkRequestStatus.accepted,
          data: data,
        );
      }

      // ========================================================
      // EXPIRED
      //
      // Manual/legacy only.
      // ========================================================

      if (status == 'expired') {
        if (_activeRequestId == id) {
          _activeRequestId = null;
        }

        return InstaWalkRequestState(
          status:
              InstaWalkRequestStatus.expired,
          data: data,
        );
      }

      // ========================================================
      // CANCELLED
      // ========================================================

      if (status == 'cancelled' ||
          status == 'owner_cancelled' ||
          status == 'walker_cancelled') {
        if (_activeRequestId == id) {
          _activeRequestId = null;
        }

        return InstaWalkRequestState(
          status:
              InstaWalkRequestStatus.cancelled,
          data: data,
        );
      }

      return InstaWalkRequestState(
        status:
            InstaWalkRequestStatus.unknown,
        data: data,
      );
    } on FirebaseException catch (e) {
      _logFirebaseError(
        'getRequestState',
        e,
      );

      return InstaWalkRequestState(
        status:
            InstaWalkRequestStatus.error,
        errorMessage:
            _firebaseErrorMessage(e),
      );
    } catch (e) {
      _logError(
        'getRequestState',
        e,
      );

      return const InstaWalkRequestState(
        status:
            InstaWalkRequestStatus.error,
        errorMessage:
            'Unable to check walk request.',
      );
    }
  }

  // ============================================================
  // CANCEL SEARCH
  //
  // ONLY OWNER CAN STOP SEARCH FROM OWNER APP.
  //
  // This service writes owner_cancelled.
  // Firestore rules must enforce that only the owner can do it.
  // ============================================================

  Future<bool> cancelSearch({
    String? requestId,
  }) async {
    final User? user =
        _auth.currentUser;

    if (user == null) {
      return false;
    }

    final String? requestedId =
        requestId?.trim();

    final String? activeId =
        _activeRequestId?.trim();

    final String? id =
        requestedId != null &&
                requestedId.isNotEmpty
            ? requestedId
            : activeId;

    if (id == null ||
        id.isEmpty) {
      return false;
    }

    try {
      final DocumentReference<
          Map<String, dynamic>> ref =
          _firestore
              .collection(
                walkRequestsCollection,
              )
              .doc(id);

      final DocumentSnapshot<
          Map<String, dynamic>> snapshot =
          await ref.get();

      if (!snapshot.exists) {
        await clearActiveRequest();
        return false;
      }

      final Map<String, dynamic> data =
          snapshot.data() ??
              <String, dynamic>{};

      final String status =
          _statusFromData(data);

      // ========================================================
      // ACCEPTED
      // ========================================================

      if (status == 'accepted') {
        return false;
      }

      // ========================================================
      // ONLY SEARCHING CAN BE CANCELLED
      // ========================================================

      if (status != 'searching') {
        await clearActiveRequest();
        return false;
      }

      // ========================================================
      // VERIFY OWNER
      //
      // Firestore rules remain the final security layer.
      // ========================================================

      final String ownerAuthUid =
          data['ownerAuthUid']
                  ?.toString()
                  .trim() ??
              '';

      final String senderUid =
          data['senderUid']
                  ?.toString()
                  .trim() ??
              '';

      final bool ownerMatches =
          ownerAuthUid == user.uid ||
          senderUid == user.uid;

      if (!ownerMatches) {
        return false;
      }

      // ========================================================
      // OWNER CANCEL
      // ========================================================

      await ref.update({
        'status': 'owner_cancelled',
        'cancelledAt':
            FieldValue.serverTimestamp(),
        'cancelledBy': user.uid,
        'cancelledByType': 'business',
      });

      await clearActiveRequest();

      return true;
    } on FirebaseException catch (e) {
      _logFirebaseError(
        'cancelSearch',
        e,
      );

      return false;
    } catch (e) {
      _logError(
        'cancelSearch',
        e,
      );

      return false;
    }
  }

  // ============================================================
  // EXPIRE REQUEST
  //
  // AUTOMATIC EXPIRY REMOVED.
  // ============================================================

  Future<bool> expireRequest({
    String? requestId,
  }) async {
    return false;
  }

  // ============================================================
  // REMAINING TIME
  //
  // NO COUNTDOWN.
  // ============================================================

  Future<Duration?> getRemainingTime(
    String requestId,
  ) async {
    return null;
  }

  // ============================================================
  // CLEAR ACTIVE REQUEST
  // ============================================================

  Future<void> clearActiveRequest() async {
    final StreamSubscription<
        DocumentSnapshot<Map<String, dynamic>>>?
        subscription =
        _requestSubscription;

    _requestSubscription = null;
    _activeRequestId = null;

    await subscription?.cancel();
  }

  // ============================================================
  // STATUS
  // ============================================================

  String _statusFromData(
    Map<String, dynamic> data,
  ) {
    return data['status']
            ?.toString()
            .trim()
            .toLowerCase() ??
        '';
  }

  // ============================================================
  // REQUEST ID
  // ============================================================

  String _requestIdFromDoc(
    QueryDocumentSnapshot<
        Map<String, dynamic>> doc,
    Map<String, dynamic> data,
  ) {
    final String storedId =
        data['requestId']
                ?.toString()
                .trim() ??
            '';

    if (storedId.isNotEmpty) {
      return storedId;
    }

    return doc.id.trim();
  }

  // ============================================================
  // ENSURE REQUEST ID EXISTS IN LOCAL MAP
  //
  // Does NOT write to Firestore.
  // ============================================================

  Map<String, dynamic> _withRequestId(
    String documentId,
    Map<String, dynamic> data,
  ) {
    final Map<String, dynamic> result =
        Map<String, dynamic>.from(data);

    final String existingId =
        result['requestId']
                ?.toString()
                .trim() ??
            '';

    if (existingId.isEmpty &&
        documentId.trim().isNotEmpty) {
      result['requestId'] =
          documentId.trim();
    }

    return result;
  }

  // ============================================================
  // FIREBASE ERROR MESSAGE
  // ============================================================

  String _firebaseErrorMessage(
    FirebaseException e,
  ) {
    switch (e.code) {
      case 'permission-denied':
        return 'Walk request was blocked by Firestore rules.';

      case 'unavailable':
        return 'Network is unavailable. Please try again.';

      case 'failed-precondition':
        return 'Firestore is not ready for this request.';

      case 'unauthenticated':
        return 'Please login again.';

      case 'not-found':
        return 'Walk request was not found.';

      case 'already-exists':
        return 'This walk request already exists.';

      case 'aborted':
        return 'The request was interrupted. Please try again.';

      default:
        return 'Unable to process Insta Walk request.';
    }
  }

  // ============================================================
  // LOG FIREBASE ERROR
  // ============================================================

  void _logFirebaseError(
    String method,
    FirebaseException error,
  ) {
    print(
      'InstaWalkSearchService.$method '
      'FirebaseException: '
      '${error.code} - ${error.message}',
    );
  }

  // ============================================================
  // LOG ERROR
  // ============================================================

  void _logError(
    String method,
    Object error,
  ) {
    print(
      'InstaWalkSearchService.$method '
      'error: $error',
    );
  }
}

// ==================================================================
// SEARCH RESULT
// ==================================================================

class InstaWalkSearchResult {
  final bool success;
  final String? requestId;
  final DateTime? expiresAt;
  final Duration? duration;
  final int? searchNumber;
  final String? message;
  final String? errorCode;

  const InstaWalkSearchResult({
    required this.success,
    this.requestId,
    this.expiresAt,
    this.duration,
    this.searchNumber,
    this.message,
    this.errorCode,
  });

  const InstaWalkSearchResult.success({
    required String requestId,
    DateTime? expiresAt,
    Duration? duration,
    int? searchNumber,
  }) : this(
          success: true,
          requestId: requestId,
          expiresAt: expiresAt,
          duration: duration,
          searchNumber: searchNumber,
        );

  const InstaWalkSearchResult.failure({
    required String message,
    String? errorCode,
  }) : this(
          success: false,
          message: message,
          errorCode: errorCode,
        );
}

// ==================================================================
// ACCEPTED DATA
// ==================================================================

class InstaWalkAcceptedData {
  final String requestId;
  final String businessId;
  final String ownerId;
  final String ownerAuthUid;
  final String ownerName;
  final String walkerUid;
  final String walkerId;
  final String walkerName;
  final DateTime? acceptedAt;
  final Map<String, dynamic> rawData;

  const InstaWalkAcceptedData({
    required this.requestId,
    required this.businessId,
    required this.ownerId,
    required this.ownerAuthUid,
    required this.ownerName,
    required this.walkerUid,
    required this.walkerId,
    required this.walkerName,
    required this.acceptedAt,
    required this.rawData,
  });

  factory InstaWalkAcceptedData.fromMap(
    Map<String, dynamic> data,
  ) {
    DateTime? acceptedAt;

    final dynamic acceptedValue =
        data['acceptedAt'];

    if (acceptedValue is Timestamp) {
      acceptedAt =
          acceptedValue.toDate();
    } else if (acceptedValue is DateTime) {
      acceptedAt = acceptedValue;
    }

    // ==========================================================
    // REQUEST ID
    // ==========================================================

    final String requestId =
        data['requestId']
                ?.toString()
                .trim() ??
            '';

    // ==========================================================
    // WALKER UID
    // ==========================================================

    String walkerUid =
        data['walkerUid']
                ?.toString()
                .trim() ??
            '';

    if (walkerUid.isEmpty) {
      walkerUid =
          data['acceptedBy']
                  ?.toString()
                  .trim() ??
              '';
    }

    // ==========================================================
    // BUSINESS ID
    // ==========================================================

    String businessId =
        data['businessId']
                ?.toString()
                .trim() ??
            '';

    if (businessId.isEmpty) {
      businessId =
          data['ownerId']
                  ?.toString()
                  .trim() ??
              '';
    }

    // ==========================================================
    // OWNER ID
    // ==========================================================

    final String ownerId =
        data['ownerId']
                ?.toString()
                .trim()
                .isNotEmpty ==
            true
        ? data['ownerId']
            .toString()
            .trim()
        : businessId;

    // ==========================================================
    // OWNER AUTH UID
    // ==========================================================

    final String ownerAuthUid =
        data['ownerAuthUid']
                ?.toString()
                .trim() ??
            '';

    // ==========================================================
    // OWNER NAME
    // ==========================================================

    final String rawOwnerName =
        data['ownerName']
                ?.toString()
                .trim() ??
            '';

    final String ownerName =
        rawOwnerName.isEmpty
            ? 'Dog Owner'
            : rawOwnerName;

    // ==========================================================
    // WALKER ID
    // ==========================================================

    final String walkerId =
        data['walkerId']
                ?.toString()
                .trim() ??
            '';

    // ==========================================================
    // WALKER NAME
    // ==========================================================

    final String rawWalkerName =
        data['walkerName']
                ?.toString()
                .trim() ??
            '';

    final String walkerName =
        rawWalkerName.isEmpty
            ? 'Walker'
            : rawWalkerName;

    // ==========================================================
    // RETURN
    // ==========================================================

    return InstaWalkAcceptedData(
      requestId: requestId,
      businessId: businessId,
      ownerId: ownerId,
      ownerAuthUid: ownerAuthUid,
      ownerName: ownerName,
      walkerUid: walkerUid,
      walkerId: walkerId,
      walkerName: walkerName,
      acceptedAt: acceptedAt,
      rawData:
          Map<String, dynamic>.from(data),
    );
  }

  bool get hasWalker =>
      walkerId.isNotEmpty ||
      walkerUid.isNotEmpty;
}

// ==================================================================
// REQUEST STATUS
// ==================================================================

enum InstaWalkRequestStatus {
  searching,
  accepted,
  expired,
  cancelled,
  notFound,
  unknown,
  error,
}

// ==================================================================
// REQUEST STATE
// ==================================================================

class InstaWalkRequestState {
  final InstaWalkRequestStatus status;
  final Map<String, dynamic>? data;
  final String? errorMessage;

  const InstaWalkRequestState({
    required this.status,
    this.data,
    this.errorMessage,
  });

  bool get isSearching =>
      status ==
      InstaWalkRequestStatus.searching;

  bool get isAccepted =>
      status ==
      InstaWalkRequestStatus.accepted;

  bool get isExpired =>
      status ==
      InstaWalkRequestStatus.expired;

  bool get isCancelled =>
      status ==
      InstaWalkRequestStatus.cancelled;

  // ============================================================
  // REQUEST ID
  // ============================================================

  String? get requestId {
    final String value =
        data?['requestId']
                ?.toString()
                .trim() ??
            '';

    return value.isEmpty
        ? null
        : value;
  }

  // ============================================================
  // BUSINESS ID
  // ============================================================

  String? get businessId {
    String value =
        data?['businessId']
                ?.toString()
                .trim() ??
            '';

    if (value.isEmpty) {
      value =
          data?['ownerId']
                  ?.toString()
                  .trim() ??
              '';
    }

    return value.isEmpty
        ? null
        : value;
  }

  // ============================================================
  // OWNER ID
  // ============================================================

  String? get ownerId =>
      businessId;

  // ============================================================
  // OWNER AUTH UID
  // ============================================================

  String? get ownerAuthUid {
    final String value =
        data?['ownerAuthUid']
                ?.toString()
                .trim() ??
            '';

    return value.isEmpty
        ? null
        : value;
  }

  // ============================================================
  // EXPIRY
  //
  // COMPATIBILITY ONLY.
  //
  // New Insta Walk requests do not create expiresAt.
  // ============================================================

  DateTime? get expiresAt {
    final dynamic value =
        data?['expiresAt'];

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  // ============================================================
  // SEARCH NUMBER
  //
  // COMPATIBILITY ONLY.
  // ============================================================

  int? get searchNumber {
    final dynamic value =
        data?['searchNumber'];

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value?.toString() ?? '',
    );
  }

  // ============================================================
  // STATUS TEXT
  // ============================================================

  String get statusText {
    switch (status) {
      case InstaWalkRequestStatus.searching:
        return 'Searching';

      case InstaWalkRequestStatus.accepted:
        return 'Accepted';

      case InstaWalkRequestStatus.expired:
        return 'Expired';

      case InstaWalkRequestStatus.cancelled:
        return 'Cancelled';

      case InstaWalkRequestStatus.notFound:
        return 'Not Found';

      case InstaWalkRequestStatus.unknown:
        return 'Unknown';

      case InstaWalkRequestStatus.error:
        return 'Error';
    }
  }
}
