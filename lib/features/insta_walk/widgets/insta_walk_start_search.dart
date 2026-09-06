part of '../controllers/insta_walk_container.dart';

// ============================================================
// START SEARCH
// ============================================================

extension _StartSearchRole on _InstaWalkContainerState {
  Future<void> _startSearch({
    required String ownerId,
    required String ownerName,
    required String address,
    required GeoPoint ownerLocation,
    required String dogName,
    required String dogBreed,
  }) async {
    // ==========================================================
    // SEARCH FLOW GUARD
    // ==========================================================
    //
    // If the current request has already been accepted, never
    // start another search or restart the search animation.
    //
    if (!mounted || _acceptHandled) {
      debugPrint(
        '🛑 Insta Walk start ignored: accept already handled.',
      );
      return;
    }

    try {
      debugPrint(
        '🔎 Insta Walk startSearch() called.',
      );

      final InstaWalkSearchResult result =
          await _service.startSearch(
        ownerId: ownerId,
        ownerName: ownerName,
        address: address,
        ownerLocation: ownerLocation,
        dogName: dogName,
        dogBreed: dogBreed,
      );

      if (!mounted) {
        return;
      }

      // ========================================================
      // ACCEPT GUARD AFTER ASYNC OPERATION
      // ========================================================
      //
      // Acceptance may have been detected while startSearch()
      // was waiting for Firestore.
      //
      // Do not overwrite the accepted state.
      //
      if (_acceptHandled) {
        debugPrint(
          '🛑 Insta Walk start aborted: request accepted '
          'while startSearch() was awaiting.',
        );

        _stopSearchAnimation();
        _service.stopListening();

        return;
      }

      // ========================================================
      // INVALID SEARCH RESULT
      // ========================================================

      if (!result.success ||
          result.requestId == null ||
          result.requestId!.trim().isEmpty) {
        _requestId = null;

        _stopSearchAnimation();
        _service.stopListening();

        _updateState(() {
          _checkingAddress = false;
          _searching = false;
          _searchFinished = false;
          _stopping = false;
        });

        _setActive(false);

        _message(
          result.message ?? 'Unable to start search.',
        );

        return;
      }

      final String requestId =
          result.requestId!.trim();

      // ========================================================
      // SECOND ACCEPT GUARD
      // ========================================================
      //
      // Keep this immediately before changing the UI to the
      // SEARCHING state.
      //
      if (_acceptHandled) {
        debugPrint(
          '🛑 Insta Walk search state NOT started: '
          'accept already handled.',
        );

        _stopSearchAnimation();
        _service.stopListening();

        return;
      }

      _requestId = requestId;

      _updateState(() {
        _checkingAddress = false;
        _searching = true;
        _searchFinished = false;
        _stopping = false;
      });

      // ========================================================
      // ACTIVE SEARCH
      // ========================================================

      _setActive(true);

      // Small animated search icon.
      // NO GPS.
      // NO RADAR.
      _startSearchAnimation();

      debugPrint(
        '🔵 Insta Walk search active: $requestId',
      );

      // ========================================================
      // FIRESTORE REALTIME LISTENER
      // ========================================================

      _service.listenAndStore(
        requestId,
        onData: (
          InstaWalkRequestState state,
        ) {
          if (!mounted) {
            return;
          }

          // ======================================================
          // ACCEPTED
          // ======================================================
          //
          // Walker acceptance is handled by the existing
          // _walkerAccepted() -> _handleAccepted() flow.
          //
          // Do not duplicate navigation/state logic here.
          // ======================================================

          if (state.isAccepted) {
            final Map<String, dynamic> data =
                state.data ?? <String, dynamic>{};

            final InstaWalkAcceptedData accepted =
                InstaWalkAcceptedData.fromMap(data);

            _walkerAccepted(accepted);
            return;
          }

          // ======================================================
          // CANCELLED
          // ======================================================

          if (state.isCancelled) {
            _finishSearch(
              message: 'Walk request was cancelled.',
            );
            return;
          }

          // ======================================================
          // EXPIRED
          // ======================================================

          if (state.isExpired) {
            _finishSearch(
              message: 'Walk request expired.',
            );
            return;
          }

          // ======================================================
          // SEARCHING
          // ======================================================
          //
          // Nothing to do.
          // Firestore listener keeps the search alive.
          // ======================================================
        },
        onError: (Object error) {
          debugPrint(
            'Insta Walk listener error: $error',
          );
        },
      );
    } catch (e) {
      debugPrint(
        'Insta Walk search error: $e',
      );

      if (!mounted) {
        return;
      }

      // ========================================================
      // ACCEPT GUARD
      // ========================================================
      //
      // If acceptance was already handled, don't overwrite
      // the accepted flow with an error state.
      //
      if (_acceptHandled) {
        debugPrint(
          '🛑 Insta Walk error ignored: '
          'accept already handled.',
        );

        _stopSearchAnimation();
        _service.stopListening();

        return;
      }

      _stopSearchAnimation();
      _service.stopListening();

      _requestId = null;

      _updateState(() {
        _checkingAddress = false;
        _searching = false;
        _searchFinished = false;
        _stopping = false;
      });

      _setActive(false);

      _message(
        'Unable to start Insta Walk.',
      );
    }
  }
}
