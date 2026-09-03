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
    required this.activeWalkId,
    required this.isWalker,
  });

  final String activeWalkId;
  final bool isWalker;

  @override
  State<LiveWalkScreen> createState() =>
      _LiveWalkScreenState();
}

class _LiveWalkScreenState
    extends State<LiveWalkScreen> {
  final LiveWalkService _service =
      LiveWalkService();

  StreamSubscription<LiveWalkSession?>?
      _subscription;

  LiveWalkSession? _session;

  Timer? _durationTimer;

  int _liveElapsedSeconds = 0;

  bool _loading = true;
  bool _ending = false;
  bool _closing = false;

  static const Color navy =
      Color(0xFF263746);

  static const Color primary =
      Color(0xFFFF8A00);

  static const Color green =
      Color(0xFF16A34A);

  static const Color red =
      Color(0xFFDC2626);

  static const Color blue =
      Color(0xFF238EAE);

  static const Color lightBg =
      Color(0xFFF7F8F9);

  @override
  void initState() {
    super.initState();

    _listen();
  }

  // ===========================================================
  // LIVE SESSION LISTENER
  // ===========================================================

  void _listen() {
    final String walkId =
        widget.activeWalkId.trim();

    if (walkId.isEmpty) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
      return;
    }

    _subscription =
        _service.watchSession(walkId).listen(
      (LiveWalkSession? session) {
        if (!mounted) return;

        // -----------------------------------------------------
        // SESSION NOT AVAILABLE YET
        // -----------------------------------------------------

        if (session == null) {
          // Do not immediately show "not found".
          //
          // Firestore listener remains active and will
          // automatically receive the session when it appears.
          setState(() {
            _loading = true;
          });

          return;
        }

        // -----------------------------------------------------
        // COMPLETED → CLOSE SCREEN
        // -----------------------------------------------------

        if (session.isCompleted) {
          _session = session;

          _stopDurationTimer();

          _closeScreen();

          return;
        }

        // -----------------------------------------------------
        // UPDATE SESSION
        // -----------------------------------------------------

        _session = session;

        _syncElapsedTime(session);

        setState(() {
          _loading = false;
        });

        // -----------------------------------------------------
        // TIMER ONLY WHEN ACTUAL WALK IS LIVE
        // -----------------------------------------------------

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
          'LiveWalkScreen Firestore error: $error',
        );

        debugPrint(
          stackTrace.toString(),
        );

        if (!mounted) return;

        setState(() {
          _loading = false;
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to load live walk.',
            ),
          ),
        );
      },
    );
  }

  // ===========================================================
  // ELAPSED TIME
  // ===========================================================

  void _syncElapsedTime(
    LiveWalkSession session,
  ) {
    if (!session.isLive) {
      _liveElapsedSeconds =
          session.elapsedSeconds;
      return;
    }

    // If startedAt exists, use it as the real timer
    // baseline instead of resetting from every Firestore
    // snapshot.
    if (session.startedAt != null) {
      final int seconds =
          DateTime.now()
              .difference(
                session.startedAt!,
              )
              .inSeconds;

      if (seconds >= 0) {
        _liveElapsedSeconds =
            seconds;
        return;
      }
    }

    _liveElapsedSeconds =
        session.elapsedSeconds;
  }

  void _startDurationTimer() {
    if (_durationTimer != null) {
      return;
    }

    final LiveWalkSession? session =
        _session;

    if (session == null ||
        !session.isLive) {
      return;
    }

    _durationTimer =
        Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted ||
            _session == null) {
          return;
        }

        final LiveWalkSession current =
            _session!;

        if (current.isCompleted) {
          _stopDurationTimer();
          return;
        }

        if (!current.walkStarted &&
            !current.trackingStarted) {
          return;
        }

        if (current.startedAt != null) {
          final int seconds =
              DateTime.now()
                  .difference(
                    current.startedAt!,
                  )
                  .inSeconds;

          if (seconds >= 0) {
            setState(() {
              _liveElapsedSeconds =
                  seconds;
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
    final Duration duration =
        Duration(
      seconds: _liveElapsedSeconds,
    );

    final int hours =
        duration.inHours;

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

  // ===========================================================
  // AUTO CLOSE
  // ===========================================================

  void _closeScreen() {
    if (_closing || !mounted) {
      return;
    }

    _closing = true;

    WidgetsBinding.instance
        .addPostFrameCallback(
      (_) {
        if (!mounted) return;

        Navigator.of(context).pop();
      },
    );
  }

  // ===========================================================
  // BUILD
  // ===========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final LiveWalkSession? session =
        _session;

    return Scaffold(
      backgroundColor: lightBg,
      body: SafeArea(
        child: _loading &&
                session == null
            ? _loadingState()
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
            child:
                CircularProgressIndicator(
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
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  // TOP BAR
  // ===========================================================

  Widget _topBar(
    LiveWalkSession session,
  ) {
    final bool live =
        session.isLive;

    return Container(
      height: 66,
      padding:
          const EdgeInsets.symmetric(
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
                    color:
                        live
                            ? green
                            : primary,
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w900,
                    letterSpacing: .8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  session.dogBreed.isEmpty
                      ? session.dogName
                      : '${session.dogName} • ${session.dogBreed}',
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color:
                  (live
                          ? green
                          : primary)
                      .withValues(
                        alpha: .10,
                      ),
              borderRadius:
                  BorderRadius.circular(20),
            ),
            child: Text(
              live
                  ? 'LIVE'
                  : 'READY',
              style: TextStyle(
                color:
                    live
                        ? green
                        : primary,
                fontSize: 8,
                fontWeight:
                    FontWeight.w900,
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
    final bool live =
        session.isLive;

    return Container(
      width: double.infinity,
      constraints:
          const BoxConstraints(
        maxHeight: 310,
      ),
      padding:
          const EdgeInsets.fromLTRB(
        15,
        12,
        15,
        12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(
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
              duration:
                  _durationLabel(),
              steps:
                  session.steps,
              distance:
                  session.distanceLabel,
              peeCount:
                  session.peeCount,
              poopCount:
                  session.poopCount,
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
                child:
                    ElevatedButton.icon(
                  onPressed:
                      _ending
                          ? null
                          : _endWalk,
                  icon:
                      _ending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color:
                                    Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.flag_rounded,
                            ),
                  label: Text(
                    _ending
                        ? 'Ending Walk...'
                        : 'End Walk',
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        navy,
                    foregroundColor:
                        Colors.white,
                    elevation: 0,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        13,
                      ),
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
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color:
            primary.withValues(alpha: .07),
        borderRadius:
            BorderRadius.circular(13),
        border: Border.all(
          color:
              primary.withValues(alpha: .15),
        ),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child:
                CircularProgressIndicator(
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
                fontWeight:
                    FontWeight.w700,
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
    final String name =
        widget.isWalker
            ? session.ownerName
            : session.walkerName;

    final String uid =
        widget.isWalker
            ? session.ownerUid
            : session.walkerUid;

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: lightBg,
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color:
                  primary.withValues(
                alpha: .10,
              ),
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
                  widget.isWalker
                      ? 'OWNER'
                      : 'WALKER',
                  style: const TextStyle(
                    color:
                        Color(0xFF475569),
                    fontSize: 8,
                    fontWeight:
                        FontWeight.w900,
                    letterSpacing: .6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
                if (uid.isNotEmpty)
                  Text(
                    'UID: $uid',
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      color:
                          Color(0xFF475569),
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
      padding:
          const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: lightBg,
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color:
                  primary.withValues(
                alpha: .10,
              ),
              borderRadius:
                  BorderRadius.circular(10),
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
                    color:
                        Color(0xFF475569),
                    fontSize: 8,
                    fontWeight:
                        FontWeight.w900,
                    letterSpacing: .5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  session
                      .destinationAddress,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w800,
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
            fontWeight:
                FontWeight.w800,
          ),
        ),
        style:
            OutlinedButton.styleFrom(
          backgroundColor:
              color.withValues(
            alpha: .05,
          ),
          side: BorderSide(
            color:
                color.withValues(
              alpha: .18,
            ),
          ),
          padding: EdgeInsets.zero,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(11),
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
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Walker live location is not available yet.',
          ),
        ),
      );
      return;
    }

    // LiveWalkMap receives the latest
    // walker location through rebuild.
    setState(() {});
  }

  // ===========================================================
  // CALL
  // ===========================================================

  Future<void> _call() async {
    final LiveWalkSession? session =
        _session;

    if (session == null) return;

    final String phone =
        widget.isWalker
            ? session.ownerPhone
            : session.walkerPhone;

    if (phone.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
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
        'Call error: $error',
      );
    }
  }

  // ===========================================================
  // CHAT
  // ===========================================================

  void _chat() {
    ScaffoldMessenger.of(context)
        .showSnackBar(
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
    final LiveWalkSession? session =
        _session;

    if (!widget.isWalker ||
        _ending ||
        session == null ||
        session.isCompleted ||
        !session.isLive) {
      return;
    }

    final bool? confirm =
        await showDialog<bool>(
      context: context,
      builder:
          (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(
            'End Walk?',
            style: TextStyle(
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          content: const Text(
            'Are you sure you want to end this walk?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child: const Text(
                'Keep Walking',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor: red,
                foregroundColor:
                    Colors.white,
              ),
              child: const Text(
                'End Walk',
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true ||
        !mounted) {
      return;
    }

    setState(() {
      _ending = true;
    });

    try {
      await _service.completeWalk(
        session: session,
      );

      // Firestore snapshot will return
      // completed=true and _closeScreen()
      // will close this screen automatically.
    } catch (error) {
      debugPrint(
        'End walk error: $error',
      );

      if (!mounted) return;

      setState(() {
        _ending = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
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
        padding:
            const EdgeInsets.all(24),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons.directions_walk_rounded,
              color: primary,
              size: 48,
            ),
            const SizedBox(height: 12),
            const Text(
              'Live walk session not found.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color: navy,
                fontSize: 16,
                fontWeight:
                    FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context)
                    .pop();
              },
              child:
                  const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _stopDurationTimer();

    super.dispose();
  }
}
