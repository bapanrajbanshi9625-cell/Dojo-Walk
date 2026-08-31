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
    required String dogName,
    required String dogBreed,
  }) async {
    try {
      final InstaWalkSearchResult result =
          await _service.startSearch(
        ownerId: ownerId,
        ownerName: ownerName,
        address: address,
        ownerLocation: GeoPoint(
          position.latitude,
          position.longitude,
        ),
        dogName: dogName,
        dogBreed: dogBreed,
      );

      if (!mounted) {
        return;
      }

      if (!result.success ||
          result.requestId == null ||
          result.requestId!.trim().isEmpty) {
        _requestId = null;
        _stopRadar();

        _updateState(() {
          _checkingAddress = false;
          _searching = false;
          _searchFinished = false;
          _stopping = false;
        });

        _setActive(false);

        _message(
          result.message ?? 'Unable to start search.',
        );

        return;
      }

      final String requestId =
          result.requestId!.trim();

      _requestId = requestId;

      _updateState(() {
        _checkingAddress = false;
        _searching = true;
        _searchFinished = false;
        _stopping = false;
      });

      _setActive(true);
      _startRadar();

      // ========================================================
      // FIRESTORE REALTIME LISTENER
      // ========================================================

      _service.listenAndStore(
        requestId,
        onData: (
          InstaWalkRequestState state,
        ) {
          if (!mounted) {
            return;
          }

          if (state.isAccepted) {
            final Map<String, dynamic> data =
                state.data ?? <String, dynamic>{};

            final InstaWalkAcceptedData accepted =
                InstaWalkAcceptedData.fromMap(data);

            _walkerAccepted(accepted);
            return;
          }

          if (state.isCancelled) {
            _finishSearch(
              message: 'Walk request was cancelled.',
            );
            return;
          }

          if (state.isExpired) {
            _finishSearch(
              message: 'Walk request expired.',
            );
            return;
          }

          // searching = continue
        },
        onError: (Object error) {
          debugPrint(
            'Insta Walk listener error: $error',
          );
        },
      );
    } catch (e) {
      debugPrint(
        'Insta Walk search error: $e',
      );

      if (!mounted) {
        return;
      }

      _stopRadar();
      _requestId = null;

      _updateState(() {
        _checkingAddress = false;
        _searching = false;
        _searchFinished = false;
        _stopping = false;
      });

      _setActive(false);

      _message(
        'Unable to start Insta Walk.',
      );
    }
  }
}
