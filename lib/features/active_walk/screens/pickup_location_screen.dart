import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/active_walk_service.dart';

class PickupLocationScreen extends StatefulWidget {
  const PickupLocationScreen({
    super.key,
    required this.activeWalkId,
  });

  final String activeWalkId;

  @override
  State<PickupLocationScreen> createState() =>
      _PickupLocationScreenState();
}

class _PickupLocationScreenState
    extends State<PickupLocationScreen> {
  // ==========================================================
  // FIRESTORE / SERVICE
  // ==========================================================

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final ActiveWalkService _service =
      ActiveWalkService.instance;

  final MapController _mapController =
      MapController();

  StreamSubscription<
      DocumentSnapshot<Map<String, dynamic>>>?
      _subscription;

  // ==========================================================
  // DATA
  // ==========================================================

  String _ownerName = 'Owner';
  String _dogName = 'Dog';
  String _dogBreed = 'Breed not available';
  String _address = 'Pickup location unavailable';

  String _walkerPhone = '';

  LatLng? _pickupLocation;
  LatLng? _walkerLocation;

  String _status = 'On that way';

  bool _loading = true;
  bool _reaching = false;

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

    _listenToActiveWalk();
  }

  // ==========================================================
  // LISTENER
  // ==========================================================

  void _listenToActiveWalk() {
    _subscription = _firestore
        .collection('active_walk')
        .doc(widget.activeWalkId)
        .snapshots()
        .listen(
      (
        DocumentSnapshot<Map<String, dynamic>>
            snapshot,
      ) {
        if (!snapshot.exists) {
          return;
        }

        final Map<String, dynamic> data =
            snapshot.data() ??
                <String, dynamic>{};

        _readData(data);

        if (!mounted) {
          return;
        }

        setState(() {
          _loading = false;
        });

        // ------------------------------------------------------
        // ALREADY REACHED
        // ------------------------------------------------------

        if (_status.toLowerCase() == 'reached') {
          return;
        }

        // ------------------------------------------------------
        // WALK STARTED
        // ------------------------------------------------------

        if (_status.toLowerCase() == 'started') {
          _openLiveWalk();
        }
      },
      onError: (Object error) {
        debugPrint(
          'Pickup listener error: $error',
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
  // READ DATA
  // ==========================================================

  void _readData(
    Map<String, dynamic> data,
  ) {
    _ownerName =
        _readString(
          data['ownerName'],
        ) ??
        'Owner';

    _dogName =
        _readString(
          data['dogName'],
        ) ??
        'Dog';

    _dogBreed =
        _readString(
          data['dogBreed'],
        ) ??
        'Breed not available';

    _address =
        _readString(
          data['address'],
        ) ??
        'Pickup location unavailable';

    _walkerPhone =
        _readString(
          data['walkerPhone'],
        ) ??
        '';

    _status =
        _readString(
          data['status'],
        ) ??
        'On that way';

    // ----------------------------------------------------------
    // OWNER PICKUP LOCATION
    // ----------------------------------------------------------

    _pickupLocation =
        _readLatLng(
          data['destinationLocation'],
        );

    // ----------------------------------------------------------
    // WALKER CURRENT LOCATION
    // ----------------------------------------------------------

    _walkerLocation =
        _readLatLng(
          data['walkerLocation'],
        ) ??
        _readLatLng(
          data['currentLocation'],
        );
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
    return Container(
      height: 70,
      padding:
          const EdgeInsets.symmetric(
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

          const SizedBox(width: 2),

          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'PICKUP LOCATION',
                  style: TextStyle(
                    color: primary,
                    fontSize: 9,
                    fontWeight:
                        FontWeight.w900,
                    letterSpacing: .7,
                  ),
                ),

                const SizedBox(height: 3),

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
                  primary.withOpacity(.10),
              borderRadius:
                  BorderRadius.circular(20),
            ),
            child: Text(
              _status.toUpperCase(),
              style: const TextStyle(
                color: primary,
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

  // ==========================================================
  // OSM MAP
  // ==========================================================

  Widget _buildMap() {
    final LatLng center =
        _pickupLocation ??
        _walkerLocation ??
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
                if (_pickupLocation != null)
                  Marker(
                    point:
                        _pickupLocation!,
                    width: 60,
                    height: 70,
                    child:
                        _pickupMarker(),
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
                BorderRadius.circular(13),
            child: InkWell(
              borderRadius:
                  BorderRadius.circular(13),
              onTap:
                  _fitPickupAndWalker,
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
  // PICKUP MARKER
  // ==========================================================

  Widget _pickupMarker() {
    return Column(
      children: [
        Container(
          width: 45,
          height: 45,
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
            size: 23,
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
  // BOTTOM PANEL
  // ==========================================================

  Widget _buildBottomPanel() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.fromLTRB(
        15,
        14,
        15,
        15,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(25),
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
          _buildOwnerAndPickup(),

          const SizedBox(height: 12),

          Row(
            children: [
              // ------------------------------------------------
              // CALL
              // ------------------------------------------------

              Expanded(
                child: _actionButton(
                  icon:
                      Icons.call_rounded,
                  label: 'Call',
                  color: green,
                  onTap:
                      _callOwner,
                ),
              ),

              const SizedBox(width: 8),

              // ------------------------------------------------
              // CHAT
              // ------------------------------------------------

              Expanded(
                child: _actionButton(
                  icon:
                      Icons.chat_rounded,
                  label: 'Chat',
                  color: blue,
                  onTap:
                      _openChat,
                ),
              ),

              const SizedBox(width: 8),

              // ------------------------------------------------
              // MAP
              // ------------------------------------------------

              Expanded(
                child: _actionButton(
                  icon:
                      Icons.location_on_rounded,
                  label: 'Map',
                  color: primary,
                  onTap:
                      _fitPickupAndWalker,
                ),
              ),
            ],
          ),

          const SizedBox(height: 11),

          // ----------------------------------------------------
          // REACHED BUTTON
          // ----------------------------------------------------

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed:
                  _reaching
                      ? null
                      : _markReached,
              icon: _reaching
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
                      Icons.check_circle_rounded,
                    ),
              label: Text(
                _reaching
                    ? 'Updating...'
                    : 'I’ve Reached',
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    green,
                foregroundColor:
                    Colors.white,
                disabledBackgroundColor:
                    green.withOpacity(.5),
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

          const SizedBox(height: 8),

          const Text(
            'Go to the owner pickup location before starting the walk.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: slate,
              fontSize: 10,
              fontWeight:
                  FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // OWNER / PICKUP
  // ==========================================================

  Widget _buildOwnerAndPickup() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            const Color(0xFFF7F8F9),
        borderRadius:
            BorderRadius.circular(15),
        border: Border.all(
          color:
              const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration:
                BoxDecoration(
              color:
                  primary.withOpacity(.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              color: primary,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  _ownerName,
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

                const SizedBox(height: 3),

                Text(
                  _address,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    color: slate,
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w600,
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
  // FIT MAP
  // ==========================================================

  void _fitPickupAndWalker() {
    final LatLng? pickup =
        _pickupLocation;

    final LatLng? walker =
        _walkerLocation;

    if (pickup == null &&
        walker == null) {
      return;
    }

    // ----------------------------------------------------------
    // BOTH LOCATIONS
    // ----------------------------------------------------------

    if (pickup != null &&
        walker != null) {
      final double minLat =
          pickup.latitude <
                  walker.latitude
              ? pickup.latitude
              : walker.latitude;

      final double maxLat =
          pickup.latitude >
                  walker.latitude
              ? pickup.latitude
              : walker.latitude;

      final double minLng =
          pickup.longitude <
                  walker.longitude
              ? pickup.longitude
              : walker.longitude;

      final double maxLng =
          pickup.longitude >
                  walker.longitude
              ? pickup.longitude
              : walker.longitude;

      final LatLngBounds bounds =
          LatLngBounds(
        LatLng(
          minLat,
          minLng,
        ),
        LatLng(
          maxLat,
          maxLng,
        ),
      );

      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding:
              const EdgeInsets.all(60),
        ),
      );

      return;
    }

    // ----------------------------------------------------------
    // ONLY ONE LOCATION
    // ----------------------------------------------------------

    _mapController.move(
      pickup ?? walker!,
      17,
    );
  }

  // ==========================================================
  // NAVIGATE TO PICKUP
  // ==========================================================

  Future<void> _navigateToPickup() async {
    final LatLng? pickup =
        _pickupLocation;

    if (pickup == null) {
      return;
    }

    final Uri uri = Uri.parse(
      'https://www.openstreetmap.org/?mlat='
      '${pickup.latitude}'
      '&mlon='
      '${pickup.longitude}'
      '#map=17/'
      '${pickup.latitude}/'
      '${pickup.longitude}',
    );

    try {
      await launchUrl(
        uri,
        mode:
            LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint(
        'Navigation error: $e',
      );
    }
  }

  // ==========================================================
  // CALL OWNER
  // ==========================================================

  Future<void> _callOwner() async {
    final String phone =
        _walkerPhone.trim();

    // ----------------------------------------------------------
    // PHONE NOT AVAILABLE
    // ----------------------------------------------------------

    if (phone.isEmpty) {
      if (!mounted) {
        return;
      }

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

    // ----------------------------------------------------------
    // OPEN PHONE DIALER
    // ----------------------------------------------------------

    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: phone,
    );

    try {
      final bool launched =
          await launchUrl(
        phoneUri,
        mode:
            LaunchMode.externalApplication,
      );

      if (!launched) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context)
            .showSnackBar(
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

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to open phone dialer.',
          ),
        ),
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
          'Chat screen will open here.',
        ),
      ),
    );
  }

  // ==========================================================
  // REACHED
  // ==========================================================

  Future<void> _markReached() async {
    if (_reaching) {
      return;
    }

    final bool? confirm =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Reached pickup?',
          ),
          content: const Text(
            'Confirm that you have reached the owner pickup location.',
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
                'Not Yet',
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
                'Yes, Reached',
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
      _reaching = true;
    });

    try {
      await _service.markReached(
        walkId:
            widget.activeWalkId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _status = 'Reached';
        _reaching = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Pickup reached. Waiting to start the walk.',
          ),
        ),
      );
    } catch (e) {
      debugPrint(
        'Mark reached error: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _reaching = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to update pickup status.',
          ),
        ),
      );
    }
  }

  // ==========================================================
  // OPEN LIVE WALK
  // ==========================================================

  void _openLiveWalk() {
    // Connect your existing LiveWalkScreen here.
    //
    // Example:
    //
    // Navigator.pushReplacement(
    //   context,
    //   MaterialPageRoute(
    //     builder: (_) => LiveWalkScreen(
    //       activeWalkId:
    //           widget.activeWalkId,
    //       isWalker: true,
    //     ),
    //   ),
    // );
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

  // ==========================================================
  // READ GEOPOINT
  // ==========================================================

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

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _subscription?.cancel();

    super.dispose();
  }
}
