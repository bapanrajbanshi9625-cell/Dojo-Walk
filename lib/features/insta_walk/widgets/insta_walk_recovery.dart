part of 'insta_walk_container.dart';

// ============================================================
// SEARCH RECOVERY
//
// FIRESTORE = SOURCE OF TRUTH
//
// SEARCHING REQUEST:
//   - No expiry
//   - No countdown
//   - No automatic stop
//   - Survives screen navigation
//   - Recovers after app reopen
// ============================================================

extension _RecoveryRole on _InstaWalkContainerState {
  Future<void> _recoverSearch() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) {
        return;
      }

      _updateState(() {
        _recovering = false;
        _searching = false;
        _searchFinished = false;
        _checkingAddress = false;
        _stopping = false;
      });

      _setActive(false);
      return;
    }

    try {
      // ========================================================
      // FIND OWNER PROFILE
      // ========================================================

      final DocumentSnapshot<Map<String, dynamic>>? ownerDoc =
          await _service.findOwnerProfile();

      if (!mounted) {
        return;
      }

      if (ownerDoc == null) {
        _resetSearchState();
        return;
      }

      // ========================================================
      // OWNER DATA
      // ========================================================

      final Map<String, dynamic> ownerData =
          ownerDoc.data() ?? <String, dynamic>{};

      _petName = _readFirstString(
        ownerData,
        const [
          'petName',
          'Pet Name',
          'dogName',
          'Dog Name',
        ],
      );

      if (_petName.isEmpty) {
        _petName = 'Your Pet';
      }

      // ========================================================
      // OWNER ID
      // ========================================================

      String ownerId = _readFirstString(
        ownerData,
        const [
          'businessId',
          'Business ID',
          'ownerId',
          'Owner ID',
        ],
      );

      if (ownerId.isEmpty) {
        ownerId = ownerDoc.id.trim();
      }

      if (ownerId.isEmpty) {
        _resetSearchState();
        return;
      }

      // ========================================================
      // FIND ACTIVE REQUEST
      // ========================================================

      final InstaWalkRequestState? active =
          await _service.findActiveRequest(
        ownerId: ownerId,
      );

      if (!mounted) {
        return;
      }

      if (active == null) {
        _resetSearchState();
        return;
      }

      // ========================================================
      // SEARCHING
      // ========================================================

      if (active.isSearching) {
        await _recoverSearchingRequest(active);
        return;
      }

      // ========================================================
      // ACCEPTED
      // ========================================================

      if (active.isAccepted) {
        await _recoverAcceptedRequest(active);
        return;
      }

      // ========================================================
      // CANCELLED / EXPIRED / UNKNOWN
      // ========================================================

      _resetSearchState();
    } catch (e) {
      debugPrint(
        'Insta Walk recovery error: $e',
      );

      if (!mounted) {
        return;
      }

      _resetSearchState();
    }
  }

  // ============================================================
  // RECOVER SEARCHING REQUEST
  // ============================================================

  Future<void> _recoverSearchingRequest(
    InstaWalkRequestState active,
  ) async {
    final String requestId = active.requestId.trim();

    if (requestId.isEmpty) {
      _resetSearchState();
      return;
    }

    // ==========================================================
    // RESTORE REQUEST ID
    // ==========================================================

    _requestId = requestId;

    // ==========================================================
    // RESTORE OWNER LOCATION
    // ==========================================================

    _ownerPosition = _readOwnerPosition(
      active.data,
    );

    // ==========================================================
    // RESTORE SEARCH UI
    // ==========================================================

    if (!mounted) {
      return;
    }

    _updateState(() {
      _recovering = false;
      _searching = true;
      _searchFinished = false;
      _checkingAddress = false;
      _stopping = false;
    });

    _setActive(true);

    // ==========================================================
    // START RADAR
    // ==========================================================

    _startRadar();

    // ==========================================================
    // REALTIME FIRESTORE LISTENER
    // ==========================================================

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

          // ====================================================
          // WALKER ACCEPTED
          // ====================================================

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

          // ====================================================
          // CANCELLED
          // ====================================================

          if (state.isCancelled) {
            _finishSearch(
              message: 'Walk request was cancelled.',
            );
            return;
          }

          // ====================================================
          // EXPIRED
          //
          // Only handles an actual Firestore expired state.
          // No automatic expiry is performed here.
          // ====================================================

          if (state.isExpired) {
            _finishSearch(
              message:
                  'This Insta Walk request is no longer active.',
            );
            return;
          }

          // ====================================================
          // SEARCHING
          //
          // Do nothing.
          //
          // Firestore status remains the source of truth.
          // ====================================================
        },
        onError: (
          Object error,
        ) {
          debugPrint(
            'Insta Walk Firestore listener error: $error',
          );
        },
      );
    } catch (e) {
      debugPrint(
        'Insta Walk listener setup error: $e',
      );
    }

    // ==========================================================
    // IMPORTANT
    //
    // NO TIMER
    // NO COUNTDOWN
    // NO AUTOMATIC EXPIRY
    // ==========================================================
  }

  // ============================================================
  // RECOVER ACCEPTED REQUEST
  // ============================================================

  Future<void> _recoverAcceptedRequest(
    InstaWalkRequestState active,
  ) async {
    final Map<String, dynamic> data =
        active.data ?? <String, dynamic>{};

    final InstaWalkAcceptedData accepted =
        InstaWalkAcceptedData.fromMap(
      data,
    );

    final String recoveredId =
        accepted.requestId.trim();

    _requestId = recoveredId.isEmpty
        ? active.requestId
        : recoveredId;

    // ==========================================================
    // STOP RADAR
    // ==========================================================

    _stopRadar();

    if (!mounted) {
      return;
    }

    // ==========================================================
    // UPDATE UI
    // ==========================================================

    _updateState(() {
      _recovering = false;
      _searching = false;
      _searchFinished = false;
      _checkingAddress = false;
      _stopping = false;
    });

    // ==========================================================
    // WALK IS STILL ACTIVE
    // ==========================================================

    _setActive(true);

    // ==========================================================
    // SHOW WALKER FOUND
    // ==========================================================

    widget.onWalkerFound?.call();
  }
}
