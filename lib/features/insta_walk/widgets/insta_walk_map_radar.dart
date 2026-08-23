import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../painters/radar_painter.dart';

class InstaWalkMapRadar extends StatelessWidget {
  final LatLng ownerPoint;
  final double searchRadiusKm;
  final Animation<double> radarAnimation;

  const InstaWalkMapRadar({
    super.key,
    required this.ownerPoint,
    required this.searchRadiusKm,
    required this.radarAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 175,
        width: double.infinity,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: ownerPoint,
                initialZoom: 14.5,
                interactionOptions:
                    const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName:
                      'com.doojowalker.app',
                ),
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: ownerPoint,
                      radius:
                          searchRadiusKm * 1000,
                      useRadiusInMeter: true,
                      color: const Color(0xFF65D6C8)
                          .withValues(alpha: .08),
                      borderColor:
                          const Color(0xFF65D6C8)
                              .withValues(alpha: .60),
                      borderStrokeWidth: 1.5,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: ownerPoint,
                      width: 42,
                      height: 42,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF243746),
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
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
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: radarAnimation,
                  builder: (_, __) {
                    return CustomPaint(
                      painter: RadarPainter(
                        progress: radarAnimation.value,
                      ),
                    );
                  },
                ),
              ),
            ),

            Positioned(
              left: 10,
              top: 10,
              child: _MapBadge(
                icon: Icons.radar_rounded,
                text: 'LIVE SEARCH',
              ),
            ),

            Positioned(
              right: 10,
              bottom: 10,
              child: _MapBadge(
                icon: Icons.near_me_rounded,
                text:
                    '${searchRadiusKm.toStringAsFixed(0)} km',
                light: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool light;

  const _MapBadge({
    required this.icon,
    required this.text,
    this.light = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: light
            ? Colors.white.withValues(alpha: .94)
            : const Color(0xFF172733)
                .withValues(alpha: .88),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: light
                ? const Color(0xFF243746)
                : Colors.white,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: light
                  ? const Color(0xFF243746)
                  : Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
