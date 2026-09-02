part of '../controllers/insta_walk_container.dart';

// ============================================================
// WALKER ACCEPTED
// ============================================================
//
// Responsibility:
//   • Validate accepted request
//   • Stop radar
//   • Stop searching
//   • Store request ID
//   • Mark walk state
//   • Open Owner WalkerAcceptScreen through controller
//
// Navigation itself is implemented by:
//   _InstaWalkContainerState._handleAccepted()
//
// ============================================================

extension _WalkerAcceptedRole on _InstaWalkContainerState {
  Future<void> _walkerAccepted(
    InstaWalkAcceptedData accepted,
  ) async {
    debugPrint('');
    debugPrint(
      '==============================================',
    );
    debugPrint(
      '🔥 _WALKER ACCEPTED METHOD CALLED',
    );
    debugPrint(
      '==============================================',
    );

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
    // INTERNAL ACCEPTED HANDLER
    // ==========================================================
    //
    // IMPORTANT:
    //
    // Previously this file called:
    //
    // widget.onAccepted?.call(accepted);
    //
    // That depended on the old InstaWalkScreen.
    //
    // Now the Container itself owns the screen/navigation flow.
    //
    // Therefore call the State handler directly.
    //
    // ==========================================================

    debugPrint(
      '🚀 Sending accepted request to Container handler...',
    );

    _handleAccepted(accepted);

    debugPrint(
      '🚀 Accepted request sent to Container handler.',
    );

    debugPrint('');
    debugPrint(
      '==============================================',
    );
    debugPrint(
      '✅ OWNER ACCEPTED FLOW STARTED',
    );
    debugPrint(
      'requestId = $requestId',
    );
    debugPrint(
      '==============================================',
    );
  }
}
