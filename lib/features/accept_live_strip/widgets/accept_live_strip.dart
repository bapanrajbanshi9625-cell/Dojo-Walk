import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/dojo_walk_design_system.dart';
import '../../live_walk/screens/live_walk_screen.dart';
import '../../walker_accept/screens/walker_accept_screen.dart';
import '../models/accept_live_strip_data.dart';
import '../services/accept_live_strip_trigger.dart';

class AcceptLiveStrip extends StatefulWidget {
  const AcceptLiveStrip({
    super.key,
  });

  @override
  State<AcceptLiveStrip> createState() =>
      _AcceptLiveStripState();
}

class _AcceptLiveStripState
    extends State<AcceptLiveStrip> {
  late final AcceptLiveStripTrigger _trigger;

  StreamSubscription<AcceptLiveStripData>?
      _subscription;

  AcceptLiveStripData _data =
      AcceptLiveStripData.empty;

  bool _loading = true;
  bool _opening = false;

  @override
  void initState() {
    super.initState();

    _trigger = AcceptLiveStripTrigger();

    _subscription = _trigger.trigger().listen(
      (data) {
        if (!mounted) {
          return;
        }

        setState(() {
          _data = data;
          _loading = false;
        });
      },
      onError: (error) {
        debugPrint(
          'AcceptLiveStrip trigger error: $error',
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

  @override
  void dispose() {
    _subscription?.cancel();
    _trigger.dispose();

    super.dispose();
  }

  // ==========================================================
  // STATUS HELPERS
  // ==========================================================

  String get _sessionStatus {
    return _data.sessionStatus
        .trim()
        .toLowerCase();
  }

  bool get _isTerminal {
    switch (_sessionStatus) {
      case 'completed':
      case 'cancelled':
      case 'canceled':
      case 'rejected':
      case 'expired':
      case 'ended':
        return true;

      default:
        return false;
    }
  }

  bool get _canOpenLiveWalk {
    if (_isTerminal) {
      return false;
    }

    switch (_sessionStatus) {
      case 'live':
      case 'active':
      case 'walking':
      case 'in_progress':
      case 'in-progress':
      case 'started':
        return true;

      default:
        return false;
    }
  }

  bool get _canOpenAcceptWalk {
    if (_isTerminal) {
      return false;
    }

    switch (_sessionStatus) {
      case 'accepted':
      case 'ready':
      case 'reached':
        return true;

      default:
        return false;
    }
  }

  // ==========================================================
  // TITLE
  // ==========================================================

  String get _mainTitle {
    if (_canOpenLiveWalk && _data.isLive) {
      return 'LIVE WALK';
    }

    return 'WALK ACCEPTED';
  }

  // ==========================================================
  // SECONDARY
  // ==========================================================

  String get _secondaryText {
    if (_canOpenLiveWalk && _data.isLive) {
      return 'Your dog walk is currently in progress';
    }

    if (_sessionStatus == 'ready') {
      return 'Walker is ready to start the walk';
    }

    if (_sessionStatus == 'reached') {
      return 'Walker has reached you';
    }

    return 'Your walker has accepted the walk';
  }

  // ==========================================================
  // STATUS
  // ==========================================================

  String get _statusTitle {
    if (_canOpenLiveWalk && _data.isLive) {
      return 'LIVE WALK';
    }

    if (_sessionStatus == 'ready') {
      return 'READY';
    }

    if (_sessionStatus == 'reached') {
      return 'REACHED';
    }

    return 'ACCEPTED';
  }

  String get _statusSubtitle {
    if (_canOpenLiveWalk && _data.isLive) {
      return 'Tap to view live walk';
    }

    if (_sessionStatus == 'ready') {
      return 'Tap to open walk';
    }

    if (_sessionStatus == 'reached') {
      return 'Tap to view walk';
    }

    return 'Tap to view walker';
  }

  // ==========================================================
  // OPEN WALK
  // ==========================================================

  Future<void> _openWalk() async {
    if (_opening || !mounted) {
      return;
    }

    if (_isTerminal) {
      debugPrint(
        'AcceptLiveStrip → navigation blocked. '
        'Terminal status: $_sessionStatus',
      );
      return;
    }

    final String? requestId =
        _data.requestId?.trim();

    if (requestId == null ||
        requestId.isEmpty) {
      debugPrint(
        'AcceptLiveStrip → missing requestId.',
      );
      return;
    }

    _opening = true;

    try {
      final String? walkId =
          _data.walkId?.trim();

      // ======================================================
      // LIVE WALK
      // ======================================================

      if (_data.isLive &&
          _canOpenLiveWalk &&
          walkId != null &&
          walkId.isNotEmpty) {
        debugPrint(
          'AcceptLiveStrip → opening LiveWalkScreen.',
        );

        debugPrint(
          'walkId = $walkId',
        );

        debugPrint(
          'sessionStatus = $_sessionStatus',
        );

        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) {
              return LiveWalkScreen(
                walkId: walkId,
                isWalker: false,
              );
            },
          ),
        );

        return;
      }

      // ======================================================
      // ACCEPT / READY / REACHED
      // ======================================================

      if (_canOpenAcceptWalk) {
        debugPrint(
          'AcceptLiveStrip → opening WalkerAcceptScreen.',
        );

        debugPrint(
          'requestId = $requestId',
        );

        debugPrint(
          'sessionStatus = $_sessionStatus',
        );

        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) {
              return WalkerAcceptScreen(
                requestId: requestId,
              );
            },
          ),
        );

        return;
      }

      // ======================================================
      // INVALID / UNKNOWN STATE
      // ======================================================

      debugPrint(
        'AcceptLiveStrip → navigation blocked.',
      );

      debugPrint(
        'sessionStatus = $_sessionStatus',
      );

      debugPrint(
        'isLive = ${_data.isLive}',
      );
    } catch (e, stackTrace) {
      debugPrint(
        'AcceptLiveStrip navigation error: $e',
      );

      debugPrint(
        '$stackTrace',
      );
    } finally {
      _opening = false;
    }
  }

  // ==========================================================
  // UI
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox.shrink();
    }

    if (_isTerminal) {
      return const SizedBox.shrink();
    }

    if (!_data.isVisible) {
      return const SizedBox.shrink();
    }

    return Material(
      color: DojoWalkColors.transparent,
      child: InkWell(
        onTap: _openWalk,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 6,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: DojoWalkColors.primary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                blurRadius: 12,
                offset: const Offset(0, 4),
                color: DojoWalkColors.black.withValues(
                  alpha: 0.12,
                ),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: DojoWalkColors.white.withValues(
                    alpha: 0.16,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _data.isLive &&
                          _canOpenLiveWalk
                      ? Icons.directions_walk_rounded
                      : Icons.pets_rounded,
                  color: DojoWalkColors.white,
                  size: 22,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      _mainTitle,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: DojoWalkColors.white,
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      _secondaryText,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                            DojoWalkColors.white
                                .withValues(
                          alpha: 0.88,
                        ),
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Column(
                mainAxisSize:
                    MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: [
                  Text(
                    _statusTitle,
                    style: const TextStyle(
                      color: DojoWalkColors.white,
                      fontSize: 10,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    _statusSubtitle,
                    textAlign:
                        TextAlign.right,
                    style: TextStyle(
                      color:
                          DojoWalkColors.white
                              .withValues(
                        alpha: 0.78,
                      ),
                      fontSize: 8,
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 4),

              const Icon(
                Icons.chevron_right_rounded,
                color: DojoWalkColors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
