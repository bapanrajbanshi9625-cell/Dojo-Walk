import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// ============================================================
// INSTA WALK MAP + RADAR
// ============================================================
//
// Contains:
// • Interactive OpenStreetMap
// • Owner search-location pin
// • Search-radius circle
// • Animated radar
// • Radar rings
// • Radar pulse
// • Radar sweep
// • LIVE SEARCH badge
// • Search-radius badge
// • Map movement / zoom
//
// RadarPainter is intentionally kept in this same file.
// No separate radar_painter.dart is required.
// ============================================================

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
        height: 190,
        width: double.infinity,
        child: Stack(
          children: [
            // ==================================================
            // MAP
            // ==================================================

            FlutterMap(
              options: MapOptions(
                initialCenter: ownerPoint,
                initialZoom: 14.5,

                // REAL INTERACTIVE MAP
                interactionOptions:
                    const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
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
                ),

                // ==================================================
                // SEARCH AREA
                // ==================================================

                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: ownerPoint,
                      radius:
                          searchRadiusKm * 1000,
                      useRadiusInMeter: true,
                      color: const Color(0xFF65D6C8)
                          .withValues(alpha: .10),
                      borderColor:
                          const Color(0xFF65D6C8)
                              .withValues(alpha: .65),
                      borderStrokeWidth: 1.5,
                    ),
                  ],
                ),

                // ==================================================
                // OWNER SEARCH LOCATION
                // ==================================================

                MarkerLayer(
                  markers: [
                    Marker(
                      point: ownerPoint,
                      width: 52,
                      height: 62,
                      child: Column(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration:
                                BoxDecoration(
                              shape:
                                  BoxShape.circle,
                              color:
                                  const Color(
                                0xFF243746,
                              ),
                              border:
                                  Border.all(
                                color:
                                    Colors.white,
                                width: 3,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color:
                                      Colors.black26,
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                  offset:
                                      Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons
                                  .location_on_rounded,
                              color:
                                  Colors.white,
                              size: 23,
                            ),
                          ),

                          // Small pin tail
                          Transform.translate(
                            offset:
                                const Offset(
                              0,
                              -8,
                            ),
                            child:
                                const Icon(
                              Icons
                                  .arrow_drop_down,
                              color:
                                  Color(
                                0xFF243746,
                              ),
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // ==================================================
            // RADAR OVERLAY
            // ==================================================

            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: radarAnimation,
                  builder: (_, __) {
                    return CustomPaint(
                      painter: RadarPainter(
                        progress:
                            radarAnimation.value,
                      ),
                    );
                  },
                ),
              ),
            ),

            // ==================================================
            // TOP LEFT — LIVE SEARCH
            // ==================================================

            Positioned(
              left: 10,
              top: 10,
              child: _MapBadge(
                icon:
                    Icons.radar_rounded,
                text: 'LIVE SEARCH',
              ),
            ),

            // ==================================================
            // TOP RIGHT — MOVE MAP
            // ==================================================

            Positioned(
              right: 10,
              top: 10,
              child: _MapBadge(
                icon:
                    Icons.pan_tool_alt_rounded,
                text: 'MOVE',
                light: true,
              ),
            ),

            // ==================================================
            // BOTTOM LEFT — LOCATION
            // ==================================================

            Positioned(
              left: 10,
              bottom: 10,
              child: _MapBadge(
                icon:
                    Icons.location_on_rounded,
                text: 'YOUR LOCATION',
                light: true,
              ),
            ),

            // ==================================================
            // BOTTOM RIGHT — SEARCH RADIUS
            // ==================================================

            Positioned(
              right: 10,
              bottom: 10,
              child: _MapBadge(
                icon:
                    Icons.near_me_rounded,
                text:
                    '${searchRadiusKm.toStringAsFixed(1)} km',
                light: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// MAP BADGE
// ============================================================

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
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: light
            ? Colors.white
                .withValues(alpha: .94)
            : const Color(0xFF172733)
                .withValues(alpha: .90),
        borderRadius:
            BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 7,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: light
                ? const Color(
                    0xFF243746,
                  )
                : Colors.white,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: light
                  ? const Color(
                      0xFF243746,
                    )
                  : Colors.white,
              fontSize: 9,
              fontWeight:
                  FontWeight.w900,
              letterSpacing: .3,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// RADAR PAINTER
// ============================================================

class RadarPainter extends CustomPainter {
  final double progress;

  RadarPainter({
    required this.progress,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final Offset center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final double radius =
        math.min(
              size.width,
              size.height,
            ) *
            .42;

    // ========================================================
    // RADAR RINGS
    // ========================================================

    final Paint rings = Paint()
      ..style =
          PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color =
          const Color(0xFF65D6C8)
              .withValues(alpha: .30);

    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(
        center,
        radius * i / 3,
        rings,
      );
    }

    // ========================================================
    // OUTER SOFT RING
    // ========================================================

    final Paint outerRing = Paint()
      ..style =
          PaintingStyle.stroke
      ..strokeWidth = 2
      ..color =
          const Color(0xFF65D6C8)
              .withValues(alpha: .16);

    canvas.drawCircle(
      center,
      radius,
      outerRing,
    );

    // ========================================================
    // PULSE
    // ========================================================

    final double pulse =
        radius *
        (.25 + progress * .75);

    final Paint pulsePaint = Paint()
      ..style =
          PaintingStyle.stroke
      ..strokeWidth = 2
      ..color =
          const Color(0xFF8FFFEF)
              .withValues(
        alpha:
            (1 - progress) * .65,
      );

    canvas.drawCircle(
      center,
      pulse,
      pulsePaint,
    );

    // ========================================================
    // RADAR SWEEP
    // ========================================================

    final double angle =
        progress *
        math.pi *
        2;

    final Paint sweep = Paint()
      ..shader = SweepGradient(
        startAngle:
            angle - 1.0,
        endAngle: angle,
        colors: [
          const Color(0xFF65D6C8)
              .withValues(alpha: 0),
          const Color(0xFF8FFFEF)
              .withValues(alpha: .55),
        ],
      ).createShader(
        Rect.fromCircle(
          center: center,
          radius: radius,
        ),
      );

    canvas.drawCircle(
      center,
      radius,
      sweep,
    );

    // ========================================================
    // CENTER GLOW
    // ========================================================

    final Paint centerGlow = Paint()
      ..color =
          const Color(0xFF8FFFEF)
              .withValues(alpha: .10);

    canvas.drawCircle(
      center,
      18,
      centerGlow,
    );
  }

  @override
  bool shouldRepaint(
    covariant RadarPainter oldDelegate,
  ) {
    return oldDelegate.progress !=
        progress;
  }
}
