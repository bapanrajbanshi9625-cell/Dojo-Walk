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

    // ==========================================================
    // CLEAN REQUIRED VALUES
    // ==========================================================

    final String cleanOwnerId =
        ownerId.trim();

    final String cleanOwnerName =
        ownerName.trim().isEmpty
            ? 'Dog Owner'
            : ownerName.trim();

    final String cleanAddress =
        address.trim();

    // ==========================================================
    // REQUIRED DATA CHECK
    // ==========================================================

    if (cleanOwnerId.isEmpty) {
      _message(
        'Business ID / Owner ID is missing.',
      );
      return;
    }

    if (cleanAddress.isEmpty) {
      _message(
        'Owner address is missing.',
      );
      return;
    }

    try {
      // ========================================================
      // FIRESTORE REQUEST
      //
      // This calls InstaWalkSearchService.startSearch()
      //
      // Firebase receives:
      //
      // ownerId
      // ownerName
      // address
      // ownerLocation
      // ========================================================

      final InstaWalkSearchResult result =
          await _service.startSearch(
        ownerId: cleanOwnerId,
        ownerName: cleanOwnerName,
        address: cleanAddress,
        ownerLocation: GeoPoint(
          position.latitude,
          position.longitude,
        ),
      );

      if (!mounted) {
        return;
      }

      // ========================================================
      // FIRESTORE WRITE FAILED
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
              'Unable to create Insta Walk request.',
        );

        debugPrint(
          'Insta Walk request failed: '
          '${result.errorCode ?? 'unknown'}',
        );

        return;
      }

      // ========================================================
      // FIRESTORE REQUEST CREATED
      // ========================================================

      final String requestId =
          result.requestId!.trim();

      _requestId = requestId;

      debugPrint(
        'Insta Walk request created successfully: '
        '$requestId',
      );

      // ========================================================
      // SEARCH ACTIVE
      // ========================================================

      _updateState(() {
        _checkingAddress = false;
        _searching = true;
        _searchFinished = false;
        _secondsLeft = 0;
        _stopping = false;
      });

      _setActive(true);

      // ========================================================
      // START RADAR
      // ========================================================

      _startRadar();

      // ========================================================
      // LISTEN FOR WALKER
      // ========================================================

      try {
        await _service.listenForRequest(
          requestId: requestId,

          // ----------------------------------------------------
          // WALKER ACCEPTED
          // ----------------------------------------------------

          onAccepted: (
            InstaWalkAcceptedData data,
          ) {
            _walkerAccepted(data);
          },

          // ----------------------------------------------------
          // OLD / MANUAL EXPIRED REQUEST
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
          // FIRESTORE LISTENER ERROR
          // ----------------------------------------------------

          onError: (
            Object error,
          ) {
            debugPrint(
              'Insta Walk Firestore listener error: '
              '$error',
            );

            // IMPORTANT:
            // Request ko searching state se remove
            // nahi karna.
            //
            // Firestore document source of truth hai.
          },
        );
      } catch (e) {
        debugPrint(
          'Insta Walk listener setup error: $e',
        );

        // Request already Firebase me create ho chuka hai.
        // Isliye search ko automatically cancel nahi karna.
      }

      // ========================================================
      // NO TIMER
      // ========================================================
      //
      // Insta Walk permanently searching rahega jab tak:
      //
      // 1. Walker accepts
      // 2. Owner stops search
      // 3. Request manually cancelled
      //
      // ========================================================
    } on FirebaseException catch (e) {
      debugPrint(
        'Insta Walk FirebaseException: '
        '${e.code} - ${e.message}',
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
      // REAL FIREBASE ERROR
      // ========================================================

      String message;

      switch (e.code) {
        case 'permission-denied':
          message =
              'Firestore permission denied. '
              'Request was not allowed.';
          break;

        case 'unauthenticated':
          message =
              'Firebase login expired. Please login again.';
          break;

        case 'unavailable':
          message =
              'Firebase is temporarily unavailable. '
              'Please try again.';
          break;

        case 'failed-precondition':
          message =
              'Firestore requires an index or configuration fix.';
          break;

        default:
          message =
              'Firebase error: ${e.code}';
      }

      _message(message);
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

      _message(
        'Unable to start Insta Walk.',
      );
    }
  }
}
