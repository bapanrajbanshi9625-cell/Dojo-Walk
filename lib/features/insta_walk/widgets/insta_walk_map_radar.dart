import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// ============================================================
// INSTA WALK MAP + RADAR
// ============================================================
//
// • Interactive OpenStreetMap
// • Owner search-location pin
// • Search-radius circle
// • Animated radar
// • Radar rings
// • Radar pulse
// • Radar sweep
// • My Location button
//
// ============================================================

class InstaWalkMapRadar extends StatefulWidget {
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
  State<InstaWalkMapRadar> createState() =>
      _InstaWalkMapRadarState();
}

class _InstaWalkMapRadarState
    extends State<InstaWalkMapRadar> {
  // ==========================================================
  // MAP CONTROLLER
  // ==========================================================

  final MapController _mapController =
      MapController();

  // ==========================================================
  // MY LOCATION
  // ==========================================================

  void _goToMyLocation() {
    _mapController.move(
      widget.ownerPoint,
      14.5,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    final Color primary =
        colors.primary;

    final Color surface =
        colors.surface;

    final Color onSurface =
        colors.onSurface;

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(20),
      child: SizedBox(
        height: 270,
        width: double.infinity,
        child: Stack(
          children: [
            // ==================================================
            // MAP
            // ==================================================

            FlutterMap(
              mapController:
                  _mapController,
              options: MapOptions(
                initialCenter:
                    widget.ownerPoint,
                initialZoom: 14.5,
                interactionOptions:
                    const InteractionOptions(
                  flags:
                      InteractiveFlag.all,
                ),
              ),
              children: [
                // ==============================================
                // OPEN STREET MAP
                // ==============================================

                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName:
                      'com.doojowalker.app',
                ),

                // ==============================================
                // SEARCH RADIUS
                // ==============================================

                CircleLayer(
                  circles: [
                    CircleMarker(
                      point:
                          widget.ownerPoint,
                      radius:
                          widget.searchRadiusKm *
                              1000,
                      useRadiusInMeter:
                          true,
                      color:
                          primary.withValues(
                        alpha: .10,
                      ),
                      borderColor:
                          primary.withValues(
                        alpha: .55,
                      ),
                      borderStrokeWidth:
                          1.5,
                    ),
                  ],
                ),

                // ==============================================
                // OWNER LOCATION PIN
                // ==============================================

                MarkerLayer(
                  markers: [
                    Marker(
                      point:
                          widget.ownerPoint,
                      width: 54,
                      height: 64,
                      child: Column(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration:
                                BoxDecoration(
                              shape:
                                  BoxShape.circle,
                              color:
                                  colors
                                      .surface,
                              border:
                                  Border.all(
                                color:
                                    primary,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      Colors
                                          .black
                                          .withValues(
                                    alpha: .22,
                                  ),
                                  blurRadius:
                                      10,
                                  offset:
                                      const Offset(
                                    0,
                                    3,
                                  ),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons
                                  .location_on_rounded,
                              color:
                                  primary,
                              size: 25,
                            ),
                          ),

                          Transform.translate(
                            offset:
                                const Offset(
                              0,
                              -8,
                            ),
                            child: Icon(
                              Icons
                                  .arrow_drop_down,
                              color:
                                  surface,
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
                  animation:
                      widget.radarAnimation,
                  builder: (
                    BuildContext context,
                    Widget? child,
                  ) {
                    return CustomPaint(
                      painter:
                          RadarPainter(
                        progress:
                            widget
                                .radarAnimation
                                .value,
                        color:
                            primary,
                        glowColor:
                            colors
                                .secondary,
                      ),
                    );
                  },
                ),
              ),
            ),

            // ==================================================
            // MY LOCATION BUTTON
            // ==================================================

            Positioned(
              right: 12,
              bottom: 12,
              child: Material(
                color: Colors.transparent,
                elevation: 4,
                shadowColor:
                    Colors.black.withValues(
                  alpha: .22,
                ),
                borderRadius:
                    BorderRadius.circular(
                  15,
                ),
                child: InkWell(
                  onTap:
                      _goToMyLocation,
                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration:
                        BoxDecoration(
                      color: surface,
                      borderRadius:
                          BorderRadius
                              .circular(
                        15,
                      ),
                      border: Border.all(
                        color: primary
                            .withValues(
                          alpha: .18,
                        ),
                      ),
                    ),
                    child: Icon(
                      Icons
                          .my_location_rounded,
                      color: primary,
                      size: 23,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// RADAR PAINTER
// ============================================================

class RadarPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color glowColor;

  RadarPainter({
    required this.progress,
    required this.color,
    required this.glowColor,
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
          color.withValues(
        alpha: .25,
      );

    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(
        center,
        radius * i / 3,
        rings,
      );
    }

    // ========================================================
    // OUTER RING
    // ========================================================

    final Paint outerRing = Paint()
      ..style =
          PaintingStyle.stroke
      ..strokeWidth = 2
      ..color =
          color.withValues(
        alpha: .14,
      );

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
          glowColor.withValues(
        alpha:
            (1 - progress) * .55,
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
          color.withValues(
            alpha: 0,
          ),
          glowColor.withValues(
            alpha: .42,
          ),
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
          glowColor.withValues(
        alpha: .08,
      );

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
            progress ||
        oldDelegate.color != color ||
        oldDelegate.glowColor !=
            glowColor;
  }
}
