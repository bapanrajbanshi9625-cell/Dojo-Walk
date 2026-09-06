// File:
// lib/features/insta_walk/widgets/insta_walk_find_walker.dart

part of '../controllers/insta_walk_container.dart';

// ============================================================
// FIND WALKER
// ============================================================
//
// OWNER-SIDE INSTA WALK
//
// ADDRESS / LOCATION FLOW:
//
// Find Walker
//      ↓
// owners/{owner}
//      ↓
// Read saved address + coordinates
//      ↓
// Address + GeoPoint available?
//      ↓ YES
// Start Insta Walk Search
//
// If address is missing:
//      ↓
// AddressScreen
//      ↓
// Reload owners/{owner}
//      ↓
// Start Search
//
// IMPORTANT:
//
// InstaWalkContainer NEVER fetches GPS.
//
// Supported location sources:
//
// 1. owners.latitude + longitude
// 2. owners.location (GeoPoint / Map)
// 3. owners.ownerLocation (GeoPoint / Map)
// 4. savedAddresses[].latitude + longitude
// 5. savedAddresses[].location
// 6. savedAddresses[].ownerLocation
//
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
          dogName.isEmpty ? 'Your Pet' : dogName;

      // ========================================================
      // READ ADDRESS
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

      // ========================================================
      // READ LOCATION
      // ========================================================

      GeoPoint? ownerLocation =
          _readOwnerProfileLocation(data);

      // ========================================================
      // DIRECT OWNER ADDRESS
      // ========================================================

      if (address.isNotEmpty) {
        debugPrint(
          '✅ InstaWalk: owners address found.',
        );

        debugPrint(
          '📍 address = $address',
        );

        if (ownerLocation != null) {
          debugPrint(
            '📍 owners coordinates found.',
          );

          debugPrint(
            'latitude = ${ownerLocation.latitude}',
          );

          debugPrint(
            'longitude = ${ownerLocation.longitude}',
          );
        }
      }

      // ========================================================
      // SAVED ADDRESS FALLBACK
      // ========================================================

      Map<String, dynamic>? selectedSavedAddress;

      if (address.isEmpty ||
          ownerLocation == null) {
        selectedSavedAddress =
            _getSavedAddress(data);

        if (selectedSavedAddress != null) {
          final String savedAddress =
              _buildSavedAddress(
            selectedSavedAddress,
          );

          final GeoPoint? savedLocation =
              _readSavedAddressLocation(
            selectedSavedAddress,
          );

          if (address.isEmpty &&
              savedAddress.isNotEmpty) {
            address = savedAddress;
          }

          if (ownerLocation == null &&
              savedLocation != null) {
            ownerLocation = savedLocation;
          }

          if (address.isNotEmpty) {
            debugPrint(
              '✅ InstaWalk: saved address available.',
            );
          }

          if (ownerLocation != null) {
            debugPrint(
              '📍 InstaWalk: saved address coordinates available.',
            );
          }
        }
      }

      // ========================================================
      // STRUCTURED ADDRESS FALLBACK
      // ========================================================

      if (address.isEmpty) {
        address = _buildAddressFromProfile(data);

        if (address.isNotEmpty) {
          debugPrint(
            '✅ InstaWalk: structured address found.',
          );
        }
      }

      // ========================================================
      // LOCATION FALLBACK AGAIN
      // ========================================================

      if (ownerLocation == null) {
        ownerLocation =
            _readOwnerProfileLocation(data);
      }

      // ========================================================
      // ADDRESS SCREEN
      //
      // Open AddressScreen when address OR location is missing.
      //
      // NO GPS FALLBACK.
      // ========================================================

      if (address.isEmpty ||
          ownerLocation == null) {
        debugPrint(
          '⚠️ InstaWalk: address/location incomplete.',
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

        ownerDoc =
            await _service.findOwnerProfile();

        if (!mounted) {
          return;
        }

        if (ownerDoc == null ||
            !ownerDoc.exists) {
          _message(
            'Unable to reload owner address.',
          );

          return;
        }

        data =
            ownerDoc.data() ??
                <String, dynamic>{};

        // ======================================================
        // RELOAD ADDRESS
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

        // ======================================================
        // RELOAD LOCATION
        // ========================================================

        ownerLocation =
            _readOwnerProfileLocation(data);

        // ======================================================
        // SAVED ADDRESS FALLBACK
        // ========================================================

        if (address.isEmpty ||
            ownerLocation == null) {
          selectedSavedAddress =
              _getSavedAddress(data);

          if (selectedSavedAddress != null) {
            if (address.isEmpty) {
              address = _buildSavedAddress(
                selectedSavedAddress,
              );
            }

            if (ownerLocation == null) {
              ownerLocation =
                  _readSavedAddressLocation(
                selectedSavedAddress,
              );
            }
          }
        }

        // ======================================================
        // STRUCTURED ADDRESS FALLBACK
        // ======================================================

        if (address.isEmpty) {
          address =
              _buildAddressFromProfile(data);
        }

        // ======================================================
        // STILL INCOMPLETE
        // ========================================================

        if (address.isEmpty) {
          _updateState(() {
            _checkingAddress = false;
          });

          _message(
            'Please save your walking address before starting Insta Walk.',
          );

          return;
        }

        if (ownerLocation == null) {
          _updateState(() {
            _checkingAddress = false;
          });

          _message(
            'Your saved address is missing location coordinates. Please choose your walking address again.',
          );

          return;
        }

        debugPrint(
          '✅ InstaWalk: address and location restored.',
        );

        _updateState(() {
          _checkingAddress = true;
          _searchFinished = false;
        });
      }

      // ========================================================
      // FINAL LOCATION CHECK
      //
      // There is intentionally NO GPS fallback here.
      //
      // ownerLocation is guaranteed to be non-null after the
      // address/location flow above.
      // ========================================================

      // ========================================================
      // FINAL DEBUG
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
        'latitude = ${ownerLocation.latitude}',
      );
      debugPrint(
        'longitude = ${ownerLocation.longitude}',
      );
      debugPrint(
        'dogName = $dogName',
      );
      debugPrint(
        'dogBreed = $dogBreed',
      );

      // ========================================================
      // START SEARCH
      // ========================================================

      await _startSearch(
        ownerId: ownerId,
        ownerName: ownerName,
        address: address,
        ownerLocation: ownerLocation,
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
    final dynamic saved =
        data['savedAddresses'];

    if (saved is! List ||
        saved.isEmpty) {
      return null;
    }

    // ----------------------------------------------------------
    // Prefer selected/default address if available.
    // ----------------------------------------------------------

    for (final dynamic item in saved) {
      if (item is Map) {
        final Map<String, dynamic> address =
            Map<String, dynamic>.from(item);

        final dynamic selected =
            address['selected'] ??
            address['isSelected'] ??
            address['default'] ??
            address['isDefault'];

        if (selected == true) {
          final String text =
              _buildSavedAddress(address);

          if (text.isNotEmpty) {
            return address;
          }
        }
      }
    }

    // ----------------------------------------------------------
    // Otherwise use first valid saved address.
    // ----------------------------------------------------------

    for (final dynamic item in saved) {
      if (item is Map) {
        final Map<String, dynamic> address =
            Map<String, dynamic>.from(item);

        final String text =
            _buildSavedAddress(address);

        if (text.isNotEmpty) {
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
    final String combined =
        _readFirstString(
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

    final List<String> parts =
        <String>[];

    const List<String> keys =
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
  // READ SAVED ADDRESS LOCATION
  // ==========================================================

  GeoPoint? _readSavedAddressLocation(
    Map<String, dynamic> data,
  ) {
    // ========================================================
    // LATITUDE + LONGITUDE
    // ========================================================

    final dynamic latitude =
        data['latitude'];

    final dynamic longitude =
        data['longitude'];

    if (latitude is num &&
        longitude is num) {
      return _geoPointFromCoordinates(
        latitude.toDouble(),
        longitude.toDouble(),
      );
    }

    // ========================================================
    // LOCATION
    // ========================================================

    final dynamic location =
        data['location'];

    final GeoPoint? locationPoint =
        _geoPointFromValue(location);

    if (locationPoint != null) {
      return locationPoint;
    }

    // ========================================================
    // OWNER LOCATION
    // ========================================================

    final dynamic ownerLocation =
        data['ownerLocation'];

    final GeoPoint? ownerPoint =
        _geoPointFromValue(
      ownerLocation,
    );

    if (ownerPoint != null) {
      return ownerPoint;
    }

    return null;
  }

  // ==========================================================
  // READ OWNER PROFILE LOCATION
  // ==========================================================

  GeoPoint? _readOwnerProfileLocation(
    Map<String, dynamic> data,
  ) {
    // ========================================================
    // DIRECT LATITUDE + LONGITUDE
    // ========================================================

    final dynamic latitude =
        data['latitude'];

    final dynamic longitude =
        data['longitude'];

    if (latitude is num &&
        longitude is num) {
      return _geoPointFromCoordinates(
        latitude.toDouble(),
        longitude.toDouble(),
      );
    }

    // ========================================================
    // LOCATION
    // ========================================================

    final GeoPoint? location =
        _geoPointFromValue(
      data['location'],
    );

    if (location != null) {
      return location;
    }

    // ========================================================
    // OWNER LOCATION
    // ========================================================

    final GeoPoint? ownerLocation =
        _geoPointFromValue(
      data['ownerLocation'],
    );

    if (ownerLocation != null) {
      return ownerLocation;
    }

    return null;
  }

  // ==========================================================
  // GEOPOINT FROM VALUE
  // ==========================================================

  GeoPoint? _geoPointFromValue(
    dynamic value,
  ) {
    // --------------------------------------------------------
    // Firestore GeoPoint
    // --------------------------------------------------------

    if (value is GeoPoint) {
      return value;
    }

    // --------------------------------------------------------
    // Map
    // --------------------------------------------------------

    if (value is Map) {
      final dynamic latitude =
          value['latitude'] ??
          value['lat'];

      final dynamic longitude =
          value['longitude'] ??
          value['lng'] ??
          value['lon'];

      if (latitude is num &&
          longitude is num) {
        return _geoPointFromCoordinates(
          latitude.toDouble(),
          longitude.toDouble(),
        );
      }
    }

    return null;
  }

  // ==========================================================
  // GEOPOINT FROM COORDINATES
  // ==========================================================

  GeoPoint _geoPointFromCoordinates(
    double latitude,
    double longitude,
  ) {
    return GeoPoint(
      latitude,
      longitude,
    );
  }

  // ==========================================================
  // BUILD ADDRESS FROM PROFILE
  // ==========================================================

  String _buildAddressFromProfile(
    Map<String, dynamic> data,
  ) {
    final List<String> parts =
        <String>[];

    const List<String> keys =
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
}
