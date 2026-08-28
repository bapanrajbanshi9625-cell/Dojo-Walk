// File location:
// lib/screens/live_walk_screen.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

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
  // FIRESTORE
  // ==========================================================

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static const String liveWalkSessionsCollection =
      'liveWalkSessions';

  StreamSubscription<
          QuerySnapshot<Map<String, dynamic>>>?
      _subscription;

  final MapController _mapController =
      MapController();

  Timer? _durationTimer;

  // ==========================================================
  // SESSION
  // ==========================================================

  String? _sessionDocumentId;

  bool _loading = true;

  bool _ending = false;

  bool _walkCompleted = false;

  bool _trackingStarted = false;

  bool _trackingEnded = false;

  bool _walkStarted = false;

  bool _walkEnded = false;

  // ==========================================================
  // OWNER
  // ==========================================================

  String _ownerId = '';

  String _ownerUid = '';

  String _ownerName = 'Owner';

  String _ownerPhone = '';

  // ==========================================================
  // WALKER
  // ==========================================================

  String _walkerId = '';

  String _walkerUid = '';

  String _walkerName = 'Walker';

  // ==========================================================
  // DOG
  // ==========================================================

  String _dogName = 'Dog';

  String _dogBreed = '';

  // ==========================================================
  // LOCATION
  // ==========================================================

  LatLng? _walkerLocation;

  LatLng? _destination;

  final List<LatLng> _routePoints =
      <LatLng>[];

  bool _didInitialCenter = false;

  // ==========================================================
  // STATS
  // ==========================================================

  String _duration = '00:00';

  String _distance = '0.0 km';

  int _steps = 0;

  int _peeCount = 0;

  int _poopCount = 0;

  // ==========================================================
  // ADDRESS
  // ==========================================================

  String _destinationAddress =
      'Destination not available';

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

    _listenToLiveWalkSession();
  }

  // ==========================================================
  // LISTEN TO LIVE WALK SESSION
  // ==========================================================

  void _listenToLiveWalkSession() {
    final String walkId =
        widget.activeWalkId.trim();

    if (walkId.isEmpty) {
      _setLoadingFinished();

      return;
    }

    debugPrint(
      'LiveWalkScreen: listening to '
      '$liveWalkSessionsCollection '
      'walkId=$walkId',
    );

    _subscription = _firestore
        .collection(
          liveWalkSessionsCollection,
        )
        .where(
          'walkId',
          isEqualTo: walkId,
        )
        .limit(1)
        .snapshots()
        .listen(
      _onSnapshot,
      onError: _onError,
    );
  }

  // ==========================================================
  // SNAPSHOT
  // ==========================================================

  void _onSnapshot(
    QuerySnapshot<Map<String, dynamic>>
        snapshot,
  ) {
    if (!mounted) {
      return;
    }

    if (snapshot.docs.isEmpty) {
      debugPrint(
        'LiveWalkScreen: no liveWalkSessions '
        'document found for walkId='
        '${widget.activeWalkId}',
      );

      setState(() {
        _loading = false;
      });

      return;
    }

    final QueryDocumentSnapshot<
        Map<String, dynamic>> document =
        snapshot.docs.first;

    _sessionDocumentId =
        document.id;

    final Map<String, dynamic> data =
        document.data();

    _readSessionData(data);

    if (!mounted) {
      return;
    }

    setState(() {
      _loading = false;
    });

    _startDurationTimer();

    _centerMapOnce();
  }

  // ==========================================================
  // ERROR
  // ==========================================================

  void _onError(Object error) {
    debugPrint(
      'LiveWalkScreen Firestore error: $error',
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
  }

  // ==========================================================
  // READ SESSION
  // ==========================================================

  void _readSessionData(
    Map<String, dynamic> data,
  ) {
    // ========================================================
    // OWNER
    // ========================================================

    _ownerId =
        _readString(data['ownerId']);

    _ownerUid =
        _readString(data['ownerUid']);

    _ownerName =
        _readString(data['ownerName']);

    if (_ownerName.isEmpty) {
      _ownerName = 'Owner';
    }

    _ownerPhone =
        _readString(data['ownerPhone']);

    // ========================================================
    // WALKER
    // ========================================================

    _walkerId =
        _readString(data['walkerId']);

    _walkerUid =
        _readString(data['walkerUid']);

    _walkerName =
        _readString(data['walkerName']);

    if (_walkerName.isEmpty) {
      _walkerName = 'Walker';
    }

    // ========================================================
    // DOG
    // ========================================================

    _dogName =
        _readString(data['dogName']);

    if (_dogName.isEmpty) {
      _dogName = 'Dog';
    }

    _dogBreed =
        _readString(data['dogBreed']);

    // ========================================================
    // CURRENT LOCATION
    // ========================================================

    _walkerLocation =
        _readLocation(
      data['currentLocation'],
    );

    // Fallback:
    // Some records may use lat/lng directly.

    if (_walkerLocation == null) {
      final double? lat =
          _readDouble(data['lat']);

      final double? lng =
          _readDouble(data['lng']);

      if (lat != null &&
          lng != null &&
          _validCoordinates(
            lat,
            lng,
          )) {
        _walkerLocation =
            LatLng(
          lat,
          lng,
        );
      }
    }

    // ========================================================
    // DESTINATION
    // ========================================================

    _destination =
        _readLocation(
      data['destinationLocation'],
    );

    // ========================================================
    // ADDRESS
    // ========================================================

    _destinationAddress =
        _readString(
      data['address'],
    );

    if (_destinationAddress.isEmpty) {
      _destinationAddress =
          _readString(
        data['destinationAddress'],
      );
    }

    if (_destinationAddress.isEmpty) {
      _destinationAddress =
          'Destination not available';
    }

    // ========================================================
    // DISTANCE
    // ========================================================

    final dynamic distance =
        data['distanceKm'];

    if (distance is num) {
      _distance =
          '${distance.toStringAsFixed(1)} km';
    } else {
      final String distanceText =
          _readString(distance);

      if (distanceText.isNotEmpty) {
        _distance =
            distanceText.contains('km')
                ? distanceText
                : '$distanceText km';
      }
    }

    // ========================================================
    // ELAPSED SECONDS
    // ========================================================

    final int elapsedSeconds =
        _readInt(
      data['elapsedSeconds'],
    );

    if (elapsedSeconds > 0) {
      _duration =
          _formatDuration(
        Duration(
          seconds: elapsedSeconds,
        ),
      );
    } else {
      final DateTime? startedAt =
          _readDate(
        data['startedAt'],
      );

      if (startedAt != null) {
        _duration =
            _formatDuration(
          DateTime.now()
              .difference(startedAt),
        );
      }
    }

    // ========================================================
    // STEPS
    // ========================================================

    _steps =
        _readInt(data['steps']);

    // ========================================================
    // PEE / POOP
    // ========================================================

    _peeCount =
        _readInt(data['peeCount']);

    _poopCount =
        _readInt(data['poopCount']);

    // ========================================================
    // FLAGS
    // ========================================================

    _trackingStarted =
        _readBool(
      data['trackingStarted'],
    );

    _trackingEnded =
        _readBool(
      data['trackingEnded'],
    );

    _walkStarted =
        _readBool(
      data['walkStarted'],
    );

    _walkEnded =
        _readBool(
      data['walkEnded'],
    );

    // ========================================================
    // STATUS
    // ========================================================

    final String status =
        _normalizeStatus(
      data['status'],
    );

    _walkCompleted =
        _trackingEnded ||
        _walkEnded ||
        status == 'completed' ||
        status == 'ended' ||
        status == 'cancelled';

    // ========================================================
    // ROUTE
    // ========================================================

    _readRouteCoordinates(
      data['routeCoordinates'],
    );
  }

  // ==========================================================
  // ROUTE COORDINATES
  // ==========================================================

  void _readRouteCoordinates(
    dynamic value,
  ) {
    if (value is! List) {
      return;
    }

    final List<LatLng> points =
        <LatLng>[];

    for (final dynamic item in value) {
      final LatLng? point =
          _readLocation(item);

      if (point != null) {
        points.add(point);
      }
    }

    if (points.isEmpty) {
      return;
    }

    _routePoints
      ..clear()
      ..addAll(points);
  }

  // ==========================================================
  // DURATION TIMER
  // ==========================================================

  void _startDurationTimer() {
    if (_durationTimer != null) {
      return;
    }

    _durationTimer =
        Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted ||
            _walkCompleted) {
          return;
        }

        _updateDurationFromFirestore();
      },
    );
  }

  void _updateDurationFromFirestore() {
    // The Firestore listener supplies the
    // latest elapsedSeconds/startedAt.
    //
    // We only locally increment when the
    // walk is actively running.

    if (!_walkStarted ||
        _walkEnded ||
        _trackingEnded) {
      return;
    }

    final int currentSeconds =
        _durationToSeconds(
      _duration,
    );

    final int nextSeconds =
        currentSeconds + 1;

    setState(() {
      _duration =
          _formatDuration(
        Duration(
          seconds: nextSeconds,
        ),
      );
    });
  }

  int _durationToSeconds(
    String value,
  ) {
    final List<String> parts =
        value.split(':');

    if (parts.length == 2) {
      final int minutes =
          int.tryParse(parts[0]) ?? 0;

      final int seconds =
          int.tryParse(parts[1]) ?? 0;

      return minutes * 60 + seconds;
    }

    if (parts.length == 3) {
      final int hours =
          int.tryParse(parts[0]) ?? 0;

      final int minutes =
          int.tryParse(parts[1]) ?? 0;

      final int seconds =
          int.tryParse(parts[2]) ?? 0;

      return hours * 3600 +
          minutes * 60 +
          seconds;
    }

    return 0;
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: lightBg,
      body: SafeArea(
        child: _loading
            ? const Center(
                child:
                    CircularProgressIndicator(
                  color: primary,
                ),
              )
            : Column(
                children: [
                  _buildTopBar(),

                  Expanded(
                    child: _buildMap(),
                  ),

                  _buildBottomPanel(),
                ],
              ),
      ),
    );
  }

  // ==========================================================
  // TOP BAR
  // ==========================================================

  Widget _buildTopBar() {
    final bool live =
        !_walkCompleted &&
        (_walkStarted ||
            _trackingStarted);

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
                  live
                      ? 'LIVE WALK'
                      : _walkCompleted
                          ? 'WALK COMPLETED'
                          : 'ACTIVE WALK',
                  style: TextStyle(
                    color:
                        live ? green : primary,
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w900,
                    letterSpacing: .8,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  _dogBreed.isEmpty
                      ? _dogName
                      : '$_dogName • $_dogBreed',
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
            decoration: BoxDecoration(
              color:
                  (_walkCompleted
                          ? red
                          : live
                              ? green
                              : primary)
                      .withOpacity(.10),
              borderRadius:
                  BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  color:
                      _walkCompleted
                          ? red
                          : live
                              ? green
                              : primary,
                  size: 7,
                ),

                const SizedBox(width: 4),

                Text(
                  _walkCompleted
                      ? 'ENDED'
                      : live
                          ? 'LIVE'
                          : 'ACTIVE',
                  style: TextStyle(
                    color:
                        _walkCompleted
                            ? red
                            : live
                                ? green
                                : primary,
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

  Widget _buildMap() {
    final LatLng center =
        _walkerLocation ??
            _destination ??
            const LatLng(
              28.6139,
              77.2090,
            );

    return Stack(
      children: [
        FlutterMap(
          mapController:
              _mapController,

          options:
              MapOptions(
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
                if (_destination != null)
                  Marker(
                    point:
                        _destination!,
                    width: 54,
                    height: 64,
                    child:
                        _destinationMarker(),
                  ),

                if (_walkerLocation != null)
                  Marker(
                    point:
                        _walkerLocation!,
                    width: 60,
                    height: 70,
                    child:
                        _walkerMarker(),
                  ),
              ],
            ),
          ],
        ),

        // ======================================================
        // MAP STATUS
        // ======================================================

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
              boxShadow: const [
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
                  Icons.location_on_rounded,
                  size: 17,
                  color:
                      _walkerLocation != null
                          ? green
                          : Colors.grey,
                ),

                const SizedBox(
                  width: 6,
                ),

                Text(
                  _walkerLocation != null
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

        // ======================================================
        // RECENTER
        // ======================================================

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
              child:
                  const SizedBox(
                width: 46,
                height: 46,
                child: Icon(
                  Icons
                      .my_location_rounded,
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
            Icons
                .directions_walk_rounded,
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

  Widget _buildBottomPanel() {
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
            _buildWalkerInfo(),

            const SizedBox(height: 10),

            _buildDestination(),

            const SizedBox(height: 10),

            _buildStats(),

            const SizedBox(height: 9),

            _buildToiletStats(),

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

                const SizedBox(width: 8),

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

                const SizedBox(width: 8),

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

            const SizedBox(height: 10),

            // ==================================================
            // WALKER ONLY
            // ==================================================

            if (widget.isWalker &&
                !_walkCompleted)
              SizedBox(
                width:
                    double.infinity,
                height: 46,
                child:
                    ElevatedButton.icon(
                  onPressed:
                      _ending
                          ? null
                          : _endWalk,
                  icon: _ending
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
                    disabledBackgroundColor:
                        navy.withOpacity(
                      .5,
                    ),
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
        ),
      ),
    );
  }

  // ==========================================================
  // WALKER INFO
  // ==========================================================

  Widget _buildWalkerInfo() {
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
                  primary.withOpacity(
                .10,
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
                const Text(
                  'WALKER',
                  style:
                      TextStyle(
                    color: slate,
                    fontSize: 8,
                    fontWeight:
                        FontWeight.w900,
                    letterSpacing: .6,
                  ),
                ),

                const SizedBox(
                  height: 2,
                ),

                Text(
                  _walkerName,
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

                if (_walkerUid
                    .isNotEmpty)
                  Text(
                    'UID: $_walkerUid',
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

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 5,
            ),
            decoration:
                BoxDecoration(
              color:
                  (_walkCompleted
                          ? red
                          : green)
                      .withOpacity(.10),
              borderRadius:
                  BorderRadius.circular(
                20,
              ),
            ),
            child: Text(
              _walkCompleted
                  ? 'ENDED'
                  : 'ACTIVE',
              style:
                  TextStyle(
                color:
                    _walkCompleted
                        ? red
                        : green,
                fontSize: 9,
                fontWeight:
                    FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // DESTINATION
  // ==========================================================

  Widget _buildDestination() {
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
                  primary.withOpacity(
                .10,
              ),
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
                  style:
                      TextStyle(
                    color: slate,
                    fontSize: 8,
                    fontWeight:
                        FontWeight.w900,
                    letterSpacing: .5,
                  ),
                ),

                const SizedBox(
                  height: 2,
                ),

                Text(
                  _destinationAddress,
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

  Widget _buildStats() {
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
            Icons
                .directions_walk_rounded,
            'Steps',
            '$_steps',
          ),
        ),

        const SizedBox(width: 7),

        Expanded(
          child: _statCard(
            Icons.route_rounded,
            'Distance',
            _distance,
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

  Widget _buildToiletStats() {
    return Row(
      children: [
        Expanded(
          child: _toiletCard(
            icon:
                Icons.water_drop_rounded,
            title: 'Pee',
            value: _peeCount,
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: _toiletCard(
            icon:
                Icons.eco_rounded,
            title: 'Poop',
            value: _poopCount,
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
  // ACTION BUTTON
  // ==========================================================

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 42,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(
          icon,
          size: 16,
          color: color,
        ),
        label: Text(
          label,
          style:
              TextStyle(
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
  // RECENTER
  // ==========================================================

  void _recenterOnWalker() {
    final LatLng? location =
        _walkerLocation;

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

  void _centerMapOnce() {
    if (_didInitialCenter) {
      return;
    }

    final LatLng? location =
        _walkerLocation ??
            _destination;

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
  // CALL WALKER
  // ==========================================================

  Future<void> _callWalker() async {
    final String phone =
        _ownerPhone.isNotEmpty &&
                !widget.isWalker
            ? _walkerPhoneFromData()
            : _ownerPhone;

    if (phone.isEmpty) {
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

  String _walkerPhoneFromData() {
    return '';
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
  // END WALK
  // ==========================================================

  Future<void> _endWalk() async {
    if (_ending) {
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
            style:
                TextStyle(
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
                backgroundColor:
                    red,
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
      // ======================================================
      // SESSION DOCUMENT
      // ======================================================

      DocumentReference<
              Map<String, dynamic>>?
          sessionRef;

      if (_sessionDocumentId != null) {
        sessionRef = _firestore
            .collection(
              liveWalkSessionsCollection,
            )
            .doc(_sessionDocumentId);
      } else {
        final QuerySnapshot<
                Map<String, dynamic>>
            query =
            await _firestore
                .collection(
                  liveWalkSessionsCollection,
                )
                .where(
                  'walkId',
                  isEqualTo:
                      widget.activeWalkId,
                )
                .limit(1)
                .get();

        if (query.docs.isNotEmpty) {
          sessionRef =
              query.docs.first.reference;
        }
      }

      if (sessionRef == null) {
        throw Exception(
          'Live walk session not found.',
        );
      }

      // ======================================================
      // FINAL ROUTE
      // ======================================================

      final List<GeoPoint>
          finalRoute =
          _routePoints
              .map(
                (LatLng point) =>
                    GeoPoint(
                  point.latitude,
                  point.longitude,
                ),
              )
              .toList();

      if (_walkerLocation != null) {
        final GeoPoint finalPoint =
            GeoPoint(
          _walkerLocation!.latitude,
          _walkerLocation!.longitude,
        );

        if (finalRoute.isEmpty ||
            finalRoute.last.latitude !=
                finalPoint.latitude ||
            finalRoute.last.longitude !=
                finalPoint.longitude) {
          finalRoute.add(
            finalPoint,
          );
        }
      }

      // ======================================================
      // END LIVE SESSION
      // ======================================================

      await sessionRef.update({
        'status': 'completed',

        'trackingEnded': true,

        'walkEnded': true,

        'endedAt':
            FieldValue.serverTimestamp(),

        'updatedAt':
            FieldValue.serverTimestamp(),

        'elapsedSeconds':
            _durationToSeconds(
          _duration,
        ),

        'distanceKm':
            _distanceToNumber(
          _distance,
        ),

        'peeCount':
            _peeCount,

        'poopCount':
            _poopCount,

        'routeCoordinates':
            finalRoute,

        'currentLocation':
            _walkerLocation != null
                ? GeoPoint(
                    _walkerLocation!
                        .latitude,
                    _walkerLocation!
                        .longitude,
                  )
                : null,
      });

      // ======================================================
      // SAVE HISTORY
      // ======================================================

      await _firestore
          .collection('walk_history')
          .doc(widget.activeWalkId)
          .set(
        {
          'walkId':
              widget.activeWalkId,

          'status':
              'completed',

          'ownerId':
              _ownerId,

          'ownerUid':
              _ownerUid,

          'ownerName':
              _ownerName,

          'ownerPhone':
              _ownerPhone,

          'walkerId':
              _walkerId,

          'walkerUid':
              _walkerUid,

          'walkerName':
              _walkerName,

          'dogName':
              _dogName,

          'dogBreed':
              _dogBreed,

          'startedAt':
              _readDateForHistory(),

          'endedAt':
              FieldValue.serverTimestamp(),

          'duration':
              _duration,

          'elapsedSeconds':
              _durationToSeconds(
            _duration,
          ),

          'distanceKm':
              _distanceToNumber(
            _distance,
          ),

          'peeCount':
              _peeCount,

          'poopCount':
              _poopCount,

          'routeCoordinates':
              finalRoute,

          'completedAt':
              FieldValue.serverTimestamp(),

          'createdAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _walkCompleted = true;
        _ending = false;
      });

      // Give Firestore listener time to
      // receive completed status.
      await Future<void>.delayed(
        const Duration(
          milliseconds: 400,
        ),
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint(
        'End live walk error: $e',
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
  // DISTANCE NUMBER
  // ==========================================================

  double _distanceToNumber(
    String value,
  ) {
    String clean =
        value
            .replaceAll(
              'km',
              '',
            )
            .trim();

    return double.tryParse(
          clean,
        ) ??
        0.0;
  }

  // ==========================================================
  // START DATE FOR HISTORY
  // ==========================================================

  DateTime? _readDateForHistory() {
    return null;
  }

  // ==========================================================
  // LOADING
  // ==========================================================

  void _setLoadingFinished() {
    if (!mounted) {
      return;
    }

    setState(() {
      _loading = false;
    });
  }

  // ==========================================================
  // STRING
  // ==========================================================

  String _readString(
    dynamic value,
  ) {
    if (value == null) {
      return '';
    }

    return value
        .toString()
        .trim();
  }

  // ==========================================================
  // INT
  // ==========================================================

  int _readInt(
    dynamic value,
  ) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  // ==========================================================
  // DOUBLE
  // ==========================================================

  double? _readDouble(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value?.toString() ?? '',
    );
  }

  // ==========================================================
  // BOOL
  // ==========================================================

  bool _readBool(
    dynamic value,
  ) {
    if (value is bool) {
      return value;
    }

    return value
            ?.toString()
            .toLowerCase() ==
        'true';
  }

  // ==========================================================
  // LOCATION
  // ==========================================================

  LatLng? _readLocation(
    dynamic value,
  ) {
    if (value is GeoPoint) {
      if (!_validCoordinates(
        value.latitude,
        value.longitude,
      )) {
        return null;
      }

      return LatLng(
        value.latitude,
        value.longitude,
      );
    }

    if (value is Map) {
      final dynamic lat =
          value['lat'] ??
              value['latitude'];

      final dynamic lng =
          value['lng'] ??
              value['longitude'];

      final double? latitude =
          _readDouble(lat);

      final double? longitude =
          _readDouble(lng);

      if (latitude != null &&
          longitude != null &&
          _validCoordinates(
            latitude,
            longitude,
          )) {
        return LatLng(
          latitude,
          longitude,
        );
      }
    }

    return null;
  }

  // ==========================================================
  // VALID COORDINATES
  // ==========================================================

  bool _validCoordinates(
    double latitude,
    double longitude,
  ) {
    if (latitude == 0 &&
        longitude == 0) {
      return false;
    }

    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  // ==========================================================
  // DATE
  // ==========================================================

  DateTime? _readDate(
    dynamic value,
  ) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(
        value,
      );
    }

    return null;
  }

  // ==========================================================
  // STATUS
  // ==========================================================

  String _normalizeStatus(
    dynamic value,
  ) {
    String status =
        _readString(value)
            .toLowerCase()
            .trim();

    status = status.replaceAll(
      RegExp(r'\s+'),
      '_',
    );

    status = status.replaceAll(
      '-',
      '_',
    );

    while (status.contains('__')) {
      status =
          status.replaceAll(
        '__',
        '_',
      );
    }

    if (status ==
        'on_that_way') {
      return 'on_the_way';
    }

    if (status ==
        'ontheway') {
      return 'on_the_way';
    }

    if (status ==
        'on_way') {
      return 'on_the_way';
    }

    return status;
  }

  // ==========================================================
  // FORMAT DURATION
  // ==========================================================

  String _formatDuration(
    Duration duration,
  ) {
    if (duration.isNegative) {
      return '00:00';
    }

    final int hours =
        duration.inHours;

    final int minutes =
        duration.inMinutes
            .remainder(60);

    final int seconds =
        duration.inSeconds
            .remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
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
