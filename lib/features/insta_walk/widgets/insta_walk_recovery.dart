part of 'insta_walk_container.dart';

// ============================================================
// SEARCH RECOVERY
//
// FIRESTORE = SOURCE OF TRUTH
//
// SEARCHING:
//   - No expiry
//   - No countdown
//   - No automatic stop
//   - Survives screen navigation
//   - Recovers after app reopen
//
// ACCEPTED:
//   - Restores accepted walker
//   - Restores requestId from Firestore document ID
// ============================================================

extension _RecoveryRole on _InstaWalkContainerState {
  Future<void> _recoverSearch() async {
    final User? user =
        FirebaseAuth.instance.currentUser;

    // ==========================================================
    // NOT LOGGED IN
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
          ownerDoc.data() ??
              <String, dynamic>{};

      // ========================================================
      // PET NAME
      // ========================================================

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

      // Fallback:
      // ownerProfiles document ID
      if (ownerId.isEmpty) {
        ownerId =
            ownerDoc.id.trim();
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

      // ========================================================
      // NO ACTIVE SEARCH
      // ========================================================

      if (active == null) {
        _resetSearchState();
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
    } on FirebaseException catch (e) {
      debugPrint(
        'Insta Walk recovery Firebase error: '
        '${e.code} - ${e.message}',
      );

      if (!mounted) {
        return;
      }

      _resetSearchState();

      _message(
        e.code == 'permission-denied'
            ? 'Firestore permission denied while recovering Insta Walk.'
            : 'Unable to recover Insta Walk.',
      );
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
    final String requestId =
        active.requestId.trim();

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
          .listenForRequest(
            requestId,
          )
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
                state.data ??
                    <String, dynamic>{};

            final InstaWalkAcceptedData accepted =
                InstaWalkAcceptedData.fromMap(
              data,

              // IMPORTANT:
              // Firestore document ID is the real request ID.
              requestId: requestId,
            );

            _walkerAccepted(
              accepted,
            );

            return;
          }

          // ====================================================
          // CANCELLED
          // ====================================================

          if (state.isCancelled) {
            _finishSearch(
              message:
                  'Walk request was cancelled.',
            );

            return;
          }

          // ====================================================
          // EXPIRED
          //
          // Only reacts to Firestore:
          //
          // status = expired
          //
          // No automatic expiry.
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
          // Keep searching.
          // ====================================================
        },
        onError: (
          Object error,
          StackTrace stackTrace,
        ) {
          debugPrint(
            'Insta Walk Firestore listener error: '
            '$error',
          );

          debugPrint(
            stackTrace.toString(),
          );
        },
      );
    } on FirebaseException catch (e) {
      debugPrint(
        'Insta Walk listener Firebase error: '
        '${e.code} - ${e.message}',
      );

      // IMPORTANT:
      // Listener failure does NOT cancel Firestore request.
    } catch (e) {
      debugPrint(
        'Insta Walk listener setup error: $e',
      );

      // IMPORTANT:
      // Request remains in Firestore.
    }

    // ==========================================================
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
        active.data ??
            <String, dynamic>{};

    // ==========================================================
    // IMPORTANT
    //
    // active.requestId is Firestore document ID.
    //
    // Do not depend on data['requestId'].
    // ==========================================================

    final InstaWalkAcceptedData accepted =
        InstaWalkAcceptedData.fromMap(
      data,
      requestId: active.requestId,
    );

    // ==========================================================
    // RESTORE REQUEST ID
    // ==========================================================

    _requestId =
        active.requestId.trim();

    if (_requestId!.isEmpty) {
      _requestId =
          accepted.requestId.trim();
    }

    // ==========================================================
    // RESTORE OWNER LOCATION
    // ==========================================================

    _ownerPosition =
        _readOwnerPosition(
      data,
    );

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
    // REQUEST IS STILL ACTIVE
    //
    // Accepted request is not the same as cancelled/expired.
    // ==========================================================

    _setActive(true);

    // ==========================================================
    // VALIDATE WALKER
    // ==========================================================

    final String walkerId =
        accepted.walkerId.trim();

    final String walkerUid =
        accepted.walkerUid.trim();

    if (walkerId.isEmpty &&
        walkerUid.isEmpty) {
      debugPrint(
        'Accepted request recovered, '
        'but walker ID/UID is missing.',
      );

      _message(
        'Walker accepted the request, but walker information is missing.',
      );

      return;
    }

    // ==========================================================
    // RESTORE ACCEPTED WALKER
    // ==========================================================

    _walkerAccepted(
      accepted,
    );
  }
}
