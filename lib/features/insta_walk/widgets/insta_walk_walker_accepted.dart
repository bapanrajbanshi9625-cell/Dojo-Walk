part of 'insta_walk_container.dart';

// ============================================================
// WALKER ACCEPTED
// ============================================================

extension _WalkerAcceptedRole on _InstaWalkContainerState {
  void _walkerAccepted(
    InstaWalkAcceptedData accepted,
  ) {
    if (!mounted) {
      return;
    }

    // ==========================================================
    // VALIDATE ACCEPTED DATA
    // ==========================================================

    final String requestId =
        accepted.requestId.trim();

    final String walkerId =
        accepted.walkerId.trim();

    final String walkerUid =
        accepted.walkerUid.trim();

    final String walkerName =
        accepted.walkerName.trim();

    // ==========================================================
    // REQUEST ID
    // ==========================================================

    if (requestId.isNotEmpty) {
      _requestId = requestId;
    }

    // ==========================================================
    // STOP SEARCH UI
    // ==========================================================

    _stopRadar();

    _updateState(() {
      _searching = false;
      _searchFinished = false;
      _checkingAddress = false;
      _recovering = false;
      _stopping = false;
    });

    // ==========================================================
    // SEARCH IS NO LONGER ACTIVE
    // ==========================================================

    _setActive(false);

    // ==========================================================
    // DEBUG
    // ==========================================================

    debugPrint(
      '================================================',
    );

    debugPrint(
      'INSTA WALK WALKER ACCEPTED',
    );

    debugPrint(
      'requestId: $requestId',
    );

    debugPrint(
      'ownerId: ${accepted.ownerId}',
    );

    debugPrint(
      'ownerName: ${accepted.ownerName}',
    );

    debugPrint(
      'address: ${accepted.address}',
    );

    debugPrint(
      'walkerId: $walkerId',
    );

    debugPrint(
      'walkerUid: $walkerUid',
    );

    debugPrint(
      'walkerName: $walkerName',
    );

    debugPrint(
      'walkerPhone: ${accepted.walkerPhone}',
    );

    debugPrint(
      'acceptedAt: ${accepted.acceptedAt}',
    );

    debugPrint(
      '================================================',
    );

    // ==========================================================
    // INVALID WALKER DATA
    // ==========================================================

    if (walkerId.isEmpty &&
        walkerUid.isEmpty) {
      _message(
        'Walker accepted the request, but walker information is missing.',
      );

      return;
    }

    // ==========================================================
    // CALLBACK
    //
    // Parent screen can open active-walk / walker UI.
    // ==========================================================

    widget.onAccepted?.call(
      accepted,
    );

    // ==========================================================
    // LEGACY CALLBACK
    // ==========================================================

    widget.onWalkerFound?.call();

    // ==========================================================
    // USER MESSAGE
    // ==========================================================

    final String displayName =
        walkerName.isEmpty
            ? 'Walker'
            : walkerName;

    _message(
      '$displayName accepted your Insta Walk request.',
    );
  }
}
