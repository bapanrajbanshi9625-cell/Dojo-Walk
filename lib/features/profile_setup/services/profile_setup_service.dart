// File:
// lib/features/profile_setup/services/profile_setup_service.dart

import 'dart:developer' as developer;
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';

import '../../../models/pet_data.dart';
import '../../../services/owner_id_service.dart';

/// ============================================================
/// PROFILE SETUP SERVICE
/// ============================================================
///
/// Owner profile flow:
///
/// Firebase Auth UID
///       ↓
/// phoneAccounts/{uid}
///       ↓
/// OwnerIdService
///       ↓
/// owners/{ownerId}
///       ↓
/// profileCompleted = true
///
/// ============================================================

class ProfileSetupService {
  ProfileSetupService._();

  static final ProfileSetupService instance =
      ProfileSetupService._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static final FirebaseStorage _storage =
      FirebaseStorage.instance;

  // ============================================================
  // COLLECTIONS
  // ============================================================

  static const String _ownersCollection = 'owners';

  static const String _phoneAccountsCollection =
      'phoneAccounts';

  // ============================================================
  // STORAGE
  // ============================================================

  static const String _ownerProfilePhotosFolder =
      'owner_profile_photos';

  // ============================================================
  // LIMITS
  // ============================================================

  static const int maximumPets = 3;

  // ============================================================
  // NORMALIZE PHONE
  // ============================================================

  static String _normalizePhone(
    String phoneNumber,
  ) {
    final String raw = phoneNumber.trim();

    if (raw.isEmpty) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'invalid-phone',
        message: 'Mobile number is required.',
      );
    }

    final String clean = raw.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    String tenDigitNumber;

    if (clean.length == 10) {
      tenDigitNumber = clean;
    } else if (clean.length == 12 &&
        clean.startsWith('91')) {
      tenDigitNumber = clean.substring(2);
    } else {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'invalid-phone',
        message:
            'Please enter a valid 10-digit mobile number.',
      );
    }

    if (!RegExp(
      r'^[6-9][0-9]{9}$',
    ).hasMatch(tenDigitNumber)) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'invalid-phone',
        message:
            'Please enter a valid 10-digit Indian mobile number.',
      );
    }

    return '+91$tenDigitNumber';
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  static User _requireCurrentUser() {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'user-not-authenticated',
        message:
            'User is not logged in. Please login again.',
      );
    }

    final String uid = user.uid.trim();

    if (uid.isEmpty) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'invalid-user',
        message:
            'Firebase UID was not found.',
      );
    }

    return user;
  }

  // ============================================================
  // LOCATION
  // ============================================================

  static Future<Position?> _getCurrentLocation() async {
  try {
    final bool serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return null;
    }

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition();
  } catch (e) {
    developer.log(
      'Location error: $e',
      name: 'ProfileSetupService',
    );

    return null;
  }
  }

  // ============================================================
  // UPLOAD PROFILE PHOTO
  // ============================================================

  static Future<String> uploadOwnerProfilePhoto({
    required String ownerId,
    required File imageFile,
  }) async {
    final String cleanOwnerId =
        ownerId.trim();

    if (cleanOwnerId.isEmpty) {
      throw FirebaseException(
        plugin: 'firebase_storage',
        code: 'owner-id-missing',
        message:
            'Owner ID was not found.',
      );
    }

    if (!await imageFile.exists()) {
      throw FirebaseException(
        plugin: 'firebase_storage',
        code: 'file-not-found',
        message:
            'Profile photo file was not found.',
      );
    }

    final Reference storageRef =
        _storage
            .ref()
            .child(
              _ownerProfilePhotosFolder,
            )
            .child(
              cleanOwnerId,
            )
            .child(
              'profile.jpg',
            );

    await storageRef.putFile(
      imageFile,
      SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl:
            'public,max-age=86400',
      ),
    );

    final String url =
        await storageRef.getDownloadURL();

    return url.trim();
  }

  // ============================================================
  // PET CONVERSION
  // ============================================================

  static List<Map<String, dynamic>> _convertPets(
    List<PetData> pets,
  ) {
    if (pets.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'minimum-pet-required',
        message:
            'At least one pet is required.',
      );
    }

    if (pets.length > maximumPets) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'maximum-pets-exceeded',
        message:
            'Maximum $maximumPets pets can be added.',
      );
    }

    return pets.map(
      (PetData pet) {
        return <String, dynamic>{
          'name':
              pet.nameController.text.trim(),
          'age':
              pet.age,
          'breed':
              pet.breed,
          'behaviour':
              pet.behaviour,
        };
      },
    ).toList();
  }

  // ============================================================
  // SAVE PROFILE
  // ============================================================

  static Future<void> saveProfile({
    required String ownerName,
    required String address,
    required String phoneNumber,
    required List<PetData> pets,
    File? profilePhoto,
    bool requireLocation = false,
  }) async {
    // ----------------------------------------------------------
    // 1. CURRENT AUTH USER
    // ----------------------------------------------------------

    final User user =
        _requireCurrentUser();

    final String uid =
        user.uid.trim();

    // ----------------------------------------------------------
    // 2. PHONE
    // ----------------------------------------------------------

    final String fullPhoneNumber =
        _normalizePhone(phoneNumber);

    // ----------------------------------------------------------
    // 3. BASIC DATA
    // ----------------------------------------------------------

    final String cleanOwnerName =
        ownerName.trim();

    final String cleanAddress =
        address.trim();

    if (cleanOwnerName.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'owner-name-required',
        message:
            'Owner name is required.',
      );
    }

    if (cleanOwnerName.length < 2) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-owner-name',
        message:
            'Owner name must contain at least 2 characters.',
      );
    }

    // ----------------------------------------------------------
    // ADDRESS IS OPTIONAL
    // ----------------------------------------------------------

    // Do NOT reject empty address.
    //
    // ProfileSetupScreen already treats address as optional.

    // ----------------------------------------------------------
    // 4. PETS
    // ----------------------------------------------------------

    final List<Map<String, dynamic>> petData =
        _convertPets(pets);

    // ----------------------------------------------------------
    // 5. OWNER ID
    // ----------------------------------------------------------

    String? ownerId =
        await OwnerIdService.instance
            .getExistingOwnerId(
      uid: uid,
    );

    ownerId ??=
        await OwnerIdService.instance
            .getOrCreateOwnerId(
      uid: uid,
      phoneNumber:
          fullPhoneNumber,
    );

    ownerId =
        ownerId.trim();

    if (ownerId.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'owner-id-missing',
        message:
            'Owner ID could not be created.',
      );
    }

    // ----------------------------------------------------------
    // 6. LOCATION
    // ----------------------------------------------------------

    Position? position;

    if (requireLocation) {
      position =
          await _getCurrentLocation();

      if (position == null) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'location-required',
          message:
              'Current location is required. Please enable location permission and try again.',
        );
      }
    } else {
      // Location is optional during profile setup.
      position =
          await _getCurrentLocation();
    }

    // ==========================================================
    // 7. PROFILE DATA
    // ==========================================================

    final Map<String, dynamic> profileData =
        <String, dynamic>{
      'ownerId':
          ownerId,

      'authUid':
          uid,

      'uid':
          uid,

      'phone':
          fullPhoneNumber,

      'mainPhone':
          fullPhoneNumber,

      'ownerName':
          cleanOwnerName,

      'fullName':
          cleanOwnerName,

      'address':
          cleanAddress,

      'pets':
          petData,

      'role':
          'owner',

      'isActive':
          true,

      'profileCompleted':
          true,

      'updatedAt':
          FieldValue.serverTimestamp(),

      'profileCompletedAt':
          FieldValue.serverTimestamp(),
    };

    // ==========================================================
    // 8. PROFILE PHOTO
    // ==========================================================

    if (profilePhoto != null) {
      final String photoUrl =
          await uploadOwnerProfilePhoto(
        ownerId:
            ownerId,
        imageFile:
            profilePhoto,
      );

      if (photoUrl.isNotEmpty) {
        profileData[
                'profilePhotoUrl'] =
            photoUrl;

        profileData[
                'profilePhoto'] =
            photoUrl;
      }
    }

    // ==========================================================
    // 9. LOCATION DATA
    // ==========================================================

    if (position != null) {
      profileData[
              'latitude'] =
          position.latitude;

      profileData[
              'longitude'] =
          position.longitude;

      profileData[
              'location'] =
          <String, dynamic>{
        'latitude':
            position.latitude,
        'longitude':
            position.longitude,
      };

      profileData[
              'locationAccuracy'] =
          position.accuracy;

      profileData[
              'locationUpdatedAt'] =
          FieldValue.serverTimestamp();
    }

    // ==========================================================
    // 10. SAVE OWNER
    // ==========================================================

    final DocumentReference<
        Map<String, dynamic>> ownerRef =
        _firestore
            .collection(
              _ownersCollection,
            )
            .doc(ownerId);

    await ownerRef.set(
      profileData,
      SetOptions(
        merge: true,
      ),
    );

    // ==========================================================
    // 11. SAVE PHONE ACCOUNT
    // ==========================================================

    final DocumentReference<
        Map<String, dynamic>> phoneAccountRef =
        _firestore
            .collection(
              _phoneAccountsCollection,
            )
            .doc(uid);

    await phoneAccountRef.set(
      <String, dynamic>{
        'authUid':
            uid,

        'uid':
            uid,

        'phone':
            fullPhoneNumber,

        'mainPhone':
            fullPhoneNumber,

        'role':
            'owner',

        'ownerId':
            ownerId,

        'profileCompleted':
            true,

        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    developer.log(
      'Owner profile saved successfully.',
      name:
          'ProfileSetupService',
    );

    developer.log(
      'Firebase UID: $uid',
      name:
          'ProfileSetupService',
    );

    developer.log(
      'Owner ID: $ownerId',
      name:
          'ProfileSetupService',
    );
  }

  // ============================================================
  // UPDATE PROFILE PHOTO
  // ============================================================

  static Future<String> updateProfilePhoto(
    File imageFile,
  ) async {
    final User user =
        _requireCurrentUser();

    final String uid =
        user.uid.trim();

    final String? ownerId =
        await OwnerIdService.instance
            .getExistingOwnerId(
      uid: uid,
    );

    if (ownerId == null ||
        ownerId.trim().isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'owner-id-missing',
        message:
            'Owner ID was not found.',
      );
    }

    final String photoUrl =
        await uploadOwnerProfilePhoto(
      ownerId:
          ownerId.trim(),
      imageFile:
          imageFile,
    );

    await _firestore
        .collection(
          _ownersCollection,
        )
        .doc(
          ownerId.trim(),
        )
        .set(
      <String, dynamic>{
        'profilePhotoUrl':
            photoUrl,
        'profilePhoto':
            photoUrl,
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    return photoUrl;
  }

  // ============================================================
  // CHECK PROFILE COMPLETED
  // ============================================================

  static Future<bool>
      isProfileCompleted() async {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return false;
    }

    final String uid =
        user.uid.trim();

    if (uid.isEmpty) {
      return false;
    }

    final String? ownerId =
        await OwnerIdService.instance
            .getExistingOwnerId(
      uid: uid,
    );

    if (ownerId == null ||
        ownerId.trim().isEmpty) {
      return false;
    }

    try {
      final DocumentSnapshot<
          Map<String, dynamic>> snapshot =
          await _firestore
              .collection(
                _ownersCollection,
              )
              .doc(
                ownerId.trim(),
              )
              .get();

      if (!snapshot.exists) {
        return false;
      }

      final Map<String, dynamic>? data =
          snapshot.data();

      return data?[
              'profileCompleted'] ==
          true;
    } on FirebaseException catch (e) {
      developer.log(
        'Profile completion check failed: '
        '${e.code} - ${e.message}',
        name:
            'ProfileSetupService',
      );

      return false;
    }
  }

  // ============================================================
  // GET OWNER PROFILE
  // ============================================================

  static Future<
          DocumentSnapshot<
              Map<String, dynamic>>?>
      getOwnerProfile() async {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return null;
    }

    final String uid =
        user.uid.trim();

    if (uid.isEmpty) {
      return null;
    }

    final String? ownerId =
        await OwnerIdService.instance
            .getExistingOwnerId(
      uid: uid,
    );

    if (ownerId == null ||
        ownerId.trim().isEmpty) {
      return null;
    }

    return _firestore
        .collection(
          _ownersCollection,
        )
        .doc(
          ownerId.trim(),
        )
        .get();
  }

  // ============================================================
  // GET CURRENT OWNER ID
  // ============================================================

  static Future<String?>
      getCurrentOwnerId() async {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return null;
    }

    final String uid =
        user.uid.trim();

    if (uid.isEmpty) {
      return null;
    }

    final String? ownerId =
        await OwnerIdService.instance
            .getExistingOwnerId(
      uid: uid,
    );

    if (ownerId == null ||
        ownerId.trim().isEmpty) {
      return null;
    }

    return ownerId.trim();
  }

  // ============================================================
  // GET PROFILE PHOTO
  // ============================================================

  static Future<String?>
      getProfilePhotoUrl() async {
    final DocumentSnapshot<
            Map<String, dynamic>>?
        snapshot =
        await getOwnerProfile();

    if (snapshot == null ||
        !snapshot.exists) {
      return null;
    }

    final Map<String, dynamic>? data =
        snapshot.data();

    final dynamic value =
        data?['profilePhotoUrl'] ??
            data?['profilePhoto'];

    if (value == null) {
      return null;
    }

    final String url =
        value.toString().trim();

    return url.isEmpty
        ? null
        : url;
  }

  // ============================================================
  // UPDATE CURRENT LOCATION
  // ============================================================

  static Future<void>
      updateCurrentLocation() async {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    final String uid =
        user.uid.trim();

    if (uid.isEmpty) {
      return;
    }

    final String? ownerId =
        await OwnerIdService.instance
            .getExistingOwnerId(
      uid: uid,
    );

    if (ownerId == null ||
        ownerId.trim().isEmpty) {
      return;
    }

    final Position? position =
        await _getCurrentLocation();

    if (position == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'location-unavailable',
        message:
            'Current location could not be obtained.',
      );
    }

    await _firestore
        .collection(
          _ownersCollection,
        )
        .doc(
          ownerId.trim(),
        )
        .set(
      <String, dynamic>{
        'latitude':
            position.latitude,

        'longitude':
            position.longitude,

        'location':
            <String, dynamic>{
          'latitude':
              position.latitude,
          'longitude':
              position.longitude,
        },

        'locationAccuracy':
            position.accuracy,

        'locationUpdatedAt':
            FieldValue.serverTimestamp(),

        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );
  }
}
