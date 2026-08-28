import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'owner_id_service.dart';

/// ============================================================
/// OWNER AUTH SERVICE
/// ============================================================
///
/// जिम्मेदारी:
/// - Firebase session create / restore करना
/// - Firebase UID प्राप्त करना
/// - Existing OwnerIdService से Owner ID प्राप्त करना
/// - Owner profile load करना
/// - isActive check करना
/// - profileCompleted check करना
///
/// यह service:
/// - MSG91 OTP verify नहीं करती
/// - OTP resend नहीं करती
/// - Navigation नहीं करती
/// - Profile setup save नहीं करती
///
/// ============================================================

class OwnerAuthService {
  OwnerAuthService._();

  static final OwnerAuthService instance =
      OwnerAuthService._();

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // COLLECTION
  // ============================================================

  static const String _ownersCollection =
      'owners';

  // ============================================================
  // CREATE / RESTORE FIREBASE SESSION
  // ============================================================

  Future<User> createOrRestoreSession() async {
    User? user = _auth.currentUser;

    // ----------------------------------------------------------
    // EXISTING SESSION
    // ----------------------------------------------------------

    if (user != null) {
      return user;
    }

    // ----------------------------------------------------------
    // CREATE ANONYMOUS FIREBASE SESSION
    // ----------------------------------------------------------

    final UserCredential credential =
        await _auth.signInAnonymously();

    user = credential.user;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'firebase-user-missing',
        message:
            'Unable to create Firebase session.',
      );
    }

    return user;
  }

  // ============================================================
  // GET FIREBASE UID
  // ============================================================

  Future<String> getFirebaseUid() async {
    final User user =
        await createOrRestoreSession();

    final String uid =
        user.uid.trim();

    if (uid.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-user',
        message:
            'Firebase UID was not found.',
      );
    }

    return uid;
  }

  // ============================================================
  // GET / CREATE OWNER ID
  // ============================================================

  Future<String> getOwnerId({
    required String phoneNumber,
  }) async {
    final String uid =
        await getFirebaseUid();

    String cleanPhone =
        phoneNumber.trim();

    // ----------------------------------------------------------
    // NORMALIZE PHONE
    // ----------------------------------------------------------

    cleanPhone = cleanPhone.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (cleanPhone.length > 10) {
      cleanPhone = cleanPhone.substring(
        cleanPhone.length - 10,
      );
    }

    if (cleanPhone.length != 10) {
      throw FirebaseAuthException(
        code: 'phone-not-found',
        message:
            'Verified mobile number was not found.',
      );
    }

    final String fullPhoneNumber =
        '+91$cleanPhone';

    // ----------------------------------------------------------
    // EXISTING OwnerIdService
    // ----------------------------------------------------------

    final String ownerId =
        await OwnerIdService.instance
            .getOrCreateOwnerId(
      uid: uid,
      phoneNumber: fullPhoneNumber,
    );

    final String cleanOwnerId =
        ownerId.trim();

    if (cleanOwnerId.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'owner-id-missing',
        message:
            'Owner ID could not be created.',
      );
    }

    return cleanOwnerId;
  }

  // ============================================================
  // LOAD OWNER PROFILE
  // ============================================================

  Future<Map<String, dynamic>> getOwnerProfile({
    required String ownerId,
  }) async {
    final String cleanOwnerId =
        ownerId.trim();

    if (cleanOwnerId.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'owner-id-missing',
        message:
            'Owner ID is empty.',
      );
    }

    final DocumentSnapshot<
        Map<String, dynamic>> snapshot =
        await _firestore
            .collection(_ownersCollection)
            .doc(cleanOwnerId)
            .get();

    if (!snapshot.exists) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'owner-profile-not-found',
        message:
            'Owner profile was not found.',
      );
    }

    final Map<String, dynamic>? data =
        snapshot.data();

    return data ?? <String, dynamic>{};
  }

  // ============================================================
  // GET OWNER LOGIN STATE
  // ============================================================

  Future<OwnerAuthResult> authenticateOwner({
    required String phoneNumber,
  }) async {
    // ----------------------------------------------------------
    // 1. FIREBASE UID
    // ----------------------------------------------------------

    final String uid =
        await getFirebaseUid();

    // ----------------------------------------------------------
    // 2. OWNER ID
    // ----------------------------------------------------------

    final String ownerId =
        await getOwnerId(
      phoneNumber: phoneNumber,
    );

    // ----------------------------------------------------------
    // 3. OWNER PROFILE
    // ----------------------------------------------------------

    final Map<String, dynamic> profileData =
        await getOwnerProfile(
      ownerId: ownerId,
    );

    // ----------------------------------------------------------
    // 4. ACTIVE STATUS
    // ----------------------------------------------------------

    final bool isActive =
        profileData['isActive'] != false;

    // ----------------------------------------------------------
    // 5. PROFILE COMPLETED
    // ----------------------------------------------------------

    final bool profileCompleted =
        profileData['profileCompleted'] == true;

    return OwnerAuthResult(
      uid: uid,
      ownerId: ownerId,
      profileData: profileData,
      isActive: isActive,
      profileCompleted: profileCompleted,
    );
  }

  // ============================================================
  // SIGN OUT
  // ============================================================

  Future<void> signOut() async {
    await _auth.signOut();
  }
}


/// ============================================================
/// OWNER AUTH RESULT
/// ============================================================
///
/// OTP screen को एक साफ result object मिलेगा।
/// इससे OTP screen में Firestore logic नहीं रहेगा.
///

class OwnerAuthResult {
  final String uid;
  final String ownerId;
  final Map<String, dynamic> profileData;
  final bool isActive;
  final bool profileCompleted;

  const OwnerAuthResult({
    required this.uid,
    required this.ownerId,
    required this.profileData,
    required this.isActive,
    required this.profileCompleted,
  });
}
