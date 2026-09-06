import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../live_walk/screens/live_walk_screen.dart';
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
  State<WalkerAcceptScreen> createState() =>
      _WalkerAcceptScreenState();
}

class _WalkerAcceptScreenState
    extends State<WalkerAcceptScreen> {
  late final WalkerAcceptService _acceptService;
  late final WalkerRouteService _routeService;

  StreamSubscription<WalkerAcceptData?>?
      _requestSubscription;

  WalkerAcceptData? _data;
  WalkerRouteResult? _route;

  bool _loadingRoute = false;
  bool _reachedHandled = false;
  bool _liveWalkOpening = false;

  LatLng? _lastRouteWalkerLocation;

  static const double _routeRefreshDistanceMeters =
      50.0;

  static const Color _primaryOrange =
      Color(0xFFD95F00);

  static const Color _navy =
      Color(0xFF19324A);

  static const Color _pageBackground =
      Color(0xFFF5F6F8);

  final Distance _distance = const Distance();

  @override
  void initState() {
    super.initState();

    _acceptService = WalkerAcceptService();
    _routeService = WalkerRouteService();

    _listenToRequest();
  }

  // ==========================================================
  // FIRESTORE REALTIME LISTENER
  // ==========================================================

  void _listenToRequest() {
    final String requestId =
        widget.requestId.trim();

    if (requestId.isEmpty) {
      return;
    }

    _requestSubscription =
        _acceptService.watchRequest(requestId).listen(
      (WalkerAcceptData? data) {
        if (!mounted) {
          return;
        }

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

        if (!_isTerminalStatus(data.status) &&
            !data.isReached) {
          _refreshRoute(data);
        }
      },
      onError: (
        Object error,
        StackTrace stackTrace,
      ) {
        if (!mounted) {
          return;
        }

        debugPrint(
          'WalkerAcceptScreen request stream error: $error',
        );

        debugPrint(
          stackTrace.toString(),
        );
      },
    );
  }

  // ==========================================================
  // STATUS HELPERS
  // ==========================================================

  bool _isTerminalStatus(
    String status,
  ) {
    switch (status.trim().toLowerCase()) {
      case 'completed':
      case 'cancelled':
      case 'canceled':
      case 'rejected':
      case 'expired':
        return true;
      default:
        return false;
    }
  }

  bool _canOpenLiveWalk(
    String status,
  ) {
    switch (status.trim().toLowerCase()) {
      case 'accepted':
      case 'reached':
      case 'active':
      case 'in_progress':
        return true;
      default:
        return false;
    }
  }

  // ==========================================================
  // REACHED
  // ==========================================================

  void _checkReached(
    WalkerAcceptData data,
  ) {
    final String status =
        data.status.trim().toLowerCase();

    // ========================================================
    // IMPORTANT SAFETY CHECK
    //
    // Completed / cancelled / rejected / expired walks
    // must NEVER open LiveWalkScreen.
    // ========================================================

    if (_isTerminalStatus(status)) {
      debugPrint(
        'WalkerAcceptScreen → terminal status detected: $status',
      );

      return;
    }

    // ========================================================
    // LIVE WALK ALLOWLIST
    //
    // Only these statuses are allowed to transition
    // from Accept Screen → Live Walk.
    // ========================================================

    if (!_canOpenLiveWalk(status)) {
      debugPrint(
        'WalkerAcceptScreen → Live Walk blocked for status: $status',
      );

      return;
    }

    if (_reachedHandled ||
        !data.isReached) {
      return;
    }

    _reachedHandled = true;

    debugPrint(
      'WalkerAcceptScreen → Walker reached owner.',
    );

    debugPrint(
      'status = $status',
    );

    debugPrint(
      'requestId = ${data.requestId}',
    );

    widget.onReached?.call(data);

    unawaited(
      _openLiveWalk(data.requestId),
    );
  }

  // ==========================================================
  // OPEN LIVE WALK
  // ==========================================================

  Future<void> _openLiveWalk(
    String requestId,
  ) async {
    if (_liveWalkOpening) {
      return;
    }

    _liveWalkOpening = true;

    await _requestSubscription?.cancel();
    _requestSubscription = null;

    if (!mounted) {
      _liveWalkOpening = false;
      return;
    }

    final String walkId =
        requestId.trim();

    if (walkId.isEmpty) {
      _liveWalkOpening = false;
      return;
    }

    debugPrint(
      'WalkerAcceptScreen → replacing with LiveWalkScreen',
    );

    debugPrint(
      'walkId = $walkId',
    );

    await Navigator.of(context).pushReplacement<dynamic, dynamic>(
      MaterialPageRoute<dynamic>(
        builder: (_) {
          return LiveWalkScreen(
            walkId: walkId,
            isWalker: false,
          );
        },
      ),
    );

    if (!mounted) {
      return;
    }

    debugPrint(
      'WalkerAcceptScreen → replacement returned.',
    );
  }

  // ==========================================================
  // ROUTE REFRESH
  // ==========================================================

  void _refreshRoute(
    WalkerAcceptData data,
  ) {
    if (_isTerminalStatus(data.status)) {
      return;
    }

    final LatLng? walkerLocation =
        _latLngFromGeoPoint(
      data.walkerLocation,
    );

    final LatLng? ownerLocation =
        _latLngFromGeoPoint(
      data.ownerLocation,
    );

    if (walkerLocation == null ||
        ownerLocation == null) {
      return;
    }

    if (_loadingRoute) {
      return;
    }

    final LatLng? previous =
        _lastRouteWalkerLocation;

    if (previous != null) {
      final double movedMeters =
          _distance.as(
        LengthUnit.Meter,
        previous,
        walkerLocation,
      );

      if (movedMeters <
          _routeRefreshDistanceMeters) {
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

  // ==========================================================
  // LOAD OSRM ROUTE
  // ==========================================================

  Future<void> _loadRoute({
    required LatLng walkerLocation,
    required LatLng ownerLocation,
  }) async {
    if (_loadingRoute) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _loadingRoute = true;
    });

    try {
      debugPrint(
        'WalkerAcceptScreen → calculating route...',
      );

      debugPrint(
        'Walker: '
        '${walkerLocation.latitude}, '
        '${walkerLocation.longitude}',
      );

      debugPrint(
        'Owner: '
        '${ownerLocation.latitude}, '
        '${ownerLocation.longitude}',
      );

      final WalkerRouteResult? result =
          await _routeService.getRoute(
        walkerLocation: walkerLocation,
        ownerLocation: ownerLocation,
      );

      if (!mounted) {
        return;
      }

      if (result != null) {
        debugPrint(
          'WalkerAcceptScreen → route calculated.',
        );

        debugPrint(
          'Distance: ${result.distanceMeters} meters',
        );

        debugPrint(
          'Duration: ${result.durationSeconds} seconds',
        );

        debugPrint(
          'Arrives In: ${result.etaLabel}',
        );

        setState(() {
          _route = result;
          _lastRouteWalkerLocation =
              walkerLocation;
        });
      } else {
        debugPrint(
          'WalkerAcceptScreen → route calculation returned null.',
        );
      }
    } catch (error, stackTrace) {
      debugPrint(
        'WalkerAcceptScreen route error: $error',
      );

      debugPrint(
        stackTrace.toString(),
      );
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingRoute = false;
      });

      _checkForNewerLocation();
    }
  }

  // ==========================================================
  // CHECK NEWER LOCATION
  // ==========================================================

  void _checkForNewerLocation() {
    final WalkerAcceptData? latestData =
        _data;

    if (latestData == null ||
        latestData.isReached ||
        _isTerminalStatus(
          latestData.status,
        )) {
      return;
    }

    final LatLng? latestWalker =
        _latLngFromGeoPoint(
      latestData.walkerLocation,
    );

    final LatLng? lastRoute =
        _lastRouteWalkerLocation;

    if (latestWalker == null ||
        lastRoute == null) {
      return;
    }

    final double movedMeters =
        _distance.as(
      LengthUnit.Meter,
      lastRoute,
      latestWalker,
    );

    if (movedMeters >=
        _routeRefreshDistanceMeters) {
      unawaited(
        _loadRouteForLatestData(
          latestData,
        ),
      );
    }
  }

  Future<void> _loadRouteForLatestData(
    WalkerAcceptData data,
  ) async {
    if (_isTerminalStatus(data.status) ||
        data.isReached) {
      return;
    }

    final LatLng? walkerLocation =
        _latLngFromGeoPoint(
      data.walkerLocation,
    );

    final LatLng? ownerLocation =
        _latLngFromGeoPoint(
      data.ownerLocation,
    );

    if (walkerLocation == null ||
        ownerLocation == null) {
      return;
    }

    await _loadRoute(
      walkerLocation: walkerLocation,
      ownerLocation: ownerLocation,
    );
  }

  // ==========================================================
  // GEOPOINT → LATLNG
  // ==========================================================

  LatLng? _latLngFromGeoPoint(
    dynamic point,
  ) {
    if (point == null) {
      return null;
    }

    try {
      final double latitude =
          (point.latitude as num).toDouble();

      final double longitude =
          (point.longitude as num).toDouble();

      if (!_isValidCoordinate(
        latitude,
        longitude,
      )) {
        return null;
      }

      return LatLng(
        latitude,
        longitude,
      );
    } catch (_) {
      return null;
    }
  }

  bool _isValidCoordinate(
    double latitude,
    double longitude,
  ) {
    if (latitude == 0 &&
        longitude == 0) {
      return false;
    }

    if (latitude < -90 ||
        latitude > 90) {
      return false;
    }

    if (longitude < -180 ||
        longitude > 180) {
      return false;
    }

    return true;
  }

  // ==========================================================
  // CALL WALKER
  // ==========================================================

  Future<void> _callWalker() async {
    final String phone =
        _data?.walkerPhone?.trim() ?? '';

    if (phone.isEmpty) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Walker phone number is not available',
          ),
        ),
      );

      return;
    }

    final Uri uri = Uri(
      scheme: 'tel',
      path: phone,
    );

    try {
      final bool launched =
          await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to open phone dialer',
            ),
          ),
        );
      }
    } catch (error) {
      debugPrint(
        'WalkerAcceptScreen call error: $error',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to open phone dialer',
          ),
        ),
      );
    }
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    unawaited(
      _requestSubscription?.cancel(),
    );

    _routeService.dispose();

    super.dispose();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final WalkerAcceptData? data =
        _data;

    if (data == null) {
      return Scaffold(
        backgroundColor: _pageBackground,
        body: SafeArea(
          child: Column(
            children: [
              _buildLoadingHeader(),
              const Expanded(
                child: Center(
                  child:
                      CircularProgressIndicator(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final LatLng? ownerLocation =
        _latLngFromGeoPoint(
      data.ownerLocation,
    );

    final LatLng? walkerLocation =
        _latLngFromGeoPoint(
      data.walkerLocation,
    );

    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: WalkerAcceptMap(
                ownerLocation:
                    ownerLocation ??
                    const LatLng(0, 0),
                walkerLocation:
                    walkerLocation,
                walkerImageUrl:
                    data.walkerProfileImage
                        ?.trim(),
                routePoints:
                    _route?.points ??
                    const <LatLng>[],
                walkerHeading:
                    data.walkerHeading,
                onMyLocationPressed: () {},
              ),
            ),

            _buildAcceptHeader(),

            _buildBottomSheet(data),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // ACCEPT HEADER
  // ==========================================================

  Widget _buildAcceptHeader() {
    return Positioned(
      top: 12,
      left: 16,
      right: 16,
      child: Row(
        children: [
          _buildHeaderCircleButton(
            icon: Icons.arrow_back_rounded,
            onTap: () {
              Navigator.of(context).maybePop();
            },
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 52,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              decoration:
                  BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(17),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 18,
                    offset: Offset(0, 5),
                    color: Colors.black12,
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.pets_rounded,
                    color: _primaryOrange,
                    size: 23,
                  ),
                  SizedBox(width: 9),
                  Text(
                    'Accept Screen',
                    style: TextStyle(
                      color: _navy,
                      fontSize: 18,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          _buildHeaderCircleButton(
            icon: Icons.help_outline_rounded,
            onTap: widget.onHelp,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // HEADER BUTTON
  // ==========================================================

  Widget _buildHeaderCircleButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.white,
      elevation: 5,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 50,
          height: 50,
          child: Icon(
            icon,
            color: _navy,
            size: 22,
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // LOADING HEADER
  // ==========================================================

  Widget _buildLoadingHeader() {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        0,
      ),
      child: Row(
        children: [
          _buildHeaderCircleButton(
            icon: Icons.arrow_back_rounded,
            onTap: () {
              Navigator.of(context).maybePop();
            },
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 52,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              decoration:
                  BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(17),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.pets_rounded,
                    color: _primaryOrange,
                    size: 23,
                  ),
                  SizedBox(width: 9),
                  Text(
                    'Accept Screen',
                    style: TextStyle(
                      color: _navy,
                      fontSize: 18,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          _buildHeaderCircleButton(
            icon: Icons.help_outline_rounded,
            onTap: widget.onHelp,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // DRAGGABLE BOTTOM SHEET
  // ==========================================================

  Widget _buildBottomSheet(
    WalkerAcceptData data,
  ) {
    return DraggableScrollableSheet(
      initialChildSize: 0.27,
      minChildSize: 0.27,
      maxChildSize: 0.61,
      snap: true,
      snapSizes: const [
        0.27,
        0.61,
      ],
      expand: true,
      builder: (
        BuildContext context,
        ScrollController controller,
      ) {
        return Material(
          elevation: 10,
          color: Colors.white,
          borderRadius:
              const BorderRadius.vertical(
            top: Radius.circular(30),
          ),
          clipBehavior:
              Clip.antiAlias,
          child: ListView(
            controller: controller,
            padding:
                const EdgeInsets.fromLTRB(
              18,
              9,
              18,
              18,
            ),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration:
                      BoxDecoration(
                    color:
                        const Color(0xFFD2D2D2),
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              Row(
                children: [
                  _buildWalkerAvatar(data),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          data.walkerName
                                  .trim()
                                  .isEmpty
                              ? 'Walker'
                              : data.walkerName,
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            color: _navy,
                            fontSize: 19,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons
                                  .location_on_outlined,
                              size: 16,
                              color:
                                  Color(0xFF777777),
                            ),
                            const SizedBox(width: 4),
                            const Expanded(
                              child: Text(
                                'Walker is approaching',
                                maxLines: 1,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style:
                                    TextStyle(
                                  color:
                                      Color(
                                    0xFF777777,
                                  ),
                                  fontSize: 12,
                                  fontWeight:
                                      FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        if ((data.walkerPhone
                                    ?.trim()
                                    .isNotEmpty ??
                                false))
                          Row(
                            children: [
                              const Icon(
                                Icons
                                    .phone_outlined,
                                size: 15,
                                color:
                                    Color(0xFF777777),
                              ),
                              const SizedBox(
                                width: 4,
                              ),
                              Expanded(
                                child: Text(
                                  data.walkerPhone!
                                      .trim(),
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                  style:
                                      const TextStyle(
                                    color:
                                        Color(
                                      0xFF777777,
                                    ),
                                    fontSize: 12,
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildLiveBadge(),
                ],
              ),

              const SizedBox(height: 16),

              _buildTravelInfo(data),

              if (_loadingRoute) ...[
                const SizedBox(height: 9),
                _buildRouteUpdating(),
              ],

              const SizedBox(height: 13),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 12,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(0xFFFFF3E9),
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons
                          .directions_walk_rounded,
                      color: _primaryOrange,
                      size: 22,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Walker is on the way',
                        style: TextStyle(
                          color: _navy,
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 13),

              Row(
                children: [
                  Expanded(
                    child: _buildCallButton(),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildChatButton(),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              _buildVoiceInteractionButton(),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================
  // WALKER AVATAR
  // ==========================================================

  Widget _buildWalkerAvatar(
    WalkerAcceptData data,
  ) {
    final String imageUrl =
        data.walkerProfileImage
                ?.trim() ??
            '';

    return Container(
      width: 56,
      height: 56,
      decoration:
          BoxDecoration(
        color:
            const Color(0xFFFFEEE2),
        borderRadius:
            BorderRadius.circular(17),
      ),
      clipBehavior:
          Clip.antiAlias,
      child: imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (
                BuildContext context,
                Object error,
                StackTrace? stackTrace,
              ) {
                return const Icon(
                  Icons.person_rounded,
                  color: _primaryOrange,
                  size: 30,
                );
              },
            )
          : const Icon(
              Icons.person_rounded,
              color: _primaryOrange,
              size: 30,
            ),
    );
  }

  // ==========================================================
  // LIVE BADGE
  // ==========================================================

  Widget _buildLiveBadge() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFFE9F7EF),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            size: 8,
            color:
                Color(0xFF21A464),
          ),
          SizedBox(width: 5),
          Text(
            'LIVE',
            style: TextStyle(
              color:
                  Color(0xFF21A464),
              fontSize: 10,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // DISTANCE + ARRIVES IN
  // ==========================================================

  Widget _buildTravelInfo(
    WalkerAcceptData data,
  ) {
    final WalkerRouteResult? route =
        _route;

    final bool hasRouteDistance =
        route != null &&
        route.distanceMeters > 0;

    final bool hasRouteDuration =
        route != null &&
        route.durationSeconds > 0;

    final bool hasFallbackDistance =
        data.distanceMeters > 0 ||
        data.distanceKm > 0;

    final bool hasFallbackTime =
        data.etaMinutes > 0;

    String distanceValue;

    if (hasRouteDistance) {
      distanceValue =
          route.distanceLabel;
    } else if (hasFallbackDistance) {
      distanceValue =
          _formatDistance(
        meters:
            data.distanceMeters,
        km:
            data.distanceKm,
      );
    } else {
      distanceValue = _loadingRoute
          ? 'Calculating...'
          : '--';
    }

    String arrivalValue;

    if (hasRouteDuration) {
      arrivalValue =
          route.etaLabel;
    } else if (hasFallbackTime) {
      arrivalValue =
          data.etaLabel;
    } else {
      arrivalValue = _loadingRoute
          ? 'Calculating...'
          : 'Waiting';
    }

    return Container(
      height: 86,
      decoration:
          BoxDecoration(
        color:
            const Color(0xFFF7F7F8),
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildInfoItem(
              icon:
                  Icons.route_rounded,
              label:
                  'Distance',
              value:
                  distanceValue,
            ),
          ),
          Container(
            width: 1,
            height: 45,
            color:
                const Color(0xFFE0E0E0),
          ),
          Expanded(
            child: _buildInfoItem(
              icon:
                  Icons.access_time_rounded,
              label:
                  'Arrives In',
              value:
                  arrivalValue,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // INFO ITEM
  // ==========================================================

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: _primaryOrange,
          size: 21,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  color:
                      Color(0xFF8A8A8A),
                  fontSize: 10,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style:
                    const TextStyle(
                  color: _navy,
                  fontSize: 15,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // CALL
  // ==========================================================

  Widget _buildCallButton() {
    final bool hasPhone =
        _data?.walkerPhone
                ?.trim()
                .isNotEmpty ??
            false;

    return Material(
      color: hasPhone
          ? _primaryOrange
          : const Color(0xFFE5E5E5),
      borderRadius:
          BorderRadius.circular(15),
      child: InkWell(
        onTap: hasPhone
            ? _callWalker
            : null,
        borderRadius:
            BorderRadius.circular(15),
        child: SizedBox(
          height: 52,
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                Icons.call_rounded,
                color: hasPhone
                    ? Colors.white
                    : Colors.black38,
                size: 20,
              ),
              const SizedBox(width: 7),
              Text(
                'Call',
                style: TextStyle(
                  color: hasPhone
                      ? Colors.white
                      : Colors.black38,
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // CHAT
  // ==========================================================

  Widget _buildChatButton() {
    return Material(
      color:
          const Color(0xFFF1F2F4),
      borderRadius:
          BorderRadius.circular(15),
      child: InkWell(
        onTap: widget.onChat,
        borderRadius:
            BorderRadius.circular(15),
        child: const SizedBox(
          height: 52,
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                Icons
                    .chat_bubble_outline_rounded,
                color: _navy,
                size: 20,
              ),
              SizedBox(width: 7),
              Text(
                'Chat',
                style: TextStyle(
                  color: _navy,
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // VOICE INTERACTION
  // ==========================================================

  Widget _buildVoiceInteractionButton() {
    return Material(
      color:
          const Color(0xFFFFF7F1),
      borderRadius:
          BorderRadius.circular(15),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context)
              .showSnackBar(
            const SnackBar(
              content: Text(
                'Voice Interaction is coming soon.',
              ),
            ),
          );
        },
        borderRadius:
            BorderRadius.circular(15),
        child: Container(
          height: 52,
          decoration:
              BoxDecoration(
            border: Border.all(
              color:
                  const Color(0xFFF0D4BF),
            ),
            borderRadius:
                BorderRadius.circular(15),
          ),
          child: const Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                Icons.mic_none_rounded,
                color: _primaryOrange,
                size: 21,
              ),
              SizedBox(width: 8),
              Text(
                'Voice Interaction',
                style: TextStyle(
                  color: _navy,
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
              SizedBox(width: 7),
              Text(
                'Soon',
                style: TextStyle(
                  color:
                      Color(0xFF999999),
                  fontSize: 11,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // ROUTE UPDATING
  // ==========================================================

  Widget _buildRouteUpdating() {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 11,
          height: 11,
          child:
              CircularProgressIndicator(
            strokeWidth: 1.7,
            valueColor:
                AlwaysStoppedAnimation<
                    Color>(
              _primaryOrange,
            ),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          'Updating route...',
          style: TextStyle(
            color:
                Colors.grey.shade600,
            fontSize: 10,
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // DISTANCE FORMAT
  // ==========================================================

  String _formatDistance({
    int? meters,
    double? km,
  }) {
    double valueMeters =
        (meters ?? 0).toDouble();

    if (valueMeters <= 0 &&
        (km ?? 0) > 0) {
      valueMeters =
          (km ?? 0) * 1000;
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
