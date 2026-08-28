import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'owner_id_service.dart';

/// ============================================================
/// OWNER AUTH SERVICE
/// ============================================================
///
/// जिम्मेदारी:
/// - Firebase session create / restore
/// - Firebase UID प्राप्त करना
/// - Owner ID प्राप्त / create करना
/// - phoneAccounts/{uid} save करना
/// - owners/{ownerId} create / load करना
/// - isActive check करना
/// - profileCompleted check करना
///
/// यह service:
/// - MSG91 OTP verify नहीं करती
/// - OTP resend नहीं करती
/// - Navigation नहीं करती
/// - Profile setup UI नहीं संभालती
///
/// Flow:
///
/// MSG91 OTP verified
///        ↓
/// OwnerAuthService
///        ↓
/// Firebase session
///        ↓
/// Firebase UID
///        ↓
/// OwnerIdService
///        ↓
/// phoneAccounts/{uid}
///        ↓
/// owners/{ownerId}
///        ↓
/// profileCompleted
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
  // COLLECTIONS
  // ============================================================

  static const String _ownersCollection =
      'owners';

  static const String _phoneAccountsCollection =
      'phoneAccounts';

  // ============================================================
  // CREATE / RESTORE FIREBASE SESSION
  // ============================================================

  Future<User> createOrRestoreSession() async {
    User? user =
        _auth.currentUser;

    // ----------------------------------------------------------
    // EXISTING SESSION
    // ----------------------------------------------------------

    if (user != null) {
      return user;
    }

    // ----------------------------------------------------------
    // CREATE FIREBASE ANONYMOUS SESSION
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
  // NORMALIZE PHONE NUMBER
  // ============================================================
  //
  // IMPORTANT:
  // यहां कोई substring / last-10-digits logic नहीं है.
  //
  // यह method केवल:
  // - spaces हटाता है
  // - + / - / brackets जैसे characters हटाता है
  // - exactly 10 digits check करता है
  // - Indian mobile number validate करता है
  //
  // ============================================================

  String _normalizePhoneNumber(
    String phoneNumber,
  ) {
    final String cleanPhone =
        phoneNumber.trim().replaceAll(
          RegExp(r'[^0-9]'),
          '',
        );

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

    // ----------------------------------------------------------
    // EXISTING OWNER ID SERVICE
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
  // SAVE PHONE ACCOUNT
  // ============================================================
  ///
  /// Firestore:
  ///
  /// phoneAccounts/{uid}
  ///
  /// SplashScreen इसी document को पढ़ता है.
  ///
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

    final DocumentReference<
        Map<String, dynamic>> accountRef =
        _firestore
            .collection(
              _phoneAccountsCollection,
            )
            .doc(cleanUid);

    await accountRef.set(
      <String, dynamic>{
        'uid': cleanUid,
        'ownerId': cleanOwnerId,
        'phoneNumber': '+91$cleanPhone',
        'phone': cleanPhone,
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    print(
      'OwnerAuthService: phone account saved.',
    );

    print(
      'Firebase UID: $cleanUid',
    );

    print(
      'Owner ID: $cleanOwnerId',
    );
  }

  // ============================================================
  // CREATE OWNER IF MISSING
  // ============================================================
  ///
  /// Firestore:
  ///
  /// owners/{ownerId}
  ///
  /// नया user पहली बार login करे तो document
  /// automatically create होगा.
  ///
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

    final DocumentReference<
        Map<String, dynamic>> ownerRef =
        _firestore
            .collection(_ownersCollection)
            .doc(cleanOwnerId);

    final DocumentSnapshot<
        Map<String, dynamic>> snapshot =
        await ownerRef.get();

    // ----------------------------------------------------------
    // EXISTING OWNER
    // ----------------------------------------------------------

    if (snapshot.exists) {
      final Map<String, dynamic>? existingData =
          snapshot.data();

      final Map<String, dynamic> data =
          existingData ??
              <String, dynamic>{};

      await ownerRef.set(
        <String, dynamic>{
          'ownerId': cleanOwnerId,
          'uid': cleanUid,
          'phoneNumber': '+91$cleanPhone',
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      print(
        'OwnerAuthService: existing owner updated.',
      );

      return data;
    }

    // ----------------------------------------------------------
    // NEW OWNER
    // ----------------------------------------------------------

    final Map<String, dynamic> newOwnerData =
        <String, dynamic>{
      'ownerId': cleanOwnerId,
      'uid': cleanUid,
      'phoneNumber': '+91$cleanPhone',

      // Profile setup अभी बाकी है.
      'profileCompleted': false,

      // New account active रहेगा.
      'isActive': true,

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

    print(
      'OwnerAuthService: new owner created.',
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

    return data ??
        <String, dynamic>{};
  }

  // ============================================================
  // AUTHENTICATE OWNER
  // ============================================================
  ///
  /// MSG91 OTP successfully verify होने के बाद
  /// OtpVerificationScreen से इसे call करें.
  ///
  // ============================================================

  Future<OwnerAuthResult>
      authenticateOwner({
    required String phoneNumber,
  }) async {
    // ----------------------------------------------------------
    // 1. VALIDATE PHONE
    // ----------------------------------------------------------

    final String cleanPhone =
        _normalizePhoneNumber(
      phoneNumber,
    );

    // ----------------------------------------------------------
    // 2. FIREBASE SESSION
    // ----------------------------------------------------------

    final String uid =
        await getFirebaseUid();

    print(
      'OwnerAuthService: Firebase UID = $uid',
    );

    // ----------------------------------------------------------
    // 3. OWNER ID
    // ----------------------------------------------------------

    final String ownerId =
        await getOwnerId(
      phoneNumber: cleanPhone,
    );

    print(
      'OwnerAuthService: Owner ID = $ownerId',
    );

    // ----------------------------------------------------------
    // 4. SAVE PHONE ACCOUNT
    // ----------------------------------------------------------

    await savePhoneAccount(
      uid: uid,
      ownerId: ownerId,
      phoneNumber: cleanPhone,
    );

    // ----------------------------------------------------------
    // 5. CREATE OWNER IF MISSING
    // ----------------------------------------------------------

    await createOwnerIfMissing(
      ownerId: ownerId,
      uid: uid,
      phoneNumber: cleanPhone,
    );

    // ----------------------------------------------------------
    // 6. LOAD OWNER PROFILE
    // ----------------------------------------------------------

    final Map<String, dynamic> profileData =
        await getOwnerProfile(
      ownerId: ownerId,
    );

    // ----------------------------------------------------------
    // 7. ACTIVE STATUS
    // ----------------------------------------------------------

    final bool isActive =
        profileData['isActive'] != false;

    // ----------------------------------------------------------
    // 8. PROFILE COMPLETED
    // ----------------------------------------------------------

    final bool profileCompleted =
        profileData['profileCompleted'] == true;

    print(
      'OwnerAuthService: isActive = $isActive',
    );

    print(
      'OwnerAuthService: profileCompleted = '
      '$profileCompleted',
    );

    // ----------------------------------------------------------
    // 9. RETURN RESULT
    // ----------------------------------------------------------

    return OwnerAuthResult(
      uid: uid,
      ownerId: ownerId,
      phoneNumber: '+91$cleanPhone',
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

    print(
      'OwnerAuthService: Firebase session signed out.',
    );
  }
}

/// ============================================================
/// OWNER AUTH RESULT
/// ============================================================

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
