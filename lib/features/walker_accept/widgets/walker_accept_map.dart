import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'owner_home_marker.dart';
import 'walker_location_marker.dart';

class WalkerAcceptMap extends StatelessWidget {
  const WalkerAcceptMap({
    super.key,
    required this.ownerLocation,
    required this.walkerLocation,
    required this.walkerImageUrl,
    this.routePoints = const <LatLng>[],
    this.walkerHeading,
    this.onMyLocationPressed,
  });

  /// Owner's saved Firestore location.
  final LatLng ownerLocation;

  /// Walker's current live Firestore location.
  final LatLng? walkerLocation;

  /// Walker profile image.
  final String? walkerImageUrl;

  /// Remaining route only.
  ///
  /// The route service will provide only the portion
  /// of the route that is still left for the Walker.
  final List<LatLng> routePoints;

  /// Walker's current heading in degrees.
  final double? walkerHeading;

  /// Re-centers the map on the Owner's saved location.
  final VoidCallback? onMyLocationPressed;

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[
      // ========================================================
      // OWNER — SAVED LOCATION
      // ========================================================

      Marker(
        point: ownerLocation,
        width: 70,
        height: 70,
        alignment: Alignment.center,
        child: const OwnerHomeMarker(),
      ),

      // ========================================================
      // WALKER — LIVE LOCATION
      // ========================================================

      if (walkerLocation != null)
        Marker(
          point: walkerLocation!,
          width: 78,
          height: 78,
          alignment: Alignment.center,
          child: Transform.rotate(
            angle: _headingRadians,
            child: WalkerLocationMarker(
              imageUrl: walkerImageUrl,
              isLive: true,
            ),
          ),
        ),
    ];

    return Stack(
      children: [
        // ======================================================
        // OPEN STREET MAP
        // ======================================================

        FlutterMap(
          options: MapOptions(
            initialCenter: ownerLocation,
            initialZoom: 14.5,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName:
                  'com.doojowalker.app',
            ),

            // ==================================================
            // REMAINING ROUTE
            // ==================================================

            if (routePoints.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routePoints,
                    strokeWidth: 5,
                    color: Theme.of(context)
                        .colorScheme
                        .primary,
                    borderStrokeWidth: 2,
                    borderColor: Colors.white,
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
        // MAP CONTROL
        // ======================================================

        Positioned(
          right: 16,
          bottom: 16,
          child: _MapLocationButton(
            onPressed: onMyLocationPressed,
          ),
        ),

        // ======================================================
        // LIVE BADGE
        // ======================================================

        Positioned(
          left: 16,
          top: 16,
          child: _LiveMapBadge(),
        ),
      ],
    );
  }

  double get _headingRadians {
    if (walkerHeading == null) {
      return 0;
    }

    return walkerHeading! * 3.141592653589793 / 180;
  }
}

// ============================================================
// LIVE BADGE
// ============================================================

class _LiveMapBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
                  fontWeight: FontWeight.w800,
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

class _MapLocationButton extends StatelessWidget {
  const _MapLocationButton({
    required this.onPressed,
  });

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      shape: const CircleBorder(),
      color: Colors.white,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
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
