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
// Find ownerProfiles/{owner}
//        ↓
// Check savedAddresses[]
//        ↓
// ┌───────────────┐
// │ Address found │
// └───────┬───────┘
//         ↓
//   Start Walker Search
//
// If no saved address:
//        ↓
// Choose Walking Address
//        ↓
// Save Address
//        ↓
// Reload ownerProfiles
//        ↓
// Start Walker Search
//
// IMPORTANT:
// savedAddresses is the PRIMARY address source.
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

      Map<String, dynamic> data =
          ownerDoc.data() ??
              <String, dynamic>{};

      // ========================================================
      // PROFILE COMPLETION
      //
      // Address is NOT required for profile completion.
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
          'displayName',
        ],
      );

      if (ownerName.isEmpty) {
        ownerName = 'Dog Owner';
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
      //
      // IMPORTANT:
      // savedAddresses[] is checked FIRST.
      // ========================================================

      Map<String, dynamic>? selectedSavedAddress =
          _getSavedAddress(data);

      String address = '';

      Position? position;

      // ========================================================
      // SAVED ADDRESS FOUND
      // ========================================================

      if (selectedSavedAddress != null) {
        address =
            _buildSavedAddress(
          selectedSavedAddress,
        );

        position =
            _readSavedAddressPosition(
          selectedSavedAddress,
        );

        debugPrint(
          '✅ InstaWalk: saved address found.',
        );

        debugPrint(
          '📍 InstaWalk address: $address',
        );
      }

      // ========================================================
      // FALLBACK:
      // OLD PROFILE ADDRESS
      //
      // This keeps compatibility with older owner profiles.
      // ========================================================

      if (address.isEmpty) {
        address =
            _readFirstString(
          data,
          const [
            'address',
            'Adress',
            'Address',
          ],
        );
      }

      // ========================================================
      // FALLBACK:
      // STRUCTURED OWNER PROFILE ADDRESS
      // ========================================================

      if (address.isEmpty) {
        address =
            _buildAddressFromProfile(
          data,
        );
      }

      // ========================================================
      // FALLBACK:
      // PROFILE LOCATION
      // ========================================================

      if (position == null) {
        position =
            _readOwnerProfilePosition(
          data,
        );
      }

      // ========================================================
      // NO ADDRESS
      //
      // ONLY NOW open AddressScreen.
      // ========================================================

      if (address.isEmpty) {
        debugPrint(
          '⚠️ InstaWalk: no saved address found.',
        );

        _updateState(() {
          _checkingAddress = false;
        });

        await Navigator.of(context).push(
          MaterialPageRoute<dynamic>(
            builder: (_) =>
                const AddressScreen(),
          ),
        );

        if (!mounted) {
          return;
        }

        // ======================================================
        // RELOAD OWNER PROFILE
        // ======================================================

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

        data =
            updatedOwnerDoc.data() ??
                <String, dynamic>{};

        // ======================================================
        // READ SAVED ADDRESS AGAIN
        // ======================================================

        selectedSavedAddress =
            _getSavedAddress(data);

        address = '';

        position = null;

        if (selectedSavedAddress != null) {
          address =
              _buildSavedAddress(
            selectedSavedAddress,
          );

          position =
              _readSavedAddressPosition(
            selectedSavedAddress,
          );

          debugPrint(
            '✅ InstaWalk: address found after returning from AddressScreen.',
          );
        }

        // ======================================================
        // PROFILE ADDRESS FALLBACK
        // ======================================================

        if (address.isEmpty) {
          address =
              _readFirstString(
            data,
            const [
              'address',
              'Adress',
              'Address',
            ],
          );
        }

        if (address.isEmpty) {
          address =
              _buildAddressFromProfile(
            data,
          );
        }

        // ======================================================
        // PROFILE LOCATION FALLBACK
        // ======================================================

        if (position == null) {
          position =
              _readOwnerProfilePosition(
            data,
          );
        }

        // ======================================================
        // STILL NO ADDRESS
        // ======================================================

        if (address.isEmpty) {
          _updateState(() {
            _checkingAddress = false;
          });

          _message(
            'Please save your address before starting Insta Walk.',
          );

          return;
        }

        // ======================================================
        // CONTINUE SEARCH
        // ======================================================

        _updateState(() {
          _checkingAddress = true;
          _searchFinished = false;
        });
      }

      // ========================================================
      // LOCATION
      //
      // Saved address coordinates first.
      // Profile coordinates second.
      // GPS only as final fallback.
      // ========================================================

      if (position == null) {
        debugPrint(
          '⚠️ InstaWalk: saved address has no coordinates.',
        );

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
  //
  // savedAddresses is expected to be:
  //
  // [
  //   {
  //     id: address_1,
  //     title: Home,
  //     address: ...,
  //     flatNumber: ...,
  //     addressLine1: ...,
  //     area: ...,
  //     city: ...,
  //     state: ...,
  //     pincode: ...,
  //     latitude: ...,
  //     longitude: ...
  //   }
  // ]
  //
  // First valid saved address is used.
  // ==========================================================

  Map<String, dynamic>? _getSavedAddress(
    Map<String, dynamic> data,
  ) {
    final dynamic saved =
        data['savedAddresses'];

    if (saved is! List ||
        saved.isEmpty) {
      return null;
    }

    for (final dynamic item in saved) {
      if (item is Map) {
        final Map<String, dynamic> address =
            Map<String, dynamic>.from(
          item,
        );

        final String fullAddress =
            _buildSavedAddress(
          address,
        );

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
    // ========================================================
    // PREFERRED:
    // Already combined address
    // ========================================================

    final String combined =
        _readFirstString(
      data,
      const [
        'address',
        'fullAddress',
        'formattedAddress',
      ],
    );

    if (combined.isNotEmpty) {
      return combined;
    }

    // ========================================================
    // STRUCTURED ADDRESS
    // ========================================================

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
      'Pincode',
    ];

    for (final String key in keys) {
      final dynamic value =
          data[key];

      if (value == null) {
        continue;
      }

      final String text =
          value.toString().trim();

      if (text.isNotEmpty &&
          !parts.contains(text)) {
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

    final dynamic latitude =
        data['latitude'];

    final dynamic longitude =
        data['longitude'];

    if (latitude is num &&
        longitude is num) {
      return Position(
        longitude:
            longitude.toDouble(),
        latitude:
            latitude.toDouble(),
        timestamp:
            DateTime.now(),
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
    // GEOPOINT
    // ========================================================

    final dynamic location =
        data['location'];

    if (location is GeoPoint) {
      return Position(
        longitude:
            location.longitude,
        latitude:
            location.latitude,
        timestamp:
            DateTime.now(),
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
    // ownerLocation
    // ========================================================

    final dynamic ownerLocation =
        data['ownerLocation'];

    if (ownerLocation is GeoPoint) {
      return Position(
        longitude:
            ownerLocation.longitude,
        latitude:
            ownerLocation.latitude,
        timestamp:
            DateTime.now(),
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
          longitude:
              lng.toDouble(),
          latitude:
              lat.toDouble(),
          timestamp:
              DateTime.now(),
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

    // ========================================================
    // ownerLocation MAP
    // ========================================================

    if (ownerLocation is Map) {
      final dynamic lat =
          ownerLocation['latitude'] ??
              ownerLocation['lat'];

      final dynamic lng =
          ownerLocation['longitude'] ??
              ownerLocation['lng'] ??
              ownerLocation['lon'];

      if (lat is num &&
          lng is num) {
        return Position(
          longitude:
              lng.toDouble(),
          latitude:
              lat.toDouble(),
          timestamp:
              DateTime.now(),
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
  // BUILD ADDRESS FROM OWNER PROFILE
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
      'Pincode',
    ];

    for (final String key in keys) {
      final dynamic value =
          data[key];

      if (value == null) {
        continue;
      }

      final String text =
          value.toString().trim();

      if (text.isNotEmpty &&
          !parts.contains(text)) {
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

    final dynamic latitude =
        data['latitude'];

    final dynamic longitude =
        data['longitude'];

    if (latitude is num &&
        longitude is num) {
      return Position(
        longitude:
            longitude.toDouble(),
        latitude:
            latitude.toDouble(),
        timestamp:
            DateTime.now(),
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
    // ownerLocation GeoPoint
    // ========================================================

    final dynamic location =
        data['ownerLocation'];

    if (location is GeoPoint) {
      return Position(
        longitude:
            location.longitude,
        latitude:
            location.latitude,
        timestamp:
            DateTime.now(),
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
    // ownerLocation MAP
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
          longitude:
              lng.toDouble(),
          latitude:
              lat.toDouble(),
          timestamp:
              DateTime.now(),
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
        '❌ InstaWalk location error: $e',
      );

      _message(
        'Unable to get your current location.',
      );

      return null;
    }
  }
}
