// File:
// lib/features/insta_walk/widgets/insta_walk_recovery.dart

part of '../controllers/insta_walk_container.dart';

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
//   - Restores requestId
//   - Stops radar/search listener
//   - Opens accepted-walker screen
//   - Does NOT cancel/delete Firestore request
// ============================================================

extension _RecoveryRole on _InstaWalkContainerState {
  Future<void> _recoverSearch() async {
    final User? user = FirebaseAuth.instance.currentUser;

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

      // ========================================================
      // PROFILE NOT FOUND
      // ========================================================

      if (ownerDoc == null || !ownerDoc.exists) {
        _resetSearchState();
        return;
      }

      // ========================================================
      // OWNER DATA
      // ========================================================

      final Map<String, dynamic> ownerData =
          ownerDoc.data() ?? <String, dynamic>{};

      // ========================================================
      // PROFILE COMPLETION
      // ========================================================

      final bool profileCompleted =
          ownerData['profileCompleted'] == true;

      if (!profileCompleted) {
        _resetSearchState();
        return;
      }

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

      // ========================================================
      // PETS ARRAY FALLBACK
      // ========================================================

      if (_petName.isEmpty) {
        final dynamic pets = ownerData['pets'];

        if (pets is List && pets.isNotEmpty) {
          final dynamic firstPet = pets.first;

          if (firstPet is Map) {
            final dynamic petName = firstPet['name'];

            if (petName != null) {
              final String value = petName.toString().trim();

              if (value.isNotEmpty) {
                _petName = value;
              }
            }
          }
        }
      }

      if (_petName.isEmpty) {
        _petName = 'Your Pet';
      }

      // ========================================================
      // OWNER ID
      // ========================================================

      String ownerId = _readFirstString(
        ownerData,
        const [
          'ownerId',
          'Owner ID',
        ],
      );

      // ========================================================
      // FALLBACK TO OWNER PROFILE DOCUMENT ID
      // ========================================================

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

      // ========================================================
      // NO ACTIVE REQUEST
      // ========================================================

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
      // OTHER / TERMINAL STATE
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
    // ----------------------------------------------------------
    // Never restore searching after accepted navigation started.
    // ----------------------------------------------------------

    if (_acceptedNavigationStarted) {
      return;
    }

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

    if (!mounted) {
      return;
    }

    // ==========================================================
    // RESTORE SEARCH UI
    // ==========================================================

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
          // ACCEPTED
          // ====================================================

          if (state.isAccepted) {
            final Map<String, dynamic> data =
                state.data ?? <String, dynamic>{};

            final InstaWalkAcceptedData accepted =
                InstaWalkAcceptedData.fromMap(
              data,
              requestId: requestId,
            );

            _walkerAccepted(accepted);
            return;
          }

          // ====================================================
          // CANCELLED
          // ====================================================

          if (state.isCancelled) {
            // IMPORTANT:
            // This only handles an actual Firestore cancelled
            // status. It is NOT triggered by local UI changes.

            _finishSearch(
              message: 'Walk request was cancelled.',
            );

            return;
          }

          // ====================================================
          // EXPIRED
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
          // ====================================================
          //
          // Continue listening.
          //
        },
        onError: (
          Object error,
          StackTrace stackTrace,
        ) {
          debugPrint(
            'Insta Walk Firestore listener error: $error',
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
    } catch (e) {
      debugPrint(
        'Insta Walk listener setup error: $e',
      );
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
        active.data ?? <String, dynamic>{};

    // ==========================================================
    // ACCEPTED DATA
    // ==========================================================

    final InstaWalkAcceptedData accepted =
        InstaWalkAcceptedData.fromMap(
      data,
      requestId: active.requestId,
    );

    // ==========================================================
    // RESTORE REQUEST ID
    // ==========================================================

    String requestId = active.requestId.trim();

    if (requestId.isEmpty) {
      requestId = accepted.requestId.trim();
    }

    if (requestId.isEmpty) {
      debugPrint(
        'Accepted Insta Walk recovery failed: requestId missing.',
      );

      _resetSearchState();
      return;
    }

    _requestId = requestId;

    // ==========================================================
    // RESTORE OWNER LOCATION
    // ==========================================================

    _ownerPosition = _readOwnerPosition(data);

    // ==========================================================
    // STOP RADAR
    // ==========================================================

    _stopRadar();

    // ==========================================================
    // STOP SEARCH LISTENER
    // ==========================================================
    //
    // IMPORTANT:
    // This only stops the local listener.
    //
    // It does NOT:
    // - cancel request
    // - delete request
    // - change Firestore status
    //
    // ==========================================================

    _service.stopListening();

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
    // SEARCH IS NO LONGER ACTIVE
    // ==========================================================

    _setActive(false);

    // ==========================================================
    // VALIDATE WALKER
    // ==========================================================

    final String walkerId =
        accepted.walkerId.trim();

    final String walkerUid =
        accepted.walkerUid.trim();

    if (walkerId.isEmpty && walkerUid.isEmpty) {
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
    // 🔥 IMPORTANT FIX
    // ==========================================================
    //
    // DO NOT set:
    //
    // _acceptedNavigationStarted = true;
    //
    // here.
    //
    // _walkerAccepted() calls _handleAccepted().
    // _handleAccepted() itself sets the navigation guard.
    //
    // Setting the guard here first would make _handleAccepted()
    // return immediately and WalkerAcceptScreen would NOT open
    // after app recovery.
    //
    // ==========================================================

    await _walkerAccepted(
      accepted,
    );
  }
}
