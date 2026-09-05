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
  State<LiveWalkMap> createState() => _LiveWalkMapState();
}

class _LiveWalkMapState extends State<LiveWalkMap> {
  final MapController _mapController = MapController();

  bool _initialCentered = false;

  static const Color primary = Color(0xFFFF8A00);
  static const Color red = Color(0xFFDC2626);

  @override
  void didUpdateWidget(covariant LiveWalkMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    final current = widget.walkerLocation;

    if (current != null &&
        oldWidget.walkerLocation != current &&
        !_initialCentered) {
      _initialCentered = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        _mapController.move(
          current,
          17,
        );
      });
    }
  }

  List<LatLng> _buildRoute() {
    final route = List<LatLng>.from(widget.routePoints);
    final walker = widget.walkerLocation;

    if (walker == null) {
      return route;
    }

    if (route.isEmpty) {
      if (widget.destination != null) {
        return [
          widget.destination!,
          walker,
        ];
      }

      return [walker];
    }

    final last = route.last;

    if (last.latitude != walker.latitude ||
        last.longitude != walker.longitude) {
      route.add(walker);
    }

    return route;
  }

  @override
  Widget build(BuildContext context) {
    final center = widget.walkerLocation ??
        widget.destination ??
        const LatLng(28.6139, 77.2090);

    final route = _buildRoute();

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
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.doojowalker.app',
        ),

        if (route.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: route,
                strokeWidth: 5,
                color: primary,
              ),
            ],
          ),

        MarkerLayer(
          markers: [
            if (widget.destination != null)
              Marker(
                point: widget.destination!,
                width: 52,
                height: 58,
                child: _destinationMarker(),
              ),
            if (widget.walkerLocation != null)
              Marker(
                point: widget.walkerLocation!,
                width: 52,
                height: 58,
                child: _walkerMarker(),
              ),
          ],
        ),
      ],
    );
  }

  Widget _walkerMarker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: primary,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 10,
                offset: const Offset(0, 4),
                color: Colors.black.withValues(alpha: 0.24),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.directions_walk_rounded,
                color: Colors.white,
                size: 24,
              ),
              Positioned(
                right: 4,
                bottom: 5,
                child: Container(
                  width: 17,
                  height: 17,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primary,
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.pets_rounded,
                    color: primary,
                    size: 10,
                  ),
                ),
              ),
            ],
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: red,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 9,
                offset: const Offset(0, 4),
                color: Colors.black.withValues(alpha: 0.25),
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

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
