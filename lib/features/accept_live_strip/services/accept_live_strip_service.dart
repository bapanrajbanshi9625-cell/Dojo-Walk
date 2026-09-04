import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/accept_live_strip_data.dart';

class AcceptLiveStripService {
  AcceptLiveStripService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const String walkRequestCollection = 'walk_request';
  static const String liveSessionCollection = 'liveWalkSessions';

  StreamSubscription<User?>? _authSubscription;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _walkRequestSubscription;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _liveSessionSubscription;

  final StreamController<AcceptLiveStripData> _controller =
      StreamController<AcceptLiveStripData>.broadcast();

  String? _requestId;
  String? _walkId;
  String _sessionStatus = '';

  bool _hasAcceptedRequest = false;
  bool _isLive = false;

  bool _started = false;

  QuerySnapshot<Map<String, dynamic>>? _latestLiveSnapshot;

  // Completed request IDs are kept so that an accepted
  // walk_request cannot make the strip reappear after
  // the live session has completed.
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
      onError: (error) {
        _emit();
      },
    );

    final currentUser = _auth.currentUser;

    if (currentUser != null) {
      _startFirestoreListeners(currentUser.uid);
    }
  }

  // =====================================================
  // FIRESTORE LISTENERS
  // =====================================================

  void _startFirestoreListeners(String uid) {
    _listenWalkRequests(uid);
    _listenLiveSessions(uid);
  }

  void _listenWalkRequests(String uid) {
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
      onError: (error) {
        _emit();
      },
    );
  }

  void _listenLiveSessions(String uid) {
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
      onError: (error) {
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
      final data = doc.data();

      final requestId = doc.id;

      // A completed request must NEVER become visible again.
      if (_completedRequestIds.contains(requestId)) {
        continue;
      }

      final status = _readStatus(
        data['status'],
      );

      if (!_isAcceptedStatus(status)) {
        continue;
      }

      if (selected == null ||
          _getLatestTime(data).isAfter(
            _getLatestTime(selected.data()),
          )) {
        selected = doc;
      }
    }

    // No accepted request remains.
    if (selected == null) {
      _requestId = null;
      _walkId = null;
      _sessionStatus = '';

      _hasAcceptedRequest = false;
      _isLive = false;

      _emit();
      return;
    }

    final selectedRequestId = selected.id;

    // Safety check.
    if (_completedRequestIds.contains(selectedRequestId)) {
      _requestId = null;
      _walkId = null;
      _sessionStatus = 'completed';

      _hasAcceptedRequest = false;
      _isLive = false;

      _emit();
      return;
    }

    _requestId = selectedRequestId;
    _hasAcceptedRequest = true;

    // Immediately re-check the latest live-session snapshot.
    //
    // This handles the case where liveWalkSessions updated
    // before walk_request was processed.
    final liveSnapshot = _latestLiveSnapshot;

    if (liveSnapshot != null) {
      _processLiveSessions(liveSnapshot);
      return;
    }

    _emit();
  }

  // =====================================================
  // LIVE SESSION
  // =====================================================

  void _processLiveSessions(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    _latestLiveSnapshot = snapshot;

    final currentRequestId = _requestId;

    if (currentRequestId == null ||
        currentRequestId.trim().isEmpty) {
      _sessionStatus = '';
      _walkId = null;
      _isLive = false;

      _emit();
      return;
    }

    // ===================================================
    // FIRST: CHECK COMPLETED SESSION
    // ===================================================
    //
    // IMPORTANT:
    // We check ALL matching sessions for completion BEFORE
    // selecting the latest active session.
    //
    // This prevents an older completed session from being
    // ignored when another session document is newer.
    //

    for (final doc in snapshot.docs) {
      final data = doc.data();

      if (!_sessionMatchesRequest(
        data,
        currentRequestId,
      )) {
        continue;
      }

      if (_isCompletedSession(data)) {
        _markRequestCompleted(
          requestId: currentRequestId,
          data: data,
        );

        return;
      }
    }

    // ===================================================
    // SECOND: FIND LATEST ACTIVE SESSION
    // ===================================================

    QueryDocumentSnapshot<Map<String, dynamic>>? latestSession;

    for (final doc in snapshot.docs) {
      final data = doc.data();

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
            _getLatestTime(latestSession.data()),
          )) {
        latestSession = doc;
      }
    }

    // No live session found.
    if (latestSession == null) {
      _sessionStatus = '';
      _walkId = null;
      _isLive = false;

      _emit();
      return;
    }

    final data = latestSession.data();

    final status = _readStatus(
      data['status'],
    );

    final walkId = _readString(
      data['walkId'],
    );

    _sessionStatus = status;
    _walkId = walkId;
    _isLive = _isLiveStatus(status);

    _emit();
  }

  // =====================================================
  // MARK COMPLETED
  // =====================================================

  void _markRequestCompleted({
    required String requestId,
    required Map<String, dynamic> data,
  }) {
    _completedRequestIds.add(requestId);

    final walkId = _readString(
      data['walkId'],
    );

    _requestId = null;
    _walkId = walkId;
    _sessionStatus = 'completed';

    _hasAcceptedRequest = false;
    _isLive = false;

    // This is the important realtime UI update.
    _emit();
  }

  // =====================================================
  // SESSION MATCHING
  // =====================================================

  bool _sessionMatchesRequest(
    Map<String, dynamic> data,
    String requestId,
  ) {
    final walkRequestId = _readString(
      data['walkRequestId'],
    );

    final requestIdField = _readString(
      data['requestId'],
    );

    final requestIDField = _readString(
      data['requestID'],
    );

    final walkId = _readString(
      data['walkId'],
    );

    return walkRequestId == requestId ||
        requestIdField == requestId ||
        requestIDField == requestId ||
        walkId == requestId;
  }

  // =====================================================
  // ACCEPTED STATUS
  // =====================================================

  bool _isAcceptedStatus(
    String status,
  ) {
    return status == 'accepted' ||
        status == 'active' ||
        status == 'on_the_way' ||
        status == 'reached' ||
        status == 'walking' ||
        status == 'in_progress' ||
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
    final status = _readStatus(
      data['status'],
    );

    final completedAt = data['completedAt'];

    final trackingEnded =
        data['trackingEnded'] == true;

    final walkEnded =
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
        completedAt != null ||
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
        hasAcceptedRequest: _hasAcceptedRequest,
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

  String? _readString(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    final result = value.toString().trim();

    if (result.isEmpty) {
      return null;
    }

    return result;
  }

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
    final updatedAt = _timestampToDate(
      data['updatedAt'],
    );

    if (updatedAt != null) {
      return updatedAt;
    }

    final acceptedAt = _timestampToDate(
      data['acceptedAt'],
    );

    if (acceptedAt != null) {
      return acceptedAt;
    }

    final startedAt = _timestampToDate(
      data['startedAt'],
    );

    if (startedAt != null) {
      return startedAt;
    }

    final createdAt = _timestampToDate(
      data['createdAt'],
    );

    if (createdAt != null) {
      return createdAt;
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
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
