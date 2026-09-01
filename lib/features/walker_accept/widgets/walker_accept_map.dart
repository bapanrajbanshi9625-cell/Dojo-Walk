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

  /// Owner's saved location.
  final LatLng ownerLocation;

  /// Walker's current live location.
  final LatLng? walkerLocation;

  /// Walker profile image.
  final String? walkerImageUrl;

  /// Remaining route only.
  final List<LatLng> routePoints;

  /// Walker heading in degrees.
  final double? walkerHeading;

  /// Recenter button callback.
  final VoidCallback? onMyLocationPressed;

  @override
  State<WalkerAcceptMap> createState() =>
      _WalkerAcceptMapState();
}

class _WalkerAcceptMapState
    extends State<WalkerAcceptMap> {
  late final MapController _mapController;

  LatLng? _previousWalkerLocation;

  @override
  void initState() {
    super.initState();

    _mapController = MapController();

    _previousWalkerLocation =
        widget.walkerLocation;
  }

  @override
  void didUpdateWidget(
    covariant WalkerAcceptMap oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    final oldWalker =
        oldWidget.walkerLocation;

    final newWalker =
        widget.walkerLocation;

    if (newWalker == null) {
      return;
    }

    if (oldWalker == null) {
      _previousWalkerLocation = newWalker;
      return;
    }

    if (_hasLocationChanged(
      oldWalker,
      newWalker,
    )) {
      _previousWalkerLocation = newWalker;

      _followWalker(newWalker);
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[
      // ========================================================
      // OWNER SAVED LOCATION
      // ========================================================

      Marker(
        point: widget.ownerLocation,
        width: 70,
        height: 70,
        alignment: Alignment.center,
        child: const OwnerHomeMarker(),
      ),

      // ========================================================
      // WALKER LIVE LOCATION
      // ========================================================

      if (widget.walkerLocation != null)
        Marker(
          point: widget.walkerLocation!,
          width: 78,
          height: 78,
          alignment: Alignment.center,
          child: Transform.rotate(
            angle: _headingRadians,
            child: WalkerLocationMarker(
              imageUrl:
                  widget.walkerImageUrl,
              isLive: true,
            ),
          ),
        ),
    ];

    return Stack(
      children: [
        // ======================================================
        // OSM MAP
        // ======================================================

        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter:
                widget.ownerLocation,
            initialZoom: 14.5,
            minZoom: 5,
            maxZoom: 19,
            interactionOptions:
                const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            // ==================================================
            // OPEN STREET MAP TILES
            // ==================================================

            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName:
                  'com.doojowalker.app',
            ),

            // ==================================================
            // REMAINING ROUTE
            // ==================================================

            if (widget.routePoints.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points:
                        widget.routePoints,
                    strokeWidth: 5,
                    color: Theme.of(context)
                        .colorScheme
                        .primary,
                    borderStrokeWidth: 2,
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

        // ======================================================
        // LIVE BADGE
        // ======================================================

        Positioned(
          left: 16,
          top: 16,
          child: const _LiveMapBadge(),
        ),

        // ======================================================
        // RECENTER BUTTON
        // ======================================================

        Positioned(
          right: 16,
          bottom: 180,
          child: _MapLocationButton(
            onPressed: () {
              _recenterOwner();

              widget
                  .onMyLocationPressed
                  ?.call();
            },
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // FOLLOW WALKER
  // ==========================================================

  void _followWalker(
    LatLng walkerLocation,
  ) {
    if (!mounted) {
      return;
    }

    try {
      _mapController.move(
        walkerLocation,
        _mapController.camera.zoom,
      );
    } catch (_) {
      // Map controller may not be ready yet.
    }
  }

  // ==========================================================
  // RECENTER OWNER
  // ==========================================================

  void _recenterOwner() {
    if (!mounted) {
      return;
    }

    try {
      _mapController.move(
        widget.ownerLocation,
        15.5,
      );
    } catch (_) {
      // Map controller may not be ready yet.
    }
  }

  // ==========================================================
  // LOCATION CHANGE CHECK
  // ==========================================================

  bool _hasLocationChanged(
    LatLng oldLocation,
    LatLng newLocation,
  ) {
    const threshold = 0.00001;

    return (oldLocation.latitude -
                    newLocation.latitude)
                .abs() >
            threshold ||
        (oldLocation.longitude -
                    newLocation.longitude)
                .abs() >
            threshold;
  }

  // ==========================================================
  // WALKER HEADING
  // ==========================================================

  double get _headingRadians {
    final heading =
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
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            offset: Offset(0, 3),
            color: Color(0x22000000),
          ),
        ],
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.primary,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'LIVE',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(
                  fontWeight:
                      FontWeight.w800,
                  letterSpacing: 0.6,
                ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MAP LOCATION BUTTON
// ============================================================

class _MapLocationButton
    extends StatelessWidget {
  const _MapLocationButton({
    required this.onPressed,
  });

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      shape:
          const CircleBorder(),
      color: Colors.white,
      child: InkWell(
        onTap: onPressed,
        customBorder:
            const CircleBorder(),
        child: const SizedBox(
          width: 50,
          height: 50,
          child: Icon(
            Icons.my_location_rounded,
            size: 23,
          ),
        ),
      ),
    );
  }
}
