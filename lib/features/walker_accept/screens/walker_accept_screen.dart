import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../screens/live_walk_screen.dart';  
import '../models/walker_accept_data.dart';  
import '../services/walker_accept_service.dart';  
import '../services/walker_route_service.dart';  
import '../widgets/walker_accept_map.dart';  
import '../widgets/walker_accept_status.dart';  
import '../widgets/walker_contact_buttons.dart';  
import '../widgets/walker_eta_distance.dart';  
import '../widgets/walker_info_card.dart';  

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
  bool _closingAfterReached = false;

  /// Location used for the route request currently in progress.
  LatLng? _routeLocationInFlight;

  /// Latest location received while a route request was in progress.
  LatLng? _pendingRouteLocation;

  /// Last Walker location for which a route was successfully/requested.
  LatLng? _lastRouteWalkerLocation;

  /// Do not request a new route for every 10m GPS update.
  /// The marker still moves on every Firestore update.
  static const double _routeRefreshDistanceMeters = 50.0;

  static const Distance _distance = Distance();

  @override
  void initState() {
    super.initState();

    _acceptService = WalkerAcceptService();
    _routeService = WalkerRouteService();

    _listenToRequest();
  }

  // ============================================================
  // FIRESTORE REALTIME LISTENER
  // ============================================================

  void _listenToRequest() {
    final requestId = widget.requestId.trim();

    if (requestId.isEmpty) {
      debugPrint(
        '[WalkerAcceptScreen] Empty requestId.',
      );
      return;
    }

    _requestSubscription = _acceptService.watchRequest(requestId).listen(
      (WalkerAcceptData? data) {
        if (!mounted || data == null) {
          return;
        }

        setState(() {
          _data = data;
        });

        // Reached handling must happen before route work.
        _checkReached(data);

        if (!data.isReached && !_reachedHandled) {
          _refreshRoute(data);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint(
          '[WalkerAcceptScreen] Firestore listener error: $error',
        );
      },
    );
  }

  // ============================================================
  // REACHED FLOW
  // ============================================================

  void _checkReached(WalkerAcceptData data) {
    if (!data.isReached ||
        _reachedHandled ||
        _closingAfterReached) {
      return;
    }

    _reachedHandled = true;
    _closingAfterReached = true;

    // Stop listening to the accepted-request screen once
    // the Walker has reached the Owner.
    _requestSubscription?.cancel();
    _requestSubscription = null;

    widget.onReached?.call(data);

    if (!mounted) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => LiveWalkScreen(
            activeWalkId: widget.requestId.trim(),
            isWalker: false,
          ),
        ),
      );
    });
  }

  // ============================================================
  // ROUTE REFRESH
  // ============================================================

  void _refreshRoute(WalkerAcceptData data) {
    if (!mounted ||
        _reachedHandled ||
        data.isReached ||
        !data.hasWalkerLocation ||
        !data.hasOwnerLocation) {
      return;
    }

    final walkerLocation = _walkerLatLngFromData(data);
    final ownerLocation = _ownerLatLngFromData(data);

    if (walkerLocation == null || ownerLocation == null) {
      return;
    }

    // If a route request is already running, remember the latest
    // Walker location. After the current request finishes, another
    // route will be requested if needed.
    if (_loadingRoute) {
      _pendingRouteLocation = walkerLocation;
      return;
    }

    // First route should always be requested.
    if (_lastRouteWalkerLocation == null) {
      _loadRoute(
        walkerLocation: walkerLocation,
        ownerLocation: ownerLocation,
      );
      return;
    }

    final movedMeters = _distance.as(
      LengthUnit.Meter,
      _lastRouteWalkerLocation!,
      walkerLocation,
    );

    // Marker updates are realtime regardless of this threshold.
    // We only throttle route API requests.
    if (movedMeters < _routeRefreshDistanceMeters) {
      return;
    }

    _loadRoute(
      walkerLocation: walkerLocation,
      ownerLocation: ownerLocation,
    );
  }

  Future<void> _loadRoute({
    required LatLng walkerLocation,
    required LatLng ownerLocation,
  }) async {
    if (!mounted ||
        _loadingRoute ||
        _reachedHandled ||
        !_isValidLatLng(walkerLocation) ||
        !_isValidLatLng(ownerLocation)) {
      return;
    }

    _loadingRoute = true;
    _routeLocationInFlight = walkerLocation;
    _pendingRouteLocation = null;

    // Mark this location immediately so repeated Firestore snapshots
    // do not start duplicate route requests.
    _lastRouteWalkerLocation = walkerLocation;

    try {
      final result = await _routeService.getRoute(
        walkerLocation: walkerLocation,
        ownerLocation: ownerLocation,
      );

      if (!mounted || _reachedHandled) {
        return;
      }

      setState(() {
        _route = result;
      });
    } catch (error, stackTrace) {
      debugPrint(
        '[WalkerAcceptScreen] Route error: $error',
      );

      debugPrint(
        '$stackTrace',
      );
    } finally {
      _loadingRoute = false;
      _routeLocationInFlight = null;

      if (!mounted || _reachedHandled) {
        return;
      }

      // Check the latest Firestore location after the current
      // route request completes.
      final latestData = _data;

      if (latestData != null &&
          !latestData.isReached &&
          latestData.hasWalkerLocation &&
          latestData.hasOwnerLocation) {
        final latestWalker =
            _walkerLatLngFromData(latestData);

        final latestOwner =
            _ownerLatLngFromData(latestData);

        if (latestWalker != null &&
            latestOwner != null) {
          final lastRouteLocation =
              _lastRouteWalkerLocation;

          if (lastRouteLocation == null) {
            _loadRoute(
              walkerLocation: latestWalker,
              ownerLocation: latestOwner,
            );
          } else {
            final movedMeters = _distance.as(
              LengthUnit.Meter,
              lastRouteLocation,
              latestWalker,
            );

            if (movedMeters >=
                _routeRefreshDistanceMeters) {
              _loadRoute(
                walkerLocation: latestWalker,
                ownerLocation: latestOwner,
              );
            }
          }
        }
      }
    }
  }

  // ============================================================
  // LOCATION HELPERS
  // ============================================================

  LatLng? _ownerLatLngFromData(
    WalkerAcceptData data,
  ) {
    final location = data.ownerLocation;

    if (location == null) {
      return null;
    }

    final lat = location.latitude.toDouble();
    final lng = location.longitude.toDouble();

    if (!_isValidCoordinates(lat, lng)) {
      return null;
    }

    return LatLng(lat, lng);
  }

  LatLng? _walkerLatLngFromData(
    WalkerAcceptData data,
  ) {
    final location = data.walkerLocation;

    if (location == null) {
      return null;
    }

    final lat = location.latitude.toDouble();
    final lng = location.longitude.toDouble();

    // Firestore may contain GeoPoint(0, 0) before the first
    // valid Walker GPS update. Never show that as a real location.
    if (!_isValidCoordinates(lat, lng)) {
      return null;
    }

    return LatLng(lat, lng);
  }

  bool _isValidCoordinates(
    double latitude,
    double longitude,
  ) {
    if (latitude == 0.0 && longitude == 0.0) {
      return false;
    }

    if (latitude < -90.0 || latitude > 90.0) {
      return false;
    }

    if (longitude < -180.0 || longitude > 180.0) {
      return false;
    }

    return true;
  }

  bool _isValidLatLng(LatLng location) {
    return _isValidCoordinates(
      location.latitude,
      location.longitude,
    );
  }

  // ============================================================
  // MAP ACTIONS
  // ============================================================

  void _recenterOwner() {
    // WalkerAcceptMap owns the actual MapController.
    // This callback is kept for the map's existing API.
    debugPrint(
      '[WalkerAcceptScreen] Recenter requested.',
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final data = _data;

    if (data == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final ownerLocation =
        _ownerLatLngFromData(data);

    final walkerLocation =
        _walkerLatLngFromData(data);

    if (ownerLocation == null) {
      return _buildLocationUnavailable();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: WalkerAcceptMap(
                ownerLocation: ownerLocation,
                walkerLocation: walkerLocation,
                walkerImageUrl: data.walkerProfileImage,
                routePoints:
                    _route?.points ?? const <LatLng>[],
                walkerHeading: data.walkerHeading,
                onMyLocationPressed:
                    _recenterOwner,
              ),
            ),

            _buildTopHeader(data),

            _buildBottomPanel(
              data: data,
              walkerLocation: walkerLocation,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TOP HEADER
  // ============================================================

  Widget _buildTopHeader(
    WalkerAcceptData data,
  ) {
    return Positioned(
      top: 12,
      left: 16,
      right: 16,
      child: Material(
        elevation: 6,
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
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.directions_walk_rounded,
                  color: Colors.orange.shade800,
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
                      'Walker is on the way',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      data.walkerName.isNotEmpty
                          ? data.walkerName
                          : 'Your Walker',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  data.isReached
                      ? 'Arrived'
                      : 'Accepted',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM PANEL
  // ============================================================

  Widget _buildBottomPanel({
    required WalkerAcceptData data,
    required LatLng? walkerLocation,
  }) {
    final hasWalkerLocation =
        walkerLocation != null;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Material(
        elevation: 12,
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              18,
              14,
              18,
              16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                ),

                const SizedBox(height: 14),

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
                            data.walkerName.isNotEmpty
                                ? data.walkerName
                                : 'Your Walker',
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            hasWalkerLocation
                                ? 'Live location is updating'
                                : 'Waiting for Walker location…',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: hasWalkerLocation
                                  ? Colors.green.shade700
                                  : Colors.grey.shade600,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (data.walkerPhone
                        .trim()
                        .isNotEmpty)
                      _buildCircleAction(
                        icon: Icons.call_rounded,
                        onTap: widget.onCall,
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                _buildTravelInfo(data),

                if (_loadingRoute) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                              Colors.orange.shade700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Updating route…',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              Colors.grey.shade600,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 14),

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
      ),
    );
  }

  // ============================================================
  // WALKER AVATAR
  // ============================================================

  Widget _buildWalkerAvatar(
    WalkerAcceptData data,
  ) {
    final imageUrl =
        data.walkerProfileImage.trim();

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.orange.shade50,
        border: Border.all(
          color: Colors.orange.shade200,
          width: 1.5,
        ),
      ),
      child: ClipOval(
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder:
                    (_, __, ___) {
                  return Icon(
                    Icons.person_rounded,
                    color:
                        Colors.orange.shade700,
                    size: 28,
                  );
                },
              )
            : Icon(
                Icons.person_rounded,
                color: Colors.orange.shade700,
                size: 28,
              ),
      ),
    );
  }

  // ============================================================
  // TRAVEL INFO
  // ============================================================

  Widget _buildTravelInfo(
    WalkerAcceptData data,
  ) {
    final distanceMeters =
        data.distanceMeters;

    final distanceKm =
        data.distanceKm;

    final etaMinutes =
        data.etaMinutes;

    final hasDistance =
        distanceMeters != null ||
        distanceKm != null;

    final hasEta =
        etaMinutes != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildInfoItem(
              icon: Icons.route_rounded,
              title: 'Distance',
              value: hasDistance
                  ? _formatDistance(
                      meters: distanceMeters,
                      km: distanceKm,
                    )
                  : '--',
            ),
          ),
          Container(
            width: 1,
            height: 38,
            color: Colors.grey.shade200,
          ),
          Expanded(
            child: _buildInfoItem(
              icon: Icons.schedule_rounded,
              title: 'ETA',
              value: hasEta
                  ? '${etaMinutes} min'
                  : '--',
            ),
          ),
        ],
      ),
    );
  }

  String _formatDistance({
    double? meters,
    double? km,
  }) {
    if (meters != null) {
      if (meters < 1000) {
        return '${meters.round()} m';
      }

      return '${(meters / 1000).toStringAsFixed(1)} km';
    }

    if (km != null) {
      if (km < 1) {
        return '${(km * 1000).round()} m';
      }

      return '${km.toStringAsFixed(1)} km';
    }

    return '--';
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.orange.shade700,
        ),
        const SizedBox(height: 5),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ACTION BUTTONS
  // ============================================================

  Widget _buildCircleAction({
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.orange.shade50,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Icon(
            icon,
            size: 20,
            color: Colors.orange.shade800,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return SizedBox(
      height: 46,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(
          icon,
          size: 19,
        ),
        label: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.orange.shade800,
          side: BorderSide(
            color: Colors.orange.shade200,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOCATION ERROR
  // ============================================================

  Widget _buildLocationUnavailable() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          'Walker',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_off_rounded,
                  size: 34,
                  color: Colors.orange.shade700,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Owner location is unavailable.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We could not load the pickup location for this request.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _requestSubscription?.cancel();
    _requestSubscription = null;

    _routeService.dispose();

    super.dispose();
  }
}
