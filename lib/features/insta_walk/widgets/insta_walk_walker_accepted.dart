part of 'insta_walk_container.dart';

// ============================================================
// WALKER ACCEPTED
// ============================================================

extension _WalkerAcceptedRole on _InstaWalkContainerState {
  void _walkerAccepted(
    InstaWalkAcceptedData data,
  ) {
    _stopTimer();
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

    _setActive(true);

    widget.onWalkerFound?.call();

    final String name =
        data.walkerName.trim();

    _message(
      name.isEmpty
          ? 'Walker accepted your request.'
          : '$name accepted your request.',
    );
  }
}
