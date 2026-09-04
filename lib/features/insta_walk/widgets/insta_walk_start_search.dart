part of '../controllers/insta_walk_container.dart';

// ============================================================
// START SEARCH
// ============================================================

extension _StartSearchRole on _InstaWalkContainerState {
  Future<void> _startSearch({
    required String ownerId,
    required String ownerName,
    required String address,
    required Position position,
    required String dogName,
    required String dogBreed,
  }) async {
    // ==========================================================
    // SEARCH FLOW GUARD
    // ==========================================================
    //
    // Existing Accept flow is responsible for detecting ACCEPTED.
    // If it has already handled the accepted request, never start
    // a new Insta Walk search or restart the radar.
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
        ownerLocation: GeoPoint(
          position.latitude,
          position.longitude,
        ),
        dogName: dogName,
        dogBreed: dogBreed,
      );

      if (!mounted) {
        return;
      }

      // ========================================================
      // IMPORTANT:
      // During the await above, the existing Accept flow may
      // have detected ACCEPTED and handled the request.
      //
      // NEVER continue starting Insta Walk after that happens.
      // ========================================================

      if (_acceptHandled) {
        debugPrint(
          '🛑 Insta Walk start aborted: request accepted '
          'while startSearch() was awaiting.',
        );

        _stopRadar();
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

        _stopRadar();
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
      // Keep this immediately before changing the UI into the
      // searching state.
      // ========================================================

      if (_acceptHandled) {
        debugPrint(
          '🛑 Insta Walk search state NOT started: '
          'accept already handled.',
        );

        _stopRadar();
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

      // _startRadar() itself also checks _searching.
      _startRadar();

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
          // Existing Accept flow remains responsible for handling
          // the acceptance. We do not duplicate that logic here.
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
          // Nothing to do. Search continues.
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
      // If Accept flow handled the request while the async
      // operation was running, don't overwrite its state.
      // ========================================================

      if (_acceptHandled) {
        debugPrint(
          '🛑 Insta Walk error ignored: '
          'accept already handled.',
        );

        _stopRadar();
        _service.stopListening();

        return;
      }

      _stopRadar();
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
