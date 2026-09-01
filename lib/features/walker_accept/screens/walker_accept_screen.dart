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

  /// Called when the Walker reaches the Owner.
  ///
  /// Parent should create/open the Live Walk flow here.
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
    if (_reachedHandled) {
      return;
    }

    if (!data.isReached) {
      return;
    }

    _reachedHandled = true;

    debugPrint(
      'WalkerAcceptScreen: Walker reached Owner.',
    );

    widget.onReached?.call(data);
  }

  // ==========================================================
  // ROUTE REFRESH
  // ==========================================================

  void _refreshRoute(
    WalkerAcceptData data,
  ) {
    if (!data.hasWalkerLocation ||
        !data.hasOwnerLocation) {
      return;
    }

    if (_loadingRoute) {
      return;
    }

    _loadRoute(data);
  }

  Future<void> _loadRoute(
    WalkerAcceptData data,
  ) async {
    if (!mounted) {
      return;
    }

    final GeoPointLike? walker =
        _locationFromWalker(data);

    final GeoPointLike? owner =
        _locationFromOwner(data);

    if (walker == null || owner == null) {
      return;
    }

    _loadingRoute = true;

    try {
      final WalkerRouteResult? result =
          await _routeService.getRoute(
        walkerLocation: LatLng(
          walker.latitude,
          walker.longitude,
        ),
        ownerLocation: LatLng(
          owner.latitude,
          owner.longitude,
        ),
      );

      if (!mounted || result == null) {
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
  // LOCATION HELPERS
  // ==========================================================

  GeoPointLike? _locationFromOwner(
    WalkerAcceptData data,
  ) {
    final location = data.ownerLocation;

    if (location == null) {
      return null;
    }

    return GeoPointLike(
      latitude: location.latitude,
      longitude: location.longitude,
    );
  }

  GeoPointLike? _locationFromWalker(
    WalkerAcceptData data,
  ) {
    final location = data.walkerLocation;

    if (location == null) {
      return null;
    }

    return GeoPointLike(
      latitude: location.latitude,
      longitude: location.longitude,
    );
  }

  // ==========================================================
  // MAP LOCATIONS
  // ==========================================================

  LatLng? get _ownerLatLng {
    final location = _data?.ownerLocation;

    if (location == null) {
      return null;
    }

    return LatLng(
      location.latitude,
      location.longitude,
    );
  }

  LatLng? get _walkerLatLng {
    final location = _data?.walkerLocation;

    if (location == null) {
      return null;
    }

    return LatLng(
      location.latitude,
      location.longitude,
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final WalkerAcceptData? data = _data;

    if (data == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final LatLng? ownerLocation =
        _ownerLatLng;

    if (ownerLocation == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Owner location is unavailable.',
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          Theme.of(context)
              .colorScheme
              .surface,
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          // ====================================================
          // OSM MAP
          // ====================================================

          Positioned.fill(
            child: WalkerAcceptMap(
              ownerLocation: ownerLocation,
              walkerLocation: _walkerLatLng,
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

          // ====================================================
          // BOTTOM TRACKING CARD
          // ====================================================

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
  // APP BAR
  // ==========================================================

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
  ) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: colors.surface,
      titleSpacing: 0,
      title: const Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Walker is on the way',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'Live tracking',
            style: TextStyle(
              fontSize: 12,
            ),
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
    final int routeDistanceMeters =
        _route?.distanceMeters ??
            data.distanceMeters;

    final int routeEtaMinutes =
        _route?.durationMinutes ??
            data.etaMinutes;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surface,
        borderRadius:
            const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 24,
            offset: Offset(0, -6),
            color: Color(0x22000000),
          ),
        ],
      ),
      padding:
          const EdgeInsets.fromLTRB(
        18,
        16,
        18,
        14,
      ),
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          // ====================================================
          // STATUS
          // ====================================================

          WalkerAcceptStatus(
            status: data.status,
            distanceMeters:
                routeDistanceMeters,
          ),

          const SizedBox(height: 16),

          // ====================================================
          // WALKER DETAILS
          // ====================================================

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

          // ====================================================
          // ETA + DISTANCE
          // ====================================================

          WalkerEtaDistance(
            distanceMeters:
                routeDistanceMeters,
            etaMinutes:
                routeEtaMinutes,
          ),

          const SizedBox(height: 14),

          // ====================================================
          // CALL / CHAT
          // ====================================================

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
  // RECENTER OWNER
  // ==========================================================

  void _recenterOwner() {
    debugPrint(
      'WalkerAcceptScreen: recenter owner.',
    );

    // WalkerAcceptMap owns the MapController,
    // so this callback is intentionally kept here
    // for future parent-level location actions.
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

// ============================================================
// SIMPLE LOCATION VALUE
// ============================================================
//
// Keeps the screen independent from a specific location model.
// Firestore GeoPoint is converted before route calculation.
//

class GeoPointLike {
  const GeoPointLike({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}
