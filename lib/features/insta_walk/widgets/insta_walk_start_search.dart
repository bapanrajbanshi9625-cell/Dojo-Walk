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

      final InstaWalkSearchResult result =
          await _service.startSearch(
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
          _secondsLeft = 0;
          _stopping = false;
        });

        _setActive(false);

        _message(
          result.message ?? 'Unable to start search.',
        );

        return;
      }

      // ========================================================
      // REQUEST CREATED SUCCESSFULLY
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
        _secondsLeft = 0;
        _stopping = false;
      });

      // ========================================================
      // REPORT ACTIVE
      // ========================================================

      _setActive(true);

      // ========================================================
      // START RADAR
      // ========================================================

      _startRadar();

      // ========================================================
      // LISTEN FOR WALKER RESPONSE
      // ========================================================

      try {
        await _service.listenForRequest(
          requestId: requestId,

          // ----------------------------------------------------
          // WALKER ACCEPTED
          // ----------------------------------------------------

          onAccepted: _walkerAccepted,

          // ----------------------------------------------------
          // OLD / MANUAL EXPIRED STATE
          //
          // New Insta Walk requests do not expire automatically.
          // This callback is kept for compatibility with older
          // Firestore documents or manually expired requests.
          // ----------------------------------------------------

          onExpired: () {
            _finishSearch(
              message: 'Walk request expired.',
            );
          },

          // ----------------------------------------------------
          // CANCELLED
          // ----------------------------------------------------

          onCancelled: () {
            _finishSearch(
              message: 'Walk request was cancelled.',
            );
          },

          // ----------------------------------------------------
          // LISTENER ERROR
          // ----------------------------------------------------

          onError: (Object error) {
            debugPrint(
              'Insta Walk listener error: $error',
            );
          },
        );
      } catch (e) {
        debugPrint(
          'Insta Walk listener setup error: $e',
        );

        // The Firestore request has already been created.
        // Do not immediately cancel it because of a listener
        // setup/transient error.
      }

      // ========================================================
      // IMPORTANT
      //
      // NO TIMER
      // NO AUTOMATIC EXPIRY
      //
      // Search remains active until:
      //
      // 1. Walker accepts
      // 2. Owner stops search
      // 3. Request is cancelled
      //
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
        _secondsLeft = 0;
        _stopping = false;
      });

      _setActive(false);

      // ========================================================
      // SHOW REAL ERROR
      // ========================================================

      _message(
        'Unable to start Insta Walk: $e',
      );
    }
  }
}
