part of '../controllers/insta_walk_container.dart';

// ============================================================
// FIND WALKER
// ============================================================
//
// OWNER-SIDE INSTA WALK
//
// ADDRESS FLOW:
//
// Find a Walker Now
//        ↓
// Find owners/{owner}
//        ↓
// Check direct owner address
//        ↓
// ┌─────────────────────┐
// │ Address found       │
// └──────────┬──────────┘
//            ↓
//     Start Walker Search
//
// If no address:
//        ↓
// Choose Walking Address
//        ↓
// Save Address
//        ↓
// Reload owners/{owner}
//        ↓
// Start Walker Search
//
// IMPORTANT:
// The `owners` collection is the PRIMARY source.
//
// Supported direct address fields:
// - address
// - addressLine1
// - area
// - city
// - state
// - pincode
// - latitude
// - longitude
// - location
//
// `savedAddresses[]` remains supported as a fallback.
// ============================================================

extension _FindWalkerRole on _InstaWalkContainerState {
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

    final User? user = FirebaseAuth.instance.currentUser;

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
      //
      // InstaWalkSearchService already reads:
      // owners.where(authUid == currentUser.uid)
      // ========================================================

      DocumentSnapshot<Map<String, dynamic>>? ownerDoc =
          await _service.findOwnerProfile();

      if (!mounted) {
        return;
      }

      if (ownerDoc == null || !ownerDoc.exists) {
        _updateState(() {
          _checkingAddress = false;
        });

        _message(
          'Owner profile not found. Please complete your profile.',
        );

        return;
      }

      Map<String, dynamic> data =
          ownerDoc.data() ?? <String, dynamic>{};

      // ========================================================
      // PROFILE COMPLETION
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

      String ownerId = _readFirstString(
        data,
        const [
          'ownerId',
          'Owner ID',
          'id',
        ],
      );

      if (ownerId.isEmpty) {
        ownerId = user.uid;
      }

      // ========================================================
      // OWNER NAME
      // ========================================================

      String ownerName = _readFirstString(
        data,
        const [
          'ownerName',
          'fullName',
          'Full Name',
          'name',
          'displayName',
        ],
      );

      if (ownerName.isEmpty) {
        ownerName = 'Dog Owner';
      }

      // ========================================================
      // PET / DOG DATA
      // ========================================================

      String dogName = _readFirstString(
        data,
        const [
          'dogName',
          'petName',
          'Dog Name',
          'Pet Name',
        ],
      );

      String dogBreed = _readFirstString(
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

      final dynamic pets = data['pets'];

      if (pets is List && pets.isNotEmpty) {
        final dynamic firstPet = pets.first;

        if (firstPet is Map) {
          if (dogName.isEmpty) {
            final dynamic petName =
                firstPet['name'] ??
                firstPet['petName'] ??
                firstPet['dogName'];

            if (petName != null) {
              final String value = petName.toString().trim();

              if (value.isNotEmpty) {
                dogName = value;
              }
            }
          }

          if (dogBreed.isEmpty) {
            final dynamic petBreed =
                firstPet['breed'] ??
                firstPet['petBreed'] ??
                firstPet['dogBreed'];

            if (petBreed != null) {
              final String value = petBreed.toString().trim();

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

      _petName = dogName.isEmpty ? 'Your Pet' : dogName;

      // ========================================================
      // ADDRESS
      //
      // IMPORTANT:
      //
      // `owners.address` is now checked FIRST.
      //
      // This matches the actual Firestore structure.
      // ========================================================

      String address = _readFirstString(
        data,
        const [
          'address',
          'fullAddress',
          'formattedAddress',
          'Adress',
          'Address',
        ],
      );

      Position? position;

      // ========================================================
      // DIRECT OWNER ADDRESS FOUND
      // ========================================================

      if (address.isNotEmpty) {
        debugPrint(
          '✅ InstaWalk: direct owners.address found.',
        );

        debugPrint(
          '📍 InstaWalk address: $address',
        );

        // ------------------------------------------------------
        // Read coordinates directly from owners document.
        // ------------------------------------------------------

        position = _readOwnerProfilePosition(data);

        if (position != null) {
          debugPrint(
            '📍 InstaWalk: owner coordinates found.',
          );

          debugPrint(
            'latitude = ${position.latitude}',
          );

          debugPrint(
            'longitude = ${position.longitude}',
          );
        }
      }

      // ========================================================
      // SAVED ADDRESS ARRAY FALLBACK
      // ========================================================

      Map<String, dynamic>? selectedSavedAddress;

      if (address.isEmpty) {
        selectedSavedAddress = _getSavedAddress(data);

        if (selectedSavedAddress != null) {
          address = _buildSavedAddress(
            selectedSavedAddress,
          );

          position = _readSavedAddressPosition(
            selectedSavedAddress,
          );

          debugPrint(
            '✅ InstaWalk: savedAddresses[] address found.',
          );

          debugPrint(
            '📍 InstaWalk address: $address',
          );
        }
      }

      // ========================================================
      // STRUCTURED PROFILE ADDRESS FALLBACK
      // ========================================================

      if (address.isEmpty) {
        address = _buildAddressFromProfile(data);

        if (address.isNotEmpty) {
          debugPrint(
            '✅ InstaWalk: structured owner address found.',
          );
        }
      }

      // ========================================================
      // PROFILE LOCATION FALLBACK
      // ========================================================

      if (position == null) {
        position = _readOwnerProfilePosition(data);
      }

      // ========================================================
      // NO ADDRESS
      //
      // ONLY NOW open AddressScreen.
      // ========================================================

      if (address.isEmpty) {
        debugPrint(
          '⚠️ InstaWalk: NO owner address found.',
        );

        _updateState(() {
          _checkingAddress = false;
        });

        await Navigator.of(context).push(
          MaterialPageRoute<dynamic>(
            builder: (_) => const AddressScreen(),
          ),
        );

        if (!mounted) {
          return;
        }

        // ======================================================
        // RELOAD OWNER PROFILE
        // ======================================================

        ownerDoc = await _service.findOwnerProfile();

        if (!mounted) {
          return;
        }

        if (ownerDoc == null || !ownerDoc.exists) {
          _message(
            'Unable to reload owner address.',
          );

          return;
        }

        data = ownerDoc.data() ?? <String, dynamic>{};

        // ======================================================
        // CHECK DIRECT OWNER ADDRESS AGAIN
        // ======================================================

        address = _readFirstString(
          data,
          const [
            'address',
            'fullAddress',
            'formattedAddress',
            'Adress',
            'Address',
          ],
        );

        position = _readOwnerProfilePosition(data);

        // ======================================================
        // SAVED ADDRESS ARRAY FALLBACK
        // ========================================================

        if (address.isEmpty) {
          selectedSavedAddress = _getSavedAddress(data);

          if (selectedSavedAddress != null) {
            address = _buildSavedAddress(
              selectedSavedAddress,
            );

            if (position == null) {
              position = _readSavedAddressPosition(
                selectedSavedAddress,
              );
            }
          }
        }

        // ======================================================
        // STRUCTURED ADDRESS FALLBACK
        // ========================================================

        if (address.isEmpty) {
          address = _buildAddressFromProfile(data);
        }

        // ======================================================
        // STILL NO ADDRESS
        // ========================================================

        if (address.isEmpty) {
          _updateState(() {
            _checkingAddress = false;
          });

          _message(
            'Please save your address before starting Insta Walk.',
          );

          return;
        }

        debugPrint(
          '✅ InstaWalk: address available after AddressScreen.',
        );

        // ======================================================
        // CONTINUE SEARCH
        // ========================================================

        _updateState(() {
          _checkingAddress = true;
          _searchFinished = false;
        });
      }

      // ========================================================
      // LOCATION
      //
      // Priority:
      //
      // 1. owners.latitude + longitude
      // 2. owners.location
      // 3. savedAddresses coordinates
      // 4. GPS
      // ========================================================

      if (position == null) {
        debugPrint(
          '⚠️ InstaWalk: address exists but coordinates missing.',
        );

        position = await _getLocation();
      }

      if (!mounted) {
        return;
      }

      if (position == null) {
        _updateState(() {
          _checkingAddress = false;
        });

        _message(
          'Unable to get your walking location.',
        );

        return;
      }

      // ========================================================
      // SAVE OWNER POSITION
      // ========================================================

      _ownerPosition = position;

      // ========================================================
      // START SEARCH
      // ========================================================

      debugPrint('');
      debugPrint(
        '==============================================',
      );
      debugPrint(
        '🚀 INSTA WALK SEARCH STARTING',
      );
      debugPrint(
        '==============================================',
      );
      debugPrint(
        'ownerId = $ownerId',
      );
      debugPrint(
        'ownerName = $ownerName',
      );
      debugPrint(
        'address = $address',
      );
      debugPrint(
        'latitude = ${position.latitude}',
      );
      debugPrint(
        'longitude = ${position.longitude}',
      );
      debugPrint(
        'dogName = $dogName',
      );
      debugPrint(
        'dogBreed = $dogBreed',
      );

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
        '❌ InstaWalk Firebase error: '
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
        '❌ InstaWalk start error: $e',
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
  // GET SAVED ADDRESS
  // ==========================================================

  Map<String, dynamic>? _getSavedAddress(
    Map<String, dynamic> data,
  ) {
    final dynamic saved = data['savedAddresses'];

    if (saved is! List || saved.isEmpty) {
      return null;
    }

    for (final dynamic item in saved) {
      if (item is Map) {
        final Map<String, dynamic> address =
            Map<String, dynamic>.from(item);

        final String fullAddress =
            _buildSavedAddress(address);

        if (fullAddress.isNotEmpty) {
          return address;
        }
      }
    }

    return null;
  }

  // ==========================================================
  // BUILD SAVED ADDRESS
  // ==========================================================

  String _buildSavedAddress(
    Map<String, dynamic> data,
  ) {
    final String combined = _readFirstString(
      data,
      const [
        'address',
        'fullAddress',
        'formattedAddress',
        'Adress',
        'Address',
      ],
    );

    if (combined.isNotEmpty) {
      return combined;
    }

    final List<String> parts = <String>[];

    const List<String> keys = <String>[
      'flatNumber',
      'addressLine1',
      'addressLine2',
      'area',
      'city',
      'state',
      'pincode',
      'Pincode',
    ];

    for (final String key in keys) {
      final dynamic value = data[key];

      if (value == null) {
        continue;
      }

      final String text = value.toString().trim();

      if (text.isNotEmpty && !parts.contains(text)) {
        parts.add(text);
      }
    }

    return parts.join(', ');
  }

  // ==========================================================
  // READ SAVED ADDRESS POSITION
  // ==========================================================

  Position? _readSavedAddressPosition(
    Map<String, dynamic> data,
  ) {
    // ========================================================
    // DIRECT LATITUDE / LONGITUDE
    // ========================================================

    final dynamic latitude = data['latitude'];
    final dynamic longitude = data['longitude'];

    if (latitude is num && longitude is num) {
      return _positionFromCoordinates(
        latitude.toDouble(),
        longitude.toDouble(),
      );
    }

    // ========================================================
    // GEOPOINT LOCATION
    // ========================================================

    final dynamic location = data['location'];

    if (location is GeoPoint) {
      return _positionFromCoordinates(
        location.latitude,
        location.longitude,
      );
    }

    // ========================================================
    // OWNER LOCATION
    // ========================================================

    final dynamic ownerLocation = data['ownerLocation'];

    if (ownerLocation is GeoPoint) {
      return _positionFromCoordinates(
        ownerLocation.latitude,
        ownerLocation.longitude,
      );
    }

    // ========================================================
    // MAP LOCATION
    // ========================================================

    if (location is Map) {
      final dynamic lat =
          location['latitude'] ?? location['lat'];

      final dynamic lng =
          location['longitude'] ??
          location['lng'] ??
          location['lon'];

      if (lat is num && lng is num) {
        return _positionFromCoordinates(
          lat.toDouble(),
          lng.toDouble(),
        );
      }
    }

    // ========================================================
    // OWNER LOCATION MAP
    // ========================================================

    if (ownerLocation is Map) {
      final dynamic lat =
          ownerLocation['latitude'] ??
          ownerLocation['lat'];

      final dynamic lng =
          ownerLocation['longitude'] ??
          ownerLocation['lng'] ??
          ownerLocation['lon'];

      if (lat is num && lng is num) {
        return _positionFromCoordinates(
          lat.toDouble(),
          lng.toDouble(),
        );
      }
    }

    return null;
  }

  // ==========================================================
  // POSITION FROM COORDINATES
  // ==========================================================

  Position _positionFromCoordinates(
    double latitude,
    double longitude,
  ) {
    return Position(
      longitude: longitude,
      latitude: latitude,
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

  // ==========================================================
  // BUILD ADDRESS FROM OWNER PROFILE
  // ==========================================================

  String _buildAddressFromProfile(
    Map<String, dynamic> data,
  ) {
    final List<String> parts = <String>[];

    const List<String> keys = <String>[
      'flatNumber',
      'addressLine1',
      'addressLine2',
      'area',
      'city',
      'state',
      'pincode',
      'Pincode',
    ];

    for (final String key in keys) {
      final dynamic value = data[key];

      if (value == null) {
        continue;
      }

      final String text = value.toString().trim();

      if (text.isNotEmpty && !parts.contains(text)) {
        parts.add(text);
      }
    }

    return parts.join(', ');
  }

  // ==========================================================
  // READ OWNER PROFILE LOCATION
  // ==========================================================

  Position? _readOwnerProfilePosition(
    Map<String, dynamic> data,
  ) {
    // ========================================================
    // DIRECT LATITUDE / LONGITUDE
    // ========================================================

    final dynamic latitude = data['latitude'];
    final dynamic longitude = data['longitude'];

    if (latitude is num && longitude is num) {
      return _positionFromCoordinates(
        latitude.toDouble(),
        longitude.toDouble(),
      );
    }

    // ========================================================
    // LOCATION MAP
    // ========================================================

    final dynamic location = data['location'];

    if (location is GeoPoint) {
      return _positionFromCoordinates(
        location.latitude,
        location.longitude,
      );
    }

    if (location is Map) {
      final dynamic lat =
          location['latitude'] ?? location['lat'];

      final dynamic lng =
          location['longitude'] ??
          location['lng'] ??
          location['lon'];

      if (lat is num && lng is num) {
        return _positionFromCoordinates(
          lat.toDouble(),
          lng.toDouble(),
        );
      }
    }

    // ========================================================
    // OWNER LOCATION
    // ========================================================

    final dynamic ownerLocation = data['ownerLocation'];

    if (ownerLocation is GeoPoint) {
      return _positionFromCoordinates(
        ownerLocation.latitude,
        ownerLocation.longitude,
      );
    }

    if (ownerLocation is Map) {
      final dynamic lat =
          ownerLocation['latitude'] ??
          ownerLocation['lat'];

      final dynamic lng =
          ownerLocation['longitude'] ??
          ownerLocation['lng'] ??
          ownerLocation['lon'];

      if (lat is num && lng is num) {
        return _positionFromCoordinates(
          lat.toDouble(),
          lng.toDouble(),
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
          await Geolocator.isLocationServiceEnabled();

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

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _message(
          'Location permission is required.',
        );

        return null;
      }

      // ======================================================
      // CURRENT GPS
      // ======================================================

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint(
        '❌ InstaWalk location error: $e',
      );

      _message(
        'Unable to get your current location.',
      );

      return null;
    }
  }
}
