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
// IMPORTANT:
// - Do not navigate from this extension.
// - Do not set active state here.
// - Do not cancel/delete the Firestore request here.
// - Container handler controls search animation + listener shutdown.
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

    if (!mounted) {
      debugPrint(
        '❌ InstaWalkContainer is not mounted.',
      );
      return;
    }

    // ==========================================================
    // REQUEST ID
    // ==========================================================

    final String acceptedRequestId =
        accepted.requestId.trim();

    final String currentRequestId =
        (_requestId ?? '').trim();

    final String requestId =
        acceptedRequestId.isNotEmpty
            ? acceptedRequestId
            : currentRequestId;

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
    // WALKER IDENTITY VALIDATION
    // ==========================================================

    final bool hasWalkerIdentity =
        accepted.walkerId.trim().isNotEmpty ||
        accepted.walkerUid.trim().isNotEmpty;

    debugPrint(
      'walkerId = ${accepted.walkerId}',
    );

    debugPrint(
      'walkerUid = ${accepted.walkerUid}',
    );

    debugPrint(
      'walkerName = ${accepted.walkerName}',
    );

    if (!hasWalkerIdentity) {
      debugPrint(
        '❌ Walker identity is missing.',
      );
      return;
    }

    // ==========================================================
    // SAVE REQUEST ID
    // ==========================================================

    _requestId = requestId;

    // ==========================================================
    // HAND OFF TO CONTAINER ACCEPTED HANDLER
    // ==========================================================
    //
    // _handleAccepted() is the ONLY place responsible for:
    //
    // 1. Duplicate-accept protection
    // 2. Stopping search animation
    // 3. Stopping Firestore listener
    // 4. Setting search UI to normal
    // 5. Calling widget.onAccepted
    // 6. Opening WalkerAcceptScreen
    // 7. Resetting container after returning
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
