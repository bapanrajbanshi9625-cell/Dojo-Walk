part of 'insta_walk_container.dart';

// ============================================================
// WALKER ACCEPTED
// ============================================================

extension _WalkerAcceptedRole on _InstaWalkContainerState {
  void _walkerAccepted(
    InstaWalkAcceptedData data,
  ) {
    _stopRadar();

    final String acceptedRequestId =
        data.requestId.trim();

    if (acceptedRequestId.isNotEmpty) {
      _requestId = acceptedRequestId;
    }

    if (!mounted) {
      return;
    }

    _updateState(() {
      _searching = false;
      _searchFinished = false;
      _checkingAddress = false;
      _stopping = false;
    });

    // ========================================================
    // ACTIVE WALK START
    // ========================================================

    _setActive(true);

    // ========================================================
    // OWNER SCREEN NAVIGATION CALLBACK
    // ========================================================

    widget.onAccepted?.call(data);

    // ========================================================
    // OLD CALLBACK SUPPORT
    // ========================================================

    widget.onWalkerFound?.call();

    // ========================================================
    // MESSAGE
    // ========================================================

    final String name =
        data.walkerName.trim();

    _message(
      name.isEmpty
          ? 'Walker accepted your request.'
          : '$name accepted your request.',
    );
  }
}
