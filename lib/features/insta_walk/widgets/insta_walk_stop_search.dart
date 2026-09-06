part of '../controllers/insta_walk_container.dart';

// ============================================================
// STOP INSTA WALK SEARCH
// ============================================================

extension _StopSearchRole on _InstaWalkContainerState {
  Future<void> _stopSearch() async {
    // ==========================================================
    // GUARDS
    // ==========================================================

    if (_stopping) {
      return;
    }

    final String requestId =
        (_requestId ?? '').trim();

    if (requestId.isEmpty) {
      _finishSearch(
        message: 'No active Insta Walk request found.',
      );
      return;
    }

    // ==========================================================
    // STOPPING STATE
    // ==========================================================

    if (mounted) {
      _updateState(() {
        _stopping = true;
      });
    }

    try {
      // ========================================================
      // CANCEL FIRESTORE REQUEST
      //
      // Collection:
      // walk_request/{requestId}
      //
      // Service is responsible for validating:
      // ownerAuthUid == currentUser.uid
      // status == searching
      //
      // Then:
      // status = cancelled
      // cancelledAt = serverTimestamp()
      // cancelledBy = currentUser.uid
      // ========================================================

      final bool cancelled =
          await _service.cancelSearch(
        requestId: requestId,
      );

      if (!mounted) {
        return;
      }

      // ========================================================
      // SUCCESSFULLY CANCELLED
      // ========================================================

      if (cancelled) {
        _requestId = null;

        // Stop Firestore realtime listener.
        _service.stopListening();

        // Stop animated search icon.
        _stopSearchAnimation();

        _updateState(() {
          _searching = false;
          _searchFinished = true;
          _checkingAddress = false;
          _recovering = false;
          _stopping = false;
        });

        _setActive(false);

        _message(
          'Insta Walk search stopped.',
        );

        return;
      }

      // ========================================================
      // CANCEL FAILED
      //
      // Most commonly:
      // - walker already accepted
      // - request is no longer searching
      // - request ownership mismatch
      // - Firestore rules rejected the operation
      //
      // Do NOT forcibly reset the accepted flow here.
      // The realtime listener remains responsible for detecting
      // ACCEPTED and sending it through _walkerAccepted().
      // ========================================================

      _updateState(() {
        _stopping = false;
      });

      _message(
        'Unable to stop Insta Walk search.',
      );
    } on FirebaseException catch (e) {
      // ========================================================
      // FIREBASE ERROR
      // ========================================================

      debugPrint(
        'Stop Insta Walk Firebase error: '
        '${e.code} - ${e.message}',
      );

      if (!mounted) {
        return;
      }

      _updateState(() {
        _stopping = false;
      });

      if (e.code == 'permission-denied') {
        _message(
          'Permission denied. Please check Firestore rules.',
        );
      } else {
        _message(
          e.message ??
              'Unable to stop Insta Walk search.',
        );
      }
    } catch (e) {
      // ========================================================
      // UNKNOWN ERROR
      // ========================================================

      debugPrint(
        'Stop Insta Walk error: $e',
      );

      if (!mounted) {
        return;
      }

      _updateState(() {
        _stopping = false;
      });

      _message(
        'Unable to stop Insta Walk search.',
      );
    }
  }
}
