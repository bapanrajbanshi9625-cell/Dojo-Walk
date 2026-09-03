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
  static const String collectionName = 'walk_request';

  // ===========================================================
  // ONLY THESE STATUSES ARE ALLOWED TO SHOW THE STRIP
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

  // Explicitly completed/closed states.
  // These will NEVER show the strip.
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

  StreamSubscription<
          QuerySnapshot<Map<String, dynamic>>>?
      _requestSubscription;

  String? _requestId;

  String _status = '';
  String _dogName = '';
  String _dogBreed = '';
  String _walkerName = '';

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _listenToActiveWalk();
  }

  @override
  void dispose() {
    _requestSubscription?.cancel();
    super.dispose();
  }

  // ===========================================================
  // FIRESTORE LISTENER
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

    final String field =
        widget.isWalker
            ? 'walkerUid'
            : 'ownerAuthUid';

    _requestSubscription =
        FirebaseFirestore.instance
            .collection(collectionName)
            .where(
              field,
              isEqualTo: uid,
            )
            .snapshots()
            .listen(
              _onSnapshot,
              onError: _onError,
            );
  }

  // ===========================================================
  // SNAPSHOT
  // ===========================================================

  void _onSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    QueryDocumentSnapshot<
            Map<String, dynamic>>?
        selected;

    DateTime latestTime =
        DateTime.fromMillisecondsSinceEpoch(0);

    for (final doc in snapshot.docs) {
      final Map<String, dynamic> data =
          doc.data();

      final String status =
          (data['status'] ?? '')
              .toString()
              .trim()
              .toLowerCase();

      // =======================================================
      // COMPLETED / CLOSED WALK
      // =======================================================

      if (_closedStatuses.contains(status)) {
        continue;
      }

      // =======================================================
      // ONLY VALID ACTIVE WALK STATUSES
      // =======================================================

      if (!_activeStatuses.contains(status)) {
        continue;
      }

      final DateTime time =
          _getLatestTime(data);

      if (selected == null ||
          time.isAfter(latestTime)) {
        selected = doc;
        latestTime = time;
      }
    }

    if (!mounted) return;

    // =========================================================
    // NO ACTIVE WALK
    // =========================================================

    if (selected == null) {
      setState(() {
        _loading = false;
        _clearWalk();
      });
      return;
    }

    // =========================================================
    // ACTIVE WALK FOUND
    // =========================================================

    final Map<String, dynamic> data =
        selected.data();

    final String status =
        (data['status'] ?? '')
            .toString()
            .trim()
            .toLowerCase();

    setState(() {
      _loading = false;

      // Firestore document ID = walk/request ID
      _requestId = selected!.id;

      _status = status;

      _dogName =
          (data['dogName'] ?? '')
              .toString()
              .trim();

      _dogBreed =
          (data['dogBreed'] ?? '')
              .toString()
              .trim();

      _walkerName =
          (data['walkerName'] ?? '')
              .toString()
              .trim();
    });
  }

  // ===========================================================
  // CLEAR CURRENT WALK
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
        data['createdAt'];

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  // ===========================================================
  // ERROR
  // ===========================================================

  void _onError(Object error) {
    debugPrint(
      'ActiveLiveWalkStrip Firestore error: $error',
    );

    if (!mounted) return;

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

    // Actual walk/request document ID.
    final String walkId = id.trim();

    // =========================================================
    // OWNER SIDE
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
    // WALKER SIDE
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
    // No loading UI and no active request = no strip.
    if (_loading || _requestId == null) {
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
                  // PAW / WALK ICON
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
                  // PREMIUM ARROW BUTTON
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
