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

  final MapController _mapController =
      MapController();

  StreamSubscription<
      DocumentSnapshot<Map<String, dynamic>>>?
      _subscription;

  // ==========================================================
  // STATE
  // ==========================================================

  LatLng? _walkerLocation;
  LatLng? _destination;

  String _dogName = 'Dog';
  String _dogBreed = 'Breed not available';
  String _walkerName = 'Walker';
  String _walkerPhone = '';
  String _destinationAddress = 'Destination not available';

  String _duration = '00:00';
  String _distance = '0.0 km';

  int _steps = 0;
  int _peeCount = 0;
  int _poopCount = 0;

  bool _loading = true;
  bool _ending = false;

  Timer? _timer;

  DateTime? _startedAt;

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

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _listenToWalk();
  }

  // ==========================================================
  // FIRESTORE LISTENER
  // ==========================================================

  void _listenToWalk() {
    _subscription = _firestore
        .collection('active_walk')
        .doc(widget.activeWalkId)
        .snapshots()
        .listen(
      (DocumentSnapshot<Map<String, dynamic>>
          snapshot) {
        if (!snapshot.exists) {
          return;
        }

        final Map<String, dynamic> data =
            snapshot.data() ??
                <String, dynamic>{};

        _readWalkData(data);

        if (!mounted) {
          return;
        }

        setState(() {
          _loading = false;
        });
      },
      onError: (Object error) {
        debugPrint(
          'Live walk listener error: $error',
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
  // READ FIRESTORE DATA
  // ==========================================================

  void _readWalkData(
    Map<String, dynamic> data,
  ) {
    _dogName =
        _readString(
          data['dogName'],
        ) ??
        _readString(
          data['petName'],
        ) ??
        'Dog';

    _dogBreed =
        _readString(
          data['dogBreed'],
        ) ??
        _readString(
          data['breed'],
        ) ??
        'Breed not available';

    _walkerName =
        _readString(
          data['walkerName'],
        ) ??
        'Walker';

    _walkerPhone =
        _readString(
          data['walkerPhone'],
        ) ??
        '';

    _destinationAddress =
        _readString(
          data['address'],
        ) ??
        _readString(
          data['destinationAddress'],
        ) ??
        'Destination not available';

    _distance =
        _readString(
          data['distance'],
        ) ??
        '0.0 km';

    _steps =
        _readInt(
          data['steps'],
        );

    _peeCount =
        _readInt(
          data['peeCount'],
        );

    _poopCount =
        _readInt(
          data['poopCount'],
        );

    _walkerLocation =
        _readGeoPoint(
          data['walkerLocation'],
        ) ??
        _readGeoPoint(
          data['currentLocation'],
        );

    _destination =
        _readGeoPoint(
          data['ownerLocation'],
        ) ??
        _readGeoPoint(
          data['destinationLocation'],
        );

    _startedAt =
        _readDate(
          data['startedAt'],
        );

    _updateDuration();
  }

  // ==========================================================
  // DURATION
  // ==========================================================

  void _updateDuration() {
    final DateTime? start =
        _startedAt;

    if (start == null) {
      return;
    }

    _timer ??= Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) {
          return;
        }

        setState(() {
          final Duration difference =
              DateTime.now().difference(
            start,
          );

          _duration =
              _formatDuration(
            difference,
          );
        });
      },
    );
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
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F8F9),
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
                    child:
                        _buildMap(),
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
    return Container(
      height: 66,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 15,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
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
                const Text(
                  'LIVE WALK',
                  style: TextStyle(
                    color: primary,
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w900,
                    letterSpacing: .8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$_dogName • $_dogBreed',
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
                  green.withOpacity(.10),
              borderRadius:
                  BorderRadius.circular(20),
            ),
            child: const Row(
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
  // OSM MAP
  //
  // NO POLYLINE HERE
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

        // ====================================================
        // RECENTER
        // ====================================================

        Positioned(
          right: 14,
          top: 14,
          child: Material(
            color: Colors.white,
            elevation: 3,
            borderRadius:
                BorderRadius.circular(13),
            child: InkWell(
              borderRadius:
                  BorderRadius.circular(13),
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
                color:
                    Colors.black26,
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
                color:
                    Colors.black26,
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
      padding:
          const EdgeInsets.fromLTRB(
        15,
        13,
        15,
        14,
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
      child: Column(
        children: [
          _buildDestination(),

          const SizedBox(height: 12),

          _buildStats(),

          const SizedBox(height: 11),

          _buildToiletStats(),

          const SizedBox(height: 12),

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
                  icon: Icons
                      .location_on_rounded,
                  label: 'Map',
                  color: primary,
                  onTap:
                      _recenterOnWalker,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
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
          const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color:
            const Color(0xFFF7F8F9),
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
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
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
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
                  _destinationAddress,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    color: navy,
                    fontSize: 12,
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
  // STATS
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
            Icons.directions_walk_rounded,
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
        vertical: 9,
        horizontal: 5,
      ),
      decoration: BoxDecoration(
        color:
            const Color(0xFFF7F8F9),
        borderRadius:
            BorderRadius.circular(12),
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
            style: const TextStyle(
              color: navy,
              fontSize: 12,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            title,
            style: const TextStyle(
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
            icon: Icons.water_drop_rounded,
            title: 'Pee',
            value: _peeCount,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _toiletCard(
            icon: Icons.eco_rounded,
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
      height: 42,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
      ),
      decoration: BoxDecoration(
        color:
            const Color(0xFFF7F8F9),
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color:
              const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: primary,
            size: 18,
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
  // RECENTER
  // ==========================================================

  void _recenterOnWalker() {
    final LatLng? location =
        _walkerLocation;

    if (location == null) {
      return;
    }

    _mapController.move(
      location,
      17,
    );
  }

  // ==========================================================
  // CALL
  // ==========================================================

  Future<void> _callWalker() async {
    if (_walkerPhone
        .trim()
        .isEmpty) {
      return;
    }

    final Uri uri = Uri(
      scheme: 'tel',
      path:
          _walkerPhone.trim(),
    );

    await launchUrl(uri);
  }

  // ==========================================================
  // CHAT
  // ==========================================================

  void _openChat() {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Chat screen will open here.',
        ),
      ),
    );
  }

  // ==========================================================
  // END WALK
  //
  // Polyline/history saving should happen
  // inside the ActiveWalkService.
  // ==========================================================

  Future<void> _endWalk() async {
    if (_ending) {
      return;
    }

    final bool? confirm =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'End Walk?',
          ),
          content: const Text(
            'Are you sure you want to end this walk?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
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
                  context,
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
      // ------------------------------------------------------
      // IMPORTANT:
      // Replace this update with your existing
      // ActiveWalkService.endWalk() once that method
      // is connected to your History collection.
      // ------------------------------------------------------

      await _firestore
          .collection('active_walk')
          .doc(widget.activeWalkId)
          .update({
        'status': 'completed',
        'endedAt':
            FieldValue.serverTimestamp(),
      });

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
        const SnackBar(
          content: Text(
            'Unable to end walk.',
          ),
        ),
      );
    }
  }

  // ==========================================================
  // HELPERS
  // ==========================================================

  String? _readString(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    final String result =
        value.toString().trim();

    return result.isEmpty
        ? null
        : result;
  }

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

  GeoPoint? _readGeoPoint(
    dynamic value,
  ) {
    if (value is GeoPoint) {
      return value;
    }

    return null;
  }

  LatLng? _readLatLng(
    dynamic value,
  ) {
    if (value is GeoPoint) {
      return LatLng(
        value.latitude,
        value.longitude,
      );
    }

    return null;
  }

  DateTime? _readDate(
    dynamic value,
  ) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
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
