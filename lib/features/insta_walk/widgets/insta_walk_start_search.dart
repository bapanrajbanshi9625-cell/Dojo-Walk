part of 'insta_walk_container.dart';

// ============================================================
// START SEARCH
// ============================================================

extension _StartSearchRole on _InstaWalkContainerState {
  Future<void> _startSearch({
    required String ownerId,
    required String ownerName,
    required String address,
    required Position position,
  }) async {
    try {
      // ========================================================
      // CREATE INSTA WALK REQUEST
      // ========================================================

      final result = await _service.startSearch(
        ownerId: ownerId,
        ownerName: ownerName,
        address: address,
        ownerLocation: GeoPoint(
          position.latitude,
          position.longitude,
        ),
      );

      if (!mounted) {
        return;
      }

      // ========================================================
      // REQUEST FAILED
      // ========================================================

      if (!result.success ||
          result.requestId == null ||
          result.requestId!.trim().isEmpty) {
        _requestId = null;

        _stopRadar();

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

      // ========================================================
      // REQUEST CREATED
      // ========================================================

      final String requestId =
          result.requestId!.trim();

      _requestId = requestId;

      // ========================================================
      // ACTIVE SEARCH
      //
      // NO EXPIRY
      // NO COUNTDOWN
      // NO TIMER
      // ========================================================

      _updateState(() {
        _checkingAddress = false;
        _searching = true;
        _searchFinished = false;
        _stopping = false;
      });

      _setActive(true);

      // ========================================================
      // START RADAR
      // ========================================================

      _startRadar();

      // ========================================================
      // REALTIME FIRESTORE LISTENER
      // ========================================================

      try {
        _service
            .listenForRequest(requestId)
            .listen(
          (
            InstaWalkRequestState state,
          ) {
            if (!mounted) {
              return;
            }

            // ==================================================
            // WALKER ACCEPTED
            // ==================================================

            if (state.isAccepted) {
              final Map<String, dynamic> data =
                  state.data ?? <String, dynamic>{};

              final InstaWalkAcceptedData accepted =
                  InstaWalkAcceptedData.fromMap(
                data,
              );

              _walkerAccepted(accepted);
              return;
            }

            // ==================================================
            // CANCELLED
            // ==================================================

            if (state.isCancelled) {
              _finishSearch(
                message:
                    'Walk request was cancelled.',
              );
              return;
            }

            // ==================================================
            // EXPIRED
            //
            // Only responds to an actual expired Firestore state.
            // ==================================================

            if (state.isExpired) {
              _finishSearch(
                message:
                    'Walk request expired.',
              );
              return;
            }

            // ==================================================
            // SEARCHING
            //
            // Keep searching.
            // ==================================================
          },
          onError: (
            Object error,
          ) {
            debugPrint(
              'Insta Walk listener error: $error',
            );
          },
        );
      } catch (e) {
        debugPrint(
          'Insta Walk listener setup error: $e',
        );

        // Request is already in Firestore.
        // Do not cancel it because listener setup failed.
      }

      // ========================================================
      // IMPORTANT
      //
      // NO TIMER
      // NO AUTOMATIC EXPIRY
      //
      // Search ends only when:
      //
      // 1. Walker accepts
      // 2. Owner stops search
      // 3. Firestore says cancelled/expired
      // ========================================================
    } catch (e) {
      debugPrint(
        'Insta Walk search error: $e',
      );

      if (!mounted) {
        return;
      }

      _stopRadar();

      _requestId = null;

      _updateState(() {
        _checkingAddress = false;
        _searching = false;
        _searchFinished = false;
        _stopping = false;
      });

      _setActive(false);

      _message(
        'Unable to start Insta Walk: $e',
      );
    }
  }
}
