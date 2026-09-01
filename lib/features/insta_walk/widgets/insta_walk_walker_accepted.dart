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
    // ==========================================================

    _stopRadar();

    // ==========================================================
    // RESTORE OWNER LOCATION
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
      _searching = false;
      _searchFinished = false;
      _recovering = false;
      _checkingAddress = false;
      _stopping = false;
    });

    // ==========================================================
    // MARK ACTIVE
    // ==========================================================

    _setActive(true);

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
      'Radar stopped=true',
    );

    debugPrint(
      'Search stopped=true',
    );

    debugPrint(
      'Calling parent onAccepted=true',
    );

    // ==========================================================
    // IMPORTANT
    //
    // DO NOT NAVIGATE HERE.
    //
    // Parent owns navigation.
    //
    // ACCEPTED
    //   ↓
    // onAccepted
    //   ↓
    // Parent Navigator
    //   ↓
    // WalkerAcceptScreen
    //
    // SAME REQUEST:
    //
    // walk_request/{requestId}
    //
    // NO active_walks
    // ==========================================================

    widget.onAccepted?.call(accepted);

    // ==========================================================
    // EXISTING CALLBACK
    // ==========================================================

    widget.onWalkerFound?.call();

    debugPrint(
      'Parent navigation callback completed.',
    );

    debugPrint(
      '==================================================',
    );
  }
}
