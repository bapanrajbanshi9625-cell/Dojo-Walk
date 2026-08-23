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
  // SEARCH CONFIGURATION
  // ============================================================

  // Search radius remains 3 KM.
  //
  // IMPORTANT:
  // There is NO automatic search duration anymore.
  // Search continues until:
  //
  // 1. Owner cancels it
  // 2. Walker accepts it
  // 3. Request is explicitly cancelled
  //
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
  // SEARCH HAS NO TIME LIMIT.
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
      );
    }

    if (cleanAddress.isEmpty) {
      return const InstaWalkSearchResult.failure(
        message: 'Owner address is missing.',
      );
    }

    // ==========================================================
    // CHECK EXISTING ACTIVE REQUEST
    // ==========================================================

    if (hasActiveRequest) {
      final String activeId = _activeRequestId!;

      final InstaWalkRequestState state =
          await getRequestState(activeId);

      // --------------------------------------------------------
      // ALREADY SEARCHING
      //
      // Do NOT create another request.
      // --------------------------------------------------------

      if (state.isSearching) {
        return InstaWalkSearchResult.success(
          requestId: activeId,
          duration: null,
          expiresAt: null,
        );
      }

      // --------------------------------------------------------
      // ALREADY ACCEPTED
      // --------------------------------------------------------

      if (state.isAccepted) {
        return InstaWalkSearchResult.success(
          requestId: activeId,
          duration: null,
          expiresAt: null,
        );
      }

      await clearActiveRequest();
    }

    try {
      await _requestSubscription?.cancel();
      _requestSubscription = null;

      // ========================================================
      // CREATE NEW REQUEST
      // ========================================================

      final DocumentReference<Map<String, dynamic>> ref =
          _firestore
              .collection(walkRequestsCollection)
              .doc();

      // IMPORTANT:
      // No expiresAt.
      // No search duration.
      // No 2/3/5 minute system.
      // No search number.
      await ref.set({
        'requestId': ref.id,

        'status': 'searching',

        'searchType': 'insta_walk',
        'senderRole': 'owner',

        'senderUid': user.uid,
        'ownerAuthUid': user.uid,

        'businessId': businessId,

        // Compatibility with existing code.
        'ownerId': businessId,

        'ownerName': cleanOwnerName,

        'address': cleanAddress,

        'searchRadiusKm': searchRadiusKm,

        'ownerLocation': ownerLocation,

        'ownerLocationType': 'search_snapshot',

        // Walker information starts empty.
        'walkerUid': null,
        'walkerId': null,
        'walkerName': null,

        'acceptedBy': null,
        'acceptedAt': null,

        'createdAt': FieldValue.serverTimestamp(),
      });

      _activeRequestId = ref.id;

      return InstaWalkSearchResult.success(
        requestId: ref.id,
        duration: null,
        expiresAt: null,
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
        message: 'Unable to start Insta Walk search.',
      );
    }
  }

  // ============================================================
  // FIND OWNER PROFILE
  // ============================================================

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?>
      findOwnerProfile() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
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
  // Searching request remains active indefinitely.
  //
  // There is NO expiry check here.
  // ============================================================

  Future<InstaWalkRequestState?> findActiveRequest({
    required String ownerId,
  }) async {
    final User? user = _auth.currentUser;
    final String businessId = ownerId.trim();

    if (user == null || businessId.isEmpty) {
      return null;
    }

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _firestore
              .collection(walkRequestsCollection)
              .where(
                'businessId',
                isEqualTo: businessId,
              )
              .where(
                'searchType',
                isEqualTo: 'insta_walk',
              )
              .orderBy(
                'createdAt',
                descending: true,
              )
              .limit(10)
              .get();

      if (snapshot.docs.isEmpty) {
        _activeRequestId = null;
        return null;
      }

      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in snapshot.docs) {
        final Map<String, dynamic> data = doc.data();

        final String status = _statusFromData(data);

        // ------------------------------------------------------
        // SEARCHING
        //
        // No expiry.
        // ------------------------------------------------------

        if (status == 'searching') {
          _activeRequestId = doc.id;

          return InstaWalkRequestState(
            status: InstaWalkRequestStatus.searching,
            data: data,
          );
        }

        // ------------------------------------------------------
        // ACCEPTED
        // ------------------------------------------------------

        if (status == 'accepted') {
          _activeRequestId = doc.id;

          return InstaWalkRequestState(
            status: InstaWalkRequestStatus.accepted,
            data: data,
          );
        }
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
    final String id = requestId.trim();

    if (id.isEmpty) {
      return;
    }

    await _requestSubscription?.cancel();

    _activeRequestId = id;

    bool acceptedSent = false;
    bool expiredSent = false;
    bool cancelledSent = false;

    final DocumentReference<Map<String, dynamic>> ref =
        _firestore
            .collection(walkRequestsCollection)
            .doc(id);

    _requestSubscription = ref.snapshots().listen(
      (
        DocumentSnapshot<Map<String, dynamic>> snapshot,
      ) {
        if (!snapshot.exists) {
          return;
        }

        final Map<String, dynamic>? data =
            snapshot.data();

        if (data == null) {
          return;
        }

        final String status = _statusFromData(data);

        // ------------------------------------------------------
        // ACCEPTED
        // ------------------------------------------------------

        if (status == 'accepted') {
          if (acceptedSent) {
            return;
          }

          acceptedSent = true;

          onAccepted(
            InstaWalkAcceptedData.fromMap(data),
          );

          return;
        }

        // ------------------------------------------------------
        // EXPIRED
        //
        // Kept only for compatibility with old Firestore
        // requests. New requests will NEVER expire automatically.
        // ------------------------------------------------------

        if (status == 'expired') {
          if (expiredSent) {
            return;
          }

          expiredSent = true;

          onExpired?.call();

          return;
        }

        // ------------------------------------------------------
        // CANCELLED
        // ------------------------------------------------------

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

        // ------------------------------------------------------
        // SEARCHING
        //
        // Do nothing.
        // It remains active indefinitely.
        // ------------------------------------------------------
      },
      onError: (Object error) {
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
    final String id = requestId.trim();

    if (id.isEmpty) {
      return const InstaWalkRequestState(
        status: InstaWalkRequestStatus.notFound,
      );
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await _firestore
              .collection(walkRequestsCollection)
              .doc(id)
              .get();

      if (!snapshot.exists ||
          snapshot.data() == null) {
        if (_activeRequestId == id) {
          _activeRequestId = null;
        }

        return const InstaWalkRequestState(
          status: InstaWalkRequestStatus.notFound,
        );
      }

      final Map<String, dynamic> data =
          snapshot.data()!;

      final String status =
          _statusFromData(data);

      // ========================================================
      // SEARCHING
      //
      // IMPORTANT:
      // No expiresAt check.
      // No automatic expiration.
      // ========================================================

      if (status == 'searching') {
        _activeRequestId = id;

        return InstaWalkRequestState(
          status: InstaWalkRequestStatus.searching,
          data: data,
        );
      }

      // ========================================================
      // ACCEPTED
      // ========================================================

      if (status == 'accepted') {
        _activeRequestId = id;

        return InstaWalkRequestState(
          status: InstaWalkRequestStatus.accepted,
          data: data,
        );
      }

      // ========================================================
      // EXPIRED
      //
      // Only supports old/manual expired documents.
      // New searches do not create this state automatically.
      // ========================================================

      if (status == 'expired') {
        if (_activeRequestId == id) {
          _activeRequestId = null;
        }

        return InstaWalkRequestState(
          status: InstaWalkRequestStatus.expired,
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
          status: InstaWalkRequestStatus.cancelled,
          data: data,
        );
      }

      return InstaWalkRequestState(
        status: InstaWalkRequestStatus.unknown,
        data: data,
      );
    } on FirebaseException catch (e) {
      return InstaWalkRequestState(
        status: InstaWalkRequestStatus.error,
        errorMessage: _firebaseErrorMessage(e),
      );
    } catch (_) {
      return const InstaWalkRequestState(
        status: InstaWalkRequestStatus.error,
        errorMessage: 'Unable to check walk request.',
      );
    }
  }

  // ============================================================
  // CANCEL SEARCH
  //
  // THIS IS NOW THE MAIN WAY OWNER STOPS SEARCH.
  // ============================================================

  Future<bool> cancelSearch({
    String? requestId,
  }) async {
    final String? id =
        requestId ?? _activeRequestId;

    if (id == null || id.trim().isEmpty) {
      return false;
    }

    try {
      final DocumentReference<Map<String, dynamic>> ref =
          _firestore
              .collection(walkRequestsCollection)
              .doc(id.trim());

      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await ref.get();

      if (!snapshot.exists) {
        await clearActiveRequest();
        return false;
      }

      final String status =
          _statusFromData(
        snapshot.data() ?? <String, dynamic>{},
      );

      // --------------------------------------------------------
      // ACCEPTED CANNOT BE CANCELLED AS SEARCH
      // --------------------------------------------------------

      if (status == 'accepted') {
        return false;
      }

      // --------------------------------------------------------
      // ONLY SEARCHING REQUEST CAN BE CANCELLED
      // --------------------------------------------------------

      if (status != 'searching') {
        await clearActiveRequest();
        return false;
      }

      // --------------------------------------------------------
      // OWNER CANCEL
      // --------------------------------------------------------

      await ref.update({
        'status': 'owner_cancelled',
        'cancelledAt':
            FieldValue.serverTimestamp(),
        'cancelledBy': 'owner',
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
  // IMPORTANT:
  // Automatic expiry has been removed.
  //
  // This method is kept only for compatibility with any old UI
  // or service caller.
  //
  // It will NOT expire an active request.
  // ============================================================

  Future<bool> expireRequest({
    String? requestId,
  }) async {
    // No automatic expiration anymore.
    //
    // Search should continue until owner cancels
    // or walker accepts.
    return false;
  }

  // ============================================================
  // REMAINING TIME
  //
  // There is no countdown anymore.
  //
  // Kept for compatibility so existing callers don't break.
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
    await _requestSubscription?.cancel();

    _requestSubscription = null;
    _activeRequestId = null;
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

      default:
        return 'Unable to process Insta Walk request.';
    }
  }

  // ============================================================
  // LOGGING
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

  // No expiry anymore.
  final DateTime? expiresAt;

  // No duration anymore.
  final Duration? duration;

  // Kept nullable for compatibility with old UI/code.
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
      acceptedAt = acceptedValue.toDate();
    } else if (acceptedValue is DateTime) {
      acceptedAt = acceptedValue;
    }

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

    final String businessId =
        data['businessId']
                    ?.toString()
                    .trim()
                    .isNotEmpty ==
                true
            ? data['businessId']
                .toString()
                .trim()
            : data['ownerId']
                    ?.toString()
                    .trim() ??
                '';

    // ==========================================================
    // RETURN
    // ==========================================================

    return InstaWalkAcceptedData(
      requestId:
          data['requestId']
                  ?.toString()
                  .trim() ??
              '',

      businessId: businessId,

      ownerId: businessId,

      ownerAuthUid:
          data['ownerAuthUid']
                  ?.toString()
                  .trim() ??
              '',

      ownerName:
          data['ownerName']
                      ?.toString()
                      .trim()
                      .isNotEmpty ==
                  true
              ? data['ownerName']
                  .toString()
                  .trim()
              : 'Dog Owner',

      walkerUid: walkerUid,

      walkerId:
          data['walkerId']
                  ?.toString()
                  .trim() ??
              '',

      walkerName:
          data['walkerName']
                      ?.toString()
                      .trim()
                      .isNotEmpty ==
                  true
              ? data['walkerName']
                  .toString()
                  .trim()
              : 'Walker',

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
      status == InstaWalkRequestStatus.searching;

  bool get isAccepted =>
      status == InstaWalkRequestStatus.accepted;

  bool get isExpired =>
      status == InstaWalkRequestStatus.expired;

  bool get isCancelled =>
      status == InstaWalkRequestStatus.cancelled;

  // ============================================================
  // REQUEST ID
  // ============================================================

  String? get requestId {
    final String value =
        data?['requestId']
                ?.toString()
                .trim() ??
            '';

    return value.isEmpty ? null : value;
  }

  // ============================================================
  // BUSINESS ID
  // ============================================================

  String? get businessId {
    final String value =
        data?['businessId']
                ?.toString()
                .trim() ??
            data?['ownerId']
                    ?.toString()
                    .trim() ??
                '';

    return value.isEmpty ? null : value;
  }

  String? get ownerId => businessId;

  // ============================================================
  // OWNER AUTH UID
  // ============================================================

  String? get ownerAuthUid {
    final String value =
        data?['ownerAuthUid']
                ?.toString()
                .trim() ??
            '';

    return value.isEmpty ? null : value;
  }

  // ============================================================
  // EXPIRY
  //
  // New requests have no expiry.
  //
  // Getter kept for compatibility with old code.
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
  // New system does not assign search numbers.
  //
  // Getter kept for compatibility with old documents.
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
