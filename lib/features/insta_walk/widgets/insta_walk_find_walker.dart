part of 'insta_walk_container.dart';

// ============================================================
// FIND WALKER
// ============================================================

extension _FindWalkerRole on _InstaWalkContainerState {
  Future<void> _findWalker() async {
    if (_searching ||
        _checkingAddress ||
        _recovering ||
        _stopping) {
      return;
    }

    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      _message('Please login first.');
      return;
    }

    if (!mounted) {
      return;
    }

    _updateState(() {
      _checkingAddress = true;
      _searchFinished = false;
    });

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
        _updateState(() {
          _checkingAddress = false;
        });

        _message(
          'Owner profile not found. Please complete your profile.',
        );

        return;
      }

      final Map<String, dynamic> data =
          ownerDoc.data();

      // ========================================================
      // OWNER / BUSINESS ID
      //
      // Required by Firebase walk_requests.
      // ========================================================

      String ownerId = _readFirstString(
        data,
        const [
          'businessId',
          'Business ID',
          'ownerId',
          'Owner ID',
        ],
      );

      // Fallback to profile document ID.
      if (ownerId.isEmpty) {
        ownerId = ownerDoc.id.trim();
      }

      if (ownerId.isEmpty) {
        _updateState(() {
          _checkingAddress = false;
        });

        _message(
          'Business ID / Owner ID not found.',
        );

        return;
      }

      // ========================================================
      // PET NAME
      // ========================================================

      _petName = _readFirstString(
        data,
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
      // ADDRESS
      // ========================================================

      final String address = _readFirstString(
        data,
        const [
          'address',
          'Adress',
          'Address',
        ],
      );

      if (address.isEmpty) {
        _updateState(() {
          _checkingAddress = false;
        });

        _message(
          'Owner address is missing. Please complete your address first.',
        );

        return;
      }

      // ========================================================
      // OWNER NAME
      // ========================================================

      String ownerName = _readFirstString(
        data,
        const [
          'fullName',
          'Full Name',
          'ownerName',
          'name',
        ],
      );

      if (ownerName.isEmpty) {
        ownerName = 'Dog Owner';
      }

      // ========================================================
      // GET CURRENT LOCATION
      // ========================================================

      final Position? position =
          await _getLocation();

      if (!mounted) {
        return;
      }

      if (position == null) {
        _updateState(() {
          _checkingAddress = false;
        });

        return;
      }

      // ========================================================
      // SAVE OWNER POSITION
      // ========================================================

      _ownerPosition = position;

      // ========================================================
      // START FIRESTORE SEARCH
      //
      // This sends:
      //
      // requestId
      // status
      // searchType
      // senderRole
      // senderUid
      // ownerAuthUid
      // businessId
      // ownerId
      // ownerName
      // address
      // searchRadiusKm
      // ownerLocation
      // ownerLocationType
      // walkerUid
      // walkerId
      // walkerName
      // acceptedBy
      // acceptedAt
      // createdAt
      // ========================================================

      await _startSearch(
        ownerId: ownerId,
        ownerName: ownerName,
        address: address,
        position: position,
      );
    } on FirebaseException catch (e) {
      debugPrint(
        'Insta Walk Firebase error: '
        '${e.code} - ${e.message}',
      );

      if (!mounted) {
        return;
      }

      _updateState(() {
        _checkingAddress = false;
      });

      _message(
        e.code == 'permission-denied'
            ? 'Firestore permission denied. Please check Firebase rules.'
            : 'Unable to start Insta Walk.',
      );
    } catch (e) {
      debugPrint(
        'Insta Walk start error: $e',
      );

      if (!mounted) {
        return;
      }

      _updateState(() {
        _checkingAddress = false;
      });

      _message(
        'Unable to start Insta Walk.',
      );
    }
  }

  // ============================================================
  // LOCATION
  // ============================================================

  Future<Position?> _getLocation() async {
    try {
      // ========================================================
      // LOCATION SERVICE
      // ========================================================

      final bool enabled =
          await Geolocator.isLocationServiceEnabled();

      if (!enabled) {
        _message(
          'Please turn on location service.',
        );

        return null;
      }

      // ========================================================
      // LOCATION PERMISSION
      // ========================================================

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission ==
          LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      // ========================================================
      // PERMISSION DENIED
      // ========================================================

      if (permission ==
              LocationPermission.denied ||
          permission ==
              LocationPermission.deniedForever) {
        _message(
          'Location permission is required.',
        );

        return null;
      }

      // ========================================================
      // CURRENT LOCATION
      // ========================================================

      final Position position =
          await Geolocator.getCurrentPosition();

      return position;
    } catch (e) {
      debugPrint(
        'Location error: $e',
      );

      _message(
        'Unable to get your current location.',
      );

      return null;
    }
  }
}
