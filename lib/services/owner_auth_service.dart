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
  //
  // IMPORTANT:
  //
  // This method is ONLY for cases where a Firebase session is
  // actually required.
  //
  // It is NOT used to decide whether the phone number already
  // has an Owner account.
  //
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
  // FULL PHONE
  // ============================================================

  String _fullPhone(
    String phoneNumber,
  ) {
    final String cleanPhone =
        _normalizePhoneNumber(
      phoneNumber,
    );

    return '+91$cleanPhone';
  }

  // ============================================================
  // FIND EXISTING PHONE ACCOUNT
  // ============================================================
  //
  // IMPORTANT:
  //
  // DO THIS BEFORE CREATING A NEW UID.
  //
  // Existing documents may contain:
  //
  // phoneNumber
  // phone
  // mainPhone
  //
  // Therefore we check all three fields.
  //
  // ============================================================

  Future<Map<String, dynamic>?>
      findExistingPhoneAccount({
    required String phoneNumber,
  }) async {
    final String fullPhoneNumber =
        _fullPhone(phoneNumber);

    // ----------------------------------------------------------
    // CHECK phoneNumber
    // ----------------------------------------------------------

    final QuerySnapshot<Map<String, dynamic>>
        phoneNumberQuery =
        await _firestore
            .collection(
              _phoneAccountsCollection,
            )
            .where(
              'phoneNumber',
              isEqualTo: fullPhoneNumber,
            )
            .limit(1)
            .get();

    if (phoneNumberQuery.docs.isNotEmpty) {
      final Map<String, dynamic> data =
          phoneNumberQuery.docs.first.data();

      data['_documentId'] =
          phoneNumberQuery.docs.first.id;

      return data;
    }

    // ----------------------------------------------------------
    // CHECK phone
    // ----------------------------------------------------------

    final QuerySnapshot<Map<String, dynamic>>
        phoneQuery =
        await _firestore
            .collection(
              _phoneAccountsCollection,
            )
            .where(
              'phone',
              isEqualTo: fullPhoneNumber,
            )
            .limit(1)
            .get();

    if (phoneQuery.docs.isNotEmpty) {
      final Map<String, dynamic> data =
          phoneQuery.docs.first.data();

      data['_documentId'] =
          phoneQuery.docs.first.id;

      return data;
    }

    // ----------------------------------------------------------
    // CHECK mainPhone
    // ----------------------------------------------------------

    final QuerySnapshot<Map<String, dynamic>>
        mainPhoneQuery =
        await _firestore
            .collection(
              _phoneAccountsCollection,
            )
            .where(
              'mainPhone',
              isEqualTo: fullPhoneNumber,
            )
            .limit(1)
            .get();

    if (mainPhoneQuery.docs.isNotEmpty) {
      final Map<String, dynamic> data =
          mainPhoneQuery.docs.first.data();

      data['_documentId'] =
          mainPhoneQuery.docs.first.id;

      return data;
    }

    return null;
  }

  // ============================================================
  // FIND EXISTING OWNER BY PHONE
  // ============================================================
  //
  // This is a fallback.
  //
  // If phoneAccounts does not contain the mapping but the Owner
  // profile already contains the phone number, restore that
  // Owner instead of creating a new Owner ID.
  //
  // ============================================================

  Future<Map<String, dynamic>?>
      findExistingOwnerByPhone({
    required String phoneNumber,
  }) async {
    final String fullPhoneNumber =
        _fullPhone(phoneNumber);

    // ----------------------------------------------------------
    // phoneNumber
    // ----------------------------------------------------------

    final QuerySnapshot<Map<String, dynamic>>
        phoneNumberQuery =
        await _firestore
            .collection(
              _ownersCollection,
            )
            .where(
              'phoneNumber',
              isEqualTo: fullPhoneNumber,
            )
            .limit(1)
            .get();

    if (phoneNumberQuery.docs.isNotEmpty) {
      final Map<String, dynamic> data =
          phoneNumberQuery.docs.first.data();

      data['_documentId'] =
          phoneNumberQuery.docs.first.id;

      return data;
    }

    // ----------------------------------------------------------
    // phone
    // ----------------------------------------------------------

    final QuerySnapshot<Map<String, dynamic>>
        phoneQuery =
        await _firestore
            .collection(
              _ownersCollection,
            )
            .where(
              'phone',
              isEqualTo: fullPhoneNumber,
            )
            .limit(1)
            .get();

    if (phoneQuery.docs.isNotEmpty) {
      final Map<String, dynamic> data =
          phoneQuery.docs.first.data();

      data['_documentId'] =
          phoneQuery.docs.first.id;

      return data;
    }

    // ----------------------------------------------------------
    // mainPhone
    // ----------------------------------------------------------

    final QuerySnapshot<Map<String, dynamic>>
        mainPhoneQuery =
        await _firestore
            .collection(
              _ownersCollection,
            )
            .where(
              'mainPhone',
              isEqualTo: fullPhoneNumber,
            )
            .limit(1)
            .get();

    if (mainPhoneQuery.docs.isNotEmpty) {
      final Map<String, dynamic> data =
          mainPhoneQuery.docs.first.data();

      data['_documentId'] =
          mainPhoneQuery.docs.first.id;

      return data;
    }

    return null;
  }

  // ============================================================
  // GET / CREATE OWNER ID
  // ============================================================
  //
  // IMPORTANT:
  //
  // This method is now SAFE:
  //
  // 1. First search existing phone account.
  // 2. Then search existing Owner.
  // 3. ONLY if nothing exists, create Firebase UID.
  // 4. ONLY then create Owner ID.
  //
  // ============================================================

  Future<String> getOwnerId({
    required String phoneNumber,
  }) async {
    final String cleanPhone =
        _normalizePhoneNumber(
      phoneNumber,
    );

    final String fullPhoneNumber =
        '+91$cleanPhone';

    // ----------------------------------------------------------
    // 1. EXISTING PHONE ACCOUNT
    // ----------------------------------------------------------

    final Map<String, dynamic>?
        existingPhoneAccount =
        await findExistingPhoneAccount(
      phoneNumber: fullPhoneNumber,
    );

    if (existingPhoneAccount != null) {
      final String existingOwnerId =
          (existingPhoneAccount['ownerId'] ??
                  '')
              .toString()
              .trim();

      if (existingOwnerId.isNotEmpty) {
        return existingOwnerId;
      }
    }

    // ----------------------------------------------------------
    // 2. EXISTING OWNER PROFILE
    // ----------------------------------------------------------

    final Map<String, dynamic>?
        existingOwner =
        await findExistingOwnerByPhone(
      phoneNumber: fullPhoneNumber,
    );

    if (existingOwner != null) {
      final String existingOwnerId =
          (existingOwner['ownerId'] ??
                  existingOwner['_documentId'] ??
                  '')
              .toString()
              .trim();

      if (existingOwnerId.isNotEmpty) {
        return existingOwnerId;
      }
    }

    // ----------------------------------------------------------
    // 3. NO ACCOUNT FOUND
    //
    // NOW we are allowed to create/restore Firebase session.
    // ----------------------------------------------------------

    final String uid =
        await getFirebaseUid();

    // ----------------------------------------------------------
    // 4. CREATE NEW OWNER ID
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
      final Map<String, dynamic> existingData =
          snapshot.data() ??
              <String, dynamic>{};

      // --------------------------------------------------------
      // IMPORTANT:
      //
      // DO NOT overwrite the existing UID.
      //
      // The UID already stored in the existing Owner profile
      // belongs to that existing account.
      // --------------------------------------------------------

      await ownerRef.set(
        <String, dynamic>{
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

      return existingData;
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
  //
  // This method is kept because other parts of the app may use
  // it.
  //
  // It now checks PHONE FIRST.
  //
  // ============================================================

  Future<OwnerAuthResult>
      authenticateOwner({
    required String phoneNumber,
  }) async {
    final String cleanPhone =
        _normalizePhoneNumber(
      phoneNumber,
    );

    final String fullPhoneNumber =
        '+91$cleanPhone';

    // ==========================================================
    // 1. SEARCH EXISTING PHONE ACCOUNT FIRST
    // ==========================================================

    final Map<String, dynamic>?
        existingPhoneAccount =
        await findExistingPhoneAccount(
      phoneNumber: fullPhoneNumber,
    );

    String? existingOwnerId;
    String? existingUid;

    if (existingPhoneAccount != null) {
      existingOwnerId =
          (existingPhoneAccount['ownerId'] ??
                  '')
              .toString()
              .trim();

      existingUid =
          (existingPhoneAccount['authUid'] ??
                  existingPhoneAccount['uid'] ??
                  '')
              .toString()
              .trim();
    }

    // ==========================================================
    // 2. FALLBACK: SEARCH OWNER PROFILE BY PHONE
    // ==========================================================

    Map<String, dynamic>?
        existingOwner;

    if (existingOwnerId == null ||
        existingOwnerId.isEmpty) {
      existingOwner =
          await findExistingOwnerByPhone(
        phoneNumber: fullPhoneNumber,
      );

      if (existingOwner != null) {
        existingOwnerId =
            (existingOwner['ownerId'] ??
                    existingOwner['_documentId'] ??
                    '')
                .toString()
                .trim();

        existingUid =
            (existingOwner['authUid'] ??
                    existingOwner['uid'] ??
                    '')
                .toString()
                .trim();
      }
    }

    // ==========================================================
    // 3. EXISTING OWNER FOUND
    // ==========================================================

    if (existingOwnerId != null &&
        existingOwnerId.isNotEmpty) {
      final Map<String, dynamic>
          profileData =
          await getOwnerProfile(
        ownerId: existingOwnerId,
      );

      final bool isActive =
          profileData['isActive'] != false;

      final bool profileCompleted =
          profileData['profileCompleted'] == true;

      // --------------------------------------------------------
      // IMPORTANT:
      //
      // Existing UID is NOT replaced with a new anonymous UID.
      // --------------------------------------------------------

      return OwnerAuthResult(
        uid: existingUid ?? '',
        ownerId: existingOwnerId,
        phoneNumber: fullPhoneNumber,
        profileData: profileData,
        isActive: isActive,
        profileCompleted: profileCompleted,
      );
    }

    // ==========================================================
    // 4. NO EXISTING OWNER
    //
    // ONLY NOW create Firebase UID.
    // ==========================================================

    final String newUid =
        await getFirebaseUid();

    // ==========================================================
    // 5. CREATE NEW OWNER ID
    // ==========================================================

    final String newOwnerId =
        await OwnerIdService.instance
            .getOrCreateOwnerId(
      uid: newUid,
      phoneNumber: fullPhoneNumber,
    );

    if (newOwnerId.trim().isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'owner-id-missing',
        message:
            'Owner ID could not be created.',
      );
    }

    // ==========================================================
    // 6. CREATE OWNER
    // ==========================================================

    final Map<String, dynamic>
        newProfile =
        await createOwnerIfMissing(
      ownerId: newOwnerId,
      uid: newUid,
      phoneNumber: fullPhoneNumber,
    );

    // ==========================================================
    // 7. SAVE PHONE MAPPING
    // ==========================================================

    await savePhoneAccount(
      uid: newUid,
      ownerId: newOwnerId,
      phoneNumber: fullPhoneNumber,
    );

    // ==========================================================
    // 8. RESULT
    // ==========================================================

    return OwnerAuthResult(
      uid: newUid,
      ownerId: newOwnerId,
      phoneNumber: fullPhoneNumber,
      profileData: newProfile,
      isActive:
          newProfile['isActive'] != false,
      profileCompleted:
          newProfile['profileCompleted'] == true,
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
