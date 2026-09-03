import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LiveWalkMap extends StatefulWidget {
  const LiveWalkMap({
    super.key,
    required this.walkerLocation,
    required this.destination,
    required this.routePoints,
    required this.onRecenter,
  });

  final LatLng? walkerLocation;
  final LatLng? destination;
  final List<LatLng> routePoints;
  final VoidCallback onRecenter;

  @override
  State<LiveWalkMap> createState() =>
      _LiveWalkMapState();
}

class _LiveWalkMapState
    extends State<LiveWalkMap> {
  final MapController _mapController =
      MapController();

  bool _initialCentered = false;

  static const Color primary =
      Color(0xFFFF8A00);

  static const Color green =
      Color(0xFF16A34A);

  static const Color red =
      Color(0xFFDC2626);

  @override
  void didUpdateWidget(
    covariant LiveWalkMap oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    final LatLng? current =
        widget.walkerLocation;

    if (current != null &&
        oldWidget.walkerLocation !=
            current) {
      if (!_initialCentered) {
        _initialCentered = true;

        WidgetsBinding.instance
            .addPostFrameCallback(
          (_) {
            if (!mounted) return;

            _mapController.move(
              current,
              17,
            );
          },
        );
      }
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final LatLng center =
        widget.walkerLocation ??
            widget.destination ??
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

            if (widget.routePoints.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points:
                        widget.routePoints,
                    strokeWidth: 5,
                    color: primary,
                  ),
                ],
              ),

            MarkerLayer(
              markers: [
                if (widget.destination != null)
                  Marker(
                    point:
                        widget.destination!,
                    width: 54,
                    height: 64,
                    child: _destinationMarker(),
                  ),

                if (widget.walkerLocation != null)
                  Marker(
                    point:
                        widget.walkerLocation!,
                    width: 60,
                    height: 70,
                    child: _walkerMarker(),
                  ),
              ],
            ),
          ],
        ),

        Positioned(
          left: 14,
          top: 14,
          child: _statusBadge(),
        ),

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
              onTap: widget.onRecenter,
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

  Widget _statusBadge() {
    final bool hasLocation =
        widget.walkerLocation != null;

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(10),
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
                hasLocation
                    ? green
                    : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(
            hasLocation
                ? 'Live Location'
                : 'Waiting for walk',
            style: const TextStyle(
              fontSize: 11,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

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
}
