part of 'insta_walk_container.dart';

// ============================================================
// WALKER ACCEPTED
// ============================================================

extension _WalkerAcceptedRole on _InstaWalkContainerState {
  Future<void> _walkerAccepted(
    InstaWalkAcceptedData accepted,
  ) async {
    debugPrint('');
    debugPrint('==============================================');
    debugPrint('🔥 _WALKER ACCEPTED METHOD CALLED');
    debugPrint('==============================================');

    if (!mounted) {
      debugPrint('❌ Widget is not mounted.');
      return;
    }

    // ==========================================================
    // REQUEST ID
    // ==========================================================

    final String requestId =
        accepted.requestId.trim().isNotEmpty
            ? accepted.requestId.trim()
            : (_requestId ?? '').trim();

    debugPrint('requestId = $requestId');

    if (requestId.isEmpty) {
      debugPrint('❌ requestId is empty.');
      return;
    }

    // ==========================================================
    // WALKER VALIDATION
    // ==========================================================

    final String walkerId =
        accepted.walkerId.trim();

    final String walkerUid =
        accepted.walkerUid.trim();

    debugPrint('walkerId = $walkerId');
    debugPrint('walkerUid = $walkerUid');

    if (walkerId.isEmpty &&
        walkerUid.isEmpty) {
      debugPrint('❌ Walker identity missing.');
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
    // UPDATE UI
    // ==========================================================

    _updateState(() {
      _searching = false;
      _searchFinished = false;
      _recovering = false;
      _checkingAddress = false;
      _stopping = false;
    });

    _setActive(true);

    // ==========================================================
    // FIRE CALLBACK
    //
    // Navigation will be handled by InstaWalkScreen.
    // ==========================================================

    debugPrint('🚀 CALLING onAccepted CALLBACK');

    widget.onAccepted?.call(
      InstaWalkAcceptedData(
        requestId: requestId,
        ownerId: accepted.ownerId,
        ownerName: accepted.ownerName,
        address: accepted.address,
        dogName: accepted.dogName,
        dogBreed: accepted.dogBreed,
        walkerId: accepted.walkerId,
        walkerUid: accepted.walkerUid,
        walkerName: accepted.walkerName,
        walkerPhone: accepted.walkerPhone,
        ownerLocation: accepted.ownerLocation,
        acceptedAt: accepted.acceptedAt,
      ),
    );

    debugPrint('🚀 onAccepted CALLBACK FINISHED');

    debugPrint('==============================================');
  }
}
