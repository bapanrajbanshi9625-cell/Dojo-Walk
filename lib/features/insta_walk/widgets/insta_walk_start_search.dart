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
    _stopTimer();

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
      //
      // IMPORTANT:
      // expiresAt is NOT required anymore.
      //
      // Insta Walk has NO automatic expiry.
      // ========================================================

      if (!result.success ||
          result.requestId == null ||
          result.requestId!.trim().isEmpty) {
        _requestId = null;

        _stopRadar();
        _stopTimer();

        _updateState(() {
          _checkingAddress = false;
          _searching = false;
          _searchFinished = false;
          _secondsLeft = 0;
          _stopping = false;
        });

        _setActive(false);

        _message(
          result.message ??
              'Unable to start search.',
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
      // IMPORTANT
      //
      // Insta Walk has NO expiry.
      // Do NOT calculate remaining time.
      // Do NOT call expireRequest().
      // Do NOT start countdown timer.
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
      // LISTEN FOR WALKER ACCEPTANCE
      // ========================================================

      try {
        await _service.listenForRequest(
          requestId: requestId,

          // ----------------------------------------------------
          // WALKER ACCEPTED
          // ----------------------------------------------------

          onAccepted: _walkerAccepted,

          // ----------------------------------------------------
          // OLD EXPIRED STATE
          //
          // New Insta Walk requests never expire automatically.
          // This is kept only for old/manual Firestore records.
          // ----------------------------------------------------

          onExpired: () {
            _finishSearch(
              message:
                  'Walk request expired.',
            );
          },

          // ----------------------------------------------------
          // CANCELLED
          // ----------------------------------------------------

          onCancelled: () {
            _finishSearch(
              message:
                  'Walk request was cancelled.',
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

        // Don't immediately kill an already-created request.
        //
        // Firestore listener errors can be transient.
        // The request itself is already active.
      }

      // ========================================================
      // IMPORTANT
      //
      // NO _startTimer()
      //
      // Insta Walk search is indefinite until:
      //
      // 1. Walker accepts
      // 2. Owner cancels
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

      _stopTimer();
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
