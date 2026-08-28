// File:
// lib/features/profile_setup/services/profile_setup_service.dart

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
/// Responsibility:
/// - Save Owner profile
/// - Upload Owner profile photo
/// - Save pets
/// - Save current location
/// - Mark profileCompleted
/// - Read Owner profile
/// - Update current location
///
/// NOT responsible for:
/// - OTP verification
/// - OTP resend
/// - Login navigation
/// - Creating OTP session
///
/// Verified phone number is supplied by the caller because
/// MSG91 verification + Firebase anonymous authentication
/// does not provide FirebaseAuth.currentUser.phoneNumber.
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
  // PET LIMIT
  // ============================================================

  static const int maximumPets = 3;

  // ============================================================
  // NORMALIZE PHONE
  // ============================================================

  static String _normalizePhone(String phoneNumber) {
    String clean = phoneNumber.trim();

    clean = clean.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (clean.length > 10) {
      clean = clean.substring(
        clean.length - 10,
      );
    }

    if (clean.length != 10) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'phone-not-found',
        message:
            'Verified mobile number must contain 10 digits.',
      );
    }

    return '+91$clean';
  }

  // ============================================================
  // CURRENT FIREBASE USER
  // ============================================================

  static User _requireCurrentUser() {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'user-not-authenticated',
        message:
            'User is not logged in.',
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
  // CURRENT LOCATION
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

      if (permission ==
          LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission ==
              LocationPermission.denied ||
          permission ==
              LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // UPLOAD OWNER PROFILE PHOTO
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

    return storageRef.getDownloadURL();
  }

  // ============================================================
  // CONVERT PET DATA
  // ============================================================

  static List<Map<String, dynamic>> _convertPets(
    List<PetData> pets,
  ) {
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
    bool requireLocation = true,
  }) async {
    final User user =
        _requireCurrentUser();

    final String uid =
        user.uid.trim();

    final String fullPhoneNumber =
        _normalizePhone(phoneNumber);

    final String cleanOwnerName =
        ownerName.trim();

    final String cleanAddress =
        address.trim();

    // ----------------------------------------------------------
    // BASIC VALIDATION
    // ----------------------------------------------------------

    if (cleanOwnerName.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'owner-name-required',
        message:
            'Owner name is required.',
      );
    }

    if (cleanAddress.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'address-required',
        message:
            'Address is required.',
      );
    }

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

    // ==========================================================
    // OWNER ID
    // ==========================================================

    String? ownerId =
        await OwnerIdService.instance
            .getExistingOwnerId(
      uid: uid,
    );

    ownerId ??=
        await OwnerIdService.instance
            .getOrCreateOwnerId(
      uid: uid,
      phoneNumber: fullPhoneNumber,
    );

    ownerId = ownerId.trim();

    if (ownerId.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'owner-id-missing',
        message:
            'Owner ID could not be created.',
      );
    }

    // ==========================================================
    // LOCATION
    // ==========================================================

    final Position? position =
        await _getCurrentLocation();

    if (requireLocation &&
        position == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'location-required',
        message:
            'Current location is required. Please enable location permission and try again.',
      );
    }

    // ==========================================================
    // PETS
    // ==========================================================

    final List<Map<String, dynamic>> petData =
        _convertPets(pets);

    // ==========================================================
    // PROFILE DATA
    // ==========================================================

    final Map<String, dynamic> profileData =
        <String, dynamic>{
      'ownerId': ownerId,

      'authUid': uid,

      'phone': fullPhoneNumber,

      'mainPhone': fullPhoneNumber,

      'ownerName': cleanOwnerName,

      // Compatibility field.
      'fullName': cleanOwnerName,

      'address': cleanAddress,

      'pets': petData,

      'role': 'owner',

      'isActive': true,

      'profileCompleted': true,

      'updatedAt':
          FieldValue.serverTimestamp(),

      'profileCompletedAt':
          FieldValue.serverTimestamp(),
    };

    // ==========================================================
    // PROFILE PHOTO
    // ==========================================================

    if (profilePhoto != null) {
      final String photoUrl =
          await uploadOwnerProfilePhoto(
        ownerId: ownerId,
        imageFile: profilePhoto,
      );

      if (photoUrl.trim().isNotEmpty) {
        profileData['profilePhotoUrl'] =
            photoUrl;

        profileData['profilePhoto'] =
            photoUrl;
      }
    }

    // ==========================================================
    // LOCATION DATA
    // ==========================================================

    if (position != null) {
      profileData['latitude'] =
          position.latitude;

      profileData['longitude'] =
          position.longitude;

      profileData['location'] =
          <String, dynamic>{
        'latitude':
            position.latitude,
        'longitude':
            position.longitude,
      };

      profileData['locationAccuracy'] =
          position.accuracy;

      profileData['locationUpdatedAt'] =
          FieldValue.serverTimestamp();
    }

    // ==========================================================
    // SAVE OWNER PROFILE
    // ==========================================================

    await _firestore
        .collection(_ownersCollection)
        .doc(ownerId)
        .set(
      profileData,
      SetOptions(merge: true),
    );

    // ==========================================================
    // SAVE PHONE ACCOUNT
    // ==========================================================

    await _firestore
        .collection(
          _phoneAccountsCollection,
        )
        .doc(uid)
        .set(
      <String, dynamic>{
        'authUid': uid,

        'phone': fullPhoneNumber,

        'mainPhone': fullPhoneNumber,

        'role': 'owner',

        'ownerId': ownerId,

        'profileCompleted': true,

        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
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
      ownerId: ownerId,
      imageFile: imageFile,
    );

    await _firestore
        .collection(_ownersCollection)
        .doc(ownerId)
        .set(
      <String, dynamic>{
        'profilePhotoUrl':
            photoUrl,
        'profilePhoto':
            photoUrl,
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    return photoUrl;
  }

  // ============================================================
  // CHECK PROFILE COMPLETED
  // ============================================================

  static Future<bool> isProfileCompleted() async {
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

    final DocumentSnapshot<
        Map<String, dynamic>> snapshot =
        await _firestore
            .collection(_ownersCollection)
            .doc(ownerId.trim())
            .get();

    if (!snapshot.exists) {
      return false;
    }

    final Map<String, dynamic>? data =
        snapshot.data();

    return data?['profileCompleted'] ==
        true;
  }

  // ============================================================
  // GET OWNER PROFILE
  // ============================================================

  static Future<
      DocumentSnapshot<Map<String, dynamic>>?>
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
        .collection(_ownersCollection)
        .doc(ownerId.trim())
        .get();
  }

  // ============================================================
  // GET CURRENT OWNER ID
  // ============================================================

  static Future<String?> getCurrentOwnerId() async {
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

    return OwnerIdService.instance
        .getExistingOwnerId(
      uid: uid,
    );
  }

  // ============================================================
  // GET PROFILE PHOTO URL
  // ============================================================

  static Future<String?> getProfilePhotoUrl() async {
    final DocumentSnapshot<
        Map<String, dynamic>>? snapshot =
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

    return url.isEmpty ? null : url;
  }

  // ============================================================
  // UPDATE CURRENT LOCATION
  // ============================================================

  static Future<void> updateCurrentLocation() async {
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
        .collection(_ownersCollection)
        .doc(ownerId.trim())
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
      SetOptions(merge: true),
    );
  }
}
