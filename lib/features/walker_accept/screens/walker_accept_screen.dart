import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../screens/live_walk_screen.dart';
import '../models/walker_accept_data.dart';
import '../services/walker_accept_service.dart';
import '../services/walker_route_service.dart';
import '../widgets/walker_accept_map.dart';

class WalkerAcceptScreen extends StatefulWidget {
  const WalkerAcceptScreen({
    super.key,
    required this.requestId,
    this.onReached,
    this.onCall,
    this.onChat,
    this.onHelp,
  });

  final String requestId;
  final ValueChanged<WalkerAcceptData>? onReached;
  final VoidCallback? onCall;
  final VoidCallback? onChat;
  final VoidCallback? onHelp;

  @override
  State<WalkerAcceptScreen> createState() => _WalkerAcceptScreenState();
}

class _WalkerAcceptScreenState extends State<WalkerAcceptScreen> {
  late final WalkerAcceptService _acceptService;
  late final WalkerRouteService _routeService;

  StreamSubscription<WalkerAcceptData?>? _requestSubscription;

  WalkerAcceptData? _data;
  WalkerRouteResult? _route;

  bool _loadingRoute = false;
  bool _reachedHandled = false;

  LatLng? _lastRouteWalkerLocation;

  static const double _routeRefreshDistanceMeters = 50.0;

  final Distance _distance = const Distance();

  @override
  void initState() {
    super.initState();

    _acceptService = WalkerAcceptService();
    _routeService = WalkerRouteService();

    _listenToRequest();
  }

  void _listenToRequest() {
    final String requestId = widget.requestId.trim();

    if (requestId.isEmpty) {
      return;
    }

    _requestSubscription =
        _acceptService.watchRequest(requestId).listen(
      (WalkerAcceptData? data) {
        if (!mounted) return;

        if (data == null) {
          setState(() {
            _data = null;
          });
          return;
        }

        setState(() {
          _data = data;
        });

        _checkReached(data);

        if (!data.isReached) {
          _refreshRoute(data);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!mounted) return;

        debugPrint(
          'WalkerAcceptScreen request stream error: $error',
        );
      },
    );
  }

  void _checkReached(WalkerAcceptData data) {
    if (_reachedHandled || !data.isReached) {
      return;
    }

    _reachedHandled = true;

    widget.onReached?.call(data);

    unawaited(_openLiveWalk(data.requestId));
  }

  Future<void> _openLiveWalk(String requestId) async {
    await _requestSubscription?.cancel();
    _requestSubscription = null;

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => LiveWalkScreen(
          activeWalkId: requestId,
          isWalker: false,
        ),
      ),
    );
  }

  void _refreshRoute(WalkerAcceptData data) {
    final LatLng? walkerLocation =
        _latLngFromGeoPoint(data.walkerLocation);

    final LatLng? ownerLocation =
        _latLngFromGeoPoint(data.ownerLocation);

    if (walkerLocation == null || ownerLocation == null) {
      return;
    }

    if (_loadingRoute) {
      return;
    }

    final LatLng? previous = _lastRouteWalkerLocation;

    if (previous != null) {
      final double movedMeters = _distance.as(
        LengthUnit.Meter,
        previous,
        walkerLocation,
      );

      if (movedMeters < _routeRefreshDistanceMeters) {
        return;
      }
    }

    unawaited(
      _loadRoute(
        walkerLocation: walkerLocation,
        ownerLocation: ownerLocation,
      ),
    );
  }

  Future<void> _loadRoute({
    required LatLng walkerLocation,
    required LatLng ownerLocation,
  }) async {
    if (_loadingRoute) {
      return;
    }

    setState(() {
      _loadingRoute = true;
    });

    try {
      final WalkerRouteResult? result =
          await _routeService.getRoute(
        walkerLocation: walkerLocation,
        ownerLocation: ownerLocation,
      );

      if (!mounted) return;

      if (result != null) {
        setState(() {
          _route = result;
          _lastRouteWalkerLocation = walkerLocation;
        });

        // Firestore may have changed while the route was loading.
        final WalkerAcceptData? latestData = _data;

        if (latestData != null && !latestData.isReached) {
          final LatLng? latestWalker =
              _latLngFromGeoPoint(latestData.walkerLocation);

          if (latestWalker != null) {
            final LatLng? lastRoute =
                _lastRouteWalkerLocation;

            if (lastRoute != null) {
              final double movedMeters = _distance.as(
                LengthUnit.Meter,
                lastRoute,
                latestWalker,
              );

              if (movedMeters >= _routeRefreshDistanceMeters) {
                unawaited(_loadRouteForLatestData(latestData));
              }
            }
          }
        }
      }
    } catch (error, stackTrace) {
      debugPrint(
        'WalkerAcceptScreen route error: $error',
      );
      debugPrint(
        stackTrace.toString(),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingRoute = false;
        });
      }
    }
  }

  Future<void> _loadRouteForLatestData(
    WalkerAcceptData data,
  ) async {
    final LatLng? walkerLocation =
        _latLngFromGeoPoint(data.walkerLocation);

    final LatLng? ownerLocation =
        _latLngFromGeoPoint(data.ownerLocation);

    if (walkerLocation == null || ownerLocation == null) {
      return;
    }

    await _loadRoute(
      walkerLocation: walkerLocation,
      ownerLocation: ownerLocation,
    );
  }

  LatLng? _latLngFromGeoPoint(dynamic point) {
    if (point == null) {
      return null;
    }

    final double latitude = point.latitude;
    final double longitude = point.longitude;

    if (!_isValidCoordinate(latitude, longitude)) {
      return null;
    }

    return LatLng(latitude, longitude);
  }

  bool _isValidCoordinate(
    double latitude,
    double longitude,
  ) {
    if (latitude == 0 && longitude == 0) {
      return false;
    }

    if (latitude < -90 || latitude > 90) {
      return false;
    }

    if (longitude < -180 || longitude > 180) {
      return false;
    }

    return true;
  }

  @override
  void dispose() {
    unawaited(_requestSubscription?.cancel());

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final WalkerAcceptData? data = _data;

    if (data == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F6F8),
        appBar: AppBar(
          title: const Text('Walker'),
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final LatLng? ownerLocation =
        _latLngFromGeoPoint(data.ownerLocation);

    final LatLng? walkerLocation =
        _latLngFromGeoPoint(data.walkerLocation);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: WalkerAcceptMap(
                ownerLocation:
                    ownerLocation ??
                    const LatLng(0, 0),
                walkerLocation: walkerLocation,
                walkerImageUrl:
                    data.walkerProfileImage?.trim(),
                routePoints:
                    _route?.routePoints ?? const <LatLng>[],
                walkerHeading: data.walkerHeading,
                onMyLocationPressed: () {
                  // Map handles the live walker marker.
                },
              ),
            ),

            _buildTopHeader(data),

            _buildBottomPanel(data),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader(WalkerAcceptData data) {
    return Positioned(
      top: 12,
      left: 16,
      right: 16,
      child: Material(
        elevation: 5,
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 13,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1E8),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.pets_rounded,
                  color: Color(0xFFFF7A00),
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Walker is on the way',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.walkerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF171717),
                      ),
                    ),
                  ],
                ),
              ),
              _buildLiveBadge(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8EF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            size: 8,
            color: Color(0xFF1FA463),
          ),
          SizedBox(width: 5),
          Text(
            'LIVE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1FA463),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(WalkerAcceptData data) {
    final String walkerPhone =
        data.walkerPhone?.trim() ?? '';

    final bool hasDistance =
        data.distanceMeters > 0 ||
        data.distanceKm > 0;

    final bool hasEta =
        data.etaMinutes > 0;

    return Positioned(
      left: 12,
      right: 12,
      bottom: 12,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(24),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            14,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _buildWalkerAvatar(data),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.walkerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF171717),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              walkerPhone.isNotEmpty
                                  ? Icons.phone_rounded
                                  : Icons.location_on_rounded,
                              size: 14,
                              color: const Color(0xFF7A7A7A),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                walkerPhone.isNotEmpty
                                    ? walkerPhone
                                    : 'Walker is approaching',
                                maxLines: 1,
                                overflow:
                                    TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF777777),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildCallButton(data),
                ],
              ),

              const SizedBox(height: 16),

              _buildTravelInfo(
                data: data,
                hasDistance: hasDistance,
                hasEta: hasEta,
              ),

              const SizedBox(height: 12),

              if (_loadingRoute)
                _buildRouteUpdating(),

              const SizedBox(height: 4),

              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Chat',
                      onTap: widget.onChat,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.help_outline_rounded,
                      label: 'Help',
                      onTap: widget.onHelp,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalkerAvatar(WalkerAcceptData data) {
    final String imageUrl =
        data.walkerProfileImage?.trim() ?? '';

    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F1F3),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder:
                  (context, error, stackTrace) {
                return const Icon(
                  Icons.person_rounded,
                  size: 30,
                  color: Color(0xFF858585),
                );
              },
            )
          : const Icon(
              Icons.person_rounded,
              size: 30,
              color: Color(0xFF858585),
            ),
    );
  }

  Widget _buildCallButton(WalkerAcceptData data) {
    return Material(
      color: const Color(0xFFFF7A00),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: widget.onCall,
        borderRadius: BorderRadius.circular(14),
        child: const SizedBox(
          width: 46,
          height: 46,
          child: Icon(
            Icons.call_rounded,
            color: Colors.white,
            size: 21,
          ),
        ),
      ),
    );
  }

  Widget _buildTravelInfo({
    required WalkerAcceptData data,
    required bool hasDistance,
    required bool hasEta,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildInfoItem(
              icon: Icons.route_rounded,
              label: 'Distance',
              value: hasDistance
                  ? _formatDistance(
                      meters: data.distanceMeters,
                      km: data.distanceKm,
                    )
                  : '--',
            ),
          ),
          Container(
            width: 1,
            height: 34,
            color: const Color(0xFFE1E1E1),
          ),
          Expanded(
            child: _buildInfoItem(
              icon: Icons.schedule_rounded,
              label: 'ETA',
              value: hasEta
                  ? data.etaLabel
                  : 'Calculating',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFFFF7A00),
        ),
        const SizedBox(width: 9),
        Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF8A8A8A),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF202020),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRouteUpdating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1.8,
            valueColor: AlwaysStoppedAnimation<Color>(
              Color(0xFFFF7A00),
            ),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          'Updating route...',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 44,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: const Color(0xFF333333),
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDistance({
    int? meters,
    double? km,
  }) {
    double valueMeters =
        (meters ?? 0).toDouble();

    if (valueMeters <= 0 && (km ?? 0) > 0) {
      valueMeters = (km ?? 0) * 1000;
    }

    if (valueMeters <= 0) {
      return '--';
    }

    if (valueMeters >= 1000) {
      final double kilometers =
          valueMeters / 1000;

      if (kilometers >= 10) {
        return '${kilometers.toStringAsFixed(0)} km';
      }

      return '${kilometers.toStringAsFixed(1)} km';
    }

    return '${valueMeters.round()} m';
  }
}
