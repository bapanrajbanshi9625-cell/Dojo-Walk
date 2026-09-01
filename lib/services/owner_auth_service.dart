import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'owner_id_service.dart';

class OwnerAuthService {
  OwnerAuthService._();

  static final OwnerAuthService instance =
      OwnerAuthService._();

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static const String _ownersCollection =
      'owners';

  static const String _phoneAccountsCollection =
      'phoneAccounts';

  // ============================================================
  // CREATE / RESTORE FIREBASE SESSION
  // ============================================================

  Future<User> createOrRestoreSession() async {
    User? user = _auth.currentUser;

    if (user != null) {
      return user;
    }

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
  // NORMALIZE PHONE
  // ============================================================

  String _normalizePhoneNumber(
    String phoneNumber,
  ) {
    String cleanPhone =
        phoneNumber
            .trim()
            .replaceAll(
              RegExp(r'[^0-9]'),
              '',
            );

    if (cleanPhone.length == 12 &&
        cleanPhone.startsWith('91')) {
      cleanPhone =
          cleanPhone.substring(2);
    }

    if (cleanPhone.length != 10) {
      throw FirebaseAuthException(
        code: 'invalid-phone',
        message:
            'Please enter a valid 10-digit mobile number.',
      );
    }

    if (!RegExp(r'^[6-9][0-9]{9}$')
        .hasMatch(cleanPhone)) {
      throw FirebaseAuthException(
        code: 'invalid-phone',
        message:
            'Please enter a valid 10-digit mobile number.',
      );
    }

    return cleanPhone;
  }

  // ============================================================
  // GET / CREATE OWNER ID
  // ============================================================

  Future<String> getOwnerId({
    required String phoneNumber,
  }) async {
    final String uid =
        await getFirebaseUid();

    final String cleanPhone =
        _normalizePhoneNumber(
      phoneNumber,
    );

    final String fullPhoneNumber =
        '+91$cleanPhone';

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
  // SAVE PHONE ACCOUNT
  // ============================================================

  Future<void> savePhoneAccount({
    required String uid,
    required String ownerId,
    required String phoneNumber,
  }) async {
    final String cleanUid =
        uid.trim();

    final String cleanOwnerId =
        ownerId.trim();

    final String cleanPhone =
        _normalizePhoneNumber(
      phoneNumber,
    );

    if (cleanUid.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-user',
        message:
            'Firebase UID is empty.',
      );
    }

    if (cleanOwnerId.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'owner-id-missing',
        message:
            'Owner ID is empty.',
      );
    }

    final String fullPhoneNumber =
        '+91$cleanPhone';

    final DocumentReference<Map<String, dynamic>>
        accountRef =
        _firestore
            .collection(
              _phoneAccountsCollection,
            )
            .doc(cleanUid);

    await accountRef.set(
      <String, dynamic>{
        'uid': cleanUid,
        'authUid': cleanUid,
        'ownerId': cleanOwnerId,
        'phoneNumber': fullPhoneNumber,
        'phone': fullPhoneNumber,
        'mainPhone': fullPhoneNumber,
        'role': 'owner',
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );
  }

  // ============================================================
  // CREATE OWNER IF MISSING
  // ============================================================

  Future<Map<String, dynamic>>
      createOwnerIfMissing({
    required String ownerId,
    required String uid,
    required String phoneNumber,
  }) async {
    final String cleanOwnerId =
        ownerId.trim();

    final String cleanUid =
        uid.trim();

    final String cleanPhone =
        _normalizePhoneNumber(
      phoneNumber,
    );

    if (cleanOwnerId.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'owner-id-missing',
        message:
            'Owner ID is empty.',
      );
    }

    if (cleanUid.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-user',
        message:
            'Firebase UID is empty.',
      );
    }

    final String fullPhoneNumber =
        '+91$cleanPhone';

    final DocumentReference<Map<String, dynamic>>
        ownerRef =
        _firestore
            .collection(_ownersCollection)
            .doc(cleanOwnerId);

    final DocumentSnapshot<Map<String, dynamic>>
        snapshot =
        await ownerRef.get();

    // ==========================================================
    // EXISTING OWNER
    // ==========================================================

    if (snapshot.exists) {
      await ownerRef.set(
        <String, dynamic>{
          'ownerId': cleanOwnerId,
          'uid': cleanUid,
          'authUid': cleanUid,
          'phoneNumber': fullPhoneNumber,
          'phone': fullPhoneNumber,
          'mainPhone': fullPhoneNumber,
          'role': 'owner',
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      final Map<String, dynamic> data =
          snapshot.data() ??
              <String, dynamic>{};

      // IMPORTANT:
      // Existing profileCompleted / isActive
      // values are NOT overwritten.

      return data;
    }

    // ==========================================================
    // NEW OWNER
    // ==========================================================

    final Map<String, dynamic> newOwnerData =
        <String, dynamic>{
      'ownerId': cleanOwnerId,
      'uid': cleanUid,
      'authUid': cleanUid,
      'phoneNumber': fullPhoneNumber,
      'phone': fullPhoneNumber,
      'mainPhone': fullPhoneNumber,
      'role': 'owner',
      'profileCompleted': false,
      'isActive': true,
      'pets': <Map<String, dynamic>>[],
      'createdAt':
          FieldValue.serverTimestamp(),
      'updatedAt':
          FieldValue.serverTimestamp(),
    };

    await ownerRef.set(
      newOwnerData,
      SetOptions(
        merge: true,
      ),
    );

    return newOwnerData;
  }

  // ============================================================
  // LOAD OWNER PROFILE
  // ============================================================

  Future<Map<String, dynamic>>
      getOwnerProfile({
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

    final DocumentSnapshot<Map<String, dynamic>>
        snapshot =
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

    return snapshot.data() ??
        <String, dynamic>{};
  }

  // ============================================================
  // AUTHENTICATE OWNER
  // ============================================================

  Future<OwnerAuthResult>
      authenticateOwner({
    required String phoneNumber,
  }) async {
    // ----------------------------------------------------------
    // 1. PHONE
    // ----------------------------------------------------------

    final String cleanPhone =
        _normalizePhoneNumber(
      phoneNumber,
    );

    final String fullPhoneNumber =
        '+91$cleanPhone';

    // ----------------------------------------------------------
    // 2. FIREBASE SESSION
    // ----------------------------------------------------------

    final String uid =
        await getFirebaseUid();

    // ----------------------------------------------------------
    // 3. OWNER ID
    // ----------------------------------------------------------

    final String ownerId =
        await getOwnerId(
      phoneNumber: cleanPhone,
    );

    // ----------------------------------------------------------
    // 4. PHONE ACCOUNT
    // ----------------------------------------------------------

    await savePhoneAccount(
      uid: uid,
      ownerId: ownerId,
      phoneNumber: cleanPhone,
    );

    // ----------------------------------------------------------
    // 5. OWNER
    // ----------------------------------------------------------

    await createOwnerIfMissing(
      ownerId: ownerId,
      uid: uid,
      phoneNumber: cleanPhone,
    );

    // ----------------------------------------------------------
    // 6. LOAD FINAL OWNER PROFILE
    // ----------------------------------------------------------

    final Map<String, dynamic> profileData =
        await getOwnerProfile(
      ownerId: ownerId,
    );

    // ----------------------------------------------------------
    // 7. STATUS
    // ----------------------------------------------------------

    final bool isActive =
        profileData['isActive'] != false;

    final bool profileCompleted =
        profileData['profileCompleted'] == true;

    return OwnerAuthResult(
      uid: uid,
      ownerId: ownerId,
      phoneNumber: fullPhoneNumber,
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

// ============================================================
// OWNER AUTH RESULT
// ============================================================

class OwnerAuthResult {
  final String uid;
  final String ownerId;
  final String phoneNumber;
  final Map<String, dynamic> profileData;
  final bool isActive;
  final bool profileCompleted;

  const OwnerAuthResult({
    required this.uid,
    required this.ownerId,
    required this.phoneNumber,
    required this.profileData,
    required this.isActive,
    required this.profileCompleted,
  });
}
