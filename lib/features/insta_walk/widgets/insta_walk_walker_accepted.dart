part of 'insta_walk_container.dart';

// ============================================================
// WALKER ACCEPTED
// ============================================================
//
// Responsibility:
//   • Validate accepted request
//   • Stop radar
//   • Stop searching UI
//   • Mark Insta Walk active
//   • Notify parent through onAccepted
//
// Navigation:
//   • NOT handled here
//   • InstaWalkScreen handles navigation
//
// Flow:
//
// Firestore status = accepted
//          ↓
// _walkerAccepted()
//          ↓
// Radar OFF
//          ↓
// Searching OFF
//          ↓
// onAccepted(accepted)
//          ↓
// InstaWalkScreen
//          ↓
// WalkerAcceptScreen
//
// ============================================================

extension _WalkerAcceptedRole on _InstaWalkContainerState {
  Future<void> _walkerAccepted(
    InstaWalkAcceptedData accepted,
  ) async {
    debugPrint('');
    debugPrint('==============================================');
    debugPrint('🔥 INSTA WALK ACCEPTED');
    debugPrint('==============================================');

    // ==========================================================
    // MOUNT CHECK
    // ==========================================================

    if (!mounted) {
      debugPrint(
        '❌ InstaWalkContainer is no longer mounted.',
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
        '❌ Accepted requestId is missing.',
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

    debugPrint(
      'walkerId = $walkerId',
    );

    debugPrint(
      'walkerUid = $walkerUid',
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
    // UPDATE LOCAL UI STATE
    // ==========================================================

    _updateState(() {
      _searching = false;
      _searchFinished = false;
      _recovering = false;
      _checkingAddress = false;
      _stopping = false;
    });

    debugPrint(
      '✅ Searching UI stopped.',
    );

    // ==========================================================
    // MARK ACTIVE
    // ==========================================================

    _setActive(true);

    // ==========================================================
    // NOTIFY PARENT
    //
    // IMPORTANT:
    //
    // No Navigator here.
    //
    // InstaWalkScreen is responsible for opening:
    //
    // WalkerAcceptScreen(requestId: requestId)
    //
    // ==========================================================

    debugPrint(
      '🚀 Calling onAccepted callback...',
    );

    widget.onAccepted?.call(
      accepted,
    );

    debugPrint(
      '✅ onAccepted callback completed.',
    );

    debugPrint('==============================================');
    debugPrint(
      'INSTA WALK ACCEPTED FLOW COMPLETE',
    );
    debugPrint('==============================================');
  }
}
