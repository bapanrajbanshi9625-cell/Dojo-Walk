import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ============================================================
// INSTA WALK SEARCH SERVICE
//
// FIRESTORE IS THE SOURCE OF TRUTH.
//
// Search does NOT automatically expire.
//
// Search remains active until:
//
// 1. Owner stops it
// 2. Walker accepts it
// 3. Request is explicitly cancelled
//
// App close / background / screen change does NOT cancel it.
// ============================================================

class InstaWalkSearchService {
  InstaWalkSearchService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore =
            firestore ?? FirebaseFirestore.instance,
        _auth =
            auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // ============================================================
  // COLLECTIONS
  // ============================================================

  static const String walkRequestsCollection =
      'walk_requests';

  static const String ownerProfilesCollection =
      'ownerProfiles';

  // ============================================================
  // SEARCH CONFIGURATION
  // ============================================================

  static const double searchRadiusKm = 3.0;

  // ============================================================
  // INTERNAL STATE
  // ============================================================

  StreamSubscription<
      DocumentSnapshot<Map<String, dynamic>>>?
      _requestSubscription;

  String? _activeRequestId;

  // ============================================================
  // GETTERS
  // ============================================================

  String? get activeRequestId =>
      _activeRequestId;

  bool get hasActiveRequest =>
      _activeRequestId != null &&
      _activeRequestId!.trim().isNotEmpty;

  User? get currentUser =>
      _auth.currentUser;

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
  // No expiry.
  // No expiresAt.
  // No automatic timeout.
  // ============================================================

  Future<InstaWalkSearchResult> startSearch({
    required String ownerId,
    required String ownerName,
    required String address,
    required GeoPoint ownerLocation,
  }) async {
    final User? user =
        _auth.currentUser;

    if (user == null) {
      return const InstaWalkSearchResult.failure(
        message: 'Please login first.',
      );
    }

    final String businessId =
        ownerId.trim();

    final String cleanOwnerName =
        ownerName.trim().isEmpty
            ? 'Dog Owner'
            : ownerName.trim();

    final String cleanAddress =
        address.trim();

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
    // CHECK LOCAL ACTIVE REQUEST
    // ==========================================================

    if (hasActiveRequest) {
      final String activeId =
          _activeRequestId!;

      final InstaWalkRequestState state =
          await getRequestState(activeId);

      if (state.isSearching) {
        // Make sure listener is alive.
        await listenForRequest(
          requestId: activeId,
        );

        return InstaWalkSearchResult.success(
          requestId: activeId,
        );
      }

      if (state.isAccepted) {
        await listenForRequest(
          requestId: activeId,
        );

        return InstaWalkSearchResult.success(
          requestId: activeId,
        );
      }

      await clearActiveRequest();
    }

    try {
      await _requestSubscription?.cancel();

      _requestSubscription = null;

      // ========================================================
      // CREATE FIRESTORE REQUEST
      // ========================================================

      final DocumentReference<
          Map<String, dynamic>> ref =
          _firestore
              .collection(
                walkRequestsCollection,
              )
              .doc();

      await ref.set({
        'requestId': ref.id,

        // ======================================================
        // SOURCE OF TRUTH
        // ======================================================

        'status': 'searching',

        'searchType': 'insta_walk',
        'senderRole': 'owner',

        // ======================================================
        // OWNER
        // ======================================================

        'senderUid': user.uid,
        'ownerAuthUid': user.uid,

        'businessId': businessId,

        // Compatibility
        'ownerId': businessId,

        'ownerName': cleanOwnerName,

        'address': cleanAddress,

        // ======================================================
        // LOCATION
        // ======================================================

        'searchRadiusKm': searchRadiusKm,

        'ownerLocation': ownerLocation,

        'ownerLocationType':
            'search_snapshot',

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

        'createdAt':
            FieldValue.serverTimestamp(),
      });

      _activeRequestId = ref.id;

      // ========================================================
      // IMPORTANT:
      // Start Firestore listener immediately.
      // ========================================================

      await listenForRequest(
        requestId: ref.id,
      );

      return InstaWalkSearchResult.success(
        requestId: ref.id,
      );
    } on FirebaseException catch (e) {
      _logFirebaseError(
        'startSearch',
        e,
      );

      return InstaWalkSearchResult.failure(
        message:
            _firebaseErrorMessage(e),
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
    final User? user =
        _auth.currentUser;

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
  // We search Firestore directly.
  //
  // searching = ACTIVE
  // accepted  = ACTIVE FOR RECOVERY
  //
  // There is NO expiry check.
  // ============================================================

  Future<InstaWalkRequestState?> findActiveRequest({
    required String ownerId,
  }) async {
    final User? user =
        _auth.currentUser;

    final String businessId =
        ownerId.trim();

    if (user == null ||
        businessId.isEmpty) {
      return null;
    }

    try {
      // ========================================================
      // IMPORTANT:
      //
      // We avoid orderBy(createdAt) here.
      // This reduces the chance of requiring an extra composite
      // Firestore index.
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
              .limit(50)
              .get();

      if (snapshot.docs.isEmpty) {
        _activeRequestId = null;
        return null;
      }

      QueryDocumentSnapshot<
          Map<String, dynamic>>? searchingDoc;

      QueryDocumentSnapshot<
          Map<String, dynamic>>? acceptedDoc;

      DateTime latestSearching =
          DateTime.fromMillisecondsSinceEpoch(0);

      DateTime latestAccepted =
          DateTime.fromMillisecondsSinceEpoch(0);

      // ========================================================
      // FIND LATEST ACTIVE REQUEST LOCALLY
      // ========================================================

      for (final QueryDocumentSnapshot<
          Map<String, dynamic>> doc
          in snapshot.docs) {
        final Map<String, dynamic> data =
            doc.data();

        final String status =
            _statusFromData(data);

        final DateTime createdAt =
            _readTimestamp(
                  data['createdAt'],
                ) ??
                DateTime.fromMillisecondsSinceEpoch(
                  0,
                );

        if (status == 'searching') {
          if (createdAt.isAfter(
            latestSearching,
          )) {
            latestSearching = createdAt;
            searchingDoc = doc;
          }
        }

        if (status == 'accepted') {
          if (createdAt.isAfter(
            latestAccepted,
          )) {
            latestAccepted = createdAt;
            acceptedDoc = doc;
          }
        }
      }

      // ========================================================
      // SEARCHING HAS PRIORITY
      // ========================================================

      if (searchingDoc != null) {
        _activeRequestId =
            searchingDoc.id;

        return InstaWalkRequestState(
          status:
              InstaWalkRequestStatus.searching,
          data: searchingDoc.data(),
        );
      }

      // ========================================================
      // ACCEPTED
      // ========================================================

      if (acceptedDoc != null) {
        _activeRequestId =
            acceptedDoc.id;

        return InstaWalkRequestState(
          status:
              InstaWalkRequestStatus.accepted,
          data: acceptedDoc.data(),
        );
      }

      // ========================================================
      // NOTHING ACTIVE
      // ========================================================

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
  // Firestore realtime listener.
  //
  // The UI/service can react to:
  //
  // searching
  // accepted
  // cancelled
  // expired
  // ============================================================

  Future<void> listenForRequest({
    required String requestId,

    // Optional because existing part files may only need
    // accepted/cancelled callbacks.
    void Function(
      InstaWalkAcceptedData data,
    )? onAccepted,

    void Function()? onSearching,

    void Function(
      Map<String, dynamic> data,
    )? onUpdated,

    void Function()? onExpired,

    void Function()? onCancelled,

    void Function(Object error)? onError,
  }) async {
    final String id =
        requestId.trim();

    if (id.isEmpty) {
      return;
    }

    // ==========================================================
    // CANCEL OLD LISTENER
    // ==========================================================

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

    // ==========================================================
    // REALTIME LISTENER
    // ==========================================================

    _requestSubscription =
        ref.snapshots().listen(
      (
        DocumentSnapshot<
            Map<String, dynamic>> snapshot,
      ) {
        // ======================================================
        // DOCUMENT DOES NOT EXIST
        // ======================================================

        if (!snapshot.exists) {
          return;
        }

        final Map<String, dynamic>? data =
            snapshot.data();

        if (data == null) {
          return;
        }

        // ======================================================
        // ALWAYS SEND LATEST DATA
        // ======================================================

        onUpdated?.call(
          Map<String, dynamic>.from(
            data,
          ),
        );

        final String status =
            _statusFromData(data);

        // ======================================================
        // SEARCHING
        //
        // IMPORTANT:
        // Nothing expires here.
        // ======================================================

        if (status == 'searching') {
          onSearching?.call();
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

          if (onAccepted != null) {
            onAccepted(
              InstaWalkAcceptedData.fromMap(
                data,
              ),
            );
          }

          return;
        }

        // ======================================================
        // EXPIRED
        //
        // Only old/manual documents.
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

        // ======================================================
        // OTHER STATUS
        // ======================================================
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
          snapshot.data()!;

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
      return InstaWalkRequestState(
        status:
            InstaWalkRequestStatus.error,
        errorMessage:
            _firebaseErrorMessage(e),
      );
    } catch (_) {
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
  // THIS IS THE ONLY OWNER STOP ACTION.
  // ============================================================

  Future<bool> cancelSearch({
    String? requestId,
  }) async {
    final String? id =
        requestId ?? _activeRequestId;

    if (id == null ||
        id.trim().isEmpty) {
      return false;
    }

    try {
      final DocumentReference<
          Map<String, dynamic>> ref =
          _firestore
              .collection(
                walkRequestsCollection,
              )
              .doc(id.trim());

      final DocumentSnapshot<
          Map<String, dynamic>> snapshot =
          await ref.get();

      if (!snapshot.exists) {
        await clearActiveRequest();
        return false;
      }

      final String status =
          _statusFromData(
        snapshot.data() ??
            <String, dynamic>{},
      );

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
      // OWNER CANCEL
      // ========================================================

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
  // AUTOMATIC EXPIRATION IS REMOVED.
  // ============================================================

  Future<bool> expireRequest({
    String? requestId,
  }) async {
    return false;
  }

  // ============================================================
  // REMAINING TIME
  //
  // No countdown.
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
  // TIMESTAMP
  // ============================================================

  DateTime? _readTimestamp(
    dynamic value,
  ) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
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

  // Compatibility only.
  final DateTime? expiresAt;

  // Compatibility only.
  final Duration? duration;

  // Compatibility only.
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

    final String rawBusinessId =
        data['businessId']
                ?.toString()
                .trim() ??
            '';

    final String rawOwnerId =
        data['ownerId']
                ?.toString()
                .trim() ??
            '';

    final String businessId =
        rawBusinessId.isNotEmpty
            ? rawBusinessId
            : rawOwnerId;

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
          Map<String, dynamic>.from(
        data,
      ),
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

  // ============================================================
  // SEARCHING
  // ============================================================

  bool get isSearching =>
      status ==
      InstaWalkRequestStatus.searching;

  // ============================================================
  // ACCEPTED
  // ============================================================

  bool get isAccepted =>
      status ==
      InstaWalkRequestStatus.accepted;

  // ============================================================
  // EXPIRED
  // ============================================================

  bool get isExpired =>
      status ==
      InstaWalkRequestStatus.expired;

  // ============================================================
  // CANCELLED
  // ============================================================

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
    final String fromBusiness =
        data?['businessId']
                ?.toString()
                .trim() ??
            '';

    if (fromBusiness.isNotEmpty) {
      return fromBusiness;
    }

    final String fromOwner =
        data?['ownerId']
                ?.toString()
                .trim() ??
            '';

    return fromOwner.isEmpty
        ? null
        : fromOwner;
  }

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
  // New requests do not have expiresAt.
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
  // Compatibility only.
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
