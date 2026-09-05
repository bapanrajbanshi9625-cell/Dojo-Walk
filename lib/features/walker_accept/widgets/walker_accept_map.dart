import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'owner_home_marker.dart';
import 'walker_location_marker.dart';

class WalkerAcceptMap extends StatefulWidget {
  const WalkerAcceptMap({
    super.key,
    required this.ownerLocation,
    required this.walkerLocation,
    required this.walkerImageUrl,
    this.routePoints = const <LatLng>[],
    this.walkerHeading,
    this.onMyLocationPressed,
  });

  final LatLng ownerLocation;
  final LatLng? walkerLocation;
  final String? walkerImageUrl;
  final List<LatLng> routePoints;
  final double? walkerHeading;
  final VoidCallback? onMyLocationPressed;

  @override
  State<WalkerAcceptMap> createState() => _WalkerAcceptMapState();
}

class _WalkerAcceptMapState extends State<WalkerAcceptMap> {
  late final MapController _mapController;

  bool _autoFollow = true;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  // ==========================================================
  // WIDGET UPDATE
  // ==========================================================

  @override
  void didUpdateWidget(
    covariant WalkerAcceptMap oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    final LatLng? oldWalker = oldWidget.walkerLocation;
    final LatLng? newWalker = widget.walkerLocation;

    if (newWalker == null) {
      return;
    }

    if (oldWalker == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        if (_autoFollow) {
          _followWalker(newWalker);
        }
      });

      return;
    }

    if (_hasLocationChanged(oldWalker, newWalker)) {
      if (_autoFollow) {
        _followWalker(newWalker);
      }
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final double zoom = _currentZoom;

    final double ownerMarkerSize =
        _markerSizeForZoom(
      zoom,
      minSize: 28,
      maxSize: 48,
    );

    final double walkerMarkerSize =
        _markerSizeForZoom(
      zoom,
      minSize: 30,
      maxSize: 52,
    );

    final List<Marker> markers = <Marker>[
      // ======================================================
      // OWNER
      // ======================================================

      Marker(
        point: widget.ownerLocation,
        width: ownerMarkerSize,
        height: ownerMarkerSize,
        alignment: Alignment.bottomCenter,
        child: OwnerHomeMarker(
          size: ownerMarkerSize,
        ),
      ),

      // ======================================================
      // WALKER
      // ======================================================

      if (widget.walkerLocation != null)
        Marker(
          point: widget.walkerLocation!,
          width: walkerMarkerSize,
          height: walkerMarkerSize,
          alignment: Alignment.bottomCenter,
          child: Transform.rotate(
            angle: _headingRadians,
            alignment: Alignment.bottomCenter,
            child: WalkerLocationMarker(
              imageUrl: widget.walkerImageUrl,
              size: walkerMarkerSize,
              isLive: true,
            ),
          ),
        ),
    ];

    return ColoredBox(
      color: const Color(0xFFE8EEF3),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ====================================================
          // MAP
          // ====================================================

          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.ownerLocation,
              initialZoom: 15.0,
              minZoom: 5.0,
              maxZoom: 19.0,

              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),

              // =================================================
              // MAP READY
              // =================================================

              onMapReady: () {
                if (!mounted) {
                  return;
                }

                _mapReady = true;

                WidgetsBinding.instance.addPostFrameCallback(
                  (_) {
                    if (!mounted) {
                      return;
                    }

                    final LatLng? walker =
                        widget.walkerLocation;

                    if (walker != null) {
                      _fitBothLocations();
                    } else {
                      _recenterOwner();
                    }

                    setState(() {});
                  },
                );
              },

              // =================================================
              // POSITION CHANGED
              // =================================================

              onPositionChanged: (
                camera,
                hasGesture,
              ) {
                if (!mounted) {
                  return;
                }

                // Rebuild marker sizes whenever zoom changes.
                setState(() {});

                if (!hasGesture) {
                  return;
                }

                if (_autoFollow) {
                  setState(() {
                    _autoFollow = false;
                  });
                }
              },
            ),

            children: [
              // ==================================================
              // OPEN STREET MAP
              // ==================================================

              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName:
                    'com.doojowalker.app',
                maxZoom: 19,
              ),

              // ==================================================
              // ROAD ROUTE
              // ==================================================

              if (widget.routePoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    // Outer white border
                    Polyline(
                      points: widget.routePoints,
                      strokeWidth: 9,
                      color: Colors.white,
                    ),

                    // Main blue road route
                    Polyline(
                      points: widget.routePoints,
                      strokeWidth: 5,
                      color: const Color(0xFF1976D2),
                    ),
                  ],
                ),

              // ==================================================
              // LOCATION MARKERS
              // ==================================================

              MarkerLayer(
                markers: markers,
              ),
            ],
          ),

          // ====================================================
          // LIVE BADGE
          // ====================================================

          const Positioned(
            left: 16,
            top: 16,
            child: _LiveMapBadge(),
          ),

          // ====================================================
          // MAP CONTROLS
          // ====================================================

          Positioned(
            right: 16,
            bottom: 190,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MapControlButton(
                  icon: Icons.add_rounded,
                  onPressed: _zoomIn,
                ),

                const SizedBox(height: 8),

                _MapControlButton(
                  icon: Icons.remove_rounded,
                  onPressed: _zoomOut,
                ),

                const SizedBox(height: 10),

                _MapControlButton(
                  icon: Icons.my_location_rounded,
                  active: _autoFollow,
                  onPressed: _showBothLocations,
                ),
              ],
            ),
          ),

          // ====================================================
          // WAITING FOR WALKER
          // ====================================================

          if (widget.walkerLocation == null)
            const Positioned(
              left: 16,
              right: 16,
              bottom: 190,
              child: _WaitingLocationBanner(),
            ),
        ],
      ),
    );
  }

  // ==========================================================
  // CURRENT ZOOM
  // ==========================================================

  double get _currentZoom {
    if (!_mapReady) {
      return 15.0;
    }

    try {
      return _mapController.camera.zoom;
    } catch (_) {
      return 15.0;
    }
  }

  // ==========================================================
  // DYNAMIC MARKER SIZE
  // ==========================================================

  double _markerSizeForZoom(
    double zoom, {
    required double minSize,
    required double maxSize,
  }) {
    // Zoom 5  -> smallest
    // Zoom 15 -> normal
    // Zoom 19 -> largest

    const double minZoom = 5.0;
    const double maxZoom = 19.0;

    final double normalized =
        ((zoom - minZoom) /
                (maxZoom - minZoom))
            .clamp(0.0, 1.0);

    return minSize +
        ((maxSize - minSize) * normalized);
  }

  // ==========================================================
  // SHOW BOTH LOCATIONS
  // ==========================================================

  void _showBothLocations() {
    if (!_mapReady) {
      return;
    }

    if (mounted) {
      setState(() {
        _autoFollow = false;
      });
    }

    _fitBothLocations();

    widget.onMyLocationPressed?.call();
  }

  // ==========================================================
  // FIT OWNER + WALKER
  // ==========================================================

  void _fitBothLocations() {
    if (!mounted || !_mapReady) {
      return;
    }

    final LatLng? walker = widget.walkerLocation;

    if (walker == null) {
      _recenterOwner();
      return;
    }

    try {
      final LatLngBounds bounds =
          LatLngBounds.fromPoints(
        <LatLng>[
          widget.ownerLocation,
          walker,
        ],
      );

      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.fromLTRB(
            70,
            110,
            70,
            260,
          ),
          maxZoom: 16.0,
        ),
      );

      if (mounted) {
        setState(() {});
      }
    } catch (error) {
      debugPrint(
        'WalkerAcceptMap fit locations error: $error',
      );
    }
  }

  // ==========================================================
  // FOLLOW WALKER
  // ==========================================================

  void _followWalker(
    LatLng walkerLocation,
  ) {
    if (!mounted ||
        !_mapReady ||
        !_autoFollow) {
      return;
    }

    try {
      _mapController.move(
        walkerLocation,
        _mapController.camera.zoom,
      );
    } catch (error) {
      debugPrint(
        'WalkerAcceptMap follow error: $error',
      );
    }
  }

  // ==========================================================
  // OWNER
  // ==========================================================

  void _recenterOwner() {
    if (!mounted || !_mapReady) {
      return;
    }

    try {
      _mapController.move(
        widget.ownerLocation,
        15.0,
      );
    } catch (error) {
      debugPrint(
        'WalkerAcceptMap recenter error: $error',
      );
    }
  }

  // ==========================================================
  // ZOOM IN
  // ==========================================================

  void _zoomIn() {
    if (!_mapReady) {
      return;
    }

    try {
      final double zoom =
          _mapController.camera.zoom;

      _mapController.move(
        _mapController.camera.center,
        (zoom + 1)
            .clamp(5.0, 19.0)
            .toDouble(),
      );

      if (mounted) {
        setState(() {});
      }
    } catch (error) {
      debugPrint(
        'WalkerAcceptMap zoom in error: $error',
      );
    }
  }

  // ==========================================================
  // ZOOM OUT
  // ==========================================================

  void _zoomOut() {
    if (!_mapReady) {
      return;
    }

    try {
      final double zoom =
          _mapController.camera.zoom;

      _mapController.move(
        _mapController.camera.center,
        (zoom - 1)
            .clamp(5.0, 19.0)
            .toDouble(),
      );

      if (mounted) {
        setState(() {});
      }
    } catch (error) {
      debugPrint(
        'WalkerAcceptMap zoom out error: $error',
      );
    }
  }

  // ==========================================================
  // LOCATION CHANGE
  // ==========================================================

  bool _hasLocationChanged(
    LatLng oldLocation,
    LatLng newLocation,
  ) {
    const double threshold = 0.00001;

    final double latitudeDifference =
        (oldLocation.latitude -
                newLocation.latitude)
            .abs();

    final double longitudeDifference =
        (oldLocation.longitude -
                newLocation.longitude)
            .abs();

    return latitudeDifference > threshold ||
        longitudeDifference > threshold;
  }

  // ==========================================================
  // HEADING
  // ==========================================================

  double get _headingRadians {
    final double? heading =
        widget.walkerHeading;

    if (heading == null) {
      return 0;
    }

    return heading *
        3.141592653589793 /
        180;
  }
}

// ============================================================
// LIVE BADGE
// ============================================================

class _LiveMapBadge extends StatelessWidget {
  const _LiveMapBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            offset: Offset(0, 3),
            color: Color(0x22000000),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Color(0xFF1FA463),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'LIVE',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: .5,
              color: Color(0xFF1FA463),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MAP CONTROL
// ============================================================

class _MapControlButton extends StatelessWidget {
  const _MapControlButton({
    required this.icon,
    required this.onPressed,
    this.active = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active
          ? const Color(0xFFE85D04)
          : Colors.white,
      elevation: 5,
      shadowColor: Colors.black26,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            Icons.my_location_rounded,
            size: 20,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// WAITING LOCATION
// ============================================================

class _WaitingLocationBanner extends StatelessWidget {
  const _WaitingLocationBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .95),
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            offset: Offset(0, 3),
            color: Color(0x22000000),
          ),
        ],
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 17,
            height: 17,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Waiting for Walker location…',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
