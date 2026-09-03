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
  static const Color green = Color(0xFF16A34A);
  static const Color red = Color(0xFFDC2626);

  @override
  void didUpdateWidget(covariant LiveWalkMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    final LatLng? current = widget.walkerLocation;

    if (current != null &&
        oldWidget.walkerLocation != current &&
        !_initialCentered) {
      _initialCentered = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        _mapController.move(current, 17);
      });
    }
  }

  void _recenterMap() {
    final LatLng? location = widget.walkerLocation;

    if (location == null) {
      widget.onRecenter();
      return;
    }

    _mapController.move(location, 17);
  }

  @override
  Widget build(BuildContext context) {
    final LatLng center =
        widget.walkerLocation ??
        widget.destination ??
        const LatLng(28.6139, 77.2090);

    return Stack(
      children: [
        FlutterMap(
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
              userAgentPackageName: 'com.doojowalker.app',
            ),

            if (widget.routePoints.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: widget.routePoints,
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
                    width: 54,
                    height: 64,
                    child: _destinationMarker(),
                  ),

                if (widget.walkerLocation != null)
                  Marker(
                    point: widget.walkerLocation!,
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
            borderRadius: BorderRadius.circular(13),
            child: InkWell(
              borderRadius: BorderRadius.circular(13),
              onTap: _recenterMap,
              child: const SizedBox(
                width: 46,
                height: 46,
                child: Icon(
                  Icons.my_location_rounded,
                  color: primary,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusBadge() {
    final bool hasLocation = widget.walkerLocation != null;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            offset: Offset(0, 4),
            color: Color(0x22000000),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hasLocation ? green : red,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            hasLocation ? 'Live location' : 'Waiting for location',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _walkerMarker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primary,
            border: Border.all(
              color: Colors.white,
              width: 3,
            ),
            boxShadow: const [
              BoxShadow(
                blurRadius: 10,
                offset: Offset(0, 4),
                color: Color(0x44000000),
              ),
            ],
          ),
          child: const Icon(
            Icons.directions_walk_rounded,
            color: Colors.white,
            size: 25,
          ),
        ),
        CustomPaint(
          size: const Size(14, 8),
          painter: _MarkerArrowPainter(primary),
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
            shape: BoxShape.circle,
            color: red,
            border: Border.all(
              color: Colors.white,
              width: 3,
            ),
            boxShadow: const [
              BoxShadow(
                blurRadius: 9,
                offset: Offset(0, 4),
                color: Color(0x44000000),
              ),
            ],
          ),
          child: const Icon(
            Icons.home_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        CustomPaint(
          size: const Size(14, 8),
          painter: _MarkerArrowPainter(red),
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

class _MarkerArrowPainter extends CustomPainter {
  const _MarkerArrowPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final Path path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MarkerArrowPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
