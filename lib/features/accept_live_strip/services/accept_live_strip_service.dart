import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/accept_live_strip_data.dart';

class AcceptLiveStripService {
  AcceptLiveStripService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore =
            firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const String walkRequestCollection =
      'walk_request';

  static const String liveSessionCollection =
      'liveWalkSessions';

  StreamSubscription<User?>? _authSubscription;

  StreamSubscription<
          QuerySnapshot<Map<String, dynamic>>>?
      _walkRequestSubscription;

  StreamSubscription<
          QuerySnapshot<Map<String, dynamic>>>?
      _liveSessionSubscription;

  final StreamController<AcceptLiveStripData>
      _controller =
      StreamController<AcceptLiveStripData>.broadcast();

  String? _requestId;
  String? _walkId;
  String _sessionStatus = '';

  bool _hasAcceptedRequest = false;
  bool _isLive = false;

  bool _started = false;

  QuerySnapshot<Map<String, dynamic>>?
      _latestLiveSnapshot;

  final Set<String> _completedRequestIds =
      <String>{};

  final Set<String> _completedWalkIds =
      <String>{};

  // =====================================================
  // WATCH
  // =====================================================

  Stream<AcceptLiveStripData> watch() {
    if (!_started) {
      _started = true;
      _startAuthListener();
    }

    return _controller.stream;
  }

  // =====================================================
  // AUTH
  // =====================================================

  void _startAuthListener() {
    _authSubscription =
        _auth.authStateChanges().listen(
      (user) {
        _stopFirestoreListeners();
        _resetForAuthChange();

        if (user == null) {
          return;
        }

        _startFirestoreListeners(user.uid);
      },
      onError: (_) {
        _emit();
      },
    );

    final User? currentUser =
        _auth.currentUser;

    if (currentUser != null) {
      _startFirestoreListeners(
        currentUser.uid,
      );
    }
  }

  // =====================================================
  // FIRESTORE LISTENERS
  // =====================================================

  void _startFirestoreListeners(
    String uid,
  ) {
    _listenWalkRequests(uid);
    _listenLiveSessions(uid);
  }

  void _listenWalkRequests(
    String uid,
  ) {
    _walkRequestSubscription?.cancel();

    _walkRequestSubscription =
        _firestore
            .collection(
              walkRequestCollection,
            )
            .where(
              'ownerAuthUid',
              isEqualTo: uid,
            )
            .snapshots()
            .listen(
      _processWalkRequests,
      onError: (_) {
        _emit();
      },
    );
  }

  void _listenLiveSessions(
    String uid,
  ) {
    _liveSessionSubscription?.cancel();

    _liveSessionSubscription =
        _firestore
            .collection(
              liveSessionCollection,
            )
            .where(
              'ownerAuthUid',
              isEqualTo: uid,
            )
            .snapshots()
            .listen(
      _processLiveSessions,
      onError: (_) {
        _emit();
      },
    );
  }

  // =====================================================
  // WALK REQUEST
  // =====================================================

  void _processWalkRequests(
    QuerySnapshot<Map<String, dynamic>>
        snapshot,
  ) {
    QueryDocumentSnapshot<
        Map<String, dynamic>>? selected;

    for (final doc in snapshot.docs) {
      final Map<String, dynamic> data =
          doc.data();

      final String requestId = doc.id;

      // Never resurrect a completed request.
      if (_completedRequestIds
          .contains(requestId)) {
        continue;
      }

      final String status =
          _readStatus(data['status']);

      if (!_isAcceptedStatus(status)) {
        continue;
      }

      if (selected == null ||
          _getLatestTime(data).isAfter(
            _getLatestTime(
              selected.data(),
            ),
          )) {
        selected = doc;
      }
    }

    // No accepted request.
    if (selected == null) {
      _requestId = null;
      _walkId = null;
      _sessionStatus = '';

      _hasAcceptedRequest = false;
      _isLive = false;

      _emit();
      return;
    }

    final String selectedRequestId =
        selected.id;

    // Extra completed-request protection.
    if (_completedRequestIds
        .contains(selectedRequestId)) {
      _hideStrip(
        status: 'completed',
      );
      return;
    }

    final Map<String, dynamic> requestData =
        selected.data();

    _requestId = selectedRequestId;

    _hasAcceptedRequest = true;

    // IMPORTANT:
    // Walk ID comes from Firestore field,
    // never from Firebase document ID.
    _walkId = _readString(
      requestData['walkId'],
    );

    // The request status is useful before a
    // live session exists.
    final String requestStatus =
        _readStatus(
      requestData['status'],
    );

    if (_latestLiveSnapshot != null) {
      _processLiveSessions(
        _latestLiveSnapshot!,
      );
      return;
    }

    _sessionStatus = requestStatus;

    _isLive = _isLiveStatus(
      requestStatus,
    );

    _emit();
  }

  // =====================================================
  // LIVE SESSION
  // =====================================================

  void _processLiveSessions(
    QuerySnapshot<Map<String, dynamic>>
        snapshot,
  ) {
    _latestLiveSnapshot = snapshot;

    // -----------------------------------------------------
    // COMPLETED SESSION CHECK
    // -----------------------------------------------------

    for (final doc in snapshot.docs) {
      final Map<String, dynamic> data =
          doc.data();

      if (!_isCompletedSession(data)) {
        continue;
      }

      final String? sessionWalkId =
          _readString(
        data['walkId'],
      );

      final String? sessionRequestId =
          _readSessionRequestId(
        data,
      );

      final bool matchesCurrentRequest =
          _matchesCurrentRequest(
        data,
        _requestId,
      );

      final bool matchesCurrentWalk =
          sessionWalkId != null &&
          _walkId != null &&
          sessionWalkId == _walkId;

      final bool alreadyCompleted =
          (sessionWalkId != null &&
              _completedWalkIds
                  .contains(sessionWalkId)) ||
          (sessionRequestId != null &&
              _completedRequestIds
                  .contains(sessionRequestId));

      if (matchesCurrentRequest ||
          matchesCurrentWalk ||
          alreadyCompleted) {
        _markCompleted(
          data: data,
          requestId:
              sessionRequestId ?? _requestId,
          walkId:
              sessionWalkId ?? _walkId,
        );

        return;
      }
    }

    // -----------------------------------------------------
    // CURRENT REQUEST
    // -----------------------------------------------------

    final String? currentRequestId =
        _requestId;

    if (currentRequestId == null ||
        currentRequestId.trim().isEmpty) {
      _sessionStatus = '';
      _walkId = null;
      _isLive = false;
      _hasAcceptedRequest = false;

      _emit();
      return;
    }

    // -----------------------------------------------------
    // FIND ACTIVE SESSION
    // -----------------------------------------------------

    QueryDocumentSnapshot<
        Map<String, dynamic>>? latestSession;

    for (final doc in snapshot.docs) {
      final Map<String, dynamic> data =
          doc.data();

      if (!_sessionMatchesRequest(
        data,
        currentRequestId,
      )) {
        continue;
      }

      if (_isCompletedSession(data)) {
        continue;
      }

      if (latestSession == null ||
          _getLatestTime(data).isAfter(
            _getLatestTime(
              latestSession.data(),
            ),
          )) {
        latestSession = doc;
      }
    }

    // No active session.
    if (latestSession == null) {
      // Keep the request status.
      // This is important for:
      // accepted → on_the_way → reached
      // before live session exists.
      if (_sessionStatus.isEmpty) {
        _sessionStatus = 'accepted';
      }

      _isLive = _isLiveStatus(
        _sessionStatus,
      );

      _emit();
      return;
    }

    final Map<String, dynamic> data =
        latestSession.data();

    final String status =
        _readStatus(
      data['status'],
    );

    final String? walkId =
        _readString(
      data['walkId'],
    );

    _sessionStatus = status;

    if (walkId != null &&
        walkId.isNotEmpty) {
      _walkId = walkId;
    }

    _isLive = _isLiveStatus(
      status,
    );

    _emit();
  }

  // =====================================================
  // MARK COMPLETED
  // =====================================================

  void _markCompleted({
    required Map<String, dynamic> data,
    String? requestId,
    String? walkId,
  }) {
    final String? resolvedRequestId =
        requestId ?? _requestId;

    final String? resolvedWalkId =
        walkId ?? _walkId;

    if (resolvedRequestId != null &&
        resolvedRequestId.trim().isNotEmpty) {
      _completedRequestIds.add(
        resolvedRequestId.trim(),
      );
    }

    if (resolvedWalkId != null &&
        resolvedWalkId.trim().isNotEmpty) {
      _completedWalkIds.add(
        resolvedWalkId.trim(),
      );
    }

    _requestId = null;
    _walkId = null;
    _sessionStatus = 'completed';

    _hasAcceptedRequest = false;
    _isLive = false;

    _emit();
  }

  // =====================================================
  // HIDE STRIP
  // =====================================================

  void _hideStrip({
    String status = '',
  }) {
    _requestId = null;
    _walkId = null;
    _sessionStatus = status;

    _hasAcceptedRequest = false;
    _isLive = false;

    _emit();
  }

  // =====================================================
  // SESSION MATCHING
  // =====================================================

  bool _sessionMatchesRequest(
    Map<String, dynamic> data,
    String requestId,
  ) {
    return _matchesCurrentRequest(
      data,
      requestId,
    );
  }

  bool _matchesCurrentRequest(
    Map<String, dynamic> data,
    String? requestId,
  ) {
    if (requestId == null ||
        requestId.trim().isEmpty) {
      return false;
    }

    final String? walkRequestId =
        _readString(
      data['walkRequestId'],
    );

    final String? requestIdField =
        _readString(
      data['requestId'],
    );

    final String? requestIDField =
        _readString(
      data['requestID'],
    );

    final String? walkId =
        _readString(
      data['walkId'],
    );

    return walkRequestId == requestId ||
        requestIdField == requestId ||
        requestIDField == requestId ||
        walkId == requestId;
  }

  String? _readSessionRequestId(
    Map<String, dynamic> data,
  ) {
    return _readString(
          data['walkRequestId'],
        ) ??
        _readString(
          data['requestId'],
        ) ??
        _readString(
          data['requestID'],
        );
  }

  // =====================================================
  // ACCEPTED / ACTIVE REQUEST STATUS
  // =====================================================

  bool _isAcceptedStatus(
    String status,
  ) {
    return status == 'accepted' ||
        status == 'on_the_way' ||
        status == 'reached' ||
        status == 'processing' ||
        status == 'active' ||
        status == 'walking' ||
        status == 'in_progress' ||
        status == 'in-progress' ||
        status == 'started' ||
        status == 'ongoing' ||
        status == 'live';
  }

  // =====================================================
  // LIVE STATUS
  // =====================================================

  bool _isLiveStatus(
    String status,
  ) {
    return status == 'active' ||
        status == 'walking' ||
        status == 'in_progress' ||
        status == 'in-progress' ||
        status == 'started' ||
        status == 'ongoing' ||
        status == 'live';
  }

  // =====================================================
  // COMPLETION DETECTION
  // =====================================================

  bool _isCompletedSession(
    Map<String, dynamic> data,
  ) {
    final String status =
        _readStatus(
      data['status'],
    );

    final dynamic completedAt =
        data['completedAt'];

    final dynamic endedAt =
        data['endedAt'];

    final bool trackingEnded =
        data['trackingEnded'] == true;

    final bool walkEnded =
        data['walkEnded'] == true;

    return status == 'completed' ||
        status == 'complete' ||
        status == 'finished' ||
        status == 'closed' ||
        status == 'cancelled' ||
        status == 'canceled' ||
        status == 'rejected' ||
        status == 'declined' ||
        status == 'expired' ||
        status == 'ended' ||
        completedAt != null ||
        endedAt != null ||
        trackingEnded ||
        walkEnded;
  }

  // =====================================================
  // EMIT
  // =====================================================

  void _emit() {
    if (_controller.isClosed) {
      return;
    }

    _controller.add(
      AcceptLiveStripData(
        requestId: _requestId,
        walkId: _walkId,
        sessionStatus: _sessionStatus,
        hasAcceptedRequest:
            _hasAcceptedRequest,
        isLive: _isLive,
      ),
    );
  }

  // =====================================================
  // RESET
  // =====================================================

  void _resetForAuthChange() {
    _requestId = null;
    _walkId = null;
    _sessionStatus = '';

    _hasAcceptedRequest = false;
    _isLive = false;

    _latestLiveSnapshot = null;

    _completedRequestIds.clear();
    _completedWalkIds.clear();

    _emit();
  }

  // =====================================================
  // STOP LISTENERS
  // =====================================================

  void _stopFirestoreListeners() {
    _walkRequestSubscription?.cancel();
    _liveSessionSubscription?.cancel();

    _walkRequestSubscription = null;
    _liveSessionSubscription = null;

    _latestLiveSnapshot = null;
  }

  // =====================================================
  // STRING HELPERS
  // =====================================================

  String? _readString(dynamic value) {
    if (value == null) {
      return null;
    }

    final String result =
        value.toString().trim();

    if (result.isEmpty) {
      return null;
    }

    return result;
  }

  String _readStatus(dynamic value) {
    if (value == null) {
      return '';
    }

    return value
        .toString()
        .trim()
        .toLowerCase();
  }

  // =====================================================
  // LATEST TIME
  // =====================================================

  DateTime _getLatestTime(
    Map<String, dynamic> data,
  ) {
    final DateTime? updatedAt =
        _timestampToDate(
      data['updatedAt'],
    );

    if (updatedAt != null) {
      return updatedAt;
    }

    final DateTime? acceptedAt =
        _timestampToDate(
      data['acceptedAt'],
    );

    if (acceptedAt != null) {
      return acceptedAt;
    }

    final DateTime? startedAt =
        _timestampToDate(
      data['startedAt'],
    );

    if (startedAt != null) {
      return startedAt;
    }

    final DateTime? createdAt =
        _timestampToDate(
      data['createdAt'],
    );

    if (createdAt != null) {
      return createdAt;
    }

    return DateTime
        .fromMillisecondsSinceEpoch(0);
  }

  // =====================================================
  // TIMESTAMP
  // =====================================================

  DateTime? _timestampToDate(
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

  // =====================================================
  // DISPOSE
  // =====================================================

  Future<void> dispose() async {
    await _authSubscription?.cancel();
    await _walkRequestSubscription?.cancel();
    await _liveSessionSubscription?.cancel();

    _authSubscription = null;
    _walkRequestSubscription = null;
    _liveSessionSubscription = null;

    await _controller.close();
  }
}
