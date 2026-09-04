// File: lib/widgets/active_live_walk_strip.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../features/live_walk/screens/live_walk_screen.dart';
import '../features/walker_accept/screens/walker_accept_screen.dart';

class ActiveLiveWalkStrip extends StatefulWidget {
  const ActiveLiveWalkStrip({
    super.key,
  });

  @override
  State<ActiveLiveWalkStrip> createState() =>
      _ActiveLiveWalkStripState();
}

class _ActiveLiveWalkStripState
    extends State<ActiveLiveWalkStrip> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // AUTH LISTENER
  // ============================================================

  StreamSubscription<User?>? _authSubscription;

  // ============================================================
  // FIRESTORE LISTENERS
  // ============================================================

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _walkRequestSubscription;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _liveSessionSubscription;

  // ============================================================
  // CURRENT WALK
  // ============================================================

  String? _requestId;
  String? _walkId;

  String _sessionStatus = '';

  bool _isLive = false;
  bool _hasAcceptedRequest = false;
  bool _loading = true;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _listenAuthState();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _authSubscription?.cancel();
    _walkRequestSubscription?.cancel();
    _liveSessionSubscription?.cancel();

    super.dispose();
  }

  // ============================================================
  // AUTH STATE
  // ============================================================

  void _listenAuthState() {
    _authSubscription = _auth.authStateChanges().listen(
      (user) {
        if (!mounted) {
          return;
        }

        debugPrint(
          'ActiveLiveWalkStrip auth changed: '
          '${user?.uid ?? 'logged_out'}',
        );

        _stopFirestoreListeners();

        if (user == null) {
          _clearWalk();
          return;
        }

        _resetForNewUser();

        _startListeners(user.uid);
      },
      onError: (error) {
        debugPrint(
          'ActiveLiveWalkStrip auth error: $error',
        );
      },
    );

    // ==========================================================
    // IMPORTANT
    // ==========================================================
    //
    // authStateChanges() normally emits the current user
    // immediately, but we also check currentUser here so the
    // strip works correctly even if the auth stream has already
    // initialized.
    //

    final currentUser = _auth.currentUser;

    if (currentUser != null) {
      _startListeners(currentUser.uid);
    }
  }

  // ============================================================
  // START LISTENERS
  // ============================================================

  void _startListeners(String uid) {
    if (!mounted) {
      return;
    }

    debugPrint(
      'ActiveLiveWalkStrip → starting listeners for $uid',
    );

    _listenWalkRequests(uid);
    _listenLiveSessions(uid);
  }

  // ============================================================
  // STOP LISTENERS
  // ============================================================

  void _stopFirestoreListeners() {
    _walkRequestSubscription?.cancel();
    _liveSessionSubscription?.cancel();

    _walkRequestSubscription = null;
    _liveSessionSubscription = null;
  }

  // ============================================================
  // RESET FOR NEW USER
  // ============================================================

  void _resetForNewUser() {
    if (!mounted) {
      return;
    }

    setState(() {
      _loading = true;
      _hasAcceptedRequest = false;
      _requestId = null;
      _walkId = null;
      _sessionStatus = '';
      _isLive = false;
    });
  }

  // ============================================================
  // WALK REQUEST
  // ============================================================

  void _listenWalkRequests(String uid) {
    _walkRequestSubscription?.cancel();

    _walkRequestSubscription = _firestore
        .collection('walk_request')
        .where(
          'ownerAuthUid',
          isEqualTo: uid,
        )
        .snapshots()
        .listen(
      _processWalkRequests,
      onError: (error) {
        debugPrint(
          'ActiveLiveWalkStrip walk_request error: $error',
        );

        if (!mounted) {
          return;
        }

        setState(() {
          _loading = false;
        });
      },
    );
  }

  // ============================================================
  // PROCESS WALK REQUESTS
  // ============================================================

  void _processWalkRequests(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    if (!mounted) {
      return;
    }

    QueryDocumentSnapshot<Map<String, dynamic>>? selected;

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final status = _readStatus(
        data['status'],
      );

      debugPrint(
        'ActiveLiveWalkStrip request '
        '${doc.id} status=$status',
      );

      if (!_isAcceptedStatus(status)) {
        continue;
      }

      if (selected == null ||
          _getLatestTime(
            doc.data(),
          ).isAfter(
            _getLatestTime(
              selected.data(),
            ),
          )) {
        selected = doc;
      }
    }

    // ==========================================================
    // NO ACCEPTED REQUEST
    // ==========================================================

    if (selected == null) {
      _hasAcceptedRequest = false;
      _requestId = null;

      _sessionStatus = '';
      _walkId = null;
      _isLive = false;

      _recalculateVisibility();
      return;
    }

    // ==========================================================
    // ACCEPTED REQUEST FOUND
    // ==========================================================

    _hasAcceptedRequest = true;
    _requestId = selected.id;

    debugPrint(
      '🟠 ActiveLiveWalkStrip → ACCEPTED '
      'requestId=$_requestId',
    );

    _recalculateVisibility();
  }

  // ============================================================
  // LIVE WALK SESSION
  // ============================================================

  void _listenLiveSessions(String uid) {
    _liveSessionSubscription?.cancel();

    _liveSessionSubscription = _firestore
        .collection('liveWalkSessions')
        .where(
          'ownerAuthUid',
          isEqualTo: uid,
        )
        .snapshots()
        .listen(
      _processLiveSessions,
      onError: (error) {
        debugPrint(
          'ActiveLiveWalkStrip liveWalkSessions error: $error',
        );
      },
    );
  }

  // ============================================================
  // PROCESS LIVE SESSIONS
  // ============================================================

  void _processLiveSessions(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    if (!mounted) {
      return;
    }

    final currentRequestId = _requestId;

    // ==========================================================
    // NO ACCEPTED REQUEST
    // ==========================================================

    if (currentRequestId == null ||
        currentRequestId.isEmpty) {
      _sessionStatus = '';
      _walkId = null;
      _isLive = false;

      _recalculateVisibility();
      return;
    }

    QueryDocumentSnapshot<Map<String, dynamic>>? selected;

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
      // COMPLETED / CLOSED SESSION
      // ========================================================

      if (_isCompletedSession(data)) {
        debugPrint(
          '🔴 ActiveLiveWalkStrip → WALK COMPLETED '
          'requestId=$currentRequestId',
        );

        _sessionStatus = 'completed';

        _walkId = _readString(
          data['walkId'],
        );

        _isLive = false;

        _recalculateVisibility();
        return;
      }

      if (selected == null ||
          _getLatestTime(
            doc.data(),
          ).isAfter(
            _getLatestTime(
              selected.data(),
            ),
          )) {
        selected = doc;
      }
    }

    // ==========================================================
    // NO MATCHING SESSION
    // ==========================================================

    if (selected == null) {
      _sessionStatus = '';
      _walkId = null;
      _isLive = false;

      _recalculateVisibility();
      return;
    }

    // ==========================================================
    // SESSION FOUND
    // ==========================================================

    final data = selected.data();

    _sessionStatus = _readStatus(
      data['status'],
    );

    _walkId = _readString(
      data['walkId'],
    );

    _isLive = _isLiveStatus(
      _sessionStatus,
    );

    debugPrint(
      'ActiveLiveWalkStrip → session '
      'status=$_sessionStatus walkId=$_walkId',
    );

    _recalculateVisibility();
  }

  // ============================================================
  // SESSION / REQUEST MATCHING
  // ============================================================

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

    return walkRequestId == requestId ||
        requestIdField == requestId ||
        requestIDField == requestId;
  }

  // ============================================================
  // COMPLETION
  // ============================================================

  bool _isCompletedSession(
    Map<String, dynamic> data,
  ) {
    final status = _readStatus(
      data['status'],
    );

    final completedAt =
        data['completedAt'];

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

  // ============================================================
  // ACCEPTED STATUS
  // ============================================================

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

  // ============================================================
  // LIVE STATUS
  // ============================================================

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

  // ============================================================
  // STATUS READER
  // ============================================================

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

  // ============================================================
  // STRING READER
  // ============================================================

  String? _readString(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    final result = value
        .toString()
        .trim();

    if (result.isEmpty) {
      return null;
    }

    return result;
  }

  // ============================================================
  // LATEST TIME
  // ============================================================

  DateTime _getLatestTime(
    Map<String, dynamic> data,
  ) {
    final updatedAt =
        _timestampToDate(
      data['updatedAt'],
    );

    if (updatedAt != null) {
      return updatedAt;
    }

    final acceptedAt =
        _timestampToDate(
      data['acceptedAt'],
    );

    if (acceptedAt != null) {
      return acceptedAt;
    }

    final createdAt =
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

  // ============================================================
  // VISIBILITY
  // ============================================================

  void _recalculateVisibility() {
    if (!mounted) {
      return;
    }

    setState(() {
      _loading = false;

      // ========================================================
      // COMPLETED ALWAYS WINS
      // ========================================================

      if (_sessionStatus == 'completed' ||
          _sessionStatus == 'complete' ||
          _sessionStatus == 'finished' ||
          _sessionStatus == 'closed' ||
          _sessionStatus == 'cancelled' ||
          _sessionStatus == 'canceled' ||
          _sessionStatus == 'rejected' ||
          _sessionStatus == 'declined' ||
          _sessionStatus == 'expired') {
        _hasAcceptedRequest = false;
        _requestId = null;
        _walkId = null;
        _isLive = false;
      }
    });
  }

  // ============================================================
  // CLEAR WALK
  // ============================================================

  void _clearWalk() {
    if (!mounted) {
      return;
    }

    setState(() {
      _loading = false;
      _hasAcceptedRequest = false;
      _requestId = null;
      _walkId = null;
      _sessionStatus = '';
      _isLive = false;
    });
  }

  // ============================================================
  // MAIN TITLE
  // ============================================================

  String get _mainTitle {
    if (_isLive) {
      return 'LIVE WALK';
    }

    return 'WALK ACCEPTED';
  }

  // ============================================================
  // SECONDARY TEXT
  // ============================================================

  String get _secondaryText {
    if (_isLive) {
      return 'Your dog walk is currently in progress';
    }

    if (_sessionStatus == 'ready') {
      return 'Walker is ready to start the walk';
    }

    return 'Your walker has accepted the walk';
  }

  // ============================================================
  // STATUS TITLE
  // ============================================================

  String get _statusTitle {
    if (_isLive) {
      return 'LIVE WALK';
    }

    if (_sessionStatus == 'ready') {
      return 'READY';
    }

    return 'ACCEPTED';
  }

  // ============================================================
  // STATUS SUBTITLE
  // ============================================================

  String get _statusSubtitle {
    if (_isLive) {
      return 'Tap to view live walk';
    }

    if (_sessionStatus == 'ready') {
      return 'Tap to open walk';
    }

    return 'Tap to view walker';
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  Future<void> _openWalk() async {
    final requestId = _requestId;

    if (requestId == null ||
        requestId.isEmpty ||
        !mounted) {
      return;
    }

    final walkId = _walkId;

    // ==========================================================
    // LIVE WALK
    // ==========================================================

    if (_isLive &&
        walkId != null &&
        walkId.isNotEmpty) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LiveWalkScreen(
            walkId: walkId,
            isWalker: false,
          ),
        ),
      );

      return;
    }

    // ==========================================================
    // ACCEPTED / READY
    // ==========================================================

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WalkerAcceptScreen(
          requestId: requestId,
        ),
      ),
    );
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    if (_loading) {
      return const SizedBox.shrink();
    }

    if (!_hasAcceptedRequest) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openWalk,
        borderRadius:
            BorderRadius.circular(18),
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          padding:
              const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius:
                BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                blurRadius: 14,
                offset:
                    const Offset(0, 6),
                color:
                    Colors.black.withValues(
                  alpha: 0.12,
                ),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration:
                    BoxDecoration(
                  color:
                      Colors.white.withValues(
                    alpha: 0.16,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isLive
                      ? Icons
                          .directions_walk_rounded
                      : Icons.pets_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      _mainTitle,
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      _secondaryText,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          TextStyle(
                        color:
                            Colors.white.withValues(
                          alpha: 0.88,
                        ),
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: [
                  Text(
                    _statusTitle,
                    style:
                        const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),

                  const SizedBox(
                    height: 3,
                  ),

                  Text(
                    _statusSubtitle,
                    style:
                        TextStyle(
                      color:
                          Colors.white.withValues(
                        alpha: 0.78,
                      ),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                width: 6,
              ),

              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
