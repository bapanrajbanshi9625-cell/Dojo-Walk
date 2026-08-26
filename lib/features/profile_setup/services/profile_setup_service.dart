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
  // FINAL COLLECTION
  // ============================================================

  static const String _ownersCollection =
      'owners';

  // ============================================================
  // STORAGE
  // ============================================================

  static const String _ownerProfilePhotosFolder =
      'owner_profile_photos';

  // ============================================================
  // LOCATION
  // ============================================================

  static Future<Position?>
      _getCurrentLocation() async {
    try {
      final bool serviceEnabled =
          await Geolocator
              .isLocationServiceEnabled();

      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission ==
          LocationPermission.denied) {
        permission =
            await Geolocator
                .requestPermission();
      }

      if (permission ==
              LocationPermission.denied ||
          permission ==
              LocationPermission
                  .deniedForever) {
        return null;
      }

      return await Geolocator
          .getCurrentPosition(
        desiredAccuracy:
            LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }

  // ============================================================
  // UPLOAD PROFILE PHOTO
  // ============================================================

  static Future<String?>
      uploadOwnerProfilePhoto({
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
        contentType:
            'image/jpeg',
        cacheControl:
            'public,max-age=86400',
      ),
    );

    return await storageRef
        .getDownloadURL();
  }

  // ============================================================
  // UPDATE PROFILE PHOTO
  // ============================================================

  static Future<String?>
      updateProfilePhoto(
    File imageFile,
  ) async {
    final User? user =
        FirebaseAuth
            .instance
            .currentUser;

    if (user == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'user-not-authenticated',
        message:
            'User is not logged in.',
      );
    }

    final String? ownerId =
        await OwnerIdService
            .instance
            .getExistingOwnerId(
      uid: user.uid,
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

    final String? photoUrl =
        await uploadOwnerProfilePhoto(
      ownerId:
          ownerId.trim(),
      imageFile:
          imageFile,
    );

    if (photoUrl == null ||
        photoUrl.trim().isEmpty) {
      return null;
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
        'profilePhotoUrl':
            photoUrl,
        'profilePhoto':
            photoUrl,
        'updatedAt':
            FieldValue
                .serverTimestamp(),
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

  static Future<void>
      saveProfile({
    required String ownerName,
    required String address,
    required List<PetData> pets,
    File? profilePhoto,
  }) async {
    // ----------------------------------------------------------
    // CURRENT USER
    // ----------------------------------------------------------

    final User? user =
        FirebaseAuth
            .instance
            .currentUser;

    if (user == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'user-not-authenticated',
        message:
            'User is not logged in.',
      );
    }

    // ----------------------------------------------------------
    // UID
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
    // PHONE
    // ----------------------------------------------------------

    final String phone =
        user.phoneNumber
                ?.trim() ??
            '';

    if (phone.isEmpty) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'phone-not-found',
        message:
            'Verified mobile number was not found.',
      );
    }

    // ==========================================================
    // OWNER ID
    // ==========================================================

    String? ownerId =
        await OwnerIdService
            .instance
            .getExistingOwnerId(
      uid: uid,
    );

    ownerId ??=
        await OwnerIdService
            .instance
            .getOrCreateOwnerId(
      uid: uid,
      phoneNumber: phone,
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
    // LOCATION
    // ==========================================================

    final Position? position =
        await _getCurrentLocation();

    // ==========================================================
    // PETS
    // ==========================================================
    //
    // IMPORTANT:
    // Firestore में String list नहीं बनेगी.
    //
    // Proper array of maps बनेगा.
    // ==========================================================

    final List<Map<String, dynamic>>
        petData =
        pets.map(
      (PetData pet) {
        return <String, dynamic>{
          'name':
              pet.nameController.text
                  .trim(),

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
    // OWNER DOCUMENT
    // ==========================================================

    final DocumentReference<
            Map<String, dynamic>>
        ownerRef =
        _firestore
            .collection(
              _ownersCollection,
            )
            .doc(ownerId);

    // ==========================================================
    // PROFILE DATA
    // ==========================================================

    final String cleanOwnerName =
        ownerName.trim();

    final Map<String, dynamic>
        profileData =
        <String, dynamic>{
      // --------------------------------------------------------
      // IDENTITY
      // --------------------------------------------------------

      'ownerId':
          ownerId,

      'authUid':
          uid,

      'phone':
          phone,

      'mainPhone':
          phone,

      // --------------------------------------------------------
      // NAME
      // --------------------------------------------------------

      'ownerName':
          cleanOwnerName,

      'fullName':
          cleanOwnerName,

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
      // ROLE
      // --------------------------------------------------------

      'role':
          'owner',

      // --------------------------------------------------------
      // STATUS
      // --------------------------------------------------------

      'isActive':
          true,

      'profileCompleted':
          true,

      // --------------------------------------------------------
      // TIMESTAMPS
      // --------------------------------------------------------

      'updatedAt':
          FieldValue
              .serverTimestamp(),

      'profileCompletedAt':
          FieldValue
              .serverTimestamp(),
    };

    // ==========================================================
    // PROFILE PHOTO
    // ==========================================================

    if (profilePhoto != null) {
      final String? photoUrl =
          await uploadOwnerProfilePhoto(
        ownerId:
            ownerId,
        imageFile:
            profilePhoto,
      );

      if (photoUrl != null &&
          photoUrl.trim().isNotEmpty) {
        profileData[
                'profilePhotoUrl'] =
            photoUrl;

        profileData[
                'profilePhoto'] =
            photoUrl;
      }
    }

    // ==========================================================
    // LOCATION
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
          FieldValue
              .serverTimestamp();
    }

    // ==========================================================
    // SAVE TO owners
    // ==========================================================

    await ownerRef.set(
      profileData,
      SetOptions(
        merge: true,
      ),
    );

    // ==========================================================
    // PHONE ACCOUNT
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
            phone,

        'mainPhone':
            phone,

        'role':
            'owner',

        'ownerId':
            ownerId,

        'profileCompleted':
            true,

        'updatedAt':
            FieldValue
                .serverTimestamp(),
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
        FirebaseAuth
            .instance
            .currentUser;

    if (user == null) {
      return false;
    }

    final String? ownerId =
        await OwnerIdService
            .instance
            .getExistingOwnerId(
      uid: user.uid,
    );

    if (ownerId == null ||
        ownerId.trim().isEmpty) {
      return false;
    }

    final DocumentSnapshot<
            Map<String, dynamic>>
        snapshot =
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

    return snapshot.data()?[
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
        FirebaseAuth
            .instance
            .currentUser;

    if (user == null) {
      return null;
    }

    final String? ownerId =
        await OwnerIdService
            .instance
            .getExistingOwnerId(
      uid: user.uid,
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
  // UPDATE LOCATION
  // ============================================================

  static Future<void>
      updateCurrentLocation() async {
    final User? user =
        FirebaseAuth
            .instance
            .currentUser;

    if (user == null) {
      return;
    }

    final String? ownerId =
        await OwnerIdService
            .instance
            .getExistingOwnerId(
      uid: user.uid,
    );

    if (ownerId == null ||
        ownerId.trim().isEmpty) {
      return;
    }

    final Position? position =
        await _getCurrentLocation();

    if (position == null) {
      return;
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
            FieldValue
                .serverTimestamp(),

        'updatedAt':
            FieldValue
                .serverTimestamp(),
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
        FirebaseAuth
            .instance
            .currentUser;

    if (user == null) {
      return null;
    }

    return OwnerIdService
        .instance
        .getExistingOwnerId(
      uid: user.uid,
    );
  }

  // ============================================================
  // PROFILE PHOTO URL
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

    final Map<String, dynamic>?
        data =
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
