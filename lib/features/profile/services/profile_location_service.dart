// File:
// lib/features/profile/services/profile_location_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class ProfileLocationResult {
  final double latitude;
  final double longitude;

  const ProfileLocationResult({
    required this.latitude,
    required this.longitude,
  });
}

class ProfileLocationService {
  ProfileLocationService._();

  static final ProfileLocationService instance =
      ProfileLocationService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // CONNECT CURRENT LOCATION
  // ============================================================

  Future<ProfileLocationResult> connectCurrentLocation() async {
    // ----------------------------------------------------------
    // AUTH USER
    // ----------------------------------------------------------

    final User? user = _auth.currentUser;

    if (user == null) {
      throw const ProfileLocationException(
        'Your login session has expired. Please login again.',
      );
    }

    final String uid = user.uid.trim();

    if (uid.isEmpty) {
      throw const ProfileLocationException(
        'Firebase user ID was not found.',
      );
    }

    // ----------------------------------------------------------
    // LOCATION SERVICE
    // ----------------------------------------------------------

    final bool serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw const ProfileLocationServiceDisabledException();
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
      throw const ProfileLocationPermissionDeniedException();
    }

    if (permission == LocationPermission.deniedForever) {
      throw const ProfileLocationPermissionDeniedForeverException();
    }

    // ----------------------------------------------------------
    // GET CURRENT GPS POSITION
    // ----------------------------------------------------------

    final Position position =
        await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final double latitude = position.latitude;
    final double longitude = position.longitude;

    // ----------------------------------------------------------
    // FIND OWNER DOCUMENT
    // ----------------------------------------------------------

    final DocumentReference<Map<String, dynamic>>
        ownerRef = await _findOwnerDocument(uid);

    // ----------------------------------------------------------
    // SAVE LOCATION
    //
    // Existing owners document is preserved.
    // Only location fields are updated.
    // ----------------------------------------------------------

    await ownerRef.set(
      <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
        'locationConnected': true,
        'locationUpdatedAt':
            FieldValue.serverTimestamp(),
        'authUid': uid,
      },
      SetOptions(merge: true),
    );

    // ----------------------------------------------------------
    // RETURN RESULT
    // ----------------------------------------------------------

    return ProfileLocationResult(
      latitude: latitude,
      longitude: longitude,
    );
  }

  // ============================================================
  // FIND OWNER DOCUMENT
  //
  // Supported structures:
  //
  // 1. owners/{firebaseUid}
  //
  // 2. owners/{documentId}
  //      authUid: firebaseUid
  //
  // ============================================================

  Future<DocumentReference<Map<String, dynamic>>>
      _findOwnerDocument(
    String uid,
  ) async {
    final String cleanUid = uid.trim();

    if (cleanUid.isEmpty) {
      throw const ProfileLocationException(
        'Firebase user ID was not found.',
      );
    }

    // ----------------------------------------------------------
    // FIRST:
    // owners/{uid}
    // ----------------------------------------------------------

    final DocumentReference<Map<String, dynamic>>
        directRef =
        _firestore.collection('owners').doc(cleanUid);

    final DocumentSnapshot<Map<String, dynamic>>
        directDoc =
        await directRef.get();

    if (directDoc.exists) {
      return directRef;
    }

    // ----------------------------------------------------------
    // SECOND:
    // Search authUid
    // ----------------------------------------------------------

    final QuerySnapshot<Map<String, dynamic>>
        snapshot =
        await _firestore
            .collection('owners')
            .where(
              'authUid',
              isEqualTo: cleanUid,
            )
            .limit(1)
            .get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.reference;
    }

    // ----------------------------------------------------------
    // OWNER NOT FOUND
    // ----------------------------------------------------------

    throw const ProfileOwnerNotFoundException();
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

  // ============================================================
  // GET SAVED LOCATION
  // ============================================================

  Future<ProfileLocationResult?> getSavedLocation() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    final String uid = user.uid.trim();

    if (uid.isEmpty) {
      return null;
    }

    try {
      final DocumentReference<Map<String, dynamic>>
          ownerRef = await _findOwnerDocument(uid);

      final DocumentSnapshot<Map<String, dynamic>>
          snapshot = await ownerRef.get();

      if (!snapshot.exists) {
        return null;
      }

      final Map<String, dynamic>? data =
          snapshot.data();

      if (data == null) {
        return null;
      }

      final dynamic latitudeValue =
          data['latitude'];

      final dynamic longitudeValue =
          data['longitude'];

      if (latitudeValue is! num ||
          longitudeValue is! num) {
        return null;
      }

      return ProfileLocationResult(
        latitude: latitudeValue.toDouble(),
        longitude: longitudeValue.toDouble(),
      );
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // CHECK LOCATION CONNECTED
  // ============================================================

  Future<bool> isLocationConnected() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return false;
    }

    final String uid = user.uid.trim();

    if (uid.isEmpty) {
      return false;
    }

    try {
      final DocumentReference<Map<String, dynamic>>
          ownerRef = await _findOwnerDocument(uid);

      final DocumentSnapshot<Map<String, dynamic>>
          snapshot = await ownerRef.get();

      final Map<String, dynamic>? data =
          snapshot.data();

      if (data == null) {
        return false;
      }

      return data['locationConnected'] == true;
    } catch (_) {
      return false;
    }
  }
}

// ============================================================
// GENERAL PROFILE LOCATION EXCEPTION
// ============================================================

class ProfileLocationException
    implements Exception {
  final String message;

  const ProfileLocationException(
    this.message,
  );

  @override
  String toString() => message;
}

// ============================================================
// LOCATION SERVICE DISABLED
// ============================================================

class ProfileLocationServiceDisabledException
    extends ProfileLocationException {
  const ProfileLocationServiceDisabledException()
      : super(
          'Location service is turned off. Please turn on GPS and try again.',
        );
}

// ============================================================
// LOCATION PERMISSION DENIED
// ============================================================

class ProfileLocationPermissionDeniedException
    extends ProfileLocationException {
  const ProfileLocationPermissionDeniedException()
      : super(
          'Location permission is required to connect your current location.',
        );
}

// ============================================================
// LOCATION PERMISSION DENIED FOREVER
// ============================================================

class ProfileLocationPermissionDeniedForeverException
    extends ProfileLocationException {
  const ProfileLocationPermissionDeniedForeverException()
      : super(
          'Location permission is permanently denied. Please enable it from app settings.',
        );
}

// ============================================================
// OWNER NOT FOUND
// ============================================================

class ProfileOwnerNotFoundException
    extends ProfileLocationException {
  const ProfileOwnerNotFoundException()
      : super(
          'Owner profile was not found.',
        );
}
