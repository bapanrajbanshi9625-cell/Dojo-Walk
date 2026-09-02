import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

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
  bool _routeRequestedOnce = false;

  @override
  void initState() {
    super.initState();

    _acceptService = WalkerAcceptService();
    _routeService = WalkerRouteService();

    _listenToRequest();
  }

  // ==========================================================
  // FIRESTORE LISTENER
  // ==========================================================

  void _listenToRequest() {
    final String requestId =
        widget.requestId.trim();

    if (requestId.isEmpty) {
      debugPrint(
        'WalkerAcceptScreen: requestId is empty.',
      );
      return;
    }

    _requestSubscription = _acceptService
        .watchRequest(requestId)
        .listen(
      (WalkerAcceptData? data) {
        if (!mounted || data == null) {
          return;
        }

        setState(() {
          _data = data;
        });

        _checkReached(data);
        _refreshRoute(data);
      },
      onError: (Object error) {
        debugPrint(
          'WalkerAcceptScreen Firestore error: $error',
        );
      },
    );
  }

  // ==========================================================
  // REACHED
  // ==========================================================

  void _checkReached(
    WalkerAcceptData data,
  ) {
    if (_reachedHandled ||
        !data.isReached) {
      return;
    }

    _reachedHandled = true;

    debugPrint(
      'WalkerAcceptScreen: Walker reached Owner.',
    );

    widget.onReached?.call(data);
  }

  // ==========================================================
  // ROUTE
  // ==========================================================

  void _refreshRoute(
    WalkerAcceptData data,
  ) {
    if (!data.hasWalkerLocation ||
        !data.hasOwnerLocation ||
        _loadingRoute) {
      return;
    }

    // First route immediately.
    if (!_routeRequestedOnce) {
      _routeRequestedOnce = true;
      _loadRoute(data);
      return;
    }

    // Refresh only when the route becomes
    // meaningfully stale.
    _loadRoute(data);
  }

  Future<void> _loadRoute(
    WalkerAcceptData data,
  ) async {
    if (!mounted || _loadingRoute) {
      return;
    }

    final location =
        data.walkerLocation;
    final owner =
        data.ownerLocation;

    if (location == null ||
        owner == null) {
      return;
    }

    _loadingRoute = true;

    try {
      final WalkerRouteResult? result =
          await _routeService.getRoute(
        walkerLocation: LatLng(
          location.latitude.toDouble(),
          location.longitude.toDouble(),
        ),
        ownerLocation: LatLng(
          owner.latitude.toDouble(),
          owner.longitude.toDouble(),
        ),
      );

      if (!mounted ||
          result == null) {
        return;
      }

      setState(() {
        _route = result;
      });
    } catch (error) {
      debugPrint(
        'WalkerAcceptScreen route error: $error',
      );
    } finally {
      _loadingRoute = false;
    }
  }

  // ==========================================================
  // OWNER LOCATION
  // ==========================================================

  LatLng? get _ownerLatLng {
    final location =
        _data?.ownerLocation;

    if (location == null) {
      return null;
    }

    return LatLng(
      location.latitude.toDouble(),
      location.longitude.toDouble(),
    );
  }

  // ==========================================================
  // WALKER LOCATION
  // ==========================================================

  LatLng? get _walkerLatLng {
    final location =
        _data?.walkerLocation;

    if (location == null) {
      return null;
    }

    return LatLng(
      location.latitude.toDouble(),
      location.longitude.toDouble(),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final WalkerAcceptData? data = _data;

    if (data == null) {
      return _buildLoadingScreen(context);
    }

    final LatLng? ownerLocation =
        _ownerLatLng;

    if (ownerLocation == null) {
      return _buildLocationUnavailable(context);
    }

    return Scaffold(
      backgroundColor:
          Theme.of(context)
              .colorScheme
              .surface,
      appBar:
          _buildAppBar(context, data),
      body: Stack(
        children: [
          Positioned.fill(
            child: WalkerAcceptMap(
              ownerLocation:
                  ownerLocation,
              walkerLocation:
                  _walkerLatLng,
              walkerImageUrl:
                  data.walkerProfileImage,
              routePoints:
                  _route?.points ??
                      const <LatLng>[],
              walkerHeading:
                  data.walkerHeading,
              onMyLocationPressed:
                  _recenterOwner,
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: _buildBottomCard(
                context,
                data,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // LOADING
  // ==========================================================

  Widget _buildLoadingScreen(
    BuildContext context,
  ) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Center(
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: colors.primary
                    .withValues(alpha: .10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons
                    .directions_walk_rounded,
                size: 34,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Connecting to your Walker',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Starting live tracking…',
              style: TextStyle(
                fontSize: 13,
                color:
                    colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            const SizedBox(
              width: 24,
              height: 24,
              child:
                  CircularProgressIndicator(
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // LOCATION UNAVAILABLE
  // ==========================================================

  Widget _buildLocationUnavailable(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Walker is on the way',
        ),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Icon(
                Icons.location_off_rounded,
                size: 46,
              ),
              SizedBox(height: 14),
              Text(
                'Owner location is unavailable.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // APP BAR
  // ==========================================================

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    WalkerAcceptData data,
  ) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: colors.surface,
      titleSpacing: 4,
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colors.primary
                  .withValues(alpha: .10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              data.isReached
                  ? Icons.check_rounded
                  : Icons
                      .directions_walk_rounded,
              color: colors.primary,
              size: 21,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                data.isReached
                    ? 'Walker has arrived'
                    : 'Walker is on the way',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                data.isReached
                    ? 'Your Walker is here'
                    : 'Live tracking',
                style: TextStyle(
                  fontSize: 11,
                  color:
                      colors.onSurfaceVariant,
                  fontWeight:
                      FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Help & Support',
          onPressed: widget.onHelp,
          icon: const Icon(
            Icons.help_outline_rounded,
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // BOTTOM CARD
  // ==========================================================

  Widget _buildBottomCard(
    BuildContext context,
    WalkerAcceptData data,
  ) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    final double routeDistanceMeters =
        (_route?.distanceMeters ??
                data.distanceMeters)
            .toDouble();

    final int routeEtaMinutes =
        (_route?.durationMinutes ??
                data.etaMinutes)
            .toInt();

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius:
            const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 28,
            offset: Offset(0, -7),
            color: Color(0x26000000),
          ),
        ],
      ),
      padding:
          const EdgeInsets.fromLTRB(
        18,
        10,
        18,
        14,
      ),
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          // ==================================================
          // DRAG HANDLE
          // ==================================================

          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color:
                  colors.outlineVariant,
              borderRadius:
                  BorderRadius.circular(20),
            ),
          ),

          const SizedBox(height: 12),

          // ==================================================
          // ARRIVAL / STATUS
          // ==================================================

          WalkerAcceptStatus(
            status: data.status,
            distanceMeters:
                routeDistanceMeters,
          ),

          const SizedBox(height: 14),

          // ==================================================
          // WALKER
          // ==================================================

          WalkerInfoCard(
            walkerName:
                data.walkerName,
            profileImageUrl:
                data.walkerProfileImage,
            rating:
                data.walkerRating,
            distanceLabel:
                _route?.distanceLabel ??
                    data.distanceLabel,
            etaLabel:
                _route?.etaLabel ??
                    data.etaLabel,
            statusText:
                data.isReached
                    ? 'Walker has arrived'
                    : 'Walker is on the way',
          ),

          const SizedBox(height: 10),

          // ==================================================
          // ETA + DISTANCE
          // ==================================================

          WalkerEtaDistance(
            distanceMeters:
                routeDistanceMeters,
            etaMinutes:
                routeEtaMinutes,
          ),

          if (_loadingRoute)
            Padding(
              padding:
                  const EdgeInsets.only(
                top: 8,
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 13,
                    height: 13,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 1.8,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'Updating route…',
                    style: TextStyle(
                      fontSize: 10,
                      color:
                          colors.onSurfaceVariant,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),

          // ==================================================
          // CONTACT
          // ==================================================

          WalkerContactButtons(
            onCall:
                widget.onCall ?? () {},
            onChat:
                widget.onChat ?? () {},
            callEnabled:
                widget.onCall != null &&
                data.walkerPhone != null &&
                data.walkerPhone!
                    .trim()
                    .isNotEmpty,
            chatEnabled:
                widget.onChat != null,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // RECENTER
  // ==========================================================

  void _recenterOwner() {
    debugPrint(
      'WalkerAcceptScreen: map recenter requested.',
    );
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _requestSubscription?.cancel();
    _routeService.dispose();

    super.dispose();
  }
}
