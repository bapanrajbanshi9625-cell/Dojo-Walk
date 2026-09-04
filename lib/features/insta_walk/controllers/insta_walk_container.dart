// File:
// lib/features/insta_walk/controllers/insta_walk_container.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../../screens/address_screen.dart';

import '../services/insta_walk_search_service.dart';
import '../services/insta_walk_request_state.dart';
import '../services/insta_walk_accepted_data.dart';
import '../services/insta_walk_search_result.dart';

import '../widgets/insta_walk_map_radar.dart';
import '../widgets/insta_walk_search_button.dart';
import '../widgets/insta_walk_searching.dart';

import '../../walker_accept/screens/walker_accept_screen.dart';

// ============================================================
// PART FILES
// ============================================================

part '../widgets/insta_walk_find_walker.dart';
part '../widgets/insta_walk_start_search.dart';
part '../widgets/insta_walk_stop_search.dart';
part '../widgets/insta_walk_recovery.dart';
part '../widgets/insta_walk_walker_accepted.dart';
part '../widgets/insta_walk_view.dart';

// ============================================================
// INSTA WALK CONTAINER
// ============================================================

class InstaWalkContainer extends StatefulWidget {
  const InstaWalkContainer({
    super.key,
    this.onWalkerFound,
    this.onActiveChanged,
    this.fullScreen = true,
    this.onTap,
    this.onAccepted,
  });

  final VoidCallback? onWalkerFound;

  final ValueChanged<bool>? onActiveChanged;

  final bool fullScreen;

  final VoidCallback? onTap;

  final ValueChanged<InstaWalkAcceptedData>? onAccepted;

  @override
  State<InstaWalkContainer> createState() =>
      _InstaWalkContainerState();
}

// ============================================================
// STATE
// ============================================================

class _InstaWalkContainerState extends State<InstaWalkContainer>
    with SingleTickerProviderStateMixin {
  // ==========================================================
  // SERVICE
  // ==========================================================

  late final InstaWalkSearchService _service;

  // ==========================================================
  // RADAR
  // ==========================================================

  late final AnimationController _radarController;

  // ==========================================================
  // SEARCH STATE
  // ==========================================================

  bool _searching = false;
  bool _searchFinished = false;
  bool _checkingAddress = false;
  bool _recovering = true;

  // ==========================================================
  // STOP STATE
  // ==========================================================

  bool _stopping = false;

  // ==========================================================
  // ACTIVE STATE
  // ==========================================================

  bool _activeReported = false;

  // ==========================================================
  // ACCEPTED STATE
  // ==========================================================
  //
  // true while this container is handling an accepted walk.
  //
  // IMPORTANT:
  // This lock is cleared ONLY after the Live Walk screen
  // reports that the walk has actually completed.
  //

  bool _acceptedNavigationStarted = false;

  // ==========================================================
  // REQUEST
  // ==========================================================

  String? _requestId;

  // ==========================================================
  // OWNER LOCATION
  // ==========================================================

  Position? _ownerPosition;

  // ==========================================================
  // PET
  // ==========================================================

  String _petName = 'Your Pet';

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _service = InstaWalkSearchService();

    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _recoverSearch();
  }

  // ==========================================================
  // WALKER ACCEPTED
  // ==========================================================

  void _handleAccepted(
    InstaWalkAcceptedData accepted,
  ) {
    if (!mounted) {
      return;
    }

    // --------------------------------------------------------
    // Prevent duplicate navigation.
    // --------------------------------------------------------

    if (_acceptedNavigationStarted) {
      debugPrint(
        'InstaWalkContainer: accepted navigation already started.',
      );
      return;
    }

    final String requestId =
        accepted.requestId.trim();

    debugPrint('');
    debugPrint(
      '==============================================',
    );
    debugPrint(
      '🔥 OWNER INSTA WALK: WALKER ACCEPTED',
    );
    debugPrint(
      '==============================================',
    );
    debugPrint(
      'requestId = $requestId',
    );

    // --------------------------------------------------------
    // REQUEST ID REQUIRED
    // --------------------------------------------------------

    if (requestId.isEmpty) {
      debugPrint(
        '❌ Walker accepted but requestId is empty.',
      );
      return;
    }

    // --------------------------------------------------------
    // LOCK ACCEPTED STATE FIRST
    // --------------------------------------------------------
    //
    // This MUST happen before stopping listeners so that
    // no rebuild can bring back the normal search UI.
    //

    _acceptedNavigationStarted = true;

    // --------------------------------------------------------
    // KEEP REQUEST ID
    // --------------------------------------------------------

    _requestId = requestId;

    // --------------------------------------------------------
    // STOP RADAR
    // --------------------------------------------------------

    _stopRadar();

    // --------------------------------------------------------
    // STOP FIRESTORE SEARCH LISTENER
    // --------------------------------------------------------

    _service.stopListening();

    _stopping = false;

    // --------------------------------------------------------
    // STOP SEARCH UI
    // --------------------------------------------------------

    _updateState(() {
      _searching = false;
      _searchFinished = false;
      _checkingAddress = false;
      _recovering = false;
      _stopping = false;
    });

    // --------------------------------------------------------
    // SEARCH IS NO LONGER ACTIVE
    // --------------------------------------------------------

    _setActive(false);

    // --------------------------------------------------------
    // EXTERNAL CALLBACK
    // --------------------------------------------------------

    final ValueChanged<InstaWalkAcceptedData>? callback =
        widget.onAccepted;

    if (callback != null) {
      try {
        callback(accepted);
      } catch (error) {
        debugPrint(
          'InstaWalkContainer onAccepted error: $error',
        );
      }
    }

    // --------------------------------------------------------
    // NAVIGATE AFTER CURRENT FRAME
    // --------------------------------------------------------

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (!mounted) {
          debugPrint(
            '❌ Owner accepted screen navigation cancelled.',
          );
          return;
        }

        _openOwnerAcceptedScreen(requestId);
      },
    );
  }

  // ==========================================================
  // OPEN OWNER WALKER ACCEPT SCREEN
  // ==========================================================
  //
  // IMPORTANT:
  //
  // WalkerAcceptScreen eventually replaces itself with
  // LiveWalkScreen.
  //
  // LiveWalkScreen returns true when the walk is completed.
  //
  // That true comes back to this Navigator.push().
  //

  Future<void> _openOwnerAcceptedScreen(
    String requestId,
  ) async {
    if (!mounted) {
      return;
    }

    final String cleanRequestId =
        requestId.trim();

    if (cleanRequestId.isEmpty) {
      debugPrint(
        '❌ Cannot open WalkerAcceptScreen: empty requestId.',
      );
      return;
    }

    debugPrint(
      '🚀 Opening Owner WalkerAcceptScreen',
    );

    debugPrint(
      'requestId = $cleanRequestId',
    );

    final dynamic result =
        await Navigator.of(context).push<dynamic>(
      MaterialPageRoute<dynamic>(
        builder: (_) {
          return WalkerAcceptScreen(
            requestId: cleanRequestId,
          );
        },
      ),
    );

    if (!mounted) {
      return;
    }

    debugPrint(
      'OWNER WALK FLOW → WalkerAcceptScreen returned: $result',
    );

    // --------------------------------------------------------
    // WALK COMPLETED
    // --------------------------------------------------------
    //
    // LiveWalkScreen returns true when Firestore reports
    // session.isCompleted.
    //

    if (result == true) {
      debugPrint(
        '✅ OWNER WALK FLOW → walk completed.',
      );

      _resetAfterWalkCompleted();
    }
  }

  // ==========================================================
  // RESET AFTER WALK COMPLETION
  // ==========================================================
  //
  // This is the important part that allows a NEW walk request.
  //

  void _resetAfterWalkCompleted() {
    if (!mounted) {
      return;
    }

    debugPrint('');
    debugPrint(
      '==============================================',
    );
    debugPrint(
      '✅ OWNER INSTA WALK: RESET AFTER COMPLETION',
    );
    debugPrint(
      '==============================================',
    );

    // --------------------------------------------------------
    // Stop anything left from the previous search.
    // --------------------------------------------------------

    _stopRadar();
    _service.stopListening();

    // --------------------------------------------------------
    // Clear old request data.
    // --------------------------------------------------------

    _requestId = null;
    _ownerPosition = null;

    // --------------------------------------------------------
    // IMPORTANT:
    //
    // Remove the accepted lock.
    //
    // This makes InstaWalkContainer visible again.
    // --------------------------------------------------------

    _acceptedNavigationStarted = false;

    // --------------------------------------------------------
    // Restore normal idle state.
    // --------------------------------------------------------

    _updateState(() {
      _searching = false;
      _searchFinished = false;
      _checkingAddress = false;
      _recovering = false;
      _stopping = false;
    });

    // --------------------------------------------------------
    // Search is inactive.
    // --------------------------------------------------------

    _setActive(false);

    debugPrint(
      '✅ InstaWalkContainer ready for a NEW walk request.',
    );
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _stopRadar();

    _service.dispose();

    _radarController.dispose();

    super.dispose();
  }

  // ==========================================================
  // SAFE STATE UPDATE
  // ==========================================================

  void _updateState(
    VoidCallback callback,
  ) {
    if (!mounted) {
      return;
    }

    setState(callback);
  }

  // ==========================================================
  // ACTIVE STATE
  // ==========================================================

  void _setActive(
    bool active,
  ) {
    if (_activeReported == active) {
      return;
    }

    _activeReported = active;

    widget.onActiveChanged?.call(active);
  }

  // ==========================================================
  // STOP RADAR
  // ==========================================================

  void _stopRadar() {
    if (!_radarController.isAnimating &&
        _radarController.value == 0) {
      return;
    }

    _radarController.stop();
    _radarController.reset();
  }

  // ==========================================================
  // START RADAR
  // ==========================================================

  void _startRadar() {
    if (!mounted) {
      return;
    }

    if (!_radarController.isAnimating) {
      _radarController.repeat();
    }
  }

  // ==========================================================
  // RESET SEARCH STATE
  // ==========================================================

  void _resetSearchState({
    bool finished = false,
  }) {
    _stopRadar();

    _requestId = null;
    _ownerPosition = null;
    _stopping = false;

    // --------------------------------------------------------
    // IMPORTANT:
    //
    // If a walker has already accepted the request,
    // never restore normal search UI.
    //
    // The accepted lock is cleared only by
    // _resetAfterWalkCompleted().
    // --------------------------------------------------------

    if (_acceptedNavigationStarted) {
      if (mounted) {
        _updateState(() {
          _searching = false;
          _searchFinished = false;
          _checkingAddress = false;
          _recovering = false;
          _stopping = false;
        });
      }

      _setActive(false);
      return;
    }

    if (!mounted) {
      _setActive(false);
      return;
    }

    _updateState(() {
      _searching = false;
      _searchFinished = finished;
      _checkingAddress = false;
      _recovering = false;
    });

    _setActive(false);
  }

  // ==========================================================
  // FINISH SEARCH
  // ==========================================================

  void _finishSearch({
    String? message,
  }) {
    // --------------------------------------------------------
    // Never show normal search/cancel UI after acceptance.
    // --------------------------------------------------------

    if (_acceptedNavigationStarted) {
      _stopRadar();
      _service.stopListening();

      if (mounted) {
        _updateState(() {
          _searching = false;
          _searchFinished = false;
          _checkingAddress = false;
          _recovering = false;
          _stopping = false;
        });
      }

      _setActive(false);
      return;
    }

    _stopRadar();

    _requestId = null;
    _ownerPosition = null;
    _stopping = false;

    if (!mounted) {
      _setActive(false);
      return;
    }

    _updateState(() {
      _searching = false;
      _searchFinished = true;
      _checkingAddress = false;
      _recovering = false;
    });

    _setActive(false);

    if (message != null &&
        message.trim().isNotEmpty) {
      _message(message);
    }
  }

  // ==========================================================
  // RETRY SEARCH
  // ==========================================================

  Future<void> _retrySearch() async {
    // --------------------------------------------------------
    // Never retry an already accepted walk.
    // --------------------------------------------------------

    if (_acceptedNavigationStarted) {
      return;
    }

    if (_searching ||
        _checkingAddress ||
        _recovering ||
        _stopping) {
      return;
    }

    if (!mounted) {
      return;
    }

    _updateState(() {
      _searchFinished = false;
    });

    await _findWalker();
  }

  // ==========================================================
  // MESSAGE
  // ==========================================================

  void _message(
    String text,
  ) {
    if (!mounted) {
      return;
    }

    final ScaffoldMessengerState messenger =
        ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  // ==========================================================
  // READ FIRST STRING
  // ==========================================================

  String _readFirstString(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final String key in keys) {
      final dynamic value = data[key];

      if (value == null) {
        continue;
      }

      final String result =
          value.toString().trim();

      if (result.isNotEmpty) {
        return result;
      }
    }

    return '';
  }

  // ==========================================================
  // READ OWNER POSITION
  // ==========================================================

  Position? _readOwnerPosition(
    Map<String, dynamic>? data,
  ) {
    if (data == null) {
      return null;
    }

    final dynamic value =
        data['ownerLocation'];

    // --------------------------------------------------------
    // GeoPoint
    // --------------------------------------------------------

    if (value is GeoPoint) {
      return Position(
        longitude: value.longitude,
        latitude: value.latitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    }

    // --------------------------------------------------------
    // Map
    // --------------------------------------------------------

    if (value is Map) {
      final dynamic lat =
          value['latitude'] ??
          value['lat'];

      final dynamic lng =
          value['longitude'] ??
          value['lng'] ??
          value['lon'];

      if (lat is num &&
          lng is num) {
        return Position(
          longitude: lng.toDouble(),
          latitude: lat.toDouble(),
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }
    }

    return null;
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    if (widget.fullScreen) {
      return _buildFullScreen();
    }

    return _buildCompactPatti();
  }
}
