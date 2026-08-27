// File:
// lib/features/profile/change_mobile/change_mobile_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangeMobileService {
  ChangeMobileService._();

  static final ChangeMobileService instance =
      ChangeMobileService._();

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // SEND OTP
  // ============================================================

  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    void Function(int? resendToken)? onResendToken,
    required void Function(
      FirebaseAuthException error,
    ) onVerificationFailed,
    required void Function(
      PhoneAuthCredential credential,
    ) onVerificationCompleted,
  }) async {
    final String phone =
        phoneNumber.trim();

    if (phone.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-phone-number',
        message:
            'Please enter a valid mobile number.',
      );
    }

    await _auth.verifyPhoneNumber(
      phoneNumber: phone,

      verificationCompleted:
          onVerificationCompleted,

      verificationFailed:
          onVerificationFailed,

      codeSent: (
        String verificationId,
        int? resendToken,
      ) {
        onResendToken?.call(
          resendToken,
        );

        onCodeSent(
          verificationId,
        );
      },

      codeAutoRetrievalTimeout: (
        String verificationId,
      ) {},
    );
  }

  // ============================================================
  // CREATE CREDENTIAL
  // ============================================================

  PhoneAuthCredential createCredential({
    required String verificationId,
    required String smsCode,
  }) {
    final String cleanOtp =
        smsCode.trim();

    if (verificationId.trim().isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-verification-id',
        message:
            'OTP verification session is invalid.',
      );
    }

    if (cleanOtp.length != 6) {
      throw FirebaseAuthException(
        code: 'invalid-verification-code',
        message:
            'Please enter the 6-digit OTP.',
      );
    }

    return PhoneAuthProvider.credential(
      verificationId:
          verificationId.trim(),
      smsCode: cleanOtp,
    );
  }

  // ============================================================
  // GET CURRENT FIREBASE USER
  // ============================================================

  User _requireCurrentUser() {
    final User? user =
        _auth.currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message:
            'User session was not found. Please login again.',
      );
    }

    return user;
  }

  // ============================================================
  // FIND OWNER DOCUMENT BY AUTH UID
  //
  // Actual Firestore structure:
  //
  // owners/{documentId}
  //   authUid: "Firebase UID"
  //   ownerId: "OWN26GH0004"
  //   mainPhone: "+91..."
  //
  // ============================================================

  Future<DocumentReference<
      Map<String, dynamic>>> findOwnerDocument() async {
    final User user =
        _requireCurrentUser();

    final String uid =
        user.uid.trim();

    if (uid.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-auth-uid',
        message:
            'Firebase Auth UID was not found.',
      );
    }

    // ----------------------------------------------------------
    // FIRST: owners/{uid}
    // ----------------------------------------------------------

    final DocumentSnapshot<
        Map<String, dynamic>> directDoc =
        await _firestore
            .collection('owners')
            .doc(uid)
            .get();

    if (directDoc.exists) {
      return directDoc.reference;
    }

    // ----------------------------------------------------------
    // SECOND: authUid field
    // ----------------------------------------------------------

    final QuerySnapshot<
        Map<String, dynamic>> query =
        await _firestore
            .collection('owners')
            .where(
              'authUid',
              isEqualTo: uid,
            )
            .limit(1)
            .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first.reference;
    }

    throw FirebaseException(
      plugin: 'cloud_firestore',
      code: 'owner-not-found',
      message:
          'Owner profile was not found.',
    );
  }

  // ============================================================
  // GET OWNER ID
  // ============================================================

  Future<String> getOwnerId() async {
    final DocumentReference<
        Map<String, dynamic>> ownerRef =
        await findOwnerDocument();

    final DocumentSnapshot<
        Map<String, dynamic>> snapshot =
        await ownerRef.get();

    final Map<String, dynamic>? data =
        snapshot.data();

    if (data == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'owner-profile-empty',
        message:
            'Owner profile data was not found.',
      );
    }

    final dynamic ownerId =
        data['ownerId'];

    if (ownerId is String &&
        ownerId.trim().isNotEmpty) {
      return ownerId.trim();
    }

    // Fallback:
    // If the document ID itself is the owner ID.
    if (ownerRef.id.trim().isNotEmpty) {
      return ownerRef.id.trim();
    }

    throw FirebaseException(
      plugin: 'cloud_firestore',
      code: 'owner-id-not-found',
      message:
          'Owner ID was not found.',
    );
  }

  // ============================================================
  // UPDATE FIREBASE AUTH PHONE
  // ============================================================

  Future<User> updateFirebasePhone({
    required PhoneAuthCredential credential,
  }) async {
    final User user =
        _requireCurrentUser();

    await user.updatePhoneNumber(
      credential,
    );

    await user.reload();

    final User? refreshedUser =
        _auth.currentUser;

    if (refreshedUser == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message:
            'User session was lost after phone verification.',
      );
    }

    return refreshedUser;
  }

  // ============================================================
  // UPDATE OWNER FIRESTORE PHONE
  //
  // IMPORTANT:
  // Actual field = mainPhone
  //
  // We also keep authUid synchronized.
  //
  // ============================================================

  Future<void> updateOwnerPhone({
    required String ownerId,
    required String phoneNumber,
  }) async {
    final String cleanOwnerId =
        ownerId.trim();

    final String cleanPhone =
        phoneNumber.trim();

    if (cleanOwnerId.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-owner-id',
        message:
            'Owner ID was not found.',
      );
    }

    if (cleanPhone.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-phone-number',
        message:
            'Mobile number is invalid.',
      );
    }

    // ----------------------------------------------------------
    // Find exact owner document using ownerId field
    // ----------------------------------------------------------

    QuerySnapshot<
        Map<String, dynamic>> query =
        await _firestore
            .collection('owners')
            .where(
              'ownerId',
              isEqualTo: cleanOwnerId,
            )
            .limit(1)
            .get();

    DocumentReference<
        Map<String, dynamic>> ownerRef;

    if (query.docs.isNotEmpty) {
      ownerRef =
          query.docs.first.reference;
    } else {
      // --------------------------------------------------------
      // Fallback: document ID = ownerId
      // --------------------------------------------------------

      final DocumentReference<
          Map<String, dynamic>> directRef =
          _firestore
              .collection('owners')
              .doc(cleanOwnerId);

      final DocumentSnapshot<
          Map<String, dynamic>> directDoc =
          await directRef.get();

      if (!directDoc.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'owner-not-found',
          message:
              'Owner profile was not found.',
        );
      }

      ownerRef = directRef;
    }

    // ----------------------------------------------------------
    // Current Firebase UID
    // ----------------------------------------------------------

    final User user =
        _requireCurrentUser();

    // ----------------------------------------------------------
    // Update ONLY the correct phone field
    // ----------------------------------------------------------

    await ownerRef.set(
      <String, dynamic>{
        'mainPhone': cleanPhone,
        'authUid': user.uid,
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );
  }

  // ============================================================
  // COMPLETE MOBILE CHANGE
  // ============================================================

  Future<void> completeMobileChange({
    required String ownerId,
    required PhoneAuthCredential credential,
    required String newPhoneNumber,
  }) async {
    final String cleanPhone =
        newPhoneNumber.trim();

    if (cleanPhone.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-phone-number',
        message:
            'Mobile number is invalid.',
      );
    }

    // ----------------------------------------------------------
    // STEP 1
    // Verify OTP and update Firebase Auth
    // ----------------------------------------------------------

    await updateFirebasePhone(
      credential: credential,
    );

    // ----------------------------------------------------------
    // STEP 2
    // Update Firestore owner profile
    // ----------------------------------------------------------

    await updateOwnerPhone(
      ownerId: ownerId,
      phoneNumber: cleanPhone,
    );
  }
}
