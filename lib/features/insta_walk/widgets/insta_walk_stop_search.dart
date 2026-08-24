part of 'insta_walk_container.dart';

// ============================================================
// STOP SEARCH
// ============================================================

extension _StopSearchRole on _InstaWalkContainerState {
  Future<void> _stopSearch() async {
    if (_stopping) {
      return;
    }

    final String? requestId =
        _requestId;

    // ----------------------------------------------------------
    // NO REQUEST
    // ----------------------------------------------------------

    if (requestId == null ||
        requestId.trim().isEmpty) {
      _resetSearchState();
      return;
    }

    // ----------------------------------------------------------
    // ONLY ACTIVE SEARCH
    // ----------------------------------------------------------

    if (!_searching) {
      return;
    }

    if (!mounted) {
      return;
    }

    _updateState(() {
      _stopping = true;
    });

    try {
      // --------------------------------------------------------
      // CANCEL FIRESTORE REQUEST
      // --------------------------------------------------------

      final bool cancelled =
          await _service.cancelSearch(
        requestId: requestId,
      );

      if (!mounted) {
        return;
      }

      // --------------------------------------------------------
      // SUCCESSFULLY CANCELLED
      // --------------------------------------------------------

      if (cancelled) {
        _stopRadar();

        _requestId = null;
        _ownerPosition = null;

        _updateState(() {
          _searching = false;
          _searchFinished = false;
          _checkingAddress = false;
          _recovering = false;
          _stopping = false;
        });

        _setActive(false);

        _message(
          'Insta Walk search stopped.',
        );

        return;
      }

      // --------------------------------------------------------
      // CANCEL FAILED
      // READ FIRESTORE AGAIN
      // --------------------------------------------------------

      final InstaWalkRequestState state =
          await _service.getRequestState(
        requestId,
      );

      if (!mounted) {
        return;
      }

      // --------------------------------------------------------
      // WALKER ACCEPTED DURING STOP
      // --------------------------------------------------------

      if (state.isAccepted) {
        _updateState(() {
          _stopping = false;
        });

        _walkerAccepted(
          InstaWalkAcceptedData.fromMap(
            state.data ??
                <String, dynamic>{},
          ),
        );

        _message(
          'Walker already accepted this request.',
        );

        return;
      }

      // --------------------------------------------------------
      // REQUEST ALREADY ENDED
      // --------------------------------------------------------

      if (state.isExpired ||
          state.isCancelled ||
          state.status ==
              InstaWalkRequestStatus.notFound) {
        _stopTimer();
        _stopRadar();

        _requestId = null;
        _ownerPosition = null;

        _updateState(() {
          _searching = false;
          _searchFinished = false;
          _checkingAddress = false;
          _recovering = false;
          _stopping = false;
        });

        _setActive(false);

        return;
      }

      // --------------------------------------------------------
      // STILL SEARCHING
      // --------------------------------------------------------

      _updateState(() {
        _stopping = false;
      });

      _message(
        'Unable to stop search. Please try again.',
      );
    } catch (e) {
      debugPrint(
        'Insta Walk stop search error: $e',
      );

      if (!mounted) {
        return;
      }

      _updateState(() {
        _stopping = false;
      });

      _message(
        'Unable to stop search. Please try again.',
      );
    }
  }
}
