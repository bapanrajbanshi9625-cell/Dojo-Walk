// File:
// lib/features/profile_setup/services/profile_setup_service.dart

import 'dart:developer' as developer;
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/services/cloudinary_service.dart';
import '../../../models/pet_data.dart';
import '../../../services/owner_id_service.dart';

class ProfileSetupService {
  ProfileSetupService._();

  static final ProfileSetupService instance =
      ProfileSetupService._();

  // ============================================================
  // FIREBASE
  // ============================================================

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // COLLECTIONS
  // ============================================================

  static const String _ownersCollection = 'owners';

  static const String _phoneAccountsCollection =
      'phoneAccounts';

  // ============================================================
  // LIMITS
  // ============================================================

  static const int maximumPets = 3;

  // ============================================================
  // PHONE NORMALIZATION
  // ============================================================

  static String _normalizePhone(String phoneNumber) {
    String phone = phoneNumber.trim();

    phone = phone.replaceAll(
      RegExp(r'[\s\-\(\)]'),
      '',
    );

    if (phone.startsWith('+')) {
      return phone;
    }

    if (phone.length == 10) {
      return '+91$phone';
    }

    if (phone.length == 12 &&
        phone.startsWith('91')) {
      return '+$phone';
    }

    return phone;
  }

  // ============================================================
  // CURRENT FIREBASE USER
  // ============================================================

  static User _requireCurrentUser() {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message:
            'Please login again before completing your profile.',
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

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission ==
              LocationPermission.denied ||
          permission ==
              LocationPermission.deniedForever) {
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
  // UPLOAD OWNER PROFILE PHOTO
  //
  // CLOUDINARY
  //
  // Firebase Storage is NOT used here.
  // ============================================================

  static Future<String> uploadOwnerProfilePhoto({
    required File imageFile,
    required String uid,
  }) async {
    if (!await imageFile.exists()) {
      throw FirebaseException(
        plugin: 'cloudinary',
        code: 'file-not-found',
        message:
            'Profile photo file was not found.',
      );
    }

    final String cleanUid =
        uid.trim();

    if (cleanUid.isEmpty) {
      throw FirebaseException(
        plugin: 'cloudinary',
        code: 'invalid-uid',
        message:
            'Invalid Firebase UID.',
      );
    }

    try {
      final String photoUrl =
          await CloudinaryService.uploadImage(
        file: imageFile,
        folder:
            'dojo_walker/owner_profiles/$cleanUid',
      );

      if (photoUrl.trim().isEmpty) {
        throw FirebaseException(
          plugin: 'cloudinary',
          code: 'empty-url',
          message:
              'Cloudinary did not return an image URL.',
        );
      }

      developer.log(
        'Owner profile photo uploaded to Cloudinary.',
        name: 'ProfileSetupService',
      );

      return photoUrl;
    } catch (e) {
      developer.log(
        'Cloudinary profile photo upload failed: $e',
        name: 'ProfileSetupService',
      );

      rethrow;
    }
  }

  // ============================================================
  // PET CONVERSION
  // ============================================================

  static List<Map<String, dynamic>> _convertPets(
    List<PetData> pets,
  ) {
    final List<Map<String, dynamic>> result =
        <Map<String, dynamic>>[];

    for (final PetData pet
        in pets.take(maximumPets)) {
      result.add({
        'name': pet.name.trim(),
        'age': pet.age?.trim(),
        'breed': pet.breed?.trim(),
        'behaviour': pet.behaviour?.trim(),
      });
    }

    return result;
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
    if (requireLocation) {
      developer.log(
        'Location requirement ignored during profile setup.',
        name: 'ProfileSetupService',
      );
    }

    final User user =
        _requireCurrentUser();

    final String uid =
        user.uid.trim();

    if (uid.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-uid',
        message:
            'Invalid Firebase user.',
      );
    }

    // ==========================================================
    // CLEAN DATA
    // ==========================================================

    final String fullPhoneNumber =
        _normalizePhone(phoneNumber);

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

    if (fullPhoneNumber.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'phone-required',
        message:
            'Verified mobile number is required.',
      );
    }

    // ==========================================================
    // PETS
    // ==========================================================

    final List<Map<String, dynamic>> petData =
        _convertPets(pets);

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

    ownerId =
        ownerId.trim();

    if (ownerId.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'owner-id-failed',
        message:
            'Unable to create Owner ID.',
      );
    }

    // ==========================================================
    // PROFILE DATA
    // ==========================================================

    final Map<String, dynamic> profileData =
        <String, dynamic>{
      'ownerId': ownerId,

      'authUid': uid,
      'uid': uid,

      'phone': fullPhoneNumber,
      'mainPhone': fullPhoneNumber,
      'phoneNumber': fullPhoneNumber,

      'ownerName': cleanOwnerName,
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
    // CLOUDINARY PROFILE PHOTO
    // ==========================================================

    if (profilePhoto != null) {
      final String photoUrl =
          await uploadOwnerProfilePhoto(
        imageFile: profilePhoto,
        uid: uid,
      );

      profileData['profilePhotoUrl'] =
          photoUrl;

      profileData['profileImageUrl'] =
          photoUrl;
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

    final Map<String, dynamic>
        phoneAccountData =
        <String, dynamic>{
      'uid': uid,

      'ownerId': ownerId,

      'phone': fullPhoneNumber,
      'phoneNumber': fullPhoneNumber,
      'mainPhone': fullPhoneNumber,

      'role': 'owner',

      'profileCompleted': true,
      'isActive': true,

      'updatedAt':
          FieldValue.serverTimestamp(),

      'profileCompletedAt':
          FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection(
          _phoneAccountsCollection,
        )
        .doc(uid)
        .set(
          phoneAccountData,
          SetOptions(merge: true),
        );

    developer.log(
      'Owner profile saved successfully. '
      'uid=$uid ownerId=$ownerId',
      name: 'ProfileSetupService',
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

    final String photoUrl =
        await uploadOwnerProfilePhoto(
      imageFile: imageFile,
      uid: uid,
    );

    final String? ownerId =
        await OwnerIdService.instance
            .getExistingOwnerId(
      uid: uid,
    );

    if (ownerId == null ||
        ownerId.trim().isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'owner-not-found',
        message:
            'Owner profile was not found.',
      );
    }

    await _firestore
        .collection(_ownersCollection)
        .doc(ownerId)
        .set(
      {
        'profilePhotoUrl': photoUrl,
        'profileImageUrl': photoUrl,
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

    try {
      final String? ownerId =
          await OwnerIdService.instance
              .getExistingOwnerId(
        uid: user.uid,
      );

      if (ownerId == null ||
          ownerId.trim().isEmpty) {
        return false;
      }

      final DocumentSnapshot<
          Map<String, dynamic>> snapshot =
          await _firestore
              .collection(
                _ownersCollection,
              )
              .doc(ownerId)
              .get();

      if (!snapshot.exists) {
        return false;
      }

      final Map<String, dynamic>? data =
          snapshot.data();

      if (data == null) {
        return false;
      }

      return data['profileCompleted'] ==
          true;
    } catch (e) {
      developer.log(
        'Profile completion check failed: $e',
        name: 'ProfileSetupService',
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

    try {
      final String? ownerId =
          await OwnerIdService.instance
              .getExistingOwnerId(
        uid: user.uid,
      );

      if (ownerId == null ||
          ownerId.trim().isEmpty) {
        return null;
      }

      return await _firestore
          .collection(
            _ownersCollection,
          )
          .doc(ownerId)
          .get();
    } catch (e) {
      developer.log(
        'Get owner profile failed: $e',
        name: 'ProfileSetupService',
      );

      return null;
    }
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

    try {
      return await OwnerIdService.instance
          .getExistingOwnerId(
        uid: user.uid,
      );
    } catch (e) {
      developer.log(
        'Get owner ID failed: $e',
        name: 'ProfileSetupService',
      );

      return null;
    }
  }

  // ============================================================
  // GET PROFILE PHOTO URL
  // ============================================================

  static Future<String?>
      getProfilePhotoUrl() async {
    final DocumentSnapshot<
        Map<String, dynamic>>? snapshot =
        await getOwnerProfile();

    if (snapshot == null ||
        !snapshot.exists) {
      return null;
    }

    final Map<String, dynamic>? data =
        snapshot.data();

    if (data == null) {
      return null;
    }

    final dynamic value =
        data['profilePhotoUrl'] ??
            data['profileImageUrl'];

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
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message:
            'Please login before updating location.',
      );
    }

    final String uid =
        user.uid.trim();

    if (uid.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-uid',
        message:
            'Invalid Firebase UID.',
      );
    }

    final String? ownerId =
        await OwnerIdService.instance
            .getExistingOwnerId(
      uid: uid,
    );

    if (ownerId == null ||
        ownerId.trim().isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'owner-not-found',
        message:
            'Owner profile was not found.',
      );
    }

    final Position? position =
        await _getCurrentLocation();

    if (position == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'location-unavailable',
        message:
            'Current location is unavailable.',
      );
    }

    await _firestore
        .collection(_ownersCollection)
        .doc(ownerId)
        .set(
      {
        'latitude':
            position.latitude,

        'longitude':
            position.longitude,

        'location': {
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

    developer.log(
      'Owner location updated. '
      'ownerId=$ownerId',
      name: 'ProfileSetupService',
    );
  }
}
