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
      // OWNER ID
      // ========================================================

      final String ownerId =
          _readFirstString(
        data,
        const [
          'ownerId',
          'Owner ID',
        ],
      );

      if (ownerId.isEmpty) {
        _updateState(() {
          _checkingAddress = false;
        });

        _message('Owner ID not found.');
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

      String address =
          _readFirstString(
        data,
        const [
          'address',
          'Adress',
          'Address',
        ],
      );

      // ========================================================
      // ADDRESS MISSING
      // ========================================================

      if (address.isEmpty) {
        if (!mounted) {
          return;
        }

        _updateState(() {
          _checkingAddress = false;
        });

        // ------------------------------------------------------
        // OPEN ADDRESS SCREEN
        // ------------------------------------------------------

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const AddressScreen(),
          ),
        );

        if (!mounted) {
          return;
        }

        // ------------------------------------------------------
        // ADDRESS SCREEN SE SAVE KARKE WAPAS AANE KE BAAD
        // AUTOMATICALLY PROFILE DOBARA CHECK HOGA.
        // ------------------------------------------------------

        _updateState(() {
          _checkingAddress = false;
        });

        // ------------------------------------------------------
        // IMPORTANT
        //
        // User ko Search button dobara press nahi karna padega.
        // Address save hone ke baad _findWalker() automatically
        // dobara chalega.
        // ------------------------------------------------------

        await _findWalker();

        return;
      }

      // ========================================================
      // OWNER NAME
      // ========================================================

      String ownerName =
          _readFirstString(
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
      // START INSTA WALK SEARCH
      // ========================================================

      await _startSearch(
        ownerId: ownerId,
        ownerName: ownerName,
        address: address,
        position: position,
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

      return await Geolocator.getCurrentPosition();
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
