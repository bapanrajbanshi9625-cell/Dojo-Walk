part of 'insta_walk_container.dart';

// ============================================================
// WALKER ACCEPTED
// ============================================================

extension _WalkerAcceptedRole on _InstaWalkContainerState {
  Future<void> _walkerAccepted(
    InstaWalkAcceptedData accepted,
  ) async {
    // ==========================================================
    // VALIDATE REQUEST
    // ==========================================================

    final String requestId =
        accepted.requestId.trim().isNotEmpty
            ? accepted.requestId.trim()
            : (_requestId ?? '').trim();

    if (requestId.isEmpty) {
      debugPrint(
        'Insta Walk accepted but requestId is missing.',
      );
      return;
    }

    // ==========================================================
    // VALIDATE WALKER
    // ==========================================================

    final String walkerId = accepted.walkerId.trim();
    final String walkerUid = accepted.walkerUid.trim();
    final String walkerName = accepted.walkerName.trim();

    if (walkerId.isEmpty && walkerUid.isEmpty) {
      debugPrint(
        'Insta Walk accepted but walker identity is missing.',
      );
      return;
    }

    // ==========================================================
    // STORE REQUEST ID
    // ==========================================================

    _requestId = requestId;

    // ==========================================================
    // STOP RADAR ONLY
    //
    // IMPORTANT:
    // Do NOT close/pop the Insta Walk screen here.
    // The Owner must remain in the flow and move to
    // the accepted-walker / active-walk screen.
    // ==========================================================

    _stopRadar();

    // ==========================================================
    // RESTORE OWNER LOCATION
    // ==========================================================

    if (accepted.ownerLocation != null) {
      final GeoPoint location = accepted.ownerLocation!;

      _ownerPosition = Position(
        longitude: location.longitude,
        latitude: location.latitude,
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

    // ==========================================================
    // UPDATE LOCAL STATE
    // ==========================================================

    if (!mounted) {
      return;
    }

    _updateState(() {
      // Radar/search is finished.
      _searching = false;

      // This is NOT a failed/finished search.
      _searchFinished = false;

      _recovering = false;
      _checkingAddress = false;
      _stopping = false;

      // Accepted walker is now active.
      _active = true;
    });

    // ==========================================================
    // ACTIVE STATE
    // ==========================================================

    _setActive(true);

    // ==========================================================
    // CALLBACKS
    //
    // Parent screen MUST use onAccepted to open the
    // accepted-walker / active-walk screen.
    // ==========================================================

    widget.onWalkerFound?.call();

    widget.onAccepted?.call(accepted);

    // ==========================================================
    // DEBUG
    // ==========================================================

    debugPrint(
      '==================================================',
    );
    debugPrint(
      'INSTA WALK ACCEPTED',
    );
    debugPrint(
      'requestId=$requestId',
    );
    debugPrint(
      'walkerId=$walkerId',
    );
    debugPrint(
      'walkerUid=$walkerUid',
    );
    debugPrint(
      'walkerName=$walkerName',
    );
    debugPrint(
      'Radar stopped: true',
    );
    debugPrint(
      'Search stopped: true',
    );
    debugPrint(
      'Owner should remain in flow: true',
    );
    debugPrint(
      '==================================================',
    );
  }
}
