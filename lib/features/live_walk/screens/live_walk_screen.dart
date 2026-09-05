import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _ending = false;
  bool _closing = false;
  bool _hasError = false;

  String _errorMessage = '';

  double _sheetExtent = 0.25;

  static const Color navy = Color(0xFF263746);
  static const Color primary = Color(0xFFFF8A00);
  static const Color green = Color(0xFF16A34A);
  static const Color red = Color(0xFFDC2626);
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
        extendBodyBehindAppBar: true,
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
                  Positioned.fill(
                    child: LiveWalkMap(
                      walkerLocation: session.walkerLocation,
                      destination: session.ownerLocation,
                      routePoints: session.routePoints,
                      onRecenter: _recenter,
                    ),
                  ),

                  _topHeader(),

                  DraggableScrollableSheet(
                    initialChildSize: 0.25,
                    minChildSize: 0.25,
                    maxChildSize: 0.72,
                    snap: true,
                    snapSizes: const [
                      0.25,
                      0.72,
                    ],
                    builder: (context, scrollController) {
                      return _bottomSheet(
                        session,
                        scrollController,
                      );
                    },
                  ),

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

  Widget _topHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            10,
            16,
            0,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 16,
                      offset: const Offset(0, 5),
                      color: Colors.black.withValues(alpha: 0.10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '🐾',
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LIVE WALK',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                            color: navy,
                          ),
                        ),
                        SizedBox(height: 1),
                        Text(
                          'Live location & walk tracking',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF718096),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4E8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        color: primary,
                        size: 17,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _myLocationButton() {
    return Material(
      color: Colors.white,
      elevation: 5,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
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
            color: Colors.black.withValues(alpha: 0.13),
          ),
        ],
      ),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(
          16,
          10,
          16,
          28,
        ),
        children: [
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

          const SizedBox(height: 14),

          _collapsedSummary(session),

          const SizedBox(height: 20),

          _expandedContent(session),
        ],
      ),
    );
  }

  Widget _collapsedSummary(LiveWalkSession session) {
    final photo = session.walkerPhoto.trim();

    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4E8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.pets_rounded,
                  color: primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dog',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8A96A3),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      session.dogName.isEmpty
                          ? 'Your Dog'
                          : session.dogName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: navy,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        Container(
          width: 42,
          height: 42,
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
                  errorBuilder: (_, __, ___) {
                    return const Icon(
                      Icons.person_rounded,
                      color: Color(0xFF64748B),
                      size: 23,
                    );
                  },
                )
              : const Icon(
                  Icons.person_rounded,
                  color: Color(0xFF64748B),
                  size: 23,
                ),
        ),

        const SizedBox(width: 9),

        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      session.walkerName.isEmpty
                          ? 'Walker'
                          : session.walkerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: navy,
                      ),
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.verified_rounded,
                    color: primary,
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF8EF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      color: green,
                      size: 7,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: green,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _expandedContent(LiveWalkSession session) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Live Walk',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: navy,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF8EF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.circle,
                    color: green,
                    size: 7,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'LIVE',
                    style: TextStyle(
                      color: green,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        Text(
          session.walkerLocation == null
              ? 'Waiting for Walker location'
              : 'Walker location is updating live',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF718096),
          ),
        ),

        const SizedBox(height: 16),

        LiveWalkStats(
          duration: _durationLabel(_liveElapsedSeconds),
          steps: session.steps,
          distance: session.distanceLabel,
          peeCount: session.peeCount,
          poopCount: session.poopCount,
        ),

        const SizedBox(height: 16),

        if (session.destinationAddress.isNotEmpty)
          _detailCard(
            icon: Icons.home_rounded,
            title: 'Destination',
            value: session.destinationAddress,
          ),

        if (session.destinationAddress.isNotEmpty)
          const SizedBox(height: 12),

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
                label: 'Chat',
                background: const Color(0xFFFFF4E8),
                foreground: primary,
                onTap: _chat,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _actionButton(
                icon: Icons.mic_rounded,
                label: 'Voice',
                background: const Color(0xFFF1F5F9),
                foreground: navy,
                onTap: _voiceInteraction,
              ),
            ),
          ],
        ),

        if (widget.isWalker) ...[
          const SizedBox(height: 14),
          _endWalkButton(session),
        ],
      ],
    );
  }

  Widget _detailCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE8EDF2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4E8),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: primary,
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8A96A3),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                    color: navy,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 13,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: foreground,
                size: 21,
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _endWalkButton(LiveWalkSession session) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: red,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _ending ? null : () => _endWalk(session),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 14,
            ),
            child: Center(
              child: _ending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.stop_circle_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'End Walk',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
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

  Future<void> _call() async {
    final session = _session;

    if (session == null) return;

    final phone = widget.isWalker
        ? session.ownerPhone
        : session.walkerPhone;

    if (phone.trim().isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number is not available.'),
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
        throw Exception('Cannot launch phone');
      }

      await launchUrl(uri);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open phone app.'),
        ),
      );
    }
  }

  void _chat() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chat will open here.'),
      ),
    );
  }

  void _voiceInteraction() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Voice interaction will open here.'),
      ),
    );
  }

  Future<void> _endWalk(LiveWalkSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'End Walk?',
            style: TextStyle(
              color: navy,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'Are you sure you want to end this walk?',
            style: TextStyle(
              color: Color(0xFF64748B),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF64748B),
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('End Walk'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _ending = true;
    });

    try {
      await _service.completeWalk(
        session: session,
      );

      if (!mounted) return;

      setState(() {
        _ending = false;
      });

      // Do NOT manually pop here.
      // Firestore listener detects completed status
      // and closes the screen with Navigator.pop(true).
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _ending = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _friendlyError(error),
          ),
        ),
      );
    }
  }

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

  Widget _loadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: primary,
      ),
    );
  }

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

  @override
  void dispose() {
    _subscription?.cancel();
    _stopDurationTimer();
    super.dispose();
  }
}
