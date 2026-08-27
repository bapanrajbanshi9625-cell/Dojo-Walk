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
    return PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode.trim(),
    );
  }

  // ============================================================
  // UPDATE FIREBASE AUTH PHONE
  // ============================================================

  Future<User> updateFirebasePhone({
    required PhoneAuthCredential credential,
  }) async {
    final User? user =
        _auth.currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message:
            'User session was not found.',
      );
    }

    await user.updatePhoneNumber(
      credential,
    );

    return user;
  }

  // ============================================================
  // UPDATE OWNER FIRESTORE DOCUMENT
  //
  // Firestore structure:
  //
  // owners/{documentId}
  // authUid
  // ownerId
  // mainPhone
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
    // FIRST: find owner by ownerId field
    // ----------------------------------------------------------

    final QuerySnapshot<
        Map<String, dynamic>> ownerQuery =
        await _firestore
            .collection('owners')
            .where(
              'ownerId',
              isEqualTo: cleanOwnerId,
            )
            .limit(1)
            .get();

    if (ownerQuery.docs.isNotEmpty) {
      await ownerQuery.docs.first.reference
          .set(
        <String, dynamic>{
          'mainPhone': cleanPhone,
          'phone': cleanPhone,
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      return;
    }

    // ----------------------------------------------------------
    // SECOND: document ID may itself be ownerId
    // ----------------------------------------------------------

    final DocumentSnapshot<
        Map<String, dynamic>> directDoc =
        await _firestore
            .collection('owners')
            .doc(cleanOwnerId)
            .get();

    if (directDoc.exists) {
      await directDoc.reference.set(
        <String, dynamic>{
          'mainPhone': cleanPhone,
          'phone': cleanPhone,
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      return;
    }

    throw FirebaseException(
      plugin: 'cloud_firestore',
      code: 'owner-not-found',
      message:
          'Owner profile was not found.',
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
    // ----------------------------------------------------------
    // STEP 1: Firebase Auth
    // ----------------------------------------------------------

    await updateFirebasePhone(
      credential: credential,
    );

    // ----------------------------------------------------------
    // STEP 2: Firestore owner profile
    // ----------------------------------------------------------

    await updateOwnerPhone(
      ownerId: ownerId,
      phoneNumber: newPhoneNumber,
    );
  }
}
