import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

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
//
// Existing Insta Walk logic remains untouched.
//
// These files are still physically inside:
//
// lib/features/insta_walk/widgets/
//
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
//
// This is now BOTH:
//
// 1. Insta Walk controller
// 2. Insta Walk screen
//
// No separate insta_walk_screen.dart is required.
//
// ============================================================

class InstaWalkContainer extends StatefulWidget {
  const InstaWalkContainer({
    super.key,
    this.onWalkerFound,
    this.onActiveChanged,
    this.fullScreen = true,
    this.onTap,
    ValueChanged<InstaWalkAcceptedData>? onAccepted,
  }) : _externalOnAccepted = onAccepted;

  final VoidCallback? onWalkerFound;

  final ValueChanged<bool>? onActiveChanged;

  final bool fullScreen;

  final VoidCallback? onTap;

  // ==========================================================
  // EXTERNAL ACCEPTED CALLBACK
  // ==========================================================
  //
  // Kept for backward compatibility.
  //
  // Existing part file calls:
  //
  // widget.onAccepted?.call(accepted);
  //
  // So we expose a getter below which internally handles:
  //
  // Firestore accepted
  //       ↓
  // local cleanup
  //       ↓
  // Owner WalkerAcceptScreen
  //
  // ==========================================================

  final ValueChanged<InstaWalkAcceptedData>? _externalOnAccepted;

  // ==========================================================
  // ACCEPTED HANDLER
  // ==========================================================
  //
  // IMPORTANT:
  //
  // The existing insta_walk_walker_accepted.dart does not need
  // to know about navigation.
  //
  // Whenever it calls:
  //
  // widget.onAccepted?.call(accepted)
  //
  // this getter returns our internal handler.
  //
  // ==========================================================

  ValueChanged<InstaWalkAcceptedData>? get onAccepted {
    return _handleAccepted;
  }

  // ==========================================================
  // STATE
  // ==========================================================

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
  // ACCEPT NAVIGATION STATE
  // ==========================================================

  bool _acceptedNavigationStarted = false;

  // ==========================================================
  // REQUEST
  // ==========================================================

  String? _requestId;

  // ==========================================================
  // LOCATION
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
  // ACCEPTED
  // ==========================================================
  //
  // FLOW:
  //
  // Walker accepts
  //       ↓
  // Firestore status = accepted
  //       ↓
  // insta_walk_walker_accepted.dart
  //       ↓
  // widget.onAccepted?.call(accepted)
  //       ↓
  // THIS METHOD
  //       ↓
  // stop local radar
  //       ↓
  // Owner WalkerAcceptScreen
  //
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

    // ========================================================
    // REQUEST ID CHECK
    // ========================================================

    if (requestId.isEmpty) {
      debugPrint(
        '❌ Owner navigation cancelled: requestId empty.',
      );
      return;
    }

    _acceptedNavigationStarted = true;

    // ========================================================
    // KEEP REQUEST ID
    // ========================================================

    _requestId = requestId;

    // ========================================================
    // STOP ONLY LOCAL SEARCH UI
    // ========================================================
    //
    // IMPORTANT:
    //
    // We are NOT cancelling the Firestore request here.
    //
    // WalkerAcceptScreen still needs the same requestId.
    //
    // ========================================================

    _stopRadar();

    _stopping = false;

    if (mounted) {
      setState(() {
        _searching = false;
        _searchFinished = false;
        _checkingAddress = false;
        _recovering = false;
      });
    }

    _setActive(false);

    // ========================================================
    // EXTERNAL CALLBACK
    // ========================================================
    //
    // If another parent still supplied onAccepted, preserve it.
    //
    // The old InstaWalkScreen can therefore be removed later
    // without breaking the callback contract.
    //
    // ========================================================

    _externalAcceptedCallback(accepted);

    // ========================================================
    // NAVIGATION
    // ========================================================
    //
    // Wait until the current Firestore/state frame is complete.
    //
    // ========================================================

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (!mounted) {
          debugPrint(
            '❌ Owner navigation cancelled: container unmounted.',
          );
          return;
        }

        _openOwnerAcceptedScreen(requestId);
      },
    );
  }

  // ==========================================================
  // EXTERNAL CALLBACK
  // ==========================================================

  void _externalAcceptedCallback(
    InstaWalkAcceptedData accepted,
  ) {
    final ValueChanged<InstaWalkAcceptedData>?
        callback = widget._externalOnAccepted;

    if (callback == null) {
      return;
    }

    try {
      callback(accepted);
    } catch (error) {
      debugPrint(
        'InstaWalkContainer external onAccepted error: $error',
      );
    }
  }

  // ==========================================================
  // OPEN OWNER ACCEPTED SCREEN
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
      return;
    }

    debugPrint(
      '🚀 Opening Owner WalkerAcceptScreen',
    );

    debugPrint(
      'requestId = $cleanRequestId',
    );

    Navigator.of(context).pushReplacement(
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
  //
  // IMPORTANT:
  //
  // Disposing this widget MUST NOT cancel the actual
  // Insta Walk Firestore request.
  //
  // ==========================================================

  @override
  void dispose() {
    // --------------------------------------------------------
    // Stop only local radar animation.
    // --------------------------------------------------------

    _stopRadar();

    // --------------------------------------------------------
    // Clean up local service/listener.
    //
    // InstaWalkSearchService.dispose() must NOT cancel the
    // active Firestore request.
    // --------------------------------------------------------

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
  //
  // LOCAL UI ONLY.
  //
  // Does NOT change Firestore.
  //
  // ==========================================================

  void _resetSearchState({
    bool finished = false,
  }) {
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
      _searchFinished = finished;
      _checkingAddress = false;
      _recovering = false;
    });

    _setActive(false);
  }

  // ==========================================================
  // FINISH SEARCH
  //
  // No timer.
  // No countdown.
  // No automatic expiry.
  //
  // ==========================================================

  void _finishSearch({
    String? message,
  }) {
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
  // RETRY
  // ==========================================================

  Future<void> _retrySearch() async {
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
  // READ STRING
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

    return null;
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    // ========================================================
    // FULL SCREEN
    // ========================================================
    //
    // This is now the actual Insta Walk screen.
    //
    // ========================================================

    if (widget.fullScreen) {
      return Scaffold(
        backgroundColor:
            const Color(0xFFF4F7F8),

        // ====================================================
        // APP BAR
        // ====================================================

        appBar: AppBar(
          backgroundColor:
              const Color(0xFF243746),
          foregroundColor:
              Colors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'Insta Walk',
            style: TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
        ),

        // ====================================================
        // BODY
        // ====================================================

        body: SafeArea(
          child: SingleChildScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding:
                const EdgeInsets.only(
              bottom: 30,
            ),
            child: _buildFullScreen(),
          ),
        ),
      );
    }

    // ========================================================
    // COMPACT MODE
    // ========================================================

    return _buildCompactPatti();
  }
}
