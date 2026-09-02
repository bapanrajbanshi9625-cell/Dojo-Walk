part of '../controllers/insta_walk_container.dart';

// ============================================================
// FIND WALKER
// ============================================================
//
// OWNER-SIDE INSTA WALK
//
// FLOW:
//
// Start Search
//      ↓
// Check Owner Profile
//      ↓
// Address available?
//   ┌──┴──┐
//  YES    NO
//   ↓      ↓
// Search AddressScreen
//          ↓
//       Save Address
//          ↓
//        Return
//          ↓
//       Start Search
//
// IMPORTANT:
// No separate location search is used inside Insta Walk.
// ============================================================

extension _FindWalkerRole
    on _InstaWalkContainerState {
  // ==========================================================
  // FIND WALKER
  // ==========================================================

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

      final DocumentSnapshot<
          Map<String, dynamic>>? ownerDoc =
          await _service.findOwnerProfile();

      if (!mounted) {
        return;
      }

      if (ownerDoc == null ||
          !ownerDoc.exists) {
        _updateState(() {
          _checkingAddress = false;
        });

        _message(
          'Owner profile not found. Please complete your profile.',
        );

        return;
      }

      final Map<String, dynamic> data =
          ownerDoc.data() ??
              <String, dynamic>{};

      // ========================================================
      // PROFILE COMPLETION
      //
      // ADDRESS IS NOT REQUIRED FOR PROFILE COMPLETION.
      // ========================================================

      final bool profileCompleted =
          data['profileCompleted'] == true;

      if (!profileCompleted) {
        _updateState(() {
          _checkingAddress = false;
        });

        _message(
          'Owner profile is not completed. Please complete your profile first.',
        );

        return;
      }

      // ========================================================
      // OWNER ID
      // ========================================================

      String ownerId =
          _readFirstString(
        data,
        const [
          'ownerId',
          'Owner ID',
        ],
      );

      if (ownerId.isEmpty) {
        ownerId = user.uid;
      }

      // ========================================================
      // PET / DOG DATA
      // ========================================================

      String dogName =
          _readFirstString(
        data,
        const [
          'dogName',
          'petName',
          'Dog Name',
          'Pet Name',
        ],
      );

      String dogBreed =
          _readFirstString(
        data,
        const [
          'dogBreed',
          'petBreed',
          'Dog Breed',
          'Pet Breed',
        ],
      );

      // ========================================================
      // PETS ARRAY FALLBACK
      // ========================================================

      final dynamic pets =
          data['pets'];

      if (pets is List &&
          pets.isNotEmpty) {
        final dynamic firstPet =
            pets.first;

        if (firstPet is Map) {
          // ----------------------------------------------------
          // PET NAME
          // ----------------------------------------------------

          if (dogName.isEmpty) {
            final dynamic petName =
                firstPet['name'] ??
                    firstPet['petName'] ??
                    firstPet['dogName'];

            if (petName != null) {
              final String value =
                  petName.toString().trim();

              if (value.isNotEmpty) {
                dogName = value;
              }
            }
          }

          // ----------------------------------------------------
          // PET BREED
          // ----------------------------------------------------

          if (dogBreed.isEmpty) {
            final dynamic petBreed =
                firstPet['breed'] ??
                    firstPet['petBreed'] ??
                    firstPet['dogBreed'];

            if (petBreed != null) {
              final String value =
                  petBreed.toString().trim();

              if (value.isNotEmpty) {
                dogBreed = value;
              }
            }
          }
        }
      }

      // ========================================================
      // SAVE PET NAME FOR UI
      // ========================================================

      _petName =
          dogName.isEmpty
              ? 'Your Pet'
              : dogName;

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
      // ADDRESS LINE FALLBACK
      //
      // Some owner profiles may store structured address
      // instead of the combined "address" field.
      // ========================================================

      if (address.isEmpty) {
        address =
            _buildAddressFromProfile(data);
      }

      // ========================================================
      // SAVED COORDINATES
      //
      // Prefer saved owner location.
      // ========================================================

      Position? position =
          _readOwnerProfilePosition(data);

      // ========================================================
      // ADDRESS MISSING
      //
      // Open AddressScreen.
      //
      // IMPORTANT:
      // We do NOT open another location search screen.
      // AddressScreen itself handles manual address + map.
      // ========================================================

      if (address.isEmpty) {
        _updateState(() {
          _checkingAddress = false;
        });

        final dynamic result =
            await Navigator.of(context).push(
          MaterialPageRoute<dynamic>(
            builder: (_) {
              return const AddressScreen();
            },
          ),
        );

        if (!mounted) {
          return;
        }

        // ------------------------------------------------------
        // User returned from AddressScreen.
        //
        // Reload profile because address may have just been
        // saved.
        // ------------------------------------------------------

        final DocumentSnapshot<
            Map<String, dynamic>>? updatedOwnerDoc =
            await _service.findOwnerProfile();

        if (!mounted) {
          return;
        }

        if (updatedOwnerDoc == null ||
            !updatedOwnerDoc.exists) {
          _message(
            'Unable to reload owner address.',
          );

          return;
        }

        final Map<String, dynamic> updatedData =
            updatedOwnerDoc.data() ??
                <String, dynamic>{};

        address =
            _readFirstString(
          updatedData,
          const [
            'address',
            'Adress',
            'Address',
          ],
        );

        if (address.isEmpty) {
          address =
              _buildAddressFromProfile(
            updatedData,
          );
        }

        position =
            _readOwnerProfilePosition(
          updatedData,
        );

        // ------------------------------------------------------
        // Address still missing means user returned without
        // saving anything.
        // ------------------------------------------------------

        if (address.isEmpty) {
          _message(
            'Please save your address before starting Insta Walk.',
          );

          return;
        }

        // ------------------------------------------------------
        // Keep checking state active while we continue.
        // ------------------------------------------------------

        _updateState(() {
          _checkingAddress = true;
          _searchFinished = false;
        });

        // ------------------------------------------------------
        // "result" is intentionally not required.
        //
        // We reload Firestore because AddressScreen is the
        // single source of truth.
        // ------------------------------------------------------

        debugPrint(
          'InstaWalk: AddressScreen returned: $result',
        );
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
      // LOCATION
      //
      // 1. Use saved profile coordinates.
      // 2. If unavailable, get current GPS.
      //
      // There is NO separate location picker here.
      // ========================================================

      if (position == null) {
        position =
            await _getLocation();
      }

      if (!mounted) {
        return;
      }

      if (position == null) {
        _updateState(() {
          _checkingAddress = false;
        });

        return;
      }

      _ownerPosition = position;

      // ========================================================
      // START SEARCH
      // ========================================================

      await _startSearch(
        ownerId: ownerId,
        ownerName: ownerName,
        address: address,
        position: position,
        dogName: dogName,
        dogBreed: dogBreed,
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

  // ==========================================================
  // BUILD ADDRESS FROM STRUCTURED PROFILE
  // ==========================================================

  String _buildAddressFromProfile(
    Map<String, dynamic> data,
  ) {
    final List<String> parts =
        <String>[];

    final List<String> keys =
        <String>[
      'flatNumber',
      'addressLine1',
      'addressLine2',
      'area',
      'city',
      'state',
      'pincode',
    ];

    for (final String key in keys) {
      final dynamic value =
          data[key];

      if (value == null) {
        continue;
      }

      final String text =
          value.toString().trim();

      if (text.isNotEmpty) {
        parts.add(text);
      }
    }

    return parts.join(', ');
  }

  // ==========================================================
  // READ OWNER PROFILE LOCATION
  // ==========================================================
  //
  // Supports:
  //
  // latitude
  // longitude
  //
  // OR
  //
  // ownerLocation: GeoPoint
  //
  // OR
  //
  // ownerLocation: {
  //   latitude: ...
  //   longitude: ...
  // }
  // ==========================================================

  Position? _readOwnerProfilePosition(
    Map<String, dynamic> data,
  ) {
    // ========================================================
    // DIRECT LATITUDE / LONGITUDE
    // ========================================================

    final dynamic latitude =
        data['latitude'];

    final dynamic longitude =
        data['longitude'];

    if (latitude is num &&
        longitude is num) {
      return Position(
        longitude: longitude.toDouble(),
        latitude: latitude.toDouble(),
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    }

    // ========================================================
    // GEOPOINT / OWNER LOCATION
    // ========================================================

    final dynamic location =
        data['ownerLocation'];

    if (location is GeoPoint) {
      return Position(
        longitude: location.longitude,
        latitude: location.latitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    }

    // ========================================================
    // MAP LOCATION
    // ========================================================

    if (location is Map) {
      final dynamic lat =
          location['latitude'] ??
              location['lat'];

      final dynamic lng =
          location['longitude'] ??
              location['lng'] ??
              location['lon'];

      if (lat is num &&
          lng is num) {
        return Position(
          longitude: lng.toDouble(),
          latitude: lat.toDouble(),
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }
    }

    return null;
  }

  // ==========================================================
  // LOCATION FALLBACK
  // ==========================================================

  Future<Position?> _getLocation() async {
    try {
      // ======================================================
      // LOCATION SERVICE
      // ======================================================

      final bool enabled =
          await Geolocator
              .isLocationServiceEnabled();

      if (!enabled) {
        _message(
          'Please turn on location service.',
        );

        return null;
      }

      // ======================================================
      // PERMISSION
      // ======================================================

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission ==
          LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission ==
              LocationPermission.denied ||
          permission ==
              LocationPermission.deniedForever) {
        _message(
          'Location permission is required.',
        );

        return null;
      }

      // ======================================================
      // CURRENT GPS
      // ======================================================

      return await Geolocator.getCurrentPosition(
        desiredAccuracy:
            LocationAccuracy.high,
      );
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
