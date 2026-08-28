// File:
// lib/screens/live_walk_screen.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../features/active_walk/models/active_walk.dart';
import '../features/active_walk/services/active_walk_service.dart';

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
  // ==========================================================
  // SERVICE
  // ==========================================================

  final ActiveWalkService _activeWalkService =
      ActiveWalkService();

  final MapController _mapController =
      MapController();

  StreamSubscription<ActiveWalk?>?
      _subscription;

  Timer? _durationTimer;

  // ==========================================================
  // WALK
  // ==========================================================

  ActiveWalk? _walk;

  final List<LatLng> _routePoints =
      <LatLng>[];

  String _duration = '00:00';

  bool _loading = true;
  bool _ending = false;
  bool _didInitialCenter = false;

  // ==========================================================
  // COLORS
  // ==========================================================

  static const Color navy =
      Color(0xFF263746);

  static const Color primary =
      Color(0xFFFF8A00);

  static const Color green =
      Color(0xFF16A34A);

  static const Color blue =
      Color(0xFF238EAE);

  static const Color red =
      Color(0xFFDC2626);

  static const Color slate =
      Color(0xFF475569);

  static const Color lightBg =
      Color(0xFFF7F8F9);

  static const Color border =
      Color(0xFFE5E7EB);

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _listenToWalk();
  }

  // ==========================================================
  // LISTENER
  // ==========================================================

  void _listenToWalk() {
    _subscription =
        _activeWalkService
            .watchActiveWalk(
              widget.activeWalkId,
            )
            .listen(
      (ActiveWalk? walk) {
        if (!mounted) {
          return;
        }

        if (walk == null) {
          setState(() {
            _loading = false;
            _walk = null;
          });

          return;
        }

        setState(() {
          _walk = walk;
          _loading = false;
        });

        _updateRoute(walk);

        _startDurationTimer(walk);

        _centerMapOnce(walk);
      },
      onError: (Object error) {
        debugPrint(
          'LiveWalkScreen error: $error',
        );

        if (!mounted) {
          return;
        }

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

  // ==========================================================
  // ROUTE
  // ==========================================================

  void _updateRoute(
    ActiveWalk walk,
  ) {
    final List<LatLng> points =
        walk.routePoints
            .map(
              (point) => LatLng(
                point.latitude,
                point.longitude,
              ),
            )
            .toList();

    if (points.isEmpty) {
      return;
    }

    _routePoints
      ..clear()
      ..addAll(points);

    final GeoPoint? location =
        walk.walkerLocation;

    if (location == null) {
      return;
    }

    final LatLng latest =
        LatLng(
      location.latitude,
      location.longitude,
    );

    if (_routePoints.isEmpty ||
        _routePoints.last.latitude !=
            latest.latitude ||
        _routePoints.last.longitude !=
            latest.longitude) {
      _routePoints.add(latest);
    }
  }

  // ==========================================================
  // DURATION
  // ==========================================================

  void _startDurationTimer(
    ActiveWalk walk,
  ) {
    final DateTime? startedAt =
        walk.startedAt;

    if (startedAt == null) {
      return;
    }

    _durationTimer ??=
        Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) {
          return;
        }

        if (walk.isCompleted) {
          return;
        }

        final Duration difference =
            DateTime.now()
                .difference(startedAt);

        setState(() {
          _duration =
              _formatDuration(
            difference,
          );
        });
      },
    );

    final Duration difference =
        DateTime.now()
            .difference(startedAt);

    _duration =
        _formatDuration(difference);
  }

  String _formatDuration(
    Duration duration,
  ) {
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

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: lightBg,
        body: Center(
          child: CircularProgressIndicator(
            color: primary,
          ),
        ),
      );
    }

    final ActiveWalk? walk = _walk;

    if (walk == null) {
      return _buildUnavailable();
    }

    return Scaffold(
      backgroundColor: lightBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(walk),

            Expanded(
              child: _buildMap(walk),
            ),

            _buildBottomPanel(walk),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // UNAVAILABLE
  // ==========================================================

  Widget _buildUnavailable() {
    return Scaffold(
      backgroundColor: lightBg,
      body: Center(
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons.directions_walk_rounded,
              size: 55,
              color: Colors.black38,
            ),
            const SizedBox(height: 12),
            const Text(
              'Live walk not available',
              style: TextStyle(
                color: navy,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Go Back',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // TOP BAR
  // ==========================================================

  Widget _buildTopBar(
    ActiveWalk walk,
  ) {
    final bool completed =
        walk.isCompleted;

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
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: navy,
            ),
          ),

          const SizedBox(width: 3),

          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isWalker
                      ? 'LIVE WALK'
                      : 'LIVE WALK',
                  style:
                      const TextStyle(
                    color: primary,
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w900,
                    letterSpacing: .8,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  '${walk.dogName} • ${walk.dogBreed}',
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
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
            decoration:
                BoxDecoration(
              color: completed
                  ? red.withOpacity(.10)
                  : green.withOpacity(.10),
              borderRadius:
                  BorderRadius.circular(
                20,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 7,
                  color: completed
                      ? red
                      : green,
                ),
                const SizedBox(
                  width: 4,
                ),
                Text(
                  completed
                      ? 'ENDED'
                      : 'LIVE',
                  style: TextStyle(
                    color: completed
                        ? red
                        : green,
                    fontSize: 8,
                    fontWeight:
                        FontWeight.w900,
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
  // MAP
  // ==========================================================

  Widget _buildMap(
    ActiveWalk walk,
  ) {
    final LatLng center =
        _latLng(
              walk.walkerLocation,
            ) ??
            _latLng(
              walk.ownerLocation,
            ) ??
            const LatLng(
              28.6139,
              77.2090,
            );

    return Stack(
      children: [
        FlutterMap(
          mapController:
              _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 16,
            minZoom: 3,
            maxZoom: 19,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName:
                  'com.doojowalker.app',
            ),

            if (_routePoints.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points:
                        _routePoints,
                    strokeWidth: 5,
                    color: primary,
                  ),
                ],
              ),

            MarkerLayer(
              markers: [
                if (walk.ownerLocation !=
                    null)
                  Marker(
                    point:
                        _latLng(
                      walk.ownerLocation,
                    )!,
                    width: 54,
                    height: 64,
                    child:
                        _destinationMarker(),
                  ),

                if (walk.walkerLocation !=
                    null)
                  Marker(
                    point:
                        _latLng(
                      walk.walkerLocation,
                    )!,
                    width: 60,
                    height: 70,
                    child:
                        _walkerMarker(),
                  ),
              ],
            ),
          ],
        ),

        // ------------------------------------------------------
        // LIVE LABEL
        // ------------------------------------------------------

        Positioned(
          left: 14,
          top: 14,
          child: Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            decoration:
                BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(
                10,
              ),
              boxShadow:
                  const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  size: 9,
                  color:
                      walk.walkerLocation !=
                              null
                          ? green
                          : Colors.grey,
                ),
                const SizedBox(
                  width: 6,
                ),
                Text(
                  walk.walkerLocation !=
                          null
                      ? 'Live Location'
                      : 'Waiting for location',
                  style:
                      const TextStyle(
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ------------------------------------------------------
        // RECENTER
        // ------------------------------------------------------

        Positioned(
          right: 14,
          top: 14,
          child: Material(
            color: Colors.white,
            elevation: 3,
            borderRadius:
                BorderRadius.circular(
              13,
            ),
            child: InkWell(
              borderRadius:
                  BorderRadius.circular(
                13,
              ),
              onTap:
                  _recenterOnWalker,
              child: const SizedBox(
                width: 46,
                height: 46,
                child: Icon(
                  Icons.my_location_rounded,
                  color: primary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // WALKER MARKER
  // ==========================================================

  Widget _walkerMarker() {
    return Column(
      children: [
        Container(
          width: 43,
          height: 43,
          decoration:
              BoxDecoration(
            color: primary,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 4,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
              ),
            ],
          ),
          child: const Icon(
            Icons.directions_walk_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const Icon(
          Icons.arrow_drop_down,
          color: primary,
          size: 18,
        ),
      ],
    );
  }

  // ==========================================================
  // DESTINATION MARKER
  // ==========================================================

  Widget _destinationMarker() {
    return Column(
      children: [
        Container(
          width: 43,
          height: 43,
          decoration:
              BoxDecoration(
            color: red,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 4,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
              ),
            ],
          ),
          child: const Icon(
            Icons.home_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const Icon(
          Icons.arrow_drop_down,
          color: red,
          size: 18,
        ),
      ],
    );
  }

  // ==========================================================
  // BOTTOM PANEL
  // ==========================================================

  Widget _buildBottomPanel(
    ActiveWalk walk,
  ) {
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
      decoration:
          const BoxDecoration(
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
            _buildWalkerInfo(walk),

            const SizedBox(height: 10),

            _buildDestination(walk),

            const SizedBox(height: 10),

            _buildStats(walk),

            const SizedBox(height: 9),

            _buildToiletStats(walk),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child:
                      _actionButton(
                    icon:
                        Icons.call_rounded,
                    label: 'Call',
                    color: green,
                    onTap:
                        _callWalker,
                  ),
                ),

                const SizedBox(
                  width: 8,
                ),

                Expanded(
                  child:
                      _actionButton(
                    icon:
                        Icons.chat_rounded,
                    label: 'Chat',
                    color: blue,
                    onTap:
                        _openChat,
                  ),
                ),

                const SizedBox(
                  width: 8,
                ),

                Expanded(
                  child:
                      _actionButton(
                    icon:
                        Icons.location_on_rounded,
                    label: 'Map',
                    color: primary,
                    onTap:
                        _recenterOnWalker,
                  ),
                ),
              ],
            ),

            if (widget.isWalker &&
                !walk.isCompleted) ...[
              const SizedBox(height: 10),
              _buildEndWalkButton(),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // WALKER INFO
  // ==========================================================

  Widget _buildWalkerInfo(
    ActiveWalk walk,
  ) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(10),
      decoration:
          BoxDecoration(
        color: lightBg,
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        border: Border.all(
          color: border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration:
                BoxDecoration(
              color:
                  primary.withOpacity(.10),
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
                const Text(
                  'WALKER',
                  style: TextStyle(
                    color: slate,
                    fontSize: 8,
                    fontWeight:
                        FontWeight.w900,
                    letterSpacing: .6,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  walk.walkerName
                          .isEmpty
                      ? 'Walker'
                      : walk.walkerName,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    color: navy,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),

                if (walk.walkerUid
                    .isNotEmpty)
                  Text(
                    'UID: ${walk.walkerUid}',
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      color: slate,
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

  // ==========================================================
  // DESTINATION
  // ==========================================================

  Widget _buildDestination(
    ActiveWalk walk,
  ) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(10),
      decoration:
          BoxDecoration(
        color: lightBg,
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        border: Border.all(
          color: border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration:
                BoxDecoration(
              color:
                  primary.withOpacity(.10),
              borderRadius:
                  BorderRadius.circular(
                10,
              ),
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
                    color: slate,
                    fontSize: 8,
                    fontWeight:
                        FontWeight.w900,
                    letterSpacing: .5,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  walk.address.isEmpty
                      ? 'Destination not available'
                      : walk.address,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
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

  // ==========================================================
  // MAIN STATS
  // ==========================================================

  Widget _buildStats(
    ActiveWalk walk,
  ) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            Icons.timer_outlined,
            'Duration',
            _duration,
          ),
        ),

        const SizedBox(width: 7),

        Expanded(
          child: _statCard(
            Icons.directions_walk_rounded,
            'Steps',
            '${walk.steps}',
          ),
        ),

        const SizedBox(width: 7),

        Expanded(
          child: _statCard(
            Icons.route_rounded,
            'Distance',
            walk.distance.toString(),
          ),
        ),
      ],
    );
  }

  Widget _statCard(
    IconData icon,
    String title,
    String value,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical: 8,
        horizontal: 4,
      ),
      decoration:
          BoxDecoration(
        color: lightBg,
        borderRadius:
            BorderRadius.circular(
          12,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: primary,
            size: 18,
          ),

          const SizedBox(height: 3),

          Text(
            value,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style:
                const TextStyle(
              color: navy,
              fontSize: 12,
              fontWeight:
                  FontWeight.w900,
            ),
          ),

          const SizedBox(height: 1),

          Text(
            title,
            style:
                const TextStyle(
              color: slate,
              fontSize: 8,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // PEE / POOP
  // ==========================================================

  Widget _buildToiletStats(
    ActiveWalk walk,
  ) {
    return Row(
      children: [
        Expanded(
          child: _toiletCard(
            icon:
                Icons.water_drop_rounded,
            title: 'Pee',
            value: walk.peeCount,
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: _toiletCard(
            icon:
                Icons.eco_rounded,
            title: 'Poop',
            value: walk.poopCount,
          ),
        ),
      ],
    );
  }

  Widget _toiletCard({
    required IconData icon,
    required String title,
    required int value,
  }) {
    return Container(
      height: 40,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
      ),
      decoration:
          BoxDecoration(
        color: lightBg,
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        border: Border.all(
          color: border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: primary,
            size: 17,
          ),

          const SizedBox(width: 7),

          Text(
            title,
            style:
                const TextStyle(
              color: slate,
              fontSize: 11,
              fontWeight:
                  FontWeight.w700,
            ),
          ),

          const Spacer(),

          Text(
            '$value',
            style:
                const TextStyle(
              color: navy,
              fontSize: 14,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ACTION
  // ==========================================================

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 42,
      child:
          OutlinedButton.icon(
        onPressed: onTap,
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
              color.withOpacity(.05),
          side: BorderSide(
            color:
                color.withOpacity(.18),
          ),
          padding:
              EdgeInsets.zero,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              11,
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // END WALK BUTTON
  // ==========================================================

  Widget _buildEndWalkButton() {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child:
          ElevatedButton.icon(
        onPressed:
            _ending ? null : _endWalk,
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
          style:
              const TextStyle(
            fontWeight:
                FontWeight.w900,
          ),
        ),
        style:
            ElevatedButton.styleFrom(
          backgroundColor: navy,
          foregroundColor:
              Colors.white,
          disabledBackgroundColor:
              navy.withOpacity(.5),
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
    );
  }

  // ==========================================================
  // END WALK
  // ==========================================================

  Future<void> _endWalk() async {
    if (_ending) {
      return;
    }

    final ActiveWalk? walk =
        _walk;

    if (walk == null) {
      return;
    }

    final bool? confirm =
        await showDialog<bool>(
      context: context,
      builder:
          (
        BuildContext dialogContext,
      ) {
        return AlertDialog(
          title: const Text(
            'End Walk?',
            style: TextStyle(
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          content:
              const Text(
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
              child:
                  const Text(
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
              style:
                  ElevatedButton.styleFrom(
                backgroundColor: red,
                foregroundColor:
                    Colors.white,
              ),
              child:
                  const Text(
                'End Walk',
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _ending = true;
    });

    try {
      await _activeWalkService
          .endWalk(walk);

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

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to end walk: $e',
          ),
        ),
      );
    }
  }

  // ==========================================================
  // RECENTER
  // ==========================================================

  void _recenterOnWalker() {
    final ActiveWalk? walk =
        _walk;

    if (walk == null) {
      return;
    }

    final LatLng? location =
        _latLng(
      walk.walkerLocation,
    );

    if (location == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Walker location is not available yet.',
          ),
        ),
      );

      return;
    }

    _mapController.move(
      location,
      17,
    );
  }

  // ==========================================================
  // INITIAL CENTER
  // ==========================================================

  void _centerMapOnce(
    ActiveWalk walk,
  ) {
    if (_didInitialCenter) {
      return;
    }

    final LatLng? location =
        _latLng(
              walk.walkerLocation,
            ) ??
            _latLng(
              walk.ownerLocation,
            );

    if (location == null) {
      return;
    }

    _didInitialCenter = true;

    WidgetsBinding.instance
        .addPostFrameCallback(
      (_) {
        if (!mounted) {
          return;
        }

        _mapController.move(
          location,
          16,
        );
      },
    );
  }

  // ==========================================================
  // CALL
  // ==========================================================

  Future<void> _callWalker() async {
    final ActiveWalk? walk =
        _walk;

    if (walk == null) {
      return;
    }

    final String phone =
        walk.walkerPhone.trim();

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Walker phone number is not available.',
          ),
        ),
      );

      return;
    }

    final Uri uri = Uri(
      scheme: 'tel',
      path: phone,
    );

    try {
      final bool launched =
          await launchUrl(uri);

      if (!launched &&
          mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to open phone dialer.',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint(
        'Call error: $e',
      );
    }
  }

  // ==========================================================
  // CHAT
  // ==========================================================

  void _openChat() {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Chat will open here.',
        ),
      ),
    );
  }

  // ==========================================================
  // GEOPOINT
  // ==========================================================

  LatLng? _latLng(
    GeoPoint? point,
  ) {
    if (point == null) {
      return null;
    }

    return LatLng(
      point.latitude,
      point.longitude,
    );
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _subscription?.cancel();

    _durationTimer?.cancel();

    super.dispose();
  }
}
