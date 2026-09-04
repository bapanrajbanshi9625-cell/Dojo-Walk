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
//   - Restores accepted walker data
//   - Restores requestId
//   - Stops radar
//   - Stops search listener
//   - Hands accepted walk to walker_accept flow
//
// IMPORTANT:
//   This file does NOT control the accepted walk lifecycle.
//   walker_accept feature owns the accepted/live-walk flow.
// ============================================================

extension _RecoveryRole on _InstaWalkContainerState {
  // ============================================================
  // RECOVER SEARCH
  // ============================================================

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
              final String value =
                  petName.toString().trim();

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

            // --------------------------------------------------
            // Hand off to normal accepted handler.
            //
            // _handleAccepted() is responsible for:
            // - duplicate protection
            // - radar stop
            // - listener stop
            // - container search reset
            // - opening walker_accept flow
            // --------------------------------------------------

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
  //
  // This handles only recovery after app/screen restart.
  //
  // It does NOT:
  // - lock the container
  // - control LiveWalk
  // - wait for walk completion
  // - delete the request
  // - cancel the request
  //
  // The accepted data is handed to _walkerAccepted().
  // ============================================================

  Future<void> _recoverAcceptedRequest(
    InstaWalkRequestState active,
  ) async {
    final Map<String, dynamic> data =
        active.data ?? <String, dynamic>{};

    // ==========================================================
    // BUILD ACCEPTED DATA
    // ==========================================================

    final InstaWalkAcceptedData accepted =
        InstaWalkAcceptedData.fromMap(
      data,
      requestId: active.requestId,
    );

    // ==========================================================
    // RESTORE REQUEST ID
    // ==========================================================

    String requestId =
        active.requestId.trim();

    if (requestId.isEmpty) {
      requestId = accepted.requestId.trim();
    }

    if (requestId.isEmpty) {
      debugPrint(
        '❌ Accepted Insta Walk recovery failed: '
        'requestId missing.',
      );

      _resetSearchState();
      return;
    }

    _requestId = requestId;

    // ==========================================================
    // RESTORE OWNER LOCATION
    // ==========================================================

    _ownerPosition =
        _readOwnerPosition(data);

    // ==========================================================
    // STOP RADAR
    // ==========================================================

    _stopRadar();

    // ==========================================================
    // STOP SEARCH LISTENER
    // ==========================================================
    //
    // Local listener only.
    //
    // Firestore request is NOT changed.
    //
    // ==========================================================

    _service.stopListening();

    if (!mounted) {
      return;
    }

    // ==========================================================
    // CONTAINER SEARCH UI → NORMAL
    // ==========================================================

    _updateState(() {
      _recovering = false;
      _searching = false;
      _searchFinished = false;
      _checkingAddress = false;
      _stopping = false;
    });

    // ==========================================================
    // SEARCH IS NOT ACTIVE
    // ==========================================================

    _setActive(false);

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
        '❌ Accepted request recovered, '
        'but walker ID/UID is missing.',
      );

      _message(
        'Walker accepted the request, but walker information is missing.',
      );

      return;
    }

    // ==========================================================
    // HAND OFF TO ACCEPTED-WALK FLOW
    // ==========================================================
    //
    // IMPORTANT:
    //
    // Do NOT set any accepted-navigation lock here.
    //
    // _walkerAccepted() will route through the normal accepted
    // handler, where duplicate protection and navigation are
    // handled in ONE place.
    //
    // ==========================================================

    await _walkerAccepted(
      accepted,
    );
  }
}
