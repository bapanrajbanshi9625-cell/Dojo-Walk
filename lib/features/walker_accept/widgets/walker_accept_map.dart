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
  State<WalkerAcceptMap> createState() =>
      _WalkerAcceptMapState();
}

class _WalkerAcceptMapState
    extends State<WalkerAcceptMap> {
  late final MapController _mapController;

  bool _autoFollow = true;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void didUpdateWidget(
    covariant WalkerAcceptMap oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    final LatLng? oldWalker =
        oldWidget.walkerLocation;

    final LatLng? newWalker =
        widget.walkerLocation;

    if (newWalker == null) {
      return;
    }

    if (oldWalker == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) {
          if (mounted) {
            _followWalker(newWalker);
          }
        },
      );
      return;
    }

    if (_hasLocationChanged(
      oldWalker,
      newWalker,
    )) {
      _followWalker(newWalker);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    final List<Marker> markers = <Marker>[
      // OWNER
      Marker(
        point: widget.ownerLocation,
        width: 70,
        height: 70,
        alignment: Alignment.center,
        child: const OwnerHomeMarker(),
      ),

      // WALKER
      if (widget.walkerLocation != null)
        Marker(
          point: widget.walkerLocation!,
          width: 78,
          height: 78,
          alignment: Alignment.center,
          child: Transform.rotate(
            angle: _headingRadians,
            child: WalkerLocationMarker(
              imageUrl: widget.walkerImageUrl,
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
              initialCenter:
                  widget.ownerLocation,
              initialZoom: 15.0,
              minZoom: 5.0,
              maxZoom: 19.0,

              interactionOptions:
                  const InteractionOptions(
                flags:
                    InteractiveFlag.all,
              ),

              onMapReady: () {
                if (!mounted) {
                  return;
                }

                _mapReady = true;

                final LatLng? walker =
                    widget.walkerLocation;

                if (walker != null &&
                    _autoFollow) {
                  WidgetsBinding.instance
                      .addPostFrameCallback(
                    (_) {
                      if (mounted) {
                        _followWalker(walker);
                      }
                    },
                  );
                } else {
                  WidgetsBinding.instance
                      .addPostFrameCallback(
                    (_) {
                      if (mounted) {
                        _recenterOwner();
                      }
                    },
                  );
                }
              },

              onPositionChanged:
                  (camera, hasGesture) {
                if (hasGesture &&
                    mounted) {
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
              // ROUTE
              // ==================================================

              if (widget.routePoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points:
                          widget.routePoints,
                      strokeWidth: 8,
                      color:
                          colors.primary
                              .withValues(
                        alpha: .22,
                      ),
                    ),
                    Polyline(
                      points:
                          widget.routePoints,
                      strokeWidth: 4,
                      color:
                          colors.primary,
                      borderStrokeWidth: 1,
                      borderColor:
                          Colors.white,
                    ),
                  ],
                ),

              // ==================================================
              // MARKERS
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
          // FOLLOW BADGE
          // ====================================================

          Positioned(
            right: 16,
            top: 16,
            child: _FollowBadge(
              following:
                  _autoFollow,
            ),
          ),

          // ====================================================
          // MAP CONTROLS
          // ====================================================

          Positioned(
            right: 16,
            bottom: 24,
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                _MapControlButton(
                  icon:
                      Icons.add_rounded,
                  onPressed:
                      _zoomIn,
                ),

                const SizedBox(
                  height: 8,
                ),

                _MapControlButton(
                  icon:
                      Icons.remove_rounded,
                  onPressed:
                      _zoomOut,
                ),

                const SizedBox(
                  height: 12,
                ),

                _MapControlButton(
                  icon: _autoFollow
                      ? Icons
                          .navigation_rounded
                      : Icons
                          .my_location_rounded,
                  active:
                      _autoFollow,
                  onPressed:
                      _recenterPressed,
                ),
              ],
            ),
          ),

          // ====================================================
          // WAITING FOR WALKER LOCATION
          // ====================================================

          if (widget.walkerLocation ==
              null)
            const Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child:
                  _WaitingLocationBanner(),
            ),
        ],
      ),
    );
  }

  // ==========================================================
  // RECENTER / FOLLOW
  // ==========================================================

  void _recenterPressed() {
    _autoFollow = true;

    final LatLng? walker =
        widget.walkerLocation;

    if (walker != null) {
      _followWalker(walker);
    } else {
      _recenterOwner();
    }

    widget.onMyLocationPressed?.call();

    if (mounted) {
      setState(() {});
    }
  }

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

  void _recenterOwner() {
    if (!mounted ||
        !_mapReady) {
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
  // ZOOM
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
    } catch (error) {
      debugPrint(
        'WalkerAcceptMap zoom in error: $error',
      );
    }
  }

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
    const double threshold =
        0.00001;

    final double lat =
        (oldLocation.latitude -
                newLocation.latitude)
            .abs();

    final double lng =
        (oldLocation.longitude -
                newLocation.longitude)
            .abs();

    return lat > threshold ||
        lng > threshold;
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

class _LiveMapBadge
    extends StatelessWidget {
  const _LiveMapBadge();

  @override
  Widget build(
    BuildContext context,
  ) {
    final Color primary =
        Theme.of(context)
            .colorScheme
            .primary;

    return _GlassBadge(
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(
              color: primary,
              shape:
                  BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          const Text(
            'LIVE TRACKING',
            style: TextStyle(
              fontSize: 10,
              fontWeight:
                  FontWeight.w900,
              letterSpacing: .7,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// FOLLOW BADGE
// ============================================================

class _FollowBadge
    extends StatelessWidget {
  const _FollowBadge({
    required this.following,
  });

  final bool following;

  @override
  Widget build(
    BuildContext context,
  ) {
    return _GlassBadge(
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            following
                ? Icons.navigation_rounded
                : Icons
                    .pan_tool_alt_rounded,
            size: 13,
          ),
          const SizedBox(width: 5),
          Text(
            following
                ? 'FOLLOWING'
                : 'MAP MOVED',
            style: const TextStyle(
              fontSize: 9,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// GLASS BADGE
// ============================================================

class _GlassBadge
    extends StatelessWidget {
  const _GlassBadge({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 8,
      ),
      decoration:
          BoxDecoration(
        color: Colors.white
            .withValues(alpha: .94),
        borderRadius:
            BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            blurRadius: 14,
            offset: Offset(0, 4),
            color: Color(0x22000000),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ============================================================
// MAP CONTROL
// ============================================================

class _MapControlButton
    extends StatelessWidget {
  const _MapControlButton({
    required this.icon,
    required this.onPressed,
    this.active = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool active;

  @override
  Widget build(
    BuildContext context,
  ) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return Material(
      color: active
          ? colors.primary
          : Colors.white,
      elevation: 5,
      shape:
          const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder:
            const CircleBorder(),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(
            icon,
            size: 21,
            color: active
                ? colors.onPrimary
                : colors.onSurface,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// WAITING LOCATION
// ============================================================

class _WaitingLocationBanner
    extends StatelessWidget {
  const _WaitingLocationBanner();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 11,
      ),
      decoration:
          BoxDecoration(
        color: Colors.white
            .withValues(alpha: .95),
        borderRadius:
            BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 14,
            color: Color(0x22000000),
          ),
        ],
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child:
                CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Waiting for Walker location…',
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
