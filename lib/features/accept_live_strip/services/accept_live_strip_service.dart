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

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _walkRequestSubscription;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _liveSessionSubscription;

  final StreamController<AcceptLiveStripData> _controller =
      StreamController<AcceptLiveStripData>.broadcast();

  // =====================================================
  // FINAL SINGLE ID
  // =====================================================

  String? _requestId;

  String _sessionStatus = '';

  bool _hasAcceptedRequest = false;
  bool _isLive = false;

  bool _started = false;

  QuerySnapshot<Map<String, dynamic>>? _latestLiveSnapshot;

  final Set<String> _completedRequestIds = <String>{};

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
    _authSubscription = _auth.authStateChanges().listen(
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

    final User? currentUser = _auth.currentUser;

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

    _walkRequestSubscription = _firestore
        .collection(walkRequestCollection)
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

    _liveSessionSubscription = _firestore
        .collection(liveSessionCollection)
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
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    QueryDocumentSnapshot<Map<String, dynamic>>? selected;

    for (final doc in snapshot.docs) {
      final Map<String, dynamic> data = doc.data();

      // FINAL ARCHITECTURE:
      // Firestore document ID itself is DW000001.
      final String requestId = doc.id.trim();

      if (!_isValidRequestId(requestId)) {
        continue;
      }

      // Never resurrect a completed request.
      if (_completedRequestIds.contains(requestId)) {
        continue;
      }

      final String status = _readStatus(
        data['status'],
      );

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
      _sessionStatus = '';

      _hasAcceptedRequest = false;
      _isLive = false;

      _emit();
      return;
    }

    final String selectedRequestId =
        selected.id.trim();

    // Extra completed-request protection.
    if (_completedRequestIds.contains(
      selectedRequestId,
    )) {
      _hideStrip(
        status: 'completed',
      );
      return;
    }

    final Map<String, dynamic> requestData =
        selected.data();

    // FINAL SINGLE ID.
    _requestId = selectedRequestId;

    _hasAcceptedRequest = true;

    final String requestStatus = _readStatus(
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
    QuerySnapshot<Map<String, dynamic>> snapshot,
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

      // FINAL ARCHITECTURE:
      // liveWalkSessions document ID == request ID.
      final String sessionRequestId =
          doc.id.trim();

      if (!_isValidRequestId(sessionRequestId)) {
        continue;
      }

      final bool matchesCurrentRequest =
          _requestId != null &&
          sessionRequestId == _requestId;

      final bool alreadyCompleted =
          _completedRequestIds.contains(
        sessionRequestId,
      );

      if (matchesCurrentRequest ||
          alreadyCompleted) {
        _markCompleted(
          requestId: sessionRequestId,
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
      _isLive = false;
      _hasAcceptedRequest = false;

      _emit();
      return;
    }

    final String cleanRequestId =
        currentRequestId.trim();

    // -----------------------------------------------------
    // FIND ACTIVE SESSION
    // -----------------------------------------------------

    QueryDocumentSnapshot<Map<String, dynamic>>?
        latestSession;

    for (final doc in snapshot.docs) {
      final String sessionRequestId =
          doc.id.trim();

      // FINAL ARCHITECTURE:
      // Session document ID must exactly match
      // current walk request ID.
      if (sessionRequestId != cleanRequestId) {
        continue;
      }

      final Map<String, dynamic> data =
          doc.data();

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
      // Keep request status.
      //
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

    final String status = _readStatus(
      data['status'],
    );

    _sessionStatus = status;

    _isLive = _isLiveStatus(
      status,
    );

    _emit();
  }

  // =====================================================
  // MARK COMPLETED
  // =====================================================

  void _markCompleted({
    String? requestId,
  }) {
    final String? resolvedRequestId =
        requestId ?? _requestId;

    if (resolvedRequestId != null &&
        resolvedRequestId.trim().isNotEmpty) {
      _completedRequestIds.add(
        resolvedRequestId.trim(),
      );
    }

    _requestId = null;
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
    _sessionStatus = status;

    _hasAcceptedRequest = false;
    _isLive = false;

    _emit();
  }

  // =====================================================
  // REQUEST ID VALIDATION
  // =====================================================

  bool _isValidRequestId(
    String requestId,
  ) {
    return RegExp(
      r'^DW\d{6}$',
    ).hasMatch(
      requestId.trim(),
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
    final String status = _readStatus(
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
    _sessionStatus = '';

    _hasAcceptedRequest = false;
    _isLive = false;

    _latestLiveSnapshot = null;

    _completedRequestIds.clear();

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
  // STATUS
  // =====================================================

  String _readStatus(
    dynamic value,
  ) {
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

    return DateTime.fromMillisecondsSinceEpoch(
      0,
    );
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
