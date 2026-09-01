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

    final String walkerId =
        accepted.walkerId.trim();

    final String walkerUid =
        accepted.walkerUid.trim();

    final String walkerName =
        accepted.walkerName.trim();

    if (walkerId.isEmpty &&
        walkerUid.isEmpty) {
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
    // Do NOT pop the Insta Walk container.
    //
    // Do NOT use:
    // Navigator.pop()
    // Navigator.pushReplacement()
    //
    // The parent handles navigation through onAccepted.
    // ==========================================================

    _stopRadar();

    // ==========================================================
    // RESTORE OWNER SAVED LOCATION
    // ==========================================================

    final GeoPoint? acceptedOwnerLocation =
        accepted.ownerLocation;

    if (acceptedOwnerLocation != null) {
      final GeoPoint location =
          acceptedOwnerLocation;

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
      // --------------------------------------------------------
      // SEARCH IS FINISHED
      // --------------------------------------------------------

      _searching = false;

      // --------------------------------------------------------
      // NOT A FAILED SEARCH
      // --------------------------------------------------------

      _searchFinished = false;

      // --------------------------------------------------------
      // CLEAR TEMPORARY STATES
      // --------------------------------------------------------

      _recovering = false;
      _checkingAddress = false;
      _stopping = false;
    });

    // ==========================================================
    // MARK ACCEPTED / ACTIVE
    //
    // IMPORTANT:
    // _active does NOT exist in the current state.
    //
    // _setActive(true) is the correct method because it
    // updates the existing _activeReported state and callback.
    // ==========================================================

    _setActive(true);

    // ==========================================================
    // ACCEPTED CALLBACK
    //
    // Parent should open WalkerAcceptScreen using:
    //
    // walk_request/{requestId}
    //
    // The same request continues:
    //
    // accepted → reached
    //
    // No active_walks collection is created here.
    // ==========================================================

    widget.onAccepted?.call(
      accepted,
    );

    // ==========================================================
    // EXISTING WALKER FOUND CALLBACK
    //
    // Keep this for existing parent logic.
    //
    // This callback must NOT pop this container.
    // ==========================================================

    widget.onWalkerFound?.call();

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
      'request collection=walk_request',
    );

    debugPrint(
      'status=accepted',
    );

    debugPrint(
      'Radar stopped=true',
    );

    debugPrint(
      'Search stopped=true',
    );

    debugPrint(
      'InstaWalkContainer closed=false',
    );

    debugPrint(
      'WalkerAcceptScreen callback=true',
    );

    debugPrint(
      'Owner remains in flow=true',
    );

    debugPrint(
      'Live Walk session created=false',
    );

    debugPrint(
      '==================================================',
    );
  }
}
