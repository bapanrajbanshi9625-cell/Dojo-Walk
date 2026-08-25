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
    // STOP RADAR
    // ==========================================================

    _stopRadar();

    // ==========================================================
    // RESTORE OWNER LOCATION
    // ==========================================================

    if (accepted.ownerLocation != null) {
      final GeoPoint location =
          accepted.ownerLocation!;

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
      _recovering = false;
      _checkingAddress = false;

      // Search is finished because walker accepted.
      _searching = false;

      // Do not show "search finished" state.
      // Instead the accepted-walker UI takes over.
      _searchFinished = false;

      _stopping = false;
    });

    // ==========================================================
    // SEARCH IS NO LONGER ACTIVE
    //
    // The request itself is now in:
    //
    // status = accepted
    //
    // ==========================================================

    _setActive(true);

    // ==========================================================
    // CALLBACK
    // ==========================================================

    widget.onWalkerFound?.call();

    widget.onAccepted?.call(
      accepted,
    );

    // ==========================================================
    // DEBUG
    // ==========================================================

    debugPrint(
      'Insta Walk accepted: '
      'requestId=$requestId, '
      'walkerId=$walkerId, '
      'walkerUid=$walkerUid, '
      'walkerName=$walkerName',
    );
  }
}
