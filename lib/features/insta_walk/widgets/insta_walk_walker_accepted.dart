part of '../controllers/insta_walk_container.dart';

// ============================================================
// WALKER ACCEPTED
// ============================================================
//
// Owner-side accepted flow.
//
// Navigation is handled ONLY by:
// _InstaWalkContainerState._handleAccepted()
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
    // IMPORTANT
    // ==========================================================
    //
    // Do NOT call:
    //
    // _setActive(true)
    //
    // here.
    //
    // The accepted flow is already transitioning away from
    // the search screen. Changing active state here can trigger
    // the parent to rebuild/dispose this container before the
    // navigation frame executes.
    //
    // ==========================================================

    // ==========================================================
    // INTERNAL ACCEPTED HANDLER
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
