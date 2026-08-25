part of 'insta_walk_container.dart';

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
      // COLLECTION:
      // walk_requests/{requestId}
      //
      // Service checks:
      // ownerAuthUid == currentUser.uid
      // status == searching
      //
      // Then updates:
      // status = cancelled
      // cancelledAt = serverTimestamp()
      // ========================================================

      final bool cancelled =
          await _service.cancelSearch(
        requestId: requestId,
      );

      if (!mounted) {
        return;
      }

      // ========================================================
      // SUCCESS
      // ========================================================

      if (cancelled) {
        _stopRadar();

        _requestId = null;
        _ownerPosition = null;

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
      // FAILED TO CANCEL
      //
      // Possible reasons:
      //
      // 1. Walker already accepted
      // 2. Request is not searching
      // 3. Owner does not own request
      // 4. Firestore permission denied
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
