part of 'insta_walk_container.dart';

// ============================================================
// SEARCH RECOVERY
//
// FIRESTORE = SOURCE OF TRUTH
//
// SEARCHING REQUEST:
//     - No expiry
//     - No countdown
//     - No automatic stop
//     - Survives screen navigation
//     - Survives app close
//     - Recovers after app reopen
//
// RADAR:
//     Restored when status == searching
//
// MAP:
//     Restored from Firestore ownerLocation
// ============================================================

extension _RecoveryRole on _InstaWalkContainerState {
  Future<void> _recoverSearch() async {
    final User? user =
        FirebaseAuth.instance.currentUser;

    // ==========================================================
    // NO LOGIN
    // ==========================================================

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

      final QueryDocumentSnapshot<
          Map<String, dynamic>>? ownerDoc =
          await _service.findOwnerProfile();

      if (!mounted) {
        return;
      }

      if (ownerDoc == null) {
        _resetSearchState();

        if (!mounted) {
          return;
        }

        _updateState(() {
          _recovering = false;
        });

        _setActive(false);

        return;
      }

      // ========================================================
      // OWNER DATA
      // ========================================================

      final Map<String, dynamic> ownerData =
          ownerDoc.data();

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
      // BUSINESS / OWNER ID
      // ========================================================

      String ownerId =
          _readFirstString(
        ownerData,
        const [
          'businessId',
          'Business ID',
          'ownerId',
          'Owner ID',
        ],
      );

      // ========================================================
      // FALLBACK
      // ========================================================

      if (ownerId.isEmpty) {
        ownerId = ownerDoc.id.trim();
      }

      if (ownerId.isEmpty) {
        _resetSearchState();

        if (!mounted) {
          return;
        }

        _updateState(() {
          _recovering = false;
        });

        _setActive(false);

        return;
      }

      // ========================================================
      // FIND FIRESTORE ACTIVE REQUEST
      // ========================================================

      final InstaWalkRequestState? active =
          await _service.findActiveRequest(
        ownerId: ownerId,
      );

      if (!mounted) {
        return;
      }

      // ========================================================
      // NO ACTIVE REQUEST
      // ========================================================

      if (active == null) {
        _resetSearchState();

        if (!mounted) {
          return;
        }

        _updateState(() {
          _recovering = false;
        });

        _setActive(false);

        return;
      }

      // ========================================================
      // SEARCHING
      // ========================================================

      if (active.isSearching) {
        await _recoverSearchingRequest(
          active,
        );

        return;
      }

      // ========================================================
      // ACCEPTED
      // ========================================================

      if (active.isAccepted) {
        await _recoverAcceptedRequest(
          active,
        );

        return;
      }

      // ========================================================
      // CANCELLED / EXPIRED / UNKNOWN
      // ========================================================

      _resetSearchState();

      if (!mounted) {
        return;
      }

      _updateState(() {
        _recovering = false;
      });

      _setActive(false);
    } catch (e) {
      debugPrint(
        'Insta Walk recovery error: $e',
      );

      if (!mounted) {
        return;
      }

      _resetSearchState();

      if (!mounted) {
        return;
      }

      _updateState(() {
        _recovering = false;
      });

      _setActive(false);
    }
  }

  // ============================================================
  // RECOVER SEARCHING REQUEST
  //
  // IMPORTANT:
  //
  // There is deliberately NO expiresAt check here.
  //
  // If Firestore says:
  //
  // status = searching
  //
  // then the UI must stay searching.
  // ============================================================

  Future<void> _recoverSearchingRequest(
    InstaWalkRequestState active,
  ) async {
    final String? requestId =
        active.requestId;

    // ==========================================================
    // REQUEST ID REQUIRED
    // ==========================================================

    if (requestId == null ||
        requestId.trim().isEmpty) {
      _resetSearchState();

      if (!mounted) {
        return;
      }

      _updateState(() {
        _recovering = false;
      });

      _setActive(false);

      return;
    }

    // ==========================================================
    // RESTORE REQUEST ID
    // ==========================================================

    _requestId = requestId.trim();

    // ==========================================================
    // RESTORE OWNER LOCATION
    // ==========================================================

    _ownerPosition =
        _readOwnerPosition(
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

      // SEARCHING ON
      _searching = true;

      _searchFinished = false;

      _checkingAddress = false;

      // NO COUNTDOWN
      _stopping = false;
    });

    // ==========================================================
    // TELL PARENT THAT INSTA WALK IS ACTIVE
    // ==========================================================

    _setActive(true);

    // ==========================================================
    // START RADAR
    // ==========================================================

    _startRadar();

    // ==========================================================
    // REALTIME FIRESTORE LISTENER
    // ==========================================================

    try {
      await _service.listenForRequest(
        requestId: requestId,

        // ======================================================
        // WALKER ACCEPTED
        // ======================================================

        onAccepted: (
          InstaWalkAcceptedData data,
        ) {
          _walkerAccepted(data);
        },

        // ======================================================
        // OLD / MANUAL EXPIRED
        // ======================================================

        onExpired: () {
          _finishSearch(
            message:
                'This Insta Walk request is no longer active.',
          );
        },

        // ======================================================
        // CANCELLED
        // ======================================================

        onCancelled: () {
          _finishSearch(
            message:
                'Walk request was cancelled.',
          );
        },

        // ======================================================
        // LISTENER ERROR
        // ======================================================

        onError: (
          Object error,
        ) {
          debugPrint(
            'Insta Walk Firestore listener error: '
            '$error',
          );
        },
      );
    } catch (e) {
      debugPrint(
        'Insta Walk listener setup error: '
        '$e',
      );
    }

    // ==========================================================
    // IMPORTANT
    //
    // NO COUNTDOWN TIMER.
    //
    // Search remains active until:
    // owner cancels OR walker accepts.
    // ==========================================================
  }

  // ============================================================
  // RECOVER ACCEPTED REQUEST
  // ============================================================

  Future<void> _recoverAcceptedRequest(
    InstaWalkRequestState active,
  ) async {
    final Map<String, dynamic> data =
        active.data ??
            <String, dynamic>{};

    final InstaWalkAcceptedData accepted =
        InstaWalkAcceptedData.fromMap(
      data,
    );

    // ==========================================================
    // RESTORE REQUEST ID
    // ==========================================================

    final String recoveredId =
        accepted.requestId.trim();

    _requestId =
        recoveredId.isEmpty
            ? active.requestId
            : recoveredId;

    // ==========================================================
    // STOP SEARCH VISUALS
    // ==========================================================

    _stopTimer();
    _stopRadar();

    // ==========================================================
    // UPDATE STATE
    // ==========================================================

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

    // ==========================================================
    // KEEP ACTIVE BECAUSE WALKER WAS FOUND
    // ==========================================================

    _setActive(true);

    // ==========================================================
    // SHOW WALKER FOUND SCREEN
    // ==========================================================

    widget.onWalkerFound?.call();
  }
}
