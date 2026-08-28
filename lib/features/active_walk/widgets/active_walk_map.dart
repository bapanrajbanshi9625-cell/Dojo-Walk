import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/active_walk.dart';

class ActiveWalkMap extends StatefulWidget {
  const ActiveWalkMap({
    super.key,
    required this.walk,
  });

  final ActiveWalk walk;

  @override
  State<ActiveWalkMap> createState() =>
      _ActiveWalkMapState();
}

class _ActiveWalkMapState
    extends State<ActiveWalkMap> {
  final MapController _mapController =
      MapController();

  bool _initialCentered = false;

  static const Color primary =
      Color(0xFFFF8A00);

  static const Color red =
      Color(0xFFDC2626);

  @override
  void didUpdateWidget(
    covariant ActiveWalkMap oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    final LatLng? oldLocation =
        oldWidget.walk.walkerLocation;

    final LatLng? newLocation =
        widget.walk.walkerLocation;

    if (newLocation != null &&
        (oldLocation == null ||
            oldLocation.latitude !=
                newLocation.latitude ||
            oldLocation.longitude !=
                newLocation.longitude)) {
      if (_initialCentered) {
        _mapController.move(
          newLocation,
          17,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final LatLng center =
        widget.walk.walkerLocation ??
            widget.walk.destination ??
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
            onMapReady: () {
              if (_initialCentered) {
                return;
              }

              _initialCentered = true;

              final LatLng? location =
                  widget.walk.walkerLocation ??
                      widget.walk.destination;

              if (location != null) {
                _mapController.move(
                  location,
                  16,
                );
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName:
                  'com.doojowalker.app',
            ),

            if (widget
                    .walk
                    .routePoints
                    .length >=
                2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: widget
                        .walk
                        .routePoints,
                    strokeWidth: 5,
                    color: primary,
                  ),
                ],
              ),

            MarkerLayer(
              markers: [
                if (widget.walk.destination !=
                    null)
                  Marker(
                    point: widget
                        .walk
                        .destination!,
                    width: 56,
                    height: 68,
                    child:
                        _destinationMarker(),
                  ),

                if (widget.walk.walkerLocation !=
                    null)
                  Marker(
                    point: widget
                        .walk
                        .walkerLocation!,
                    width: 60,
                    height: 70,
                    child:
                        _walkerMarker(),
                  ),
              ],
            ),
          ],
        ),

        Positioned(
          left: 14,
          top: 14,
          child: Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(11),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Row(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on_rounded,
                  color: primary,
                  size: 17,
                ),
                SizedBox(width: 5),
                Text(
                  'Walker Location',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
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
              onTap: _recenter,
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

  void _recenter() {
    final LatLng? location =
        widget.walk.walkerLocation;

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
