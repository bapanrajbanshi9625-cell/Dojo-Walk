import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../live_walk/screens/live_walk_screen.dart';
import '../../walker_accept/screens/walker_accept_screen.dart';
import '../models/accept_live_strip_data.dart';
import '../services/accept_live_strip_service.dart';

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
  late final AcceptLiveStripService _service;

  StreamSubscription<AcceptLiveStripData>?
      _subscription;

  AcceptLiveStripData _data =
      AcceptLiveStripData.empty;

  bool _loading = true;
  bool _opening = false;

  @override
  void initState() {
    super.initState();

    _service = AcceptLiveStripService();

    _subscription = _service.watch().listen(
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
    _service.dispose();

    super.dispose();
  }

  // ==========================================================
  // TITLE
  // ==========================================================

  String get _mainTitle {
    if (_data.isLive) {
      return 'LIVE WALK';
    }

    return 'WALK ACCEPTED';
  }

  // ==========================================================
  // SECONDARY
  // ==========================================================

  String get _secondaryText {
    if (_data.isLive) {
      return 'Your dog walk is currently in progress';
    }

    if (_data.sessionStatus == 'ready') {
      return 'Walker is ready to start the walk';
    }

    if (_data.sessionStatus == 'reached') {
      return 'Walker has reached you';
    }

    return 'Your walker has accepted the walk';
  }

  // ==========================================================
  // STATUS
  // ==========================================================

  String get _statusTitle {
    if (_data.isLive) {
      return 'LIVE WALK';
    }

    if (_data.sessionStatus == 'ready') {
      return 'READY';
    }

    if (_data.sessionStatus == 'reached') {
      return 'REACHED';
    }

    return 'ACCEPTED';
  }

  String get _statusSubtitle {
    if (_data.isLive) {
      return 'Tap to view live walk';
    }

    if (_data.sessionStatus == 'ready') {
      return 'Tap to open walk';
    }

    if (_data.sessionStatus == 'reached') {
      return 'Tap to view walk';
    }

    return 'Tap to view walker';
  }

  // ==========================================================
  // OPEN
  // ==========================================================

  Future<void> _openWalk() async {
    if (_opening || !mounted) {
      return;
    }

    final requestId =
        _data.requestId?.trim();

    if (requestId == null ||
        requestId.isEmpty) {
      return;
    }

    _opening = true;

    try {
      final walkId =
          _data.walkId?.trim();

      // ======================================================
      // LIVE WALK
      // ======================================================

      if (_data.isLive &&
          walkId != null &&
          walkId.isNotEmpty) {
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
      // ACCEPT / REACHED
      // ======================================================

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) {
            return WalkerAcceptScreen(
              requestId: requestId,
            );
          },
        ),
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

    if (!_data.isVisible) {
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
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                blurRadius: 14,
                offset: const Offset(0, 6),
                color: Colors.black.withValues(
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
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.16,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _data.isLive
                      ? Icons.directions_walk_rounded
                      : Icons.pets_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      _mainTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                        color: Colors.white.withValues(
                          alpha: 0.88,
                        ),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.end,
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
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.white.withValues(
                        alpha: 0.78,
                      ),
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
