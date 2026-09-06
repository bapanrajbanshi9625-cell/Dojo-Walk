// File:
// lib/features/insta_walk/controllers/insta_walk_container.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../screens/address_screen.dart';

import '../services/insta_walk_search_service.dart';
import '../services/insta_walk_request_state.dart';
import '../services/insta_walk_accepted_data.dart';
import '../services/insta_walk_search_result.dart';

import '../widgets/insta_walk_search_button.dart';
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

  // Kept for compatibility with existing callers.
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
  // SEARCH ICON ANIMATION
  // ==========================================================
  //
  // Small animation only.
  //
  // No map.
  // No radar.
  // No GPS.
  //

  late final AnimationController _searchAnimationController;

  late final Animation<double> _searchRotation;
  late final Animation<double> _searchScale;
  late final Animation<Offset> _searchMovement;

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
  // ACCEPT HANDLED
  // ==========================================================
  //
  // ONLY prevents duplicate navigation.
  //
  // This is NOT a walk lifecycle lock.
  //

  bool _acceptHandled = false;

  // ==========================================================
  // REQUEST
  // ==========================================================

  String? _requestId;

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

    // --------------------------------------------------------
    // Search icon animation.
    // --------------------------------------------------------

    _searchAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _searchRotation = Tween<double>(
      begin: -0.06,
      end: 0.06,
    ).animate(
      CurvedAnimation(
        parent: _searchAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _searchScale = Tween<double>(
      begin: 0.92,
      end: 1.08,
    ).animate(
      CurvedAnimation(
        parent: _searchAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _searchMovement = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: const Offset(0, -0.04),
    ).animate(
      CurvedAnimation(
        parent: _searchAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // --------------------------------------------------------
    // Recover any existing Insta Walk request.
    // --------------------------------------------------------

    _recoverSearch();
  }

  // ==========================================================
  // START SEARCH ICON ANIMATION
  // ==========================================================

  void _startSearchAnimation() {
    if (!mounted) {
      return;
    }

    if (!_searching) {
      return;
    }

    if (!_searchAnimationController.isAnimating) {
      _searchAnimationController.repeat(
        reverse: true,
      );

      debugPrint(
        '🔎 InstaWalk search animation started.',
      );
    }
  }

  // ==========================================================
  // STOP SEARCH ICON ANIMATION
  // ==========================================================

  void _stopSearchAnimation() {
    if (!_searchAnimationController.isAnimating &&
        _searchAnimationController.value == 0) {
      return;
    }

    _searchAnimationController.stop();
    _searchAnimationController.reset();

    debugPrint(
      '🛑 InstaWalk search animation stopped.',
    );
  }

  // ==========================================================
  // WALKER ACCEPTED
  // ==========================================================
  //
  // This only:
  //
  // 1. Stops Insta Walk search UI.
  // 2. Stops Firestore listener.
  // 3. Opens existing accepted-walk screen.
  // 4. Resets this container after that screen returns.
  //
  // Accepted walk lifecycle is handled elsewhere.
  //

  void _handleAccepted(
    InstaWalkAcceptedData accepted,
  ) {
    if (!mounted) {
      return;
    }

    // --------------------------------------------------------
    // Prevent duplicate navigation only.
    // --------------------------------------------------------

    if (_acceptHandled) {
      debugPrint(
        'InstaWalkContainer: accepted event already handled.',
      );
      return;
    }

    final String requestId = accepted.requestId.trim();

    if (requestId.isEmpty) {
      debugPrint(
        '❌ Walker accepted but requestId is empty.',
      );
      return;
    }

    _acceptHandled = true;
    _requestId = requestId;

    debugPrint('');
    debugPrint(
      '==============================================',
    );
    debugPrint(
      '🔥 OWNER INSTA WALK: WALKER ACCEPTED',
    );
    debugPrint(
      '🛑 STOPPING INSTA WALK SEARCH UI',
    );
    debugPrint(
      '🛑 STOPPING SEARCH ANIMATION',
    );
    debugPrint(
      '🛑 STOPPING SEARCH LISTENER',
    );
    debugPrint(
      '==============================================',
    );
    debugPrint(
      'requestId = $requestId',
    );

    // --------------------------------------------------------
    // Stop search animation.
    // --------------------------------------------------------

    _stopSearchAnimation();

    // --------------------------------------------------------
    // Stop Firestore listener.
    // --------------------------------------------------------

    _service.stopListening();

    // --------------------------------------------------------
    // Reset only Insta Walk search UI.
    // --------------------------------------------------------

    _stopping = false;

    _updateState(() {
      _searching = false;
      _searchFinished = false;
      _checkingAddress = false;
      _recovering = false;
      _stopping = false;
    });

    // --------------------------------------------------------
    // Insta Walk search is no longer active.
    // --------------------------------------------------------

    _setActive(false);

    // --------------------------------------------------------
    // External callback.
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
    // Open existing accepted-walk screen.
    // --------------------------------------------------------

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (!mounted) {
          return;
        }

        _openOwnerAcceptedScreen(requestId);
      },
    );
  }

  // ==========================================================
  // OPEN OWNER ACCEPTED WALK SCREEN
  // ==========================================================

  Future<void> _openOwnerAcceptedScreen(
    String requestId,
  ) async {
    if (!mounted) {
      return;
    }

    final String cleanRequestId = requestId.trim();

    if (cleanRequestId.isEmpty) {
      debugPrint(
        '❌ Cannot open WalkerAcceptScreen: empty requestId.',
      );

      _resetAfterAcceptedFlow();

      return;
    }

    debugPrint(
      '🚀 Opening Owner WalkerAcceptScreen',
    );

    debugPrint(
      'requestId = $cleanRequestId',
    );

    try {
      await Navigator.of(context).push<dynamic>(
        MaterialPageRoute<dynamic>(
          builder: (_) {
            return WalkerAcceptScreen(
              requestId: cleanRequestId,
            );
          },
        ),
      );
    } catch (error) {
      debugPrint(
        '❌ Error opening WalkerAcceptScreen: $error',
      );
    }

    if (!mounted) {
      return;
    }

    // --------------------------------------------------------
    // The accepted-walk feature owns the walk lifecycle.
    //
    // We only prepare this container for a NEW Insta Walk.
    // --------------------------------------------------------

    _resetAfterAcceptedFlow();
  }

  // ==========================================================
  // RESET AFTER ACCEPTED FLOW
  // ==========================================================

  void _resetAfterAcceptedFlow() {
    if (!mounted) {
      return;
    }

    debugPrint(
      '🔄 InstaWalkContainer: resetting after accepted flow.',
    );

    // --------------------------------------------------------
    // Stop previous search activity.
    // --------------------------------------------------------

    _stopSearchAnimation();
    _service.stopListening();

    // --------------------------------------------------------
    // Clear old request.
    // --------------------------------------------------------

    _requestId = null;

    // --------------------------------------------------------
    // Allow another accepted event.
    // --------------------------------------------------------

    _acceptHandled = false;

    // --------------------------------------------------------
    // Restore normal Insta Walk state.
    // --------------------------------------------------------

    _updateState(() {
      _searching = false;
      _searchFinished = false;
      _checkingAddress = false;
      _recovering = false;
      _stopping = false;
    });

    _setActive(false);

    debugPrint(
      '✅ InstaWalkContainer ready for NEW search.',
    );
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _stopSearchAnimation();

    _service.dispose();

    _searchAnimationController.dispose();

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
  // RESET SEARCH STATE
  // ==========================================================

  void _resetSearchState({
    bool finished = false,
  }) {
    _stopSearchAnimation();

    _service.stopListening();

    _requestId = null;
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
      _stopping = false;
    });

    _setActive(false);
  }

  // ==========================================================
  // FINISH SEARCH
  // ==========================================================

  void _finishSearch({
    String? message,
  }) {
    _stopSearchAnimation();

    _service.stopListening();

    _requestId = null;
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
      _stopping = false;
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
    if (_searching ||
        _checkingAddress ||
        _recovering ||
        _stopping) {
      return;
    }

    if (!mounted) {
      return;
    }

    // --------------------------------------------------------
    // New search = allow next accepted event.
    // --------------------------------------------------------

    _acceptHandled = false;

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

      final String result = value.toString().trim();

      if (result.isNotEmpty) {
        return result;
      }
    }

    return '';
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    // --------------------------------------------------------
    // fullScreen is intentionally kept for API compatibility.
    //
    // Final Insta Walk presentation is controlled by
    // insta_walk_view.dart.
    // --------------------------------------------------------

    return _buildFullScreen();
  }
}
