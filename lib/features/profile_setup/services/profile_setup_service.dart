// File location:
// lib/features/profile_setup/services/profile_setup_service.dart

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';

import '../../../models/pet_data.dart';
import '../../../services/owner_id_service.dart';

class ProfileSetupService {
  ProfileSetupService._();

  static final ProfileSetupService instance =
      ProfileSetupService._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static final FirebaseStorage _storage =
      FirebaseStorage.instance;

  // ============================================================
  // COLLECTION
  // ============================================================

  static const String _ownerProfilesCollection =
      'ownerProfiles';

  // ============================================================
  // STORAGE
  // ============================================================

  static const String _ownerProfilePhotosFolder =
      'owner_profile_photos';

  // ============================================================
  // GET CURRENT LOCATION
  // ============================================================

  static Future<Position?> _getCurrentLocation() async {
    try {
      // --------------------------------------------------------
      // LOCATION SERVICE
      // --------------------------------------------------------

      final bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        return null;
      }

      // --------------------------------------------------------
      // PERMISSION
      // --------------------------------------------------------

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission ==
              LocationPermission.deniedForever) {
        return null;
      }

      // --------------------------------------------------------
      // CURRENT POSITION
      // --------------------------------------------------------

      return await Geolocator.getCurrentPosition(
        desiredAccuracy:
            LocationAccuracy.high,
      );
    } catch (e) {
      // Location failure must NOT stop profile saving.
      return null;
    }
  }

  // ============================================================
  // UPLOAD OWNER PROFILE PHOTO
  // ============================================================

  static Future<String?> uploadOwnerProfilePhoto({
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

    // ----------------------------------------------------------
    // CHECK FILE
    // ----------------------------------------------------------

    if (!await imageFile.exists()) {
      throw FirebaseException(
        plugin: 'firebase_storage',
        code: 'file-not-found',
        message:
            'Profile photo file was not found.',
      );
    }

    // ----------------------------------------------------------
    // STORAGE REFERENCE
    // ----------------------------------------------------------

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

    // ----------------------------------------------------------
    // UPLOAD
    // ----------------------------------------------------------

    await storageRef.putFile(
      imageFile,
      SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl:
            'public,max-age=86400',
      ),
    );

    // ----------------------------------------------------------
    // DOWNLOAD URL
    // ----------------------------------------------------------

    final String downloadUrl =
        await storageRef.getDownloadURL();

    return downloadUrl;
  }

  // ============================================================
  // UPDATE OWNER PROFILE PHOTO
  // ============================================================

  static Future<String?> updateProfilePhoto(
    File imageFile,
  ) async {
    // ----------------------------------------------------------
    // CURRENT USER
    // ----------------------------------------------------------

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

    final String uid =
        user.uid.trim();

    if (uid.isEmpty) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'invalid-user',
        message:
            'Firebase UID was not found.',
      );
    }

    // ----------------------------------------------------------
    // GET OWNER ID
    // ----------------------------------------------------------

    final String? existingOwnerId =
        await OwnerIdService.instance
            .getExistingOwnerId(
      uid: uid,
    );

    if (existingOwnerId == null ||
        existingOwnerId.trim().isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'owner-id-missing',
        message:
            'Owner ID was not found.',
      );
    }

    final String ownerId =
        existingOwnerId.trim();

    // ----------------------------------------------------------
    // UPLOAD
    // ----------------------------------------------------------

    final String? photoUrl =
        await uploadOwnerProfilePhoto(
      ownerId: ownerId,
      imageFile: imageFile,
    );

    if (photoUrl == null ||
        photoUrl.trim().isEmpty) {
      return null;
    }

    // ----------------------------------------------------------
    // UPDATE FIRESTORE
    // ----------------------------------------------------------

    await _firestore
        .collection(
          _ownerProfilesCollection,
        )
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
      SetOptions(
        merge: true,
      ),
    );

    return photoUrl;
  }

  // ============================================================
  // SAVE PROFILE
  // ============================================================

  static Future<void> saveProfile({
    required String ownerName,
    required String address,
    required List<PetData> pets,

    // ----------------------------------------------------------
    // OPTIONAL PROFILE PHOTO
    // ----------------------------------------------------------

    File? profilePhoto,
  }) async {
    // ----------------------------------------------------------
    // CURRENT FIREBASE USER
    // ----------------------------------------------------------

    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'user-not-authenticated',
        message:
            'User is not logged in. Please verify your mobile number first.',
      );
    }

    // ----------------------------------------------------------
    // AUTH UID
    // ----------------------------------------------------------

    final String uid =
        user.uid.trim();

    if (uid.isEmpty) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'invalid-user',
        message:
            'Firebase UID was not found.',
      );
    }

    // ----------------------------------------------------------
    // VERIFIED MOBILE NUMBER
    // ----------------------------------------------------------

    final String phoneNumber =
        user.phoneNumber?.trim() ?? '';

    if (phoneNumber.isEmpty) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'phone-not-found',
        message:
            'Verified mobile number was not found.',
      );
    }

    // ==========================================================
    // GET EXISTING OWNER ID
    // ==========================================================

    String? ownerId =
        await OwnerIdService.instance
            .getExistingOwnerId(
      uid: uid,
    );

    // ==========================================================
    // CREATE OWNER ID IF MISSING
    // ==========================================================

    ownerId ??=
        await OwnerIdService.instance
            .getOrCreateOwnerId(
      uid: uid,
      phoneNumber: phoneNumber,
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

    // ==========================================================
    // CURRENT GPS LOCATION
    // ==========================================================

    final Position? position =
        await _getCurrentLocation();

    // ==========================================================
    // PET DATA
    // ==========================================================

    final List<Map<String, dynamic>>
        petData =
        pets.map(
      (pet) {
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

    // ==========================================================
    // OWNER PROFILE REFERENCE
    // ==========================================================

    final DocumentReference<
            Map<String, dynamic>>
        ownerProfileRef =
        _firestore
            .collection(
              _ownerProfilesCollection,
            )
            .doc(ownerId);

    // ==========================================================
    // OWNER PROFILE DATA
    // ==========================================================

    final Map<String, dynamic>
        profileData =
        <String, dynamic>{
      // --------------------------------------------------------
      // OWNER IDENTITY
      // --------------------------------------------------------

      'ownerId':
          ownerId,

      'authUid':
          uid,

      'phone':
          phoneNumber,

      'mainPhone':
          phoneNumber,

      'ownerName':
          ownerName.trim(),

      // --------------------------------------------------------
      // ADDRESS
      // --------------------------------------------------------

      'address':
          address.trim(),

      // --------------------------------------------------------
      // PETS
      // --------------------------------------------------------

      'pets':
          petData,

      // --------------------------------------------------------
      // ROLE / STATUS
      // --------------------------------------------------------

      'role':
          'owner',

      'isActive':
          true,

      'profileCompleted':
          true,

      // --------------------------------------------------------
      // TIMESTAMPS
      // --------------------------------------------------------

      'updatedAt':
          FieldValue.serverTimestamp(),

      'profileCompletedAt':
          FieldValue.serverTimestamp(),
    };

    // ==========================================================
    // PROFILE PHOTO
    // ==========================================================

    if (profilePhoto != null) {
      final String? photoUrl =
          await uploadOwnerProfilePhoto(
        ownerId: ownerId,
        imageFile: profilePhoto,
      );

      if (photoUrl != null &&
          photoUrl.trim().isNotEmpty) {
        profileData[
                'profilePhotoUrl'] =
            photoUrl;

        // Compatibility field.
        profileData[
                'profilePhoto'] =
            photoUrl;
      }
    }

    // ==========================================================
    // CURRENT LOCATION
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
    // SAVE OWNER PROFILE
    // ==========================================================

    await ownerProfileRef.set(
      profileData,
      SetOptions(
        merge: true,
      ),
    );

    // ==========================================================
    // UPDATE PHONE ACCOUNT
    // ==========================================================

    await _firestore
        .collection(
          'phoneAccounts',
        )
        .doc(uid)
        .set(
      <String, dynamic>{
        'authUid':
            uid,

        'phone':
            phoneNumber,

        'mainPhone':
            phoneNumber,

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

    // ----------------------------------------------------------
    // GET OWNER ID
    // ----------------------------------------------------------

    final String? ownerId =
        await OwnerIdService.instance
            .getExistingOwnerId(
      uid: uid,
    );

    if (ownerId == null ||
        ownerId.trim().isEmpty) {
      return false;
    }

    // ----------------------------------------------------------
    // GET OWNER PROFILE
    // ----------------------------------------------------------

    final DocumentSnapshot<
            Map<String, dynamic>>
        snapshot =
        await _firestore
            .collection(
              _ownerProfilesCollection,
            )
            .doc(
              ownerId,
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

    // ----------------------------------------------------------
    // GET OWNER ID
    // ----------------------------------------------------------

    final String? ownerId =
        await OwnerIdService.instance
            .getExistingOwnerId(
      uid: uid,
    );

    if (ownerId == null ||
        ownerId.trim().isEmpty) {
      return null;
    }

    // ----------------------------------------------------------
    // GET PROFILE
    // ----------------------------------------------------------

    return _firestore
        .collection(
          _ownerProfilesCollection,
        )
        .doc(
          ownerId,
        )
        .get();
  }

  // ============================================================
  // UPDATE CURRENT OWNER LOCATION
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

    // ----------------------------------------------------------
    // GET OWNER ID
    // ----------------------------------------------------------

    final String? ownerId =
        await OwnerIdService.instance
            .getExistingOwnerId(
      uid: uid,
    );

    if (ownerId == null ||
        ownerId.trim().isEmpty) {
      return;
    }

    // ----------------------------------------------------------
    // GET LOCATION
    // ----------------------------------------------------------

    final Position? position =
        await _getCurrentLocation();

    if (position == null) {
      return;
    }

    // ----------------------------------------------------------
    // UPDATE FIRESTORE
    // ----------------------------------------------------------

    await _firestore
        .collection(
          _ownerProfilesCollection,
        )
        .doc(
          ownerId,
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

    return OwnerIdService.instance
        .getExistingOwnerId(
      uid: uid,
    );
  }

  // ============================================================
  // GET PROFILE PHOTO URL
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

    if (url.isEmpty) {
      return null;
    }

    return url;
  }
}
