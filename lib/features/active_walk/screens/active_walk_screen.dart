import 'dart:async';

import 'package:flutter/material.dart';

import '../models/active_walk.dart';
import '../services/active_walk_service.dart';
import '../widgets/active_walk_actions.dart';
import '../widgets/active_walk_header.dart';
import '../widgets/active_walk_map.dart';
import '../widgets/active_walk_stats.dart';
import '../widgets/active_walker_container.dart';

class ActiveWalkScreen extends StatefulWidget {
  const ActiveWalkScreen({
    super.key,
    required this.activeWalkId,
    required this.isWalker,
  });

  final String activeWalkId;
  final bool isWalker;

  @override
  State<ActiveWalkScreen> createState() =>
      _ActiveWalkScreenState();
}

class _ActiveWalkScreenState extends State<ActiveWalkScreen> {
  final ActiveWalkService _service = ActiveWalkService();

  StreamSubscription<ActiveWalk?>? _subscription;
  ActiveWalk? _walk;

  Timer? _timer;

  String _duration = '00:00';

  bool _loading = true;
  bool _ending = false;

  static const Color navy = Color(0xFF263746);
  static const Color primary = Color(0xFFFF8A00);
  static const Color lightBg = Color(0xFFF7F8F9);

  @override
  void initState() {
    super.initState();
    _listen();
  }

  // ==========================================================
  // LISTEN ACTIVE WALK
  // ==========================================================

  void _listen() {
    _subscription = _service
        .watchActiveWalk(widget.activeWalkId)
        .listen(
      (ActiveWalk? walk) {
        if (!mounted) {
          return;
        }

        setState(() {
          _walk = walk;
          _loading = false;
        });

        _startDurationTimer();
      },
      onError: (Object error) {
        debugPrint(
          'ActiveWalk listener error: $error',
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

  // ==========================================================
  // DURATION
  // ==========================================================

  void _startDurationTimer() {
    _timer ??= Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) {
          return;
        }

        final DateTime? startedAt = _walk?.startedAt;

        if (startedAt == null) {
          return;
        }

        final Duration difference =
            DateTime.now().difference(startedAt);

        setState(() {
          _duration = _formatDuration(difference);
        });
      },
    );

    final DateTime? startedAt = _walk?.startedAt;

    if (startedAt != null) {
      _duration = _formatDuration(
        DateTime.now().difference(startedAt),
      );
    }
  }

  String _formatDuration(Duration duration) {
    final int hours = duration.inHours;
    final int minutes =
        duration.inMinutes.remainder(60);
    final int seconds =
        duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: primary,
                ),
              )
            : _walk == null
                ? _buildNotFound()
                : _buildContent(_walk!),
      ),
    );
  }

  // ==========================================================
  // CONTENT
  // ==========================================================

  Widget _buildContent(ActiveWalk walk) {
    return Column(
      children: [
        ActiveWalkHeader(
          walk: walk,
          isWalker: widget.isWalker,
          onBack: () {
            Navigator.pop(context);
          },
        ),

        Expanded(
          child: Column(
            children: [
              Expanded(
                child: ActiveWalkMap(
                  walk: walk,
                ),
              ),

              _buildBottomPanel(walk),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // BOTTOM PANEL
  // ==========================================================

  Widget _buildBottomPanel(ActiveWalk walk) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        14,
        12,
        14,
        14,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 14,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDestination(walk),

            const SizedBox(height: 10),

            ActiveWalkerContainer(
              activeWalkId: walk.id,
              isWalker: widget.isWalker,
            ),

            const SizedBox(height: 10),

            ActiveWalkStats(
              walk: walk,
              duration: _duration,
            ),

            const SizedBox(height: 10),

            ActiveWalkActions(
              walk: walk,
              onChat: _openChat,
              onMap: _mapButton,
            ),

            if (widget.isWalker) ...[
              const SizedBox(height: 10),
              _buildEndWalkButton(walk),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // DESTINATION
  // ==========================================================

  Widget _buildDestination(ActiveWalk walk) {
    final String address =
        walk.destinationAddress.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: lightBg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: primary,
              size: 20,
            ),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'DESTINATION',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  address.isEmpty
                      ? 'Destination not available'
                      : address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // END WALK
  // ==========================================================

  Widget _buildEndWalkButton(ActiveWalk walk) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton.icon(
        onPressed:
            _ending ? null : () => _endWalk(walk),
        icon: _ending
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(
                Icons.flag_rounded,
              ),
        label: Text(
          _ending ? 'Ending Walk...' : 'End Walk',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: navy,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              navy.withValues(alpha: 0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // NOT FOUND
  // ==========================================================

  Widget _buildNotFound() {
    const ActiveWalk fallbackWalk = ActiveWalk(
      id: '',
      ownerId: '',
      ownerName: '',
      walkerId: '',
      walkerUid: '',
      walkerName: 'Walker',
      walkerPhone: '',
      dogName: 'Dog',
      dogBreed: 'Breed not available',
      status: 'ended',
      walkerLocation: null,
      ownerLocation: null,
      address: 'Destination not available',
      startedAt: null,
      createdAt: null,
    );

    return Column(
      children: [
        ActiveWalkHeader(
          walk: fallbackWalk,
          isWalker: widget.isWalker,
          onBack: () {
            Navigator.pop(context);
          },
        ),

        const Expanded(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Active walk is no longer available.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // MAP BUTTON
  // ==========================================================

  void _mapButton() {
    final ActiveWalk? walk = _walk;

    if (walk?.walkerLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Walker location is not available yet.',
          ),
        ),
      );

      return;
    }
  }

  // ==========================================================
  // CHAT
  // ==========================================================

  void _openChat() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Chat screen will be connected here.',
        ),
      ),
    );
  }

  // ==========================================================
  // END WALK
  // ==========================================================

  Future<void> _endWalk(ActiveWalk walk) async {
    final bool? confirm =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'End Walk?',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'Are you sure you want to end this walk?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Keep Walking',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'End Walk',
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) {
      return;
    }

    setState(() {
      _ending = true;
    });

    try {
      await _service.endWalk(walk);

      if (!mounted) {
        return;
      }

      Navigator.pop(context);
    } catch (e) {
      debugPrint(
        'End walk error: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _ending = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to end walk: $e',
          ),
        ),
      );
    }
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _subscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }
}
