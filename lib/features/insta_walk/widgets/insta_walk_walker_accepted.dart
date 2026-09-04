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
// - Container handler controls radar + listener shutdown.
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

    _requestId = requestId;

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
