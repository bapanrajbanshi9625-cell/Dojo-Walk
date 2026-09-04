import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/live_walk_session.dart';
import '../services/live_walk_service.dart';
import '../widgets/live_walk_map.dart';
import '../widgets/live_walk_stats.dart';

class LiveWalkScreen extends StatefulWidget {
  const LiveWalkScreen({
    super.key,
    required this.walkId,
    required this.isWalker,
  });

  /// Firestore liveWalkSessions.walkId
  final String walkId;

  /// true = Walker app
  /// false = Owner app
  final bool isWalker;

  @override
  State<LiveWalkScreen> createState() => _LiveWalkScreenState();
}

class _LiveWalkScreenState extends State<LiveWalkScreen> {
  final LiveWalkService _service = LiveWalkService();

  StreamSubscription<LiveWalkSession?>? _subscription;
  Timer? _durationTimer;

  LiveWalkSession? _session;

  int _liveElapsedSeconds = 0;

  bool _loading = true;
  bool _ending = false;
  bool _closing = false;
  bool _hasError = false;

  String _errorMessage = '';

  static const Color navy = Color(0xFF263746);
  static const Color primary = Color(0xFFFF8A00);
  static const Color green = Color(0xFF16A34A);
  static const Color red = Color(0xFFDC2626);
  static const Color blue = Color(0xFF238EAE);
  static const Color lightBg = Color(0xFFF7F8F9);

  @override
  void initState() {
    super.initState();
    _listen();
  }

  // ===========================================================
  // LIVE WALK LISTENER
  // ===========================================================

  void _listen() {
    _subscription?.cancel();
    _subscription = null;

    final String id = widget.walkId.trim();

    debugPrint(
      'LIVE WALK → walkId = "$id"',
    );

    debugPrint(
      'LIVE WALK → mode = '
      '${widget.isWalker ? "WALKER" : "OWNER"}',
    );

    if (id.isEmpty) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _hasError = true;
        _errorMessage = 'Walk ID is empty.';
      });

      return;
    }

    if (mounted) {
      setState(() {
        _loading = true;
        _hasError = false;
        _errorMessage = '';
      });
    }

    // =========================================================
    // Owner  → ownerUid == FirebaseAuth.currentUser.uid
    // Walker → walkerUid == FirebaseAuth.currentUser.uid
    //
    // The service is responsible for applying the correct
    // ownership filter before reading the live session.
    // =========================================================

    _subscription = _service
        .watchSession(
          id,
          isWalker: widget.isWalker,
        )
        .listen(
      (LiveWalkSession? session) {
        if (!mounted) return;

        debugPrint(
          'LIVE WALK → session = '
          '${session?.documentId ?? 'null'}',
        );

        // -------------------------------------------------------
        // SESSION NOT CREATED YET
        // -------------------------------------------------------

        if (session == null) {
          if (_session != null) {
            return;
          }

          setState(() {
            _loading = true;
            _hasError = false;
          });

          return;
        }

        // -------------------------------------------------------
        // WALK COMPLETED
        // -------------------------------------------------------

        if (session.isCompleted) {
          debugPrint(
            'LIVE WALK → walk completed',
          );

          _session = session;

          _stopDurationTimer();

          // IMPORTANT:
          // Return true only for a genuine completed walk.
          // WalkerAcceptScreen and InstaWalkContainer use this
          // result to restore the normal Insta Walk UI.
          _closeScreen();

          return;
        }

        // -------------------------------------------------------
        // UPDATE SESSION
        // -------------------------------------------------------

        _session = session;

        _syncElapsedTime(session);

        setState(() {
          _loading = false;
          _hasError = false;
          _errorMessage = '';
        });

        // -------------------------------------------------------
        // TIMER ONLY WHEN WALK IS ACTUALLY LIVE
        // -------------------------------------------------------

        if (session.isLive) {
          _startDurationTimer();
        } else {
          _stopDurationTimer();
        }
      },
      onError: (
        Object error,
        StackTrace stackTrace,
      ) {
        debugPrint(
          'LIVE WALK → Firestore error: $error',
        );

        debugPrint(
          stackTrace.toString(),
        );

        if (!mounted) return;

        setState(() {
          _loading = false;
          _hasError = true;
          _errorMessage = _friendlyError(error);
        });
      },
    );
  }

  // ===========================================================
  // ERROR MESSAGE
  // ===========================================================

  String _friendlyError(Object error) {
    final String text = error.toString().toLowerCase();

    if (text.contains('permission-denied')) {
      return widget.isWalker
          ? 'Walker does not have permission to read this live walk.'
          : 'Owner does not have permission to read this live walk.';
    }

    if (text.contains('network')) {
      return 'Network connection problem.';
    }

    if (text.contains('unavailable')) {
      return 'Firestore is temporarily unavailable.';
    }

    if (text.contains('unauthenticated')) {
      return 'Please login again to continue.';
    }

    return 'Unable to load live walk.';
  }

  // ===========================================================
  // RETRY
  // ===========================================================

  void _retry() {
    if (_closing) return;

    _subscription?.cancel();
    _subscription = null;

    if (!mounted) return;

    setState(() {
      _loading = true;
      _hasError = false;
      _errorMessage = '';
    });

    _listen();
  }

  // ===========================================================
  // ELAPSED TIME
  // ===========================================================

  void _syncElapsedTime(
    LiveWalkSession session,
  ) {
    if (!session.isLive) {
      _liveElapsedSeconds = session.elapsedSeconds;
      return;
    }

    if (session.startedAt != null) {
      final int seconds = DateTime.now()
          .difference(session.startedAt!)
          .inSeconds;

      if (seconds >= 0) {
        _liveElapsedSeconds = seconds;
        return;
      }
    }

    _liveElapsedSeconds = session.elapsedSeconds;
  }

  void _startDurationTimer() {
    if (_durationTimer != null) {
      return;
    }

    final LiveWalkSession? session = _session;

    if (session == null || !session.isLive) {
      return;
    }

    _durationTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted || _session == null) {
          return;
        }

        final LiveWalkSession current = _session!;

        if (current.isCompleted) {
          _stopDurationTimer();
          return;
        }

        if (!current.walkStarted &&
            !current.trackingStarted) {
          return;
        }

        if (current.startedAt != null) {
          final int seconds = DateTime.now()
              .difference(current.startedAt!)
              .inSeconds;

          if (seconds >= 0) {
            setState(() {
              _liveElapsedSeconds = seconds;
            });
          }

          return;
        }

        setState(() {
          _liveElapsedSeconds++;
        });
      },
    );
  }

  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  String _durationLabel() {
    final Duration duration = Duration(
      seconds: _liveElapsedSeconds,
    );

    final int hours = duration.inHours;
    final int minutes = duration.inMinutes.remainder(60);
    final int seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  // ===========================================================
  // AUTO CLOSE
  // ===========================================================

  void _closeScreen() {
    if (_closing || !mounted) {
      return;
    }

    _closing = true;

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (!mounted) return;

        // IMPORTANT:
        // true = walk genuinely completed.
        //
        // This result is consumed by the previous screen so it
        // can restore the Insta Walk / Find a Walker UI.
        Navigator.of(context).pop(true);
      },
    );
  }

  // ===========================================================
  // BUILD
  // ===========================================================

  @override
  Widget build(BuildContext context) {
    final LiveWalkSession? session = _session;

    return Scaffold(
      backgroundColor: lightBg,
      body: SafeArea(
        child: _loading && session == null
            ? _loadingState()
            : _hasError && session == null
                ? _errorState()
                : session == null
                    ? _emptyState()
                    : Column(
                        children: [
                          _topBar(session),
                          Expanded(
                            child: LiveWalkMap(
                              walkerLocation:
                                  session.walkerLocation,
                              destination:
                                  session.ownerLocation,
                              routePoints:
                                  session.routePoints,
                              onRecenter:
                                  _recenter,
                            ),
                          ),
                          _bottomPanel(session),
                        ],
                      ),
      ),
    );
  }

  // ===========================================================
  // LOADING
  // ===========================================================

  Widget _loadingState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: primary,
            ),
          ),
          SizedBox(height: 14),
          Text(
            'Connecting to live walk...',
            style: TextStyle(
              color: navy,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  // ERROR
  // ===========================================================

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: red.withValues(alpha: .10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: red,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load live walk',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: navy,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage.isEmpty
                  ? 'Please try again.'
                  : _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Go Back',
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _retry,
                  icon: const Icon(
                    Icons.refresh_rounded,
                    size: 18,
                  ),
                  label: const Text(
                    'Retry',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================
  // TOP BAR
  // ===========================================================

  Widget _topBar(
    LiveWalkSession session,
  ) {
    final bool live = session.isLive;

    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
      ),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: navy,
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  live
                      ? 'LIVE WALK'
                      : 'READY TO WALK',
                  style: TextStyle(
                    color: live ? green : primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  session.dogBreed.isEmpty
                      ? session.dogName
                      : '${session.dogName} • ${session.dogBreed}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: (live ? green : primary)
                  .withValues(alpha: .10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              live ? 'LIVE' : 'READY',
              style: TextStyle(
                color: live ? green : primary,
                fontSize: 8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  // BOTTOM PANEL
  // ===========================================================

  Widget _bottomPanel(
    LiveWalkSession session,
  ) {
    final bool live = session.isLive;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        maxHeight: 310,
      ),
      padding: const EdgeInsets.fromLTRB(
        15,
        12,
        15,
        12,
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
          children: [
            _walkerCard(session),
            const SizedBox(height: 10),
            _destinationCard(session),
            const SizedBox(height: 10),
            LiveWalkStats(
              duration: _durationLabel(),
              steps: session.steps,
              distance: session.distanceLabel,
              peeCount: session.peeCount,
              poopCount: session.poopCount,
            ),
            if (!live) ...[
              const SizedBox(height: 10),
              _waitingCard(),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _action(
                    Icons.call_rounded,
                    'Call',
                    green,
                    _call,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _action(
                    Icons.chat_rounded,
                    'Chat',
                    blue,
                    _chat,
                  ),
                ),
              ],
            ),
            if (widget.isWalker &&
                !session.isCompleted &&
                session.isLive) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: _ending ? null : _endWalk,
                  icon: _ending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.flag_rounded,
                        ),
                  label: Text(
                    _ending
                        ? 'Ending Walk...'
                        : 'End Walk',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(13),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ===========================================================
  // WAITING CARD
  // ===========================================================

  Widget _waitingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: primary.withValues(alpha: .15),
        ),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: primary,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Walker has arrived. Waiting for the walk to start.',
              style: TextStyle(
                color: navy,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  // WALKER / OWNER CARD
  // ===========================================================

  Widget _walkerCard(
    LiveWalkSession session,
  ) {
    final String name = widget.isWalker
        ? session.ownerName
        : session.walkerName;

    final String uid = widget.isWalker
        ? session.ownerUid
        : session.walkerUid;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: lightBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: .10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              color: primary,
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
                  widget.isWalker ? 'OWNER' : 'WALKER',
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (uid.isNotEmpty)
                  Text(
                    'UID: $uid',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 9,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  // DESTINATION
  // ===========================================================

  Widget _destinationCard(
    LiveWalkSession session,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: lightBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: primary,
              size: 19,
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
                    color: Color(0xFF475569),
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  session.destinationAddress,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 11,
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

  // ===========================================================
  // ACTION BUTTON
  // ===========================================================

  Widget _action(
    IconData icon,
    String label,
    Color color,
    VoidCallback callback,
  ) {
    return SizedBox(
      height: 42,
      child: OutlinedButton.icon(
        onPressed: callback,
        icon: Icon(
          icon,
          size: 16,
          color: color,
        ),
        label: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor:
              color.withValues(alpha: .05),
          side: BorderSide(
            color: color.withValues(alpha: .18),
          ),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
      ),
    );
  }

  // ===========================================================
  // RECENTER
  // ===========================================================

  void _recenter() {
    final LatLng? location =
        _session?.walkerLocation;

    if (location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Walker live location is not available yet.',
          ),
        ),
      );
      return;
    }

    setState(() {});
  }

  // ===========================================================
  // CALL
  // ===========================================================

  Future<void> _call() async {
    final LiveWalkSession? session = _session;

    if (session == null) return;

    final String phone = widget.isWalker
        ? session.ownerPhone
        : session.walkerPhone;

    if (phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Phone number is not available.',
          ),
        ),
      );
      return;
    }

    try {
      await launchUrl(
        Uri(
          scheme: 'tel',
          path: phone.trim(),
        ),
      );
    } catch (error) {
      debugPrint(
        'LIVE WALK → call error: $error',
      );
    }
  }

  // ===========================================================
  // CHAT
  // ===========================================================

  void _chat() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Chat will open here.',
        ),
      ),
    );
  }

  // ===========================================================
  // END WALK
  // ===========================================================

  Future<void> _endWalk() async {
    final LiveWalkSession? session = _session;

    if (!widget.isWalker ||
        _ending ||
        session == null ||
        session.isCompleted ||
        !session.isLive) {
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(
            'End Walk?',
            style: TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'Are you sure you want to end this walk?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text(
                'Keep Walking',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: red,
                foregroundColor: Colors.white,
              ),
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
      await _service.completeWalk(
        session: session,
      );

      // Do not pop here.
      //
      // Firestore listener will receive the completed session.
      // Then _closeScreen() will return true.
    } catch (error) {
      debugPrint(
        'LIVE WALK → end walk error: $error',
      );

      if (!mounted) return;

      setState(() {
        _ending = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to end walk: $error',
          ),
        ),
      );
    }
  }

  // ===========================================================
  // EMPTY
  // ===========================================================

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.directions_walk_rounded,
              color: primary,
              size: 48,
            ),
            const SizedBox(height: 12),
            const Text(
              'Live walk session not found.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: navy,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================
  // DISPOSE
  // ===========================================================

  @override
  void dispose() {
    _subscription?.cancel();
    _stopDurationTimer();

    super.dispose();
  }
}
