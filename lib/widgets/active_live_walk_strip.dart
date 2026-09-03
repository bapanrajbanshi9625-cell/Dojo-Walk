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
  State<ActiveLiveWalkStrip> createState() => _ActiveLiveWalkStripState();
}

class _ActiveLiveWalkStripState extends State<ActiveLiveWalkStrip> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _walkRequestSubscription;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _liveSessionSubscription;

  String? _requestId;
  String? _walkId;

  String _requestStatus = '';
  String _sessionStatus = '';

  bool _isLive = false;
  bool _hasAcceptedRequest = false;
  bool _hasLiveSession = false;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _startListeners();
  }

  @override
  void dispose() {
    _walkRequestSubscription?.cancel();
    _liveSessionSubscription?.cancel();
    super.dispose();
  }

  void _startListeners() {
    final user = _auth.currentUser;

    if (user == null) {
      _clearWalk();
      return;
    }

    _listenWalkRequests(user.uid);
    _listenLiveSessions(user.uid);
  }

  void _listenWalkRequests(String uid) {
    _walkRequestSubscription?.cancel();

    _walkRequestSubscription = _firestore
        .collection('walk_request')
        .where('ownerAuthUid', isEqualTo: uid)
        .snapshots()
        .listen(
      (snapshot) {
        _processWalkRequests(snapshot);
      },
      onError: (error) {
        debugPrint(
          'ActiveLiveWalkStrip walk_request error: $error',
        );
      },
    );
  }

  void _listenLiveSessions(String uid) {
    _liveSessionSubscription?.cancel();

    _liveSessionSubscription = _firestore
        .collection('liveWalkSessions')
        .where('ownerAuthUid', isEqualTo: uid)
        .snapshots()
        .listen(
      (snapshot) {
        _processLiveSessions(snapshot);
      },
      onError: (error) {
        debugPrint(
          'ActiveLiveWalkStrip liveWalkSessions error: $error',
        );
      },
    );
  }

  void _processWalkRequests(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    QueryDocumentSnapshot<Map<String, dynamic>>? selected;

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final status = _readStatus(data['status']);

      if (!_isAcceptedStatus(status)) {
        continue;
      }

      if (selected == null ||
          _getLatestTime(doc.data()) >
              _getLatestTime(selected.data())) {
        selected = doc;
      }
    }

    if (selected == null) {
      _hasAcceptedRequest = false;
      _requestId = null;
      _requestStatus = '';
      _recalculateVisibility();
      return;
    }

    _hasAcceptedRequest = true;
    _requestId = selected.id;
    _requestStatus = _readStatus(selected.data()['status']);

    _recalculateVisibility();
  }

  void _processLiveSessions(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    QueryDocumentSnapshot<Map<String, dynamic>>? selected;

    final currentRequestId = _requestId;

    for (final doc in snapshot.docs) {
      final data = doc.data();

      if (currentRequestId != null &&
          !_sessionMatchesRequest(data, currentRequestId)) {
        continue;
      }

      if (_isCompletedSession(data)) {
        if (currentRequestId != null &&
            _sessionMatchesRequest(data, currentRequestId)) {
          _hasLiveSession = true;
          _sessionStatus = 'completed';
          _walkId = _readString(data['walkId']);
          _isLive = false;

          _recalculateVisibility();
          return;
        }

        continue;
      }

      if (selected == null ||
          _getLatestTime(doc.data()) >
              _getLatestTime(selected.data())) {
        selected = doc;
      }
    }

    if (selected == null) {
      _hasLiveSession = false;
      _sessionStatus = '';
      _walkId = null;
      _isLive = false;

      _recalculateVisibility();
      return;
    }

    final data = selected.data();

    _hasLiveSession = true;
    _sessionStatus = _readStatus(data['status']);

    _walkId = _readString(data['walkId']);

    _isLive = _isLiveStatus(_sessionStatus);

    _recalculateVisibility();
  }

  void _recalculateVisibility() {
    if (!mounted) {
      return;
    }

    setState(() {
      _loading = false;

      // ------------------------------------------------------------
      // IMPORTANT:
      //
      // 1. Accepted walk_request => strip visible.
      // 2. Matching liveWalkSessions completed => strip hidden.
      // 3. liveWalkSessions ready => strip stays, but NOT LIVE.
      // 4. Actual live status => strip shows LIVE WALK.
      // ------------------------------------------------------------

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
        _hasLiveSession = false;
        _requestId = null;
        _walkId = null;
        _isLive = false;
      }
    });
  }

  bool _sessionMatchesRequest(
    Map<String, dynamic> data,
    String requestId,
  ) {
    final walkRequestId = _readString(data['walkRequestId']);
    final requestIdField = _readString(data['requestId']);
    final requestIDField = _readString(data['requestID']);

    return walkRequestId == requestId ||
        requestIdField == requestId ||
        requestIDField == requestId;
  }

  bool _isCompletedSession(
    Map<String, dynamic> data,
  ) {
    final status = _readStatus(data['status']);

    final completedAt = data['completedAt'];
    final trackingEnded = data['trackingEnded'] == true;
    final walkEnded = data['walkEnded'] == true;

    return status == 'completed' ||
        status == 'complete' ||
        status == 'finished' ||
        status == 'closed' ||
        (completedAt != null) ||
        trackingEnded ||
        walkEnded;
  }

  bool _isAcceptedStatus(String status) {
    return status == 'accepted' ||
        status == 'active' ||
        status == 'on_the_way' ||
        status == 'reached' ||
        status == 'walking' ||
        status == 'in_progress' ||
        status == 'started' ||
        status == 'ongoing' ||
        status == 'live' ||
        status == 'ready';
  }

  bool _isLiveStatus(String status) {
    return status == 'active' ||
        status == 'walking' ||
        status == 'in_progress' ||
        status == 'started' ||
        status == 'ongoing' ||
        status == 'live';
  }

  String _readStatus(dynamic value) {
    if (value == null) {
      return '';
    }

    return value.toString().trim().toLowerCase();
  }

  String? _readString(dynamic value) {
    if (value == null) {
      return null;
    }

    final valueString = value.toString().trim();

    if (valueString.isEmpty) {
      return null;
    }

    return valueString;
  }

  DateTime _getLatestTime(
    Map<String, dynamic> data,
  ) {
    final updatedAt = _timestampToDate(data['updatedAt']);

    if (updatedAt != null) {
      return updatedAt;
    }

    final acceptedAt = _timestampToDate(data['acceptedAt']);

    if (acceptedAt != null) {
      return acceptedAt;
    }

    final createdAt = _timestampToDate(data['createdAt']);

    if (createdAt != null) {
      return createdAt;
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  DateTime? _timestampToDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  void _clearWalk() {
    if (!mounted) {
      return;
    }

    setState(() {
      _loading = false;
      _hasAcceptedRequest = false;
      _hasLiveSession = false;
      _requestId = null;
      _walkId = null;
      _requestStatus = '';
      _sessionStatus = '';
      _isLive = false;
    });
  }

  String get _mainTitle {
    if (_isLive) {
      return 'LIVE WALK';
    }

    return 'WALK ACCEPTED';
  }

  String get _secondaryText {
    if (_isLive) {
      return 'Your dog walk is currently in progress';
    }

    if (_hasLiveSession && _sessionStatus == 'ready') {
      return 'Walker is ready to start the walk';
    }

    return 'Your walker has accepted the walk';
  }

  String get _statusTitle {
    if (_isLive) {
      return 'LIVE WALK';
    }

    if (_hasLiveSession && _sessionStatus == 'ready') {
      return 'READY';
    }

    return 'ACCEPTED';
  }

  String get _statusSubtitle {
    if (_isLive) {
      return 'Tap to view live walk';
    }

    if (_hasLiveSession && _sessionStatus == 'ready') {
      return 'Tap to open walk';
    }

    return 'Tap to view walker';
  }

  Future<void> _openWalk() async {
    final requestId = _requestId;
    final walkId = _walkId;

    if (requestId == null || requestId.isEmpty) {
      return;
    }

    if (_isLive && walkId != null && walkId.isNotEmpty) {
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

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WalkerAcceptScreen(
          requestId: requestId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        borderRadius: BorderRadius.circular(18),
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                DojoColors.primary,
                DojoColors.primaryDark,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                blurRadius: 14,
                offset: const Offset(0, 6),
                color: Colors.black.withValues(alpha: 0.12),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isLive
                      ? Icons.directions_walk_rounded
                      : Icons.pets_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _mainTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _secondaryText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _statusTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _statusSubtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 6),
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
