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
    // DO NOT:
    //   Navigator.pop()
    //   Navigator.pushReplacement()
    //   close the container
    //
    // Owner stays inside the current flow.
    // Parent will open WalkerAcceptScreen through onAccepted.
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
      // SEARCH IS OVER
      // --------------------------------------------------------

      _searching = false;

      // --------------------------------------------------------
      // THIS IS NOT A FAILED SEARCH
      // --------------------------------------------------------

      _searchFinished = false;

      // --------------------------------------------------------
      // CLEAR TEMPORARY SEARCH STATES
      // --------------------------------------------------------

      _recovering = false;
      _checkingAddress = false;
      _stopping = false;

      // --------------------------------------------------------
      // WALKER ACCEPTED
      // --------------------------------------------------------

      _active = true;
    });

    // ==========================================================
    // MARK ACTIVE LOCALLY
    // ==========================================================

    _setActive(true);

    // ==========================================================
    // IMPORTANT CALLBACK
    //
    // Parent should now open:
    //
    // WalkerAcceptScreen
    //
    // using the SAME walk_request document.
    //
    // requestId = walk_request/{requestId}
    //
    // There is NO active_walks collection.
    // ==========================================================

    widget.onAccepted?.call(
      accepted,
    );

    // ==========================================================
    // OPTIONAL EXISTING CALLBACK
    //
    // Keep this only if existing parent logic depends on it.
    // It must NOT navigate/pop the current screen.
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
      'Owner remains in flow=true',
    );

    debugPrint(
      'WalkerAcceptScreen should open=true',
    );

    debugPrint(
      '==================================================',
    );
  }
}
