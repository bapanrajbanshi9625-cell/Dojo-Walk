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

  static const String _ownersCollection = 'owners';
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

    final String uid = user.uid.trim();

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
    return OwnerIdService.instance
        .normalizePhone(phoneNumber);
  }

  String _fullPhone(
    String phoneNumber,
  ) {
    return '+91${_normalizePhoneNumber(phoneNumber)}';
  }

  // ============================================================
  // FIND EXISTING PHONE ACCOUNT
  // ============================================================

  Future<Map<String, dynamic>?>
      findExistingPhoneAccount({
    required String phoneNumber,
  }) async {
    final String cleanPhone =
        _normalizePhoneNumber(phoneNumber);

    final List<String> variants =
        OwnerIdService.instance
            .phoneVariants(cleanPhone);

    for (final String variant in variants) {
      for (final String field in <String>[
        'phoneNumber',
        'phone',
        'mainPhone',
      ]) {
        final QuerySnapshot<Map<String, dynamic>>
            query =
            await _firestore
                .collection(
                  _phoneAccountsCollection,
                )
                .where(
                  field,
                  isEqualTo: variant,
                )
                .limit(1)
                .get();

        if (query.docs.isNotEmpty) {
          final Map<String, dynamic> data =
              query.docs.first.data();

          data['_documentId'] =
              query.docs.first.id;

          return data;
        }
      }
    }

    return null;
  }

  // ============================================================
  // FIND EXISTING OWNER BY PHONE
  // ============================================================

  Future<Map<String, dynamic>?>
      findExistingOwnerByPhone({
    required String phoneNumber,
  }) async {
    final String cleanPhone =
        _normalizePhoneNumber(phoneNumber);

    final List<String> variants =
        OwnerIdService.instance
            .phoneVariants(cleanPhone);

    for (final String variant in variants) {
      for (final String field in <String>[
        'phoneNumber',
        'phone',
        'mainPhone',
      ]) {
        final QuerySnapshot<Map<String, dynamic>>
            query =
            await _firestore
                .collection(_ownersCollection)
                .where(
                  field,
                  isEqualTo: variant,
                )
                .limit(1)
                .get();

        if (query.docs.isNotEmpty) {
          final DocumentSnapshot<Map<String, dynamic>>
              doc =
              query.docs.first;

          final Map<String, dynamic> data =
              doc.data() ?? <String, dynamic>{};

          data['_documentId'] = doc.id;

          return data;
        }
      }
    }

    return null;
  }

  // ============================================================
  // GET / CREATE OWNER ID
  // ============================================================

  Future<String> getOwnerId({
    required String phoneNumber,
  }) async {
    final String cleanPhone =
        _normalizePhoneNumber(phoneNumber);

    // ==========================================================
    // 1. PHONE FIRST
    // ==========================================================

    final String? existingOwnerId =
        await OwnerIdService.instance
            .findExistingOwnerIdByPhone(
      phoneNumber: cleanPhone,
    );

    if (existingOwnerId != null &&
        existingOwnerId.trim().isNotEmpty) {
      return existingOwnerId.trim();
    }

    // ==========================================================
    // 2. ONLY NEW PHONE REACHES FIREBASE UID CREATION
    // ==========================================================

    final String uid =
        await getFirebaseUid();

    // ==========================================================
    // 3. CREATE OWNER ID
    // ==========================================================

    return OwnerIdService.instance
        .getOrCreateOwnerId(
      uid: uid,
      phoneNumber: '+91$cleanPhone',
    );
  }

  // ============================================================
  // SAVE PHONE ACCOUNT
  // ============================================================

  Future<void> savePhoneAccount({
    required String uid,
    required String ownerId,
    required String phoneNumber,
  }) async {
    final String cleanUid = uid.trim();
    final String cleanOwnerId = ownerId.trim();
    final String cleanPhone =
        _normalizePhoneNumber(phoneNumber);

    if (cleanUid.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-user',
        message: 'Firebase UID is empty.',
      );
    }

    if (cleanOwnerId.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'owner-id-missing',
        message: 'Owner ID is empty.',
      );
    }

    final String fullPhoneNumber =
        '+91$cleanPhone';

    final DocumentReference<Map<String, dynamic>>
        accountRef =
        _firestore
            .collection(_phoneAccountsCollection)
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
      SetOptions(merge: true),
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
    final String cleanOwnerId = ownerId.trim();
    final String cleanUid = uid.trim();
    final String cleanPhone =
        _normalizePhoneNumber(phoneNumber);

    if (cleanOwnerId.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'owner-id-missing',
        message: 'Owner ID is empty.',
      );
    }

    if (cleanUid.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-user',
        message: 'Firebase UID is empty.',
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
          snapshot.data() ?? <String, dynamic>{};

      // DO NOT overwrite UID.
      // DO NOT overwrite profileCompleted.

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
        SetOptions(merge: true),
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
      SetOptions(merge: true),
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
        message: 'Owner ID is empty.',
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
    final String cleanPhone =
        _normalizePhoneNumber(phoneNumber);

    final String fullPhoneNumber =
        '+91$cleanPhone';

    // ==========================================================
    // 1. PHONE ACCOUNT FIRST
    // ==========================================================

    final Map<String, dynamic>?
        existingPhoneAccount =
        await findExistingPhoneAccount(
      phoneNumber: fullPhoneNumber,
    );

    String? ownerId;
    String? existingUid;

    if (existingPhoneAccount != null) {
      ownerId =
          (existingPhoneAccount['ownerId'] ?? '')
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
    // 2. OWNER PROFILE FALLBACK
    // ==========================================================

    if (ownerId == null || ownerId.isEmpty) {
      final Map<String, dynamic>?
          existingOwner =
          await findExistingOwnerByPhone(
        phoneNumber: fullPhoneNumber,
      );

      if (existingOwner != null) {
        ownerId =
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
    // 3. EXISTING OWNER
    // ==========================================================

    if (ownerId != null && ownerId.isNotEmpty) {
      final Map<String, dynamic> profile =
          await getOwnerProfile(
        ownerId: ownerId,
      );

      final bool profileCompleted =
          profile['profileCompleted'] == true;

      final bool isActive =
          profile['isActive'] != false;

      return OwnerAuthResult(
        uid: existingUid ?? '',
        ownerId: ownerId,
        phoneNumber: fullPhoneNumber,
        profileCompleted: profileCompleted,
        isActive: isActive,
        isExistingOwner: true,
        profile: profile,
      );
    }

    // ==========================================================
    // 4. BRAND NEW PHONE
    // ==========================================================

    final String uid =
        await getFirebaseUid();

    final String newOwnerId =
        await OwnerIdService.instance
            .getOrCreateOwnerId(
      uid: uid,
      phoneNumber: fullPhoneNumber,
    );

    final Map<String, dynamic> newProfile =
        await createOwnerIfMissing(
      ownerId: newOwnerId,
      uid: uid,
      phoneNumber: fullPhoneNumber,
    );

    await savePhoneAccount(
      uid: uid,
      ownerId: newOwnerId,
      phoneNumber: fullPhoneNumber,
    );

    return OwnerAuthResult(
      uid: uid,
      ownerId: newOwnerId,
      phoneNumber: fullPhoneNumber,
      profileCompleted: false,
      isActive: true,
      isExistingOwner: false,
      profile: newProfile,
    );
  }
}

// ============================================================
// OWNER AUTH RESULT
// ============================================================

class OwnerAuthResult {
  const OwnerAuthResult({
    required this.uid,
    required this.ownerId,
    required this.phoneNumber,
    required this.profileCompleted,
    required this.isActive,
    required this.isExistingOwner,
    required this.profile,
  });

  final String uid;
  final String ownerId;
  final String phoneNumber;
  final bool profileCompleted;
  final bool isActive;
  final bool isExistingOwner;
  final Map<String, dynamic> profile;

  bool get shouldOpenProfileSetup =>
      !profileCompleted;

  bool get shouldOpenHome =>
      profileCompleted && isActive;
}
