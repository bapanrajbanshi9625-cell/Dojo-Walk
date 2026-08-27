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
    required void Function(String verificationId)
        onCodeSent,
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

    final String digits =
        phone.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    String tenDigit = digits;

    if (digits.length == 12 &&
        digits.startsWith('91')) {
      tenDigit =
          digits.substring(2);
    }

    if (tenDigit.length != 10 ||
        !RegExp(
          r'^[6-9][0-9]{9}$',
        ).hasMatch(tenDigit)) {
      throw FirebaseAuthException(
        code: 'invalid-phone-number',
        message:
            'Please enter a valid 10-digit Indian mobile number.',
      );
    }

    final String normalizedPhone =
        '+91$tenDigit';

    await _auth.verifyPhoneNumber(
      phoneNumber:
          normalizedPhone,

      verificationCompleted:
          (
        PhoneAuthCredential credential,
      ) {
        // NEVER automatically change the number.
        onVerificationCompleted(
          credential,
        );
      },

      verificationFailed:
          (
        FirebaseAuthException error,
      ) {
        onVerificationFailed(
          error,
        );
      },

      codeSent: (
        String verificationId,
        int? resendToken,
      ) {
        if (verificationId.trim().isEmpty) {
          return;
        }

        onCodeSent(
          verificationId,
        );
      },

      codeAutoRetrievalTimeout:
          (
        String verificationId,
      ) {},
    );
  }

  // ============================================================
  // CREATE OTP CREDENTIAL
  // ============================================================

  PhoneAuthCredential createCredential({
    required String verificationId,
    required String smsCode,
  }) {
    final String id =
        verificationId.trim();

    final String code =
        smsCode.trim();

    if (id.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-verification-id',
        message:
            'OTP session expired. Please request a new OTP.',
      );
    }

    if (!RegExp(
      r'^[0-9]{6}$',
    ).hasMatch(code)) {
      throw FirebaseAuthException(
        code: 'invalid-verification-code',
        message:
            'Please enter the 6-digit OTP.',
      );
    }

    return PhoneAuthProvider.credential(
      verificationId: id,
      smsCode: code,
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
            'Your login session has expired. Please login again.',
      );
    }

    await user.updatePhoneNumber(
      credential,
    );

    await user.reload();

    final User? updatedUser =
        _auth.currentUser;

    if (updatedUser == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message:
            'User session was lost after mobile update.',
      );
    }

    return updatedUser;
  }

  // ============================================================
  // FIND OWNER DOCUMENT
  // ============================================================
  //
  // Firestore structure:
  //
  // owners
  //   └── <document>
  //        authUid: Firebase Auth UID
  //        ownerId: OWN26GH0004
  //        mainPhone: +919625813987
  //
  // ============================================================

  Future<DocumentSnapshot<Map<String, dynamic>>>
      _findOwnerDocument() async {
    final User? user =
        _auth.currentUser;

    if (user == null) {
      throw FirebaseException(
        plugin:
            'cloud_firestore',
        code:
            'user-not-found',
        message:
            'Your login session has expired.',
      );
    }

    final QuerySnapshot<
        Map<String, dynamic>> snapshot =
        await _firestore
            .collection('owners')
            .where(
              'authUid',
              isEqualTo: user.uid,
            )
            .limit(1)
            .get();

    if (snapshot.docs.isEmpty) {
      throw FirebaseException(
        plugin:
            'cloud_firestore',
        code:
            'owner-not-found',
        message:
            'Owner profile was not found.',
      );
    }

    return snapshot.docs.first;
  }

  // ============================================================
  // UPDATE OWNER MAIN PHONE
  // ============================================================

  Future<void> updateOwnerPhone({
    required String ownerId,
    required String phoneNumber,
  }) async {
    final String cleanOwnerId =
        ownerId.trim();

    if (cleanOwnerId.isEmpty) {
      throw FirebaseException(
        plugin:
            'cloud_firestore',
        code:
            'invalid-owner-id',
        message:
            'Owner ID was not found.',
      );
    }

    final String digits =
        phoneNumber.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    String tenDigit = digits;

    if (digits.length == 12 &&
        digits.startsWith('91')) {
      tenDigit =
          digits.substring(2);
    }

    if (tenDigit.length != 10 ||
        !RegExp(
          r'^[6-9][0-9]{9}$',
        ).hasMatch(tenDigit)) {
      throw FirebaseException(
        plugin:
            'cloud_firestore',
        code:
            'invalid-phone-number',
        message:
            'Mobile number is invalid.',
      );
    }

    final String cleanPhone =
        '+91$tenDigit';

    // ----------------------------------------------------------
    // Find document using Firebase Auth UID.
    // ----------------------------------------------------------

    final DocumentSnapshot<
        Map<String, dynamic>> ownerDoc =
        await _findOwnerDocument();

    final Map<String, dynamic> data =
        ownerDoc.data() ??
            <String, dynamic>{};

    // ----------------------------------------------------------
    // Safety check:
    // Make sure requested ownerId belongs
    // to the authenticated owner document.
    // ----------------------------------------------------------

    final String firestoreOwnerId =
        (data['ownerId'] ?? '')
            .toString()
            .trim();

    if (firestoreOwnerId.isEmpty) {
      throw FirebaseException(
        plugin:
            'cloud_firestore',
        code:
            'invalid-owner-profile',
        message:
            'Owner ID is missing from the owner profile.',
      );
    }

    if (firestoreOwnerId !=
        cleanOwnerId) {
      throw FirebaseException(
        plugin:
            'cloud_firestore',
        code:
            'owner-id-mismatch',
        message:
            'Owner verification failed.',
      );
    }

    // ----------------------------------------------------------
    // Update SAME owner document.
    // ----------------------------------------------------------

    await _firestore
        .collection('owners')
        .doc(ownerDoc.id)
        .set(
      <String, dynamic>{
        'mainPhone':
            cleanPhone,
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
    // ----------------------------------------------------------
    // STEP 1
    // OTP verified + Firebase Auth phone updated.
    // ----------------------------------------------------------

    await updateFirebasePhone(
      credential:
          credential,
    );

    // ----------------------------------------------------------
    // STEP 2
    // Update Firestore:
    //
    // mainPhone
    //
    // NOT "phone".
    // ----------------------------------------------------------

    await updateOwnerPhone(
      ownerId:
          ownerId,
      phoneNumber:
          newPhoneNumber,
    );
  }
}
