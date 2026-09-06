import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../screens/help_support_screen.dart';

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

  final String walkId;
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
  bool _closing = false;
  bool _hasError = false;

  String _errorMessage = '';

  double _sheetExtent = 0.25;

  static const Color navy = Color(0xFF263746);
  static const Color primary = Color(0xFFFF6B35);
  static const Color green = Color(0xFF16A34A);
  static const Color lightBg = Color(0xFFF7F8F9);

  @override
  void initState() {
    super.initState();
    _listen();
  }

  void _listen() {
    _subscription?.cancel();

    setState(() {
      _loading = true;
      _hasError = false;
      _errorMessage = '';
    });

    _subscription = _service
        .watchSession(
          widget.walkId,
          isWalker: widget.isWalker,
        )
        .listen(
      (session) {
        if (!mounted) return;

        if (session == null) {
          setState(() {
            _loading = false;
            _hasError = false;
            _session = null;
          });
          return;
        }

        // Existing completion flow is preserved.
        if (session.isCompleted) {
          _stopDurationTimer();

          if (!_closing) {
            _closeScreen();
          }

          return;
        }

        setState(() {
          _loading = false;
          _hasError = false;
          _session = session;
        });

        _syncElapsedTime(session);

        if (session.isLive) {
          _startDurationTimer();
        } else {
          _stopDurationTimer();
        }
      },
      onError: (error) {
        if (!mounted) return;

        setState(() {
          _loading = false;
          _hasError = true;
          _errorMessage = _friendlyError(error);
        });

        _stopDurationTimer();
      },
    );
  }

  String _friendlyError(Object error) {
    final text = error.toString().toLowerCase();

    if (text.contains('permission-denied')) {
      return 'You do not have permission to view this live walk.';
    }

    if (text.contains('network')) {
      return 'Network connection problem. Please try again.';
    }

    return 'Unable to load the live walk right now.';
  }

  void _retry() {
    _subscription?.cancel();
    _listen();
  }

  void _syncElapsedTime(LiveWalkSession session) {
    if (_liveElapsedSeconds != session.elapsedSeconds) {
      _liveElapsedSeconds = session.elapsedSeconds;
    }
  }

  void _startDurationTimer() {
    if (_durationTimer != null) return;

    _durationTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted || _session == null) return;

        if (!_session!.isLive) {
          _stopDurationTimer();
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

  String _durationLabel(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  void _closeScreen() {
    if (_closing || !mounted) return;

    _closing = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      Navigator.of(context).pop(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: lightBg,
          body: _loadingState(),
        ),
      );
    }

    if (_hasError) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: lightBg,
          body: _errorState(),
        ),
      );
    }

    final session = _session;

    if (session == null) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: lightBg,
          body: _emptyState(),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = constraints.maxHeight;

            return NotificationListener<
                DraggableScrollableNotification>(
              onNotification: (notification) {
                if (!mounted) return false;

                setState(() {
                  _sheetExtent = notification.extent;
                });

                return false;
              },
              child: Stack(
                children: [
                  // =====================================================
                  // FULL BACKGROUND MAP
                  // =====================================================

                  Positioned.fill(
                    child: LiveWalkMap(
                      walkerLocation: session.walkerLocation,
                      destination: session.ownerLocation,
                      routePoints: session.routePoints,
                      onRecenter: _recenter,
                    ),
                  ),

                  // =====================================================
                  // TOP HEADER ONLY
                  // =====================================================

                  _topHeader(),

                  // =====================================================
                  // DRAGGABLE BOTTOM SHEET
                  // =====================================================

                  DraggableScrollableSheet(
                    initialChildSize: 0.25,
                    minChildSize: 0.25,
                    maxChildSize: 0.78,
                    snap: true,
                    snapSizes: const [
                      0.25,
                      0.78,
                    ],
                    builder: (
                      context,
                      scrollController,
                    ) {
                      return _bottomSheet(
                        session,
                        scrollController,
                      );
                    },
                  ),

                  // =====================================================
                  // RECENTER BUTTON
                  // =====================================================

                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeOut,
                    right: 16,
                    bottom: screenHeight * _sheetExtent + 14,
                    child: _myLocationButton(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ================================================================
  // TOP HEADER
  // ================================================================

  Widget _topHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: const BoxDecoration(
          color: primary,
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 72,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: 0.18,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        '🐾',
                        style: TextStyle(
                          fontSize: 19,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 11),

                  const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LIVE WALK',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Live location & walk tracking',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ==================================================
                  // CIRCULAR HELP BUTTON
                  // ==================================================

                  Material(
                    color: Colors.white.withValues(
                      alpha: 0.18,
                    ),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _openHelpSupport,
                      child: const SizedBox(
                        width: 42,
                        height: 42,
                        child: Icon(
                          Icons.support_agent_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
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

  // ================================================================
  // HELP & SUPPORT
  // ================================================================

  void _openHelpSupport() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const HelpSupportScreen(),
      ),
    );
  }

  // ================================================================
  // LOCATION BUTTON
  // ================================================================

  Widget _myLocationButton() {
    return Material(
      color: Colors.white,
      elevation: 5,
      shadowColor: Colors.black.withValues(
        alpha: 0.18,
      ),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: _recenter,
        child: const SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            Icons.my_location_rounded,
            color: primary,
            size: 22,
          ),
        ),
      ),
    );
  }

  // ================================================================
  // BOTTOM SHEET
  // ================================================================

  Widget _bottomSheet(
    LiveWalkSession session,
    ScrollController scrollController,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(26),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 22,
            offset: const Offset(0, -5),
            color: Colors.black.withValues(
              alpha: 0.14,
            ),
          ),
        ],
      ),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(
          16,
          9,
          16,
          28,
        ),
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD7DDE3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ==========================================================
          // COLLAPSED HEADER
          //
          // This is what user sees initially:
          // Walker + Dog name.
          // ==========================================================

          _collapsedSummary(session),

          const SizedBox(height: 18),

          // ==========================================================
          // ALL DETAILS
          //
          // User sees these after dragging the sheet upward.
          // ==========================================================

          _expandedContent(session),
        ],
      ),
    );
  }

  // ================================================================
  // WALKER + DOG SUMMARY
  // ================================================================

  Widget _collapsedSummary(
    LiveWalkSession session,
  ) {
    final photo = session.walkerPhoto.trim();

    final walkerName = session.walkerName.trim().isEmpty
        ? 'Walker'
        : session.walkerName.trim();

    final dogName = session.dogName.trim().isEmpty
        ? 'Your Dog'
        : session.dogName.trim();

    return Row(
      children: [
        // ==========================================================
        // WALKER PHOTO
        // ==========================================================

        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFF1F5F9),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: photo.isNotEmpty
              ? Image.network(
                  photo,
                  fit: BoxFit.cover,
                  errorBuilder: (
                    context,
                    error,
                    stackTrace,
                  ) {
                    return const Icon(
                      Icons.person_rounded,
                      color: Color(0xFF64748B),
                      size: 26,
                    );
                  },
                )
              : const Icon(
                  Icons.person_rounded,
                  color: Color(0xFF64748B),
                  size: 26,
                ),
        ),

        const SizedBox(width: 11),

        // ==========================================================
        // WALKER NAME
        // ==========================================================

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'WALKER',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                  color: Color(0xFF8A96A3),
                ),
              ),

              const SizedBox(height: 3),

              Row(
                children: [
                  Flexible(
                    child: Text(
                      walkerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: navy,
                      ),
                    ),
                  ),

                  const SizedBox(width: 4),

                  // GREEN VERIFIED BADGE
                  const Icon(
                    Icons.verified_rounded,
                    color: green,
                    size: 17,
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // ==========================================================
        // DOG NAME
        // ==========================================================

        Flexible(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.end,
            children: [
              const Text(
                'DOG',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                  color: Color(0xFF8A96A3),
                ),
              ),

              const SizedBox(height: 3),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.pets_rounded,
                    color: primary,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      dogName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: navy,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ================================================================
  // EXPANDED CONTENT
  // ================================================================

  Widget _expandedContent(
    LiveWalkSession session,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        // ==========================================================
        // LIVE STATUS
        // ==========================================================

        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF8EF),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  session.walkerLocation == null
                      ? 'Waiting for Walker location'
                      : 'Walker location is updating live',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: green,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ==========================================================
        // COUNTERS
        // ==========================================================

        LiveWalkStats(
          duration: _durationLabel(
            _liveElapsedSeconds,
          ),
          steps: session.steps,
          distance: session.distanceLabel,
          peeCount: session.peeCount,
          poopCount: session.poopCount,
        ),

        const SizedBox(height: 14),

        // ==========================================================
        // CALL + MESSAGE
        // ==========================================================

        Row(
          children: [
            Expanded(
              child: _actionButton(
                icon: Icons.call_rounded,
                label: 'Call',
                background: const Color(0xFFEAF8EF),
                foreground: green,
                onTap: _call,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _actionButton(
                icon: Icons.chat_bubble_rounded,
                label: 'Message',
                background: const Color(0xFFFFF1EB),
                foreground: primary,
                onTap: _chat,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // ==========================================================
        // VOICE INTRODUCTION
        // ==========================================================

        _voiceIntroductionButton(),
      ],
    );
  }

  // ================================================================
  // ACTION BUTTON
  // ================================================================

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color background,
    required Color foreground,
    required VoidCallback onTap,
  }) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: SizedBox(
          height: 58,
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: foreground,
                size: 21,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // VOICE INTRODUCTION
  // ================================================================

  Widget _voiceIntroductionButton() {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: _voiceInteraction,
          child: const SizedBox(
            height: 58,
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.mic_rounded,
                  color: navy,
                  size: 21,
                ),
                SizedBox(width: 8),
                Text(
                  'Voice Introduction',
                  style: TextStyle(
                    color: navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================================================================
  // CALL WALKER
  // ================================================================

  Future<void> _call() async {
    final session = _session;

    if (session == null) return;

    // IMPORTANT:
    // Call always uses WALKER phone number.
    final phone = session.walkerPhone.trim();

    if (phone.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Walker phone number is not available.',
          ),
        ),
      );
      return;
    }

    final uri = Uri(
      scheme: 'tel',
      path: phone,
    );

    try {
      final canLaunch = await canLaunchUrl(uri);

      if (!canLaunch) {
        throw Exception(
          'Cannot launch phone',
        );
      }

      await launchUrl(uri);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to open phone app.',
          ),
        ),
      );
    }
  }

  // ================================================================
  // MESSAGE
  // ================================================================

  void _chat() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Chat will open here.',
        ),
      ),
    );
  }

  // ================================================================
  // VOICE
  // ================================================================

  void _voiceInteraction() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Voice Introduction will open here.',
        ),
      ),
    );
  }

  // ================================================================
  // RECENTER
  // ================================================================

  void _recenter() {
    if (_session?.walkerLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Walker location is not available yet.',
          ),
        ),
      );
    }
  }

  // ================================================================
  // LOADING
  // ================================================================

  Widget _loadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: primary,
      ),
    );
  }

  // ================================================================
  // ERROR
  // ================================================================

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 52,
              color: Color(0xFF94A3B8),
            ),

            const SizedBox(height: 14),

            const Text(
              'Live Walk unavailable',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: navy,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),

            const SizedBox(height: 18),

            ElevatedButton(
              onPressed: _retry,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // EMPTY
  // ================================================================

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.directions_walk_rounded,
              size: 52,
              color: Color(0xFF94A3B8),
            ),

            const SizedBox(height: 14),

            const Text(
              'Live Walk not found',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: navy,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'The live walk session is not available right now.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),

            const SizedBox(height: 18),

            ElevatedButton(
              onPressed: _retry,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // DISPOSE
  // ================================================================

  @override
  void dispose() {
    _subscription?.cancel();
    _stopDurationTimer();
    super.dispose();
  }
}
