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
    required void Function(FirebaseAuthException error) onVerificationFailed,
    required void Function(PhoneAuthCredential credential)
        onVerificationCompleted,
  }) async {
    final String phone = phoneNumber.trim();

    if (phone.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-phone-number',
        message: 'Please enter a valid mobile number.',
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
        onCodeSent(verificationId);
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
    final User? user = _auth.currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'User session was not found.',
      );
    }

    await user.updatePhoneNumber(
      credential,
    );

    return user;
  }

  // ============================================================
  // UPDATE OWNER FIRESTORE DOCUMENT
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
        message: 'Owner ID was not found.',
      );
    }

    if (cleanPhone.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-phone-number',
        message: 'Mobile number is invalid.',
      );
    }

    await _firestore
        .collection('owners')
        .doc(cleanOwnerId)
        .set(
      <String, dynamic>{
        'phone': cleanPhone,
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
    await updateFirebasePhone(
      credential: credential,
    );

    await updateOwnerPhone(
      ownerId: ownerId,
      phoneNumber: newPhoneNumber,
    );
  }
}
