// File: lib/widgets/active_live_walk_strip.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../features/walker_accept/screens/walker_accept_screen.dart';
import '../features/live_walk/screens/live_walk_screen.dart';

class ActiveLiveWalkStrip extends StatefulWidget {
  const ActiveLiveWalkStrip({
    super.key,
    required this.isWalker,
  });

  final bool isWalker;

  @override
  State<ActiveLiveWalkStrip> createState() =>
      _ActiveLiveWalkStripState();
}

class _ActiveLiveWalkStripState
    extends State<ActiveLiveWalkStrip> {
  // ===========================================================
  // COLLECTIONS
  // ===========================================================

  static const String _walkRequestCollection =
      'walk_request';

  static const String _liveWalkSessionCollection =
      'liveWalkSessions';

  // ===========================================================
  // ACTIVE STATUSES
  // ===========================================================

  static const Set<String> _activeStatuses = {
    'accepted',
    'active',
    'on_the_way',
    'reached',
    'walking',
    'in_progress',
    'started',
    'ongoing',
    'live',
  };

  // ===========================================================
  // CLOSED STATUSES
  // ===========================================================

  static const Set<String> _closedStatuses = {
    'completed',
    'complete',
    'cancelled',
    'canceled',
    'rejected',
    'declined',
    'expired',
    'finished',
    'closed',
  };

  // ===========================================================
  // SUBSCRIPTIONS
  // ===========================================================

  StreamSubscription<
          QuerySnapshot<Map<String, dynamic>>>?
      _walkRequestSubscription;

  StreamSubscription<
          QuerySnapshot<Map<String, dynamic>>>?
      _liveSessionSubscription;

  // ===========================================================
  // SNAPSHOTS
  // ===========================================================

  QuerySnapshot<Map<String, dynamic>>?
      _walkRequestSnapshot;

  QuerySnapshot<Map<String, dynamic>>?
      _liveSessionSnapshot;

  // ===========================================================
  // CURRENT UI STATE
  // ===========================================================

  String? _requestId;

  String _status = '';
  String _dogName = '';
  String _dogBreed = '';
  String _walkerName = '';

  bool _loading = true;

  // ===========================================================
  // INIT
  // ===========================================================

  @override
  void initState() {
    super.initState();
    _listenToActiveWalk();
  }

  // ===========================================================
  // DISPOSE
  // ===========================================================

  @override
  void dispose() {
    _walkRequestSubscription?.cancel();
    _liveSessionSubscription?.cancel();

    super.dispose();
  }

  // ===========================================================
  // FIRESTORE LISTENERS
  // ===========================================================

  void _listenToActiveWalk() {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _clearWalk();
        });
      }

      return;
    }

    final String uid = user.uid;

    // =========================================================
    // OWNER SIDE
    //
    // walk_request is identified using ownerAuthUid.
    //
    // liveWalkSessions can use ownerAuthUid OR ownerId.
    // We listen using ownerAuthUid first because that is the
    // owner identity used by the walk_request collection.
    // =========================================================

    final String ownerField =
        'ownerAuthUid';

    _walkRequestSubscription =
        FirebaseFirestore.instance
            .collection(
              _walkRequestCollection,
            )
            .where(
              ownerField,
              isEqualTo: uid,
            )
            .snapshots()
            .listen(
              (snapshot) {
                _walkRequestSnapshot =
                    snapshot;

                _processSnapshots();
              },
              onError: (Object error) {
                _onFirestoreError(
                  _walkRequestCollection,
                  error,
                );
              },
            );

    // =========================================================
    // LIVE WALK SESSION
    //
    // IMPORTANT:
    // We query ownerAuthUid here too.
    //
    // If your liveWalkSessions document uses ownerId instead,
    // the fallback below is handled by the separate listener.
    // =========================================================

    _liveSessionSubscription =
        FirebaseFirestore.instance
            .collection(
              _liveWalkSessionCollection,
            )
            .where(
              ownerField,
              isEqualTo: uid,
            )
            .snapshots()
            .listen(
              (snapshot) {
                _liveSessionSnapshot =
                    snapshot;

                _processSnapshots();
              },
              onError: (Object error) {
                _onFirestoreError(
                  _liveWalkSessionCollection,
                  error,
                );
              },
            );
  }

  // ===========================================================
  // PROCESS BOTH COLLECTIONS
  // ===========================================================

  void _processSnapshots() {
    if (!mounted) return;

    final QuerySnapshot<Map<String, dynamic>>?
        requestSnapshot =
        _walkRequestSnapshot;

    final QuerySnapshot<Map<String, dynamic>>?
        liveSnapshot =
        _liveSessionSnapshot;

    // =========================================================
    // WAIT UNTIL REQUEST DATA IS AVAILABLE
    // =========================================================

    if (requestSnapshot == null) {
      return;
    }

    // =========================================================
    // STEP 1
    //
    // Find active walk_request.
    // =========================================================

    QueryDocumentSnapshot<
            Map<String, dynamic>>?
        selectedRequest;

    DateTime latestRequestTime =
        DateTime.fromMillisecondsSinceEpoch(0);

    for (final doc in requestSnapshot.docs) {
      final Map<String, dynamic> data =
          doc.data();

      final String status =
          _readStatus(data);

      // Closed request is never shown.
      if (_closedStatuses.contains(status)) {
        continue;
      }

      // Only active statuses.
      if (!_activeStatuses.contains(status)) {
        continue;
      }

      final DateTime time =
          _getLatestTime(data);

      if (selectedRequest == null ||
          time.isAfter(latestRequestTime)) {
        selectedRequest = doc;
        latestRequestTime = time;
      }
    }

    // =========================================================
    // NO ACTIVE REQUEST
    // =========================================================

    if (selectedRequest == null) {
      setState(() {
        _loading = false;
        _clearWalk();
      });

      return;
    }

    final Map<String, dynamic> requestData =
        selectedRequest.data();

    final String requestStatus =
        _readStatus(requestData);

    // =========================================================
    // STEP 2
    //
    // Find matching liveWalkSession.
    //
    // Match using requestId first.
    // =========================================================

    Map<String, dynamic>? matchingLiveSession;

    if (liveSnapshot != null) {
      for (final doc in liveSnapshot.docs) {
        final Map<String, dynamic> data =
            doc.data();

        final bool matches =
            _sessionMatchesRequest(
          data,
          selectedRequest.id,
        );

        if (!matches) {
          continue;
        }

        matchingLiveSession = data;
        break;
      }
    }

    // =========================================================
    // STEP 3
    //
    // LIVE SESSION HAS PRIORITY.
    //
    // If liveWalkSessions says completed, the strip MUST
    // disappear even if walk_request still says accepted.
    // =========================================================

    if (matchingLiveSession != null) {
      final String liveStatus =
          _readStatus(matchingLiveSession);

      if (_closedStatuses.contains(liveStatus) ||
          liveStatus == 'completed' ||
          liveStatus == 'complete') {
        setState(() {
          _loading = false;
          _clearWalk();
        });

        return;
      }
    }

    // =========================================================
    // STEP 4
    //
    // Extra safety on request itself.
    // =========================================================

    if (_closedStatuses.contains(requestStatus) ||
        !_activeStatuses.contains(requestStatus)) {
      setState(() {
        _loading = false;
        _clearWalk();
      });

      return;
    }

    // =========================================================
    // STEP 5
    //
    // Decide final status.
    //
    // If a live session exists with an active status,
    // use the live session status.
    // Otherwise use walk_request status.
    // =========================================================

    String finalStatus = requestStatus;

    if (matchingLiveSession != null) {
      final String liveStatus =
          _readStatus(matchingLiveSession);

      if (_activeStatuses.contains(liveStatus)) {
        finalStatus = liveStatus;
      }
    }

    // =========================================================
    // FINAL SAFETY
    // =========================================================

    if (_closedStatuses.contains(finalStatus) ||
        !_activeStatuses.contains(finalStatus)) {
      setState(() {
        _loading = false;
        _clearWalk();
      });

      return;
    }

    // =========================================================
    // DATA
    //
    // Prefer live session data when available.
    // Fall back to walk_request.
    // =========================================================

    final Map<String, dynamic> displayData =
        matchingLiveSession ?? requestData;

    final String dogName =
        _firstNonEmpty([
      displayData['dogName'],
      requestData['dogName'],
    ]);

    final String dogBreed =
        _firstNonEmpty([
      displayData['dogBreed'],
      requestData['dogBreed'],
    ]);

    final String walkerName =
        _firstNonEmpty([
      displayData['walkerName'],
      requestData['walkerName'],
    ]);

    // =========================================================
    // UPDATE UI
    // =========================================================
    
    setState(() {
  _loading = false;

  // IMPORTANT:
  // Navigation still uses walk_request document ID.
  _requestId = selectedRequest!.id;

  _status = finalStatus;

  _dogName = dogName;
  _dogBreed = dogBreed;
  _walkerName = walkerName;
});

  // ===========================================================
  // MATCH LIVE SESSION TO REQUEST
  // ===========================================================

  bool _sessionMatchesRequest(
    Map<String, dynamic> data,
    String requestId,
  ) {
    final List<dynamic> possibleIds = [
      data['requestId'],
      data['walkRequestId'],
      data['walkId'],
      data['requestID'],
    ];

    for (final value in possibleIds) {
      if (value == null) continue;

      if (value.toString().trim() == requestId) {
        return true;
      }
    }

    return false;
  }

  // ===========================================================
  // READ STATUS
  // ===========================================================

  String _readStatus(
    Map<String, dynamic> data,
  ) {
    return (data['status'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
  }

  // ===========================================================
  // FIRST NON-EMPTY VALUE
  // ===========================================================

  String _firstNonEmpty(
    List<dynamic> values,
  ) {
    for (final value in values) {
      final String text =
          (value ?? '').toString().trim();

      if (text.isNotEmpty) {
        return text;
      }
    }

    return '';
  }

  // ===========================================================
  // CLEAR WALK
  // ===========================================================

  void _clearWalk() {
    _requestId = null;
    _status = '';
    _dogName = '';
    _dogBreed = '';
    _walkerName = '';
  }

  // ===========================================================
  // LATEST TIME
  // ===========================================================

  DateTime _getLatestTime(
    Map<String, dynamic> data,
  ) {
    final dynamic value =
        data['updatedAt'] ??
        data['acceptedAt'] ??
        data['startedAt'] ??
        data['createdAt'];

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(
        value,
      );
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  // ===========================================================
  // FIRESTORE ERROR
  // ===========================================================

  void _onFirestoreError(
    String collection,
    Object error,
  ) {
    debugPrint(
      'ActiveLiveWalkStrip Firestore error '
      '[$collection]: $error',
    );

    if (!mounted) return;

    // Do not destroy valid UI state because one listener
    // temporarily reports an error.
    setState(() {
      _loading = false;
    });
  }

  // ===========================================================
  // LIVE STATUS
  // ===========================================================

  bool get _isLive {
    switch (_status) {
      case 'reached':
      case 'walking':
      case 'in_progress':
      case 'started':
      case 'ongoing':
      case 'live':
        return true;

      default:
        return false;
    }
  }

  // ===========================================================
  // STATUS TITLE
  // ===========================================================

  String get _statusTitle {
    if (_isLive) {
      return 'LIVE WALK';
    }

    return 'ACTIVE WALK';
  }

  // ===========================================================
  // STATUS SUBTITLE
  // ===========================================================

  String get _statusSubtitle {
    if (_isLive) {
      return widget.isWalker
          ? 'Walk is live • Tap to continue'
          : 'Walker has arrived • Tap to open';
    }

    return widget.isWalker
        ? 'Walk accepted • Tap to open'
        : 'Walker is on the way • Tap to track';
  }

  // ===========================================================
  // MAIN TITLE
  // ===========================================================

  String get _mainTitle {
    if (widget.isWalker) {
      if (_dogName.isNotEmpty) {
        return _dogName;
      }

      return 'Your Walk';
    }

    if (_dogName.isNotEmpty &&
        _walkerName.isNotEmpty) {
      return '$_dogName • $_walkerName';
    }

    if (_dogName.isNotEmpty) {
      return _dogName;
    }

    if (_walkerName.isNotEmpty) {
      return _walkerName;
    }

    return 'Your Dog Walk';
  }

  // ===========================================================
  // SECONDARY TEXT
  // ===========================================================

  String get _secondaryText {
    if (widget.isWalker) {
      return _dogBreed.isNotEmpty
          ? _dogBreed
          : 'Walker mode';
    }

    return _isLive
        ? 'Walking now'
        : 'Walker assigned';
  }

  // ===========================================================
  // OPEN WALK
  // ===========================================================

  void _openWalk() {
    final String? id = _requestId;

    if (id == null || id.trim().isEmpty) {
      return;
    }

    final String walkId = id.trim();

    // =========================================================
    // OWNER
    // =========================================================

    if (!widget.isWalker) {
      if (_isLive) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => LiveWalkScreen(
              walkId: walkId,
              isWalker: false,
            ),
          ),
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => WalkerAcceptScreen(
              requestId: walkId,
            ),
          ),
        );
      }

      return;
    }

    // =========================================================
    // WALKER
    // =========================================================

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LiveWalkScreen(
          walkId: walkId,
          isWalker: true,
        ),
      ),
    );
  }

  // ===========================================================
  // BUILD
  // ===========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    // =========================================================
    // NO ACTIVE WALK
    // =========================================================

    if (_loading || _requestId == null) {
      return const SizedBox.shrink();
    }

    // =========================================================
    // UI SAFETY
    // =========================================================

    if (_closedStatuses.contains(_status) ||
        !_activeStatuses.contains(_status)) {
      return const SizedBox.shrink();
    }

    final Color orange =
        AppColors.orange;

    final Color navy =
        AppColors.navy;

    final Color success =
        AppColors.success;

    final Color accent =
        _isLive ? success : orange;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        12,
        6,
        12,
        6,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius:
            BorderRadius.circular(20),
        elevation: 8,
        shadowColor:
            navy.withValues(alpha: 0.28),
        child: InkWell(
          onTap: _openWalk,
          borderRadius:
              BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  orange,
                  Color.lerp(
                    orange,
                    navy,
                    0.48,
                  )!,
                  navy,
                ],
              ),
              border: Border.all(
                color:
                    Colors.white.withValues(
                  alpha: 0.18,
                ),
                width: 1,
              ),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.all(11),
              child: Row(
                children: [
                  // =================================================
                  // ICON
                  // =================================================

                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color:
                          Colors.white.withValues(
                        alpha: 0.16,
                      ),
                      borderRadius:
                          BorderRadius.circular(14),
                      border: Border.all(
                        color:
                            Colors.white.withValues(
                          alpha: 0.20,
                        ),
                      ),
                    ),
                    child: Icon(
                      _isLive
                          ? Icons.pets_rounded
                          : Icons
                              .directions_walk_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: 10),

                  // =================================================
                  // TEXT
                  // =================================================

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                _mainTitle,
                                maxLines: 1,
                                overflow:
                                    TextOverflow.ellipsis,
                                style:
                                    const TextStyle(
                                  color:
                                      Colors.white,
                                  fontSize: 15,
                                  fontWeight:
                                      FontWeight.w800,
                                  letterSpacing:
                                      -0.2,
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 7,
                            ),
                            Container(
                              width: 7,
                              height: 7,
                              decoration:
                                  BoxDecoration(
                                color: accent,
                                shape:
                                    BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        accent.withValues(
                                      alpha: 0.65,
                                    ),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 2),

                        Text(
                          _secondaryText,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: TextStyle(
                            color:
                                Colors.white.withValues(
                              alpha: 0.82,
                            ),
                            fontSize: 11,
                            fontWeight:
                                FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Row(
                          children: [
                            Container(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration:
                                  BoxDecoration(
                                color:
                                    Colors.white.withValues(
                                  alpha: 0.14,
                                ),
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  7,
                                ),
                              ),
                              child: Text(
                                _statusTitle,
                                style:
                                    const TextStyle(
                                  color:
                                      Colors.white,
                                  fontSize: 8,
                                  fontWeight:
                                      FontWeight.w900,
                                  letterSpacing:
                                      0.7,
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 6,
                            ),
                            Flexible(
                              child: Text(
                                _statusSubtitle,
                                maxLines: 1,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style: TextStyle(
                                  color:
                                      Colors.white.withValues(
                                    alpha: 0.72,
                                  ),
                                  fontSize: 9,
                                  fontWeight:
                                      FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // =================================================
                  // ARROW
                  // =================================================

                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color:
                          Colors.white.withValues(
                        alpha: 0.18,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            Colors.white.withValues(
                          alpha: 0.20,
                        ),
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 19,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
