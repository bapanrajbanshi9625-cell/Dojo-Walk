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
  // IMPORTANT:
  // This is the permanent UI guard for this mounted
  // InstaWalkContainer instance.
  //
  // Once Firestore says accepted, normal Insta Walk
  // searching UI must never come back during this
  // container lifecycle.
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
    // IMPORTANT:
    // Set this BEFORE stopping listeners/state updates.
    // This prevents a rebuild from rendering the normal
    // Insta Walk search UI again.
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
    // STOP FIRESTORE LISTENER
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
    });

    // --------------------------------------------------------
    // DO NOT REPORT SEARCH AS ACTIVE
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

  void _openOwnerAcceptedScreen(
    String requestId,
  ) {
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

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          return WalkerAcceptScreen(
            requestId: cleanRequestId,
          );
        },
      ),
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
    // Do not unlock an already accepted request.
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
    // Never finish/reopen normal search UI after acceptance.
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
