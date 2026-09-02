part of '../controllers/insta_walk_container.dart';

// ============================================================
// WALKER ACCEPTED
// ============================================================
//
// Responsibility:
//   • Validate accepted request
//   • Stop radar
//   • Stop searching
//   • Mark walk active
//   • Notify parent
//
// Navigation is NOT handled here.
//
// Navigation is handled by:
//   InstaWalkScreen
//
// ============================================================

extension _WalkerAcceptedRole on _InstaWalkContainerState {
  Future<void> _walkerAccepted(
    InstaWalkAcceptedData accepted,
  ) async {
    debugPrint('');
    debugPrint('==============================================');
    debugPrint('🔥 _WALKER ACCEPTED METHOD CALLED');
    debugPrint('==============================================');

    // ==========================================================
    // MOUNT CHECK
    // ==========================================================

    if (!mounted) {
      debugPrint(
        '❌ InstaWalkContainer is not mounted.',
      );
      return;
    }

    // ==========================================================
    // REQUEST ID
    // ==========================================================

    final String requestId =
        accepted.requestId.trim().isNotEmpty
            ? accepted.requestId.trim()
            : (_requestId ?? '').trim();

    debugPrint(
      'requestId = $requestId',
    );

    if (requestId.isEmpty) {
      debugPrint(
        '❌ requestId is empty.',
      );
      return;
    }

    // ==========================================================
    // WALKER VALIDATION
    // ==========================================================

    final String walkerId =
        accepted.walkerId.trim();

    final String walkerUid =
        accepted.walkerUid.trim();

    final String walkerName =
        accepted.walkerName.trim();

    debugPrint(
      'walkerId = $walkerId',
    );

    debugPrint(
      'walkerUid = $walkerUid',
    );

    debugPrint(
      'walkerName = $walkerName',
    );

    if (walkerId.isEmpty &&
        walkerUid.isEmpty) {
      debugPrint(
        '❌ Walker identity is missing.',
      );
      return;
    }

    // ==========================================================
    // STORE REQUEST ID
    // ==========================================================

    _requestId = requestId;

    // ==========================================================
    // STOP RADAR
    // ==========================================================

    _stopRadar();

    debugPrint(
      '✅ Radar stopped.',
    );

    // ==========================================================
    // STOP SEARCH UI
    // ==========================================================

    _updateState(() {
      _searching = false;
      _searchFinished = false;
      _recovering = false;
      _checkingAddress = false;
      _stopping = false;
    });

    debugPrint(
      '✅ Searching stopped.',
    );

    // ==========================================================
    // MARK ACTIVE
    // ==========================================================

    _setActive(true);

    debugPrint(
      '✅ Active state = true.',
    );

    // ==========================================================
    // CALLBACK
    // ==========================================================
    //
    // IMPORTANT:
    //
    // DO NOT Navigator.push() HERE.
    //
    // Parent screen handles navigation.
    //
    // ==========================================================

    final ValueChanged<InstaWalkAcceptedData>? callback =
        widget.onAccepted;

    if (callback == null) {
      debugPrint(
        '❌ onAccepted callback is NULL.',
      );
      debugPrint(
        '❌ WalkerAcceptScreen cannot be opened from here.',
      );
      return;
    }

    debugPrint(
      '🚀 BEFORE onAccepted CALLBACK',
    );

    callback(
      accepted,
    );

    debugPrint(
      '🚀 AFTER onAccepted CALLBACK',
    );

    debugPrint('');
    debugPrint('==============================================');
    debugPrint('✅ ACCEPTED FLOW SENT TO PARENT');
    debugPrint('requestId = $requestId');
    debugPrint('==============================================');
  }
}
