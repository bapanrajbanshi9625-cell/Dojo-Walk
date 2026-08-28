// File:
// lib/features/profile/services/profile_location_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';

class ProfileLocationService {
  ProfileLocationService._();

  static final ProfileLocationService instance =
      ProfileLocationService._();

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final geocoding.Geocoding _geocoding =
      geocoding.Geocoding();

  // ============================================================
  // CONNECT CURRENT LOCATION
  // ============================================================

  Future<Map<String, dynamic>> connectCurrentLocation() async {
    final User user = _requireCurrentUser();

    // ----------------------------------------------------------
    // LOCATION SERVICE
    // ----------------------------------------------------------

    final bool serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw const LocationServiceDisabledException();
    }

    // ----------------------------------------------------------
    // PERMISSION
    // ----------------------------------------------------------

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationPermissionDeniedException();
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationPermissionDeniedForeverException();
    }

    // ----------------------------------------------------------
    // CURRENT POSITION
    // ----------------------------------------------------------

    final Position position =
        await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    // ----------------------------------------------------------
    // REVERSE GEOCODING
    // ----------------------------------------------------------

    final List<geocoding.Placemark> placemarks =
        await _geocoding.placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isEmpty) {
      throw const AddressNotFoundException();
    }

    final geocoding.Placemark place =
        placemarks.first;

    // ----------------------------------------------------------
    // ADDRESS VALUES
    // ----------------------------------------------------------

    final String street =
        place.street?.trim() ?? '';

    final String subLocality =
        place.subLocality?.trim() ?? '';

    final String locality =
        place.locality?.trim() ?? '';

    final String subAdministrativeArea =
        place.subAdministrativeArea?.trim() ?? '';

    final String administrativeArea =
        place.administrativeArea?.trim() ?? '';

    final String postalCode =
        place.postalCode?.trim() ?? '';

    // ----------------------------------------------------------
    // AREA
    // ----------------------------------------------------------

    String area = '';

    if (subLocality.isNotEmpty) {
      area = subLocality;
    } else if (locality.isNotEmpty) {
      area = locality;
    }

    // ----------------------------------------------------------
    // CITY
    // ----------------------------------------------------------

    String city = '';

    if (locality.isNotEmpty) {
      city = locality;
    } else if (subAdministrativeArea.isNotEmpty) {
      city = subAdministrativeArea;
    }

    // ----------------------------------------------------------
    // FIND OWNER DOCUMENT
    // ----------------------------------------------------------

    final DocumentReference<Map<String, dynamic>> ownerRef =
        await _findOwnerDocument(
      uid: user.uid.trim(),
    );

    // ----------------------------------------------------------
    // ADDRESS STRING
    // ----------------------------------------------------------

    final List<String> addressParts = <String>[
      street,
      area,
      city,
      administrativeArea,
      postalCode,
    ]
        .where(
          (String value) => value.trim().isNotEmpty,
        )
        .map(
          (String value) => value.trim(),
        )
        .toList();

    final String fullAddress =
        addressParts.join(', ');

    // ----------------------------------------------------------
    // FIRESTORE DATA
    //
    // Existing profile fields are preserved.
    // ----------------------------------------------------------

    final Map<String, dynamic> locationData =
        <String, dynamic>{
      'latitude': position.latitude,
      'longitude': position.longitude,

      'addressLine1': street,
      'area': area,
      'city': city,
      'state': administrativeArea,
      'pincode': postalCode,

      'address': fullAddress,

      'locationUpdatedAt':
          FieldValue.serverTimestamp(),

      'updatedAt':
          FieldValue.serverTimestamp(),

      'authUid': user.uid,
    };

    // ----------------------------------------------------------
    // SAVE
    // ----------------------------------------------------------

    await ownerRef.set(
      locationData,
      SetOptions(
        merge: true,
      ),
    );

    // ----------------------------------------------------------
    // RETURN
    // ----------------------------------------------------------

    return <String, dynamic>{
      ...locationData,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'addressLine1': street,
      'area': area,
      'city': city,
      'state': administrativeArea,
      'pincode': postalCode,
      'address': fullAddress,
    };
  }

  // ============================================================
  // FIND OWNER DOCUMENT
  //
  // Priority:
  //
  // 1. owners/{Firebase UID}
  // 2. owners where authUid == Firebase UID
  //
  // ============================================================

  Future<DocumentReference<Map<String, dynamic>>>
      _findOwnerDocument({
    required String uid,
  }) async {
    final String cleanUid = uid.trim();

    if (cleanUid.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-auth-uid',
        message:
            'Firebase Auth UID was not found.',
      );
    }

    // ----------------------------------------------------------
    // FIRST: owners/{uid}
    // ----------------------------------------------------------

    final DocumentReference<Map<String, dynamic>> directRef =
        _firestore
            .collection('owners')
            .doc(cleanUid);

    final DocumentSnapshot<Map<String, dynamic>> directDoc =
        await directRef.get();

    if (directDoc.exists) {
      return directRef;
    }

    // ----------------------------------------------------------
    // SECOND: authUid QUERY
    // ----------------------------------------------------------

    final QuerySnapshot<Map<String, dynamic>> query =
        await _firestore
            .collection('owners')
            .where(
              'authUid',
              isEqualTo: cleanUid,
            )
            .limit(1)
            .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first.reference;
    }

    throw FirebaseException(
      plugin: 'cloud_firestore',
      code: 'owner-not-found',
      message:
          'Owner profile was not found.',
    );
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  User _requireCurrentUser() {
    final User? user =
        _auth.currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message:
            'User session was not found. Please login again.',
      );
    }

    return user;
  }

  // ============================================================
  // OPEN LOCATION SETTINGS
  // ============================================================

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  // ============================================================
  // OPEN APP SETTINGS
  // ============================================================

  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }
}

// ============================================================
// CUSTOM EXCEPTIONS
// ============================================================

class LocationPermissionDeniedException
    implements Exception {
  const LocationPermissionDeniedException();
}

class LocationPermissionDeniedForeverException
    implements Exception {
  const LocationPermissionDeniedForeverException();
}

class AddressNotFoundException
    implements Exception {
  const AddressNotFoundException();
}
