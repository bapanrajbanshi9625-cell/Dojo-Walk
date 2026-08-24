part of 'insta_walk_container.dart';

// ============================================================
// SEARCH RECOVERY
//
// FIRESTORE IS THE SOURCE OF TRUTH.
//
// Searching request has NO expiry.
//
// App/screen close:
//     Firestore request remains searching.
//
// App/screen open:
//     This recovery finds it again.
//
// Only these states stop searching:
//
// 1. accepted
// 2. owner_cancelled
// 3. walker_cancelled
// 4. cancelled
// 5. old/manual expired
// ============================================================

extension _RecoveryRole on _InstaWalkContainerState {
  Future<void> _recoverSearch() async {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) {
        return;
      }

      _updateState(() {
        _recovering = false;
        _searching = false;
        _searchFinished = false;
        _checkingAddress = false;
        _secondsLeft = 0;
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
      // OWNER / BUSINESS ID
      // ========================================================

      final String ownerId =
          _readFirstString(
        ownerData,
        const [
          'businessId',
          'Business ID',
          'ownerId',
          'Owner ID',
        ],
      );

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
      // FIND ACTIVE FIRESTORE REQUEST
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
      // OTHER STATE
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
  // NO expiresAt.
  // NO remaining time.
  // NO automatic expiration.
  // ============================================================

  Future<void> _recoverSearchingRequest(
    InstaWalkRequestState active,
  ) async {
    final String? requestId =
        active.requestId;

    // ==========================================================
    // REQUEST ID MUST EXIST
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
    // RESTORE REQUEST
    // ==========================================================

    _requestId = requestId;

    _ownerPosition =
        _readOwnerPosition(
      active.data,
    );

    // ==========================================================
    // IMPORTANT:
    //
    // There is NO expiresAt check here.
    //
    // Searching means searching.
    // ==========================================================

    if (!mounted) {
      return;
    }

    _updateState(() {
      _recovering = false;
      _searching = true;
      _searchFinished = false;
      _checkingAddress = false;
      _secondsLeft = 0;
      _stopping = false;
    });

    _setActive(true);

    _startRadar();

    // ==========================================================
    // REALTIME FIRESTORE LISTENER
    // ==========================================================

    try {
      await _service.listenForRequest(
        requestId: requestId,

        // ======================================================
        // SEARCHING
        // ======================================================

        onSearching: () {
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
          _startRadar();
        },

        // ======================================================
        // ANY FIRESTORE UPDATE
        // ======================================================

        onUpdated: (
          Map<String, dynamic> data,
        ) {
          if (!mounted) {
            return;
          }

          final String status =
              data['status']
                      ?.toString()
                      .trim()
                      .toLowerCase() ??
                  '';

          // ----------------------------------------------------
          // SEARCHING
          // ----------------------------------------------------

          if (status == 'searching') {
            _updateState(() {
              _searching = true;
              _searchFinished = false;
              _recovering = false;
            });

            _setActive(true);
            _startRadar();

            return;
          }

          // ----------------------------------------------------
          // ACCEPTED
          //
          // onAccepted handles the actual UI.
          // ----------------------------------------------------

          if (status == 'accepted') {
            return;
          }
        },

        // ======================================================
        // WALKER ACCEPTED
        // ======================================================

        onAccepted: (
          InstaWalkAcceptedData data,
        ) {
          _walkerAccepted(data);
        },

        // ======================================================
        // EXPIRED
        //
        // Only old/manual Firestore documents.
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
        // FIRESTORE ERROR
        //
        // IMPORTANT:
        // Do NOT stop searching because of temporary listener
        // error. Firestore request still exists.
        // ======================================================

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

    final String recoveredId =
        accepted.requestId.trim();

    _requestId =
        recoveredId.isEmpty
            ? active.requestId
            : recoveredId;

    _stopTimer();
    _stopRadar();

    if (!mounted) {
      return;
    }

    _updateState(() {
      _recovering = false;
      _searching = false;
      _searchFinished = false;
      _checkingAddress = false;
      _secondsLeft = 0;
      _stopping = false;
    });

    _setActive(true);

    // ==========================================================
    // SHOW WALKER FOUND / ACCEPTED STATE
    // ==========================================================

    widget.onWalkerFound?.call();
  }
}
