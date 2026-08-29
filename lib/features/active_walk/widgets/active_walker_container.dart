import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/active_walk.dart';
import '../models/active_walk_mapper.dart';

class ActiveWalkerContainer extends StatefulWidget {
  const ActiveWalkerContainer({
    super.key,
    required this.activeWalkId,
    required this.isWalker,
    this.onLiveWalk,
  });

  final String activeWalkId;
  final bool isWalker;
  final VoidCallback? onLiveWalk;

  @override
  State<ActiveWalkerContainer> createState() =>
      _ActiveWalkerContainerState();
}

class _ActiveWalkerContainerState
    extends State<ActiveWalkerContainer> {
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
  // WALK
  // ==========================================================

  ActiveWalk? _walk;

  bool _loading = true;
  bool _updating = false;
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
    _listenToActiveWalk();
  }

  // ==========================================================
  // FIRESTORE LISTENER
  // COLLECTION = active_walks
  // ==========================================================

  void _listenToActiveWalk() {
    _subscription = _firestore
        .collection('active_walks')
        .doc(widget.activeWalkId)
        .snapshots()
        .listen(
      (
        DocumentSnapshot<Map<String, dynamic>> snapshot,
      ) {
        if (!snapshot.exists) {
          if (!mounted) {
            return;
          }

          setState(() {
            _loading = false;
            _walk = null;
          });

          return;
        }

        final ActiveWalk walk =
            ActiveWalkMapper.fromDocument(
          snapshot,
        );

        if (!mounted) {
          return;
        }

        setState(() {
          _walk = walk;
          _loading = false;
        });

        _centerMapOnce(walk);
      },
      onError: (Object error) {
        debugPrint(
          'ActiveWalkerContainer Firestore error: $error',
        );

        if (!mounted) {
          return;
        }

        setState(() {
          _loading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to load active walk.',
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: primary,
        ),
      );
    }

    final ActiveWalk? walk = _walk;

    if (walk == null) {
      return _buildNotAvailable();
    }

    return Scaffold(
      backgroundColor: lightBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(walk),
            Expanded(
              child: Stack(
                children: [
                  _buildMap(walk),
                  _buildBottomPanel(walk),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // NOT AVAILABLE
  // ==========================================================

  Widget _buildNotAvailable() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.directions_walk_rounded,
            size: 55,
            color: Colors.black38,
          ),
          SizedBox(height: 12),
          Text(
            'Active walk not available',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: navy,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // TOP BAR
  // ==========================================================

  Widget _buildTopBar(
    ActiveWalk walk,
  ) {
    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
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
          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isWalker
                      ? 'ACTIVE WALK'
                      : 'WALKER ON THE WAY',
                  style: const TextStyle(
                    color: primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  walk.isWalkerReached
                      ? 'Walker has arrived'
                      : '${walk.dogName} • ${walk.dogBreed}',
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
          _statusBadge(walk),
        ],
      ),
    );
  }

  // ==========================================================
  // STATUS BADGE
  // ==========================================================

  Widget _statusBadge(
    ActiveWalk walk,
  ) {
    final bool reached =
        walk.isWalkerReached;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: (reached ? green : primary)
            .withOpacity(.10),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            size: 7,
            color: reached ? green : primary,
          ),
          const SizedBox(width: 4),
          Text(
            reached ? 'REACHED' : 'ACTIVE',
            style: TextStyle(
              color: reached ? green : primary,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // OPENSTREETMAP
  // ==========================================================

  Widget _buildMap(
    ActiveWalk walk,
  ) {
    final LatLng center =
        _latLng(walk.walkerLocation) ??
            _latLng(walk.ownerLocation) ??
            const LatLng(
              28.6139,
              77.2090,
            );

    return FlutterMap(
      mapController: _mapController,
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
            if (walk.ownerLocation != null)
              Marker(
                point:
                    _latLng(walk.ownerLocation)!,
                width: 58,
                height: 68,
                child: _destinationMarker(),
              ),
            if (walk.walkerLocation != null)
              Marker(
                point:
                    _latLng(walk.walkerLocation)!,
                width: 60,
                height: 70,
                child: _walkerMarker(),
              ),
          ],
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
          decoration: BoxDecoration(
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
          decoration: BoxDecoration(
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
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        constraints: const BoxConstraints(
          maxHeight: 360,
        ),
        padding: const EdgeInsets.fromLTRB(
          15,
          14,
          15,
          15,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 15,
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

              _buildActions(walk),

              if (walk.isWalkerReached) ...[
                const SizedBox(height: 10),
                _buildReachedMessage(),
              ],

              if (widget.isWalker &&
                  !walk.isWalkerReached &&
                  !walk.isLiveWalk) ...[
                const SizedBox(height: 10),
                _buildReachedButton(),
              ],

              if (walk.isWalkerReached) ...[
                const SizedBox(height: 10),
                _buildStartLiveWalkButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // WALKER INFORMATION
  // ==========================================================

  Widget _buildWalkerInfo(
    ActiveWalk walk,
  ) {
    final String name =
        walk.walkerName.isEmpty
            ? 'Walker'
            : walk.walkerName;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: lightBg,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: primary.withOpacity(.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              color: primary,
              size: 27,
            ),
          ),
          const SizedBox(width: 11),
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
                    fontWeight: FontWeight.w900,
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
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (walk.walkerUid.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'UID: ${walk.walkerUid}',
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: slate,
                      fontSize: 9,
                    ),
                  ),
                ],
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
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: lightBg,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: primary.withOpacity(.10),
              borderRadius:
                  BorderRadius.circular(10),
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
                    fontWeight: FontWeight.w900,
                    letterSpacing: .5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  walk.address,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
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
  // CALL + CHAT + MAP
  // ==========================================================

  Widget _buildActions(
    ActiveWalk walk,
  ) {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            icon: Icons.call_rounded,
            label: 'Call',
            color: green,
            onTap: _callWalker,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _actionButton(
            icon: Icons.chat_rounded,
            label: 'Chat',
            color: blue,
            onTap: _openChat,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _actionButton(
            icon:
                Icons.my_location_rounded,
            label: 'Map',
            color: primary,
            onTap: _recenterOnWalker,
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 43,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(
          icon,
          size: 17,
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

  // ==========================================================
  // REACHED MESSAGE
  // ==========================================================

  Widget _buildReachedMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: green.withOpacity(.08),
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: green.withOpacity(.20),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: green,
            size: 22,
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Walker has reached the destination.',
              style: TextStyle(
                color: green,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // REACHED BUTTON
  // ==========================================================

  Widget _buildReachedButton() {
    return SizedBox(
      width: double.infinity,
      height: 47,
      child: ElevatedButton.icon(
        onPressed:
            _updating ? null : _markReached,
        icon: _updating
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
                Icons.location_on_rounded,
              ),
        label: Text(
          _updating
              ? 'Creating Live Session...'
              : 'I Have Reached',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
        style:
            ElevatedButton.styleFrom(
          backgroundColor: green,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(13),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // START LIVE WALK
  // ==========================================================

  Widget _buildStartLiveWalkButton() {
    return SizedBox(
      width: double.infinity,
      height: 47,
      child: ElevatedButton.icon(
        onPressed: widget.onLiveWalk,
        icon: const Icon(
          Icons.directions_walk_rounded,
        ),
        label: const Text(
          'Start Live Walk',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
        style:
            ElevatedButton.styleFrom(
          backgroundColor: navy,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(13),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // MARK REACHED + CREATE LIVE SESSION
  // ==========================================================

  Future<void> _markReached() async {
    if (_updating) {
      return;
    }

    final ActiveWalk? walk = _walk;

    if (walk == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _updating = true;
    });

    try {
      // ========================================================
      // ACTIVE WALK REFERENCE
      // ========================================================

      final DocumentReference<
              Map<String, dynamic>>
          activeWalkRef = _firestore
              .collection('active_walks')
              .doc(widget.activeWalkId);

      // ========================================================
      // READ ACTIVE WALK
      // ========================================================

      final DocumentSnapshot<
              Map<String, dynamic>>
          activeWalkSnapshot =
          await activeWalkRef.get();

      if (!activeWalkSnapshot.exists) {
        throw Exception(
          'Active walk does not exist.',
        );
      }

      final Map<String, dynamic> data =
          activeWalkSnapshot.data() ??
              <String, dynamic>{};

      // ========================================================
      // PREVENT DUPLICATE LIVE SESSION
      // ========================================================

      final String existingLiveSessionId =
          (data['liveSessionId'] ?? '')
              .toString()
              .trim();

      String liveSessionId =
          existingLiveSessionId;

      if (liveSessionId.isEmpty) {
        final QuerySnapshot<
                Map<String, dynamic>>
            existingSession =
            await _firestore
                .collection('liveWalkSessions')
                .where(
                  'walkId',
                  isEqualTo: widget.activeWalkId,
                )
                .limit(1)
                .get();

        if (existingSession.docs.isNotEmpty) {
          liveSessionId =
              existingSession.docs.first.id;
        }
      }

      // ========================================================
      // CREATE LIVE SESSION IF NOT EXISTS
      // ========================================================

      if (liveSessionId.isEmpty) {
        final DocumentReference<
                Map<String, dynamic>>
            sessionRef = _firestore
                .collection('liveWalkSessions')
                .doc();

        liveSessionId = sessionRef.id;

        final dynamic walkerLocation =
            data['walkerLocation'];

        final dynamic ownerLocation =
            data['ownerLocation'] ??
                data['destinationLocation'];

        await sessionRef.set({
          // ==================================================
          // IDENTIFICATION
          // ==================================================

          'walkId':
              widget.activeWalkId,

          'activeWalkId':
              widget.activeWalkId,

          'requestId':
              data['requestId'] ?? '',

          // ==================================================
          // OWNER
          // ==================================================

          'ownerId':
              data['ownerId'] ?? '',

          'ownerUid':
              data['ownerUid'] ??
                  data['ownerAuthUid'] ??
                  '',

          'ownerName':
              data['ownerName'] ?? '',

          'ownerPhone':
              data['ownerPhone'] ?? '',

          // ==================================================
          // WALKER
          // ==================================================

          'walkerId':
              data['walkerId'] ?? '',

          'walkerUid':
              data['walkerUid'] ?? '',

          'walkerName':
              data['walkerName'] ?? '',

          'walkerPhone':
              data['walkerPhone'] ?? '',

          // ==================================================
          // DOG
          // ==================================================

          'dogName':
              data['dogName'] ??
                  data['petName'] ??
                  '',

          'dogBreed':
              data['dogBreed'] ??
                  data['breed'] ??
                  '',

          // ==================================================
          // STATUS
          //
          // Reached only.
          // Actual walking has NOT started.
          // ==================================================

          'status': 'active',

          'trackingStarted': false,
          'trackingEnded': false,

          'walkStarted': false,
          'walkEnded': false,

          // ==================================================
          // LOCATION
          // ==================================================

          'currentLocation':
              walkerLocation,

          'destinationLocation':
              ownerLocation,

          // ==================================================
          // STATS
          // ==================================================

          'distanceKm': 0.0,
          'elapsedSeconds': 0,
          'peeCount': 0,
          'poopCount': 0,
          'steps': 0,

          // ==================================================
          // ROUTE
          // ==================================================

          'routeCoordinates':
              <GeoPoint>[],

          // ==================================================
          // EVENTS
          // ==================================================

          'events': <String>[
            'Walker reached owner location',
          ],

          // ==================================================
          // TIME
          // ==================================================

          'createdAt':
              FieldValue.serverTimestamp(),

          'updatedAt':
              FieldValue.serverTimestamp(),

          'reachedAt':
              FieldValue.serverTimestamp(),

          'startedAt': null,

          'endedAt': null,
        });
      }

      // ========================================================
      // UPDATE ACTIVE WALK
      // ========================================================

      await activeWalkRef.update({
        'status': 'reached',

        'reachedAt':
            FieldValue.serverTimestamp(),

        'liveSessionId':
            liveSessionId,

        'updatedAt':
            FieldValue.serverTimestamp(),
      });

      // ========================================================
      // SUCCESS
      // ========================================================

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Walker reached. Live session created.',
          ),
        ),
      );
    } catch (e) {
      debugPrint(
        'Mark reached / create live session error: $e',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to create live session: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _updating = false;
        });
      }
    }
  }

  // ==========================================================
  // CALL
  // ==========================================================

  Future<void> _callWalker() async {
    final ActiveWalk? walk = _walk;

    if (walk == null) {
      return;
    }

    final String phone =
        walk.walkerPhone.trim();

    if (phone.isEmpty) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
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

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Chat screen will be connected next.',
        ),
      ),
    );
  }

  // ==========================================================
  // RECENTER MAP
  // ==========================================================

  void _recenterOnWalker() {
    final ActiveWalk? walk = _walk;

    if (walk == null) {
      return;
    }

    final LatLng? location =
        _latLng(walk.walkerLocation);

    if (location == null) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
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
  // INITIAL MAP CENTER
  // ==========================================================

  void _centerMapOnce(
    ActiveWalk walk,
  ) {
    if (_didInitialCenter) {
      return;
    }

    final LatLng? location =
        _latLng(walk.walkerLocation) ??
            _latLng(walk.ownerLocation);

    if (location == null) {
      return;
    }

    _didInitialCenter = true;

    WidgetsBinding.instance.addPostFrameCallback(
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
  // GEOPOINT → LATLNG
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
    super.dispose();
  }
}
