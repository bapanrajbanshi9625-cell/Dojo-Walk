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

  // Keeps the latest live-session snapshot independently.
  QuerySnapshot<Map<String, dynamic>>? _latestLiveSnapshot;

  // Prevents a completed request from being shown again.
  String? _completedRequestId;

  // ==========================================================
  // PUBLIC STREAM
  // ==========================================================

  Stream<AcceptLiveStripData> watch() {
    if (!_started) {
      _started = true;
      _startAuthListener();
    }

    return _controller.stream;
  }

  // ==========================================================
  // AUTH
  // ==========================================================

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

  // ==========================================================
  // FIRESTORE LISTENERS
  // ==========================================================

  void _startFirestoreListeners(String uid) {
    _listenWalkRequests(uid);
    _listenLiveSessions(uid);
  }

  // ==========================================================
  // WALK REQUEST LISTENER
  // ==========================================================

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

  // ==========================================================
  // PROCESS WALK REQUESTS
  // ==========================================================

  void _processWalkRequests(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    QueryDocumentSnapshot<Map<String, dynamic>>? selected;

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final status = _readStatus(
        data['status'],
      );

      // --------------------------------------------------------
      // Do not resurrect the request that already completed.
      // --------------------------------------------------------

      if (_completedRequestId == doc.id) {
        continue;
      }

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

    // ==========================================================
    // NO ACCEPTED REQUEST
    // ==========================================================

    if (selected == null) {
      _requestId = null;
      _hasAcceptedRequest = false;

      _sessionStatus = '';
      _walkId = null;
      _isLive = false;

      _emit();
      return;
    }

    final selectedRequestId = selected.id;

    // ==========================================================
    // COMPLETED REQUEST SAFETY CHECK
    // ==========================================================

    if (_completedRequestId == selectedRequestId) {
      _requestId = null;
      _hasAcceptedRequest = false;

      _sessionStatus = 'completed';
      _walkId = null;
      _isLive = false;

      _emit();
      return;
    }

    // ==========================================================
    // ACCEPTED REQUEST
    // ==========================================================

    _requestId = selectedRequestId;
    _hasAcceptedRequest = true;

    // ----------------------------------------------------------
    // Apply latest live-session snapshot immediately.
    // ----------------------------------------------------------

    final liveSnapshot = _latestLiveSnapshot;

    if (liveSnapshot != null) {
      _processLiveSessions(liveSnapshot);
      return;
    }

    _emit();
  }

  // ==========================================================
  // LIVE SESSION LISTENER
  // ==========================================================

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

  // ==========================================================
  // PROCESS LIVE SESSIONS
  // ==========================================================

  void _processLiveSessions(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    _latestLiveSnapshot = snapshot;

    final currentRequestId = _requestId;

    // ==========================================================
    // NO ACTIVE REQUEST
    // ==========================================================

    if (currentRequestId == null ||
        currentRequestId.isEmpty ||
        !_hasAcceptedRequest) {
      _sessionStatus = '';
      _walkId = null;
      _isLive = false;

      _emit();
      return;
    }

    QueryDocumentSnapshot<Map<String, dynamic>>? latestSession;

    // ==========================================================
    // FIND MATCHING SESSION
    // ==========================================================

    for (final doc in snapshot.docs) {
      final data = doc.data();

      if (!_sessionMatchesRequest(
        data,
        currentRequestId,
      )) {
        continue;
      }

      // ========================================================
      // IMPORTANT:
      // Check completion BEFORE selecting latest session.
      //
      // If ANY matching session is completed, immediately hide
      // the strip. This prevents an older active session from
      // keeping the strip visible.
      // ========================================================

      if (_isCompletedSession(data)) {
        final walkId = _readString(
          data['walkId'],
        );

        _completedRequestId = currentRequestId;

        _sessionStatus = 'completed';
        _walkId = walkId;
        _isLive = false;

        _hasAcceptedRequest = false;
        _requestId = null;

        _emit();
        return;
      }

      // ========================================================
      // KEEP LATEST ACTIVE SESSION
      // ========================================================

      if (latestSession == null ||
          _getLatestTime(data).isAfter(
            _getLatestTime(latestSession.data()),
          )) {
        latestSession = doc;
      }
    }

    // ==========================================================
    // NO MATCHING SESSION
    // ==========================================================

    if (latestSession == null) {
      _sessionStatus = '';
      _walkId = null;
      _isLive = false;

      _emit();
      return;
    }

    // ==========================================================
    // ACTIVE / LIVE SESSION
    // ==========================================================

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

  // ==========================================================
  // MATCH SESSION WITH REQUEST
  // ==========================================================

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

  // ==========================================================
  // ACCEPTED STATUS
  // ==========================================================

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

  // ==========================================================
  // LIVE STATUS
  // ==========================================================

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

  // ==========================================================
  // COMPLETION
  // ==========================================================

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

  // ==========================================================
  // EMIT
  // ==========================================================

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

  // ==========================================================
  // RESET
  // ==========================================================

  void _resetForAuthChange() {
    _requestId = null;
    _walkId = null;
    _sessionStatus = '';

    _hasAcceptedRequest = false;
    _isLive = false;

    _latestLiveSnapshot = null;
    _completedRequestId = null;

    _emit();
  }

  // ==========================================================
  // STOP LISTENERS
  // ==========================================================

  void _stopFirestoreListeners() {
    _walkRequestSubscription?.cancel();
    _liveSessionSubscription?.cancel();

    _walkRequestSubscription = null;
    _liveSessionSubscription = null;

    _latestLiveSnapshot = null;
  }

  // ==========================================================
  // STRING
  // ==========================================================

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

  // ==========================================================
  // STATUS
  // ==========================================================

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

  // ==========================================================
  // LATEST TIME
  // ==========================================================

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

  // ==========================================================
  // TIMESTAMP
  // ==========================================================

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

  // ==========================================================
  // DISPOSE
  // ==========================================================

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
