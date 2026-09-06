import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_colors.dart';
import '../services/otp_service.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String reqId;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.reqId,
  });

  @override
  State<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState
    extends State<OtpVerificationScreen> {
  final TextEditingController _otpController =
      TextEditingController();

  final FocusNode _otpFocusNode =
      FocusNode();

  bool _isVerifying = false;
  bool _isResending = false;

  late String _reqId;

  static const String _backendUrl =
      'https://dojo-platform-backend.onrender.com';

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();

    _reqId = widget.reqId.trim();

    debugPrint(
      'OTP SCREEN REQ ID: $_reqId',
    );
  }

  // ============================================================
  // VERIFY OTP
  // ============================================================

  Future<void> _verifyOtp() async {
    if (_isVerifying) {
      return;
    }

    final String otp =
        _otpController.text.trim();

    if (!RegExp(
      r'^[0-9]{6}$',
    ).hasMatch(otp)) {
      _showMessage(
        'Please enter the complete 6-digit OTP.',
      );

      if (mounted) {
        _otpFocusNode.requestFocus();
      }

      return;
    }

    if (_reqId.trim().isEmpty) {
      _showMessage(
        'OTP session is invalid. Please request a new OTP.',
      );

      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      // ========================================================
      // 1. MSG91 OTP VERIFICATION
      // ========================================================

      debugPrint(
        'STARTING MSG91 OTP VERIFICATION',
      );

      final String accessToken =
          await OtpService.instance.verifyOtp(
        reqId: _reqId,
        otp: otp,
      );

      if (accessToken.trim().isEmpty) {
        throw Exception(
          'Secure access token was not received.',
        );
      }

      debugPrint(
        'MSG91 OTP VERIFICATION SUCCESS',
      );

      // ========================================================
      // 2. NORMALIZE PHONE
      // ========================================================

      final String? phone =
          _normalizeIndianPhone(
        widget.phoneNumber,
      );

      if (phone == null) {
        throw Exception(
          'Invalid mobile number.',
        );
      }

      debugPrint(
        'VERIFIED PHONE: $phone',
      );

      // ========================================================
      // 3. BACKEND CUSTOMER CHECK
      // ========================================================

      final Map<String, dynamic> backendData =
          await _checkCustomerWithBackend(
        accessToken: accessToken,
        phoneNumber: phone,
      );

      final bool backendSuccess =
          _isTrueValue(
        backendData['success'],
      );

      debugPrint(
        'BACKEND SUCCESS: $backendSuccess',
      );

      if (!backendSuccess) {
        final String backendMessage =
            backendData['message']
                    ?.toString()
                    .trim() ??
                '';

        throw Exception(
          backendMessage.isNotEmpty
              ? backendMessage
              : 'Secure account verification failed.',
        );
      }

      // ========================================================
      // 4. VERIFIED PHONE FROM BACKEND
      // ========================================================

      final String backendPhone =
          backendData['phone']
                  ?.toString()
                  .trim() ??
              '';

      final String verifiedPhone =
          backendPhone.isNotEmpty
              ? (_normalizeIndianPhone(
                    backendPhone,
                  ) ??
                  phone)
              : phone;

      debugPrint(
        'FINAL VERIFIED PHONE: $verifiedPhone',
      );

      // ========================================================
      // 5. BACKEND OWNER INFORMATION
      // ========================================================

      final bool backendExists =
          _isTrueValue(
        backendData['exists'],
      );

      final String backendOwnerDocumentId =
          backendData['ownerDocumentId']
                  ?.toString()
                  .trim() ??
              '';

      final String backendOwnerId =
          backendData['ownerId']
                  ?.toString()
                  .trim() ??
              '';

      final String backendAuthUid =
          backendData['authUid']
                  ?.toString()
                  .trim() ??
              '';

      final String firebaseCustomToken =
          backendData['firebaseCustomToken']
                  ?.toString()
                  .trim() ??
              '';

      final bool backendProfileCompleted =
          _isTrueValue(
        backendData['profileCompleted'],
      );

      final bool backendIsActive =
          backendData['isActive'] == null
              ? true
              : _isTrueValue(
                  backendData['isActive'],
                );

      debugPrint(
        'BACKEND EXISTS: $backendExists',
      );

      debugPrint(
        'BACKEND OWNER DOCUMENT ID: '
        '$backendOwnerDocumentId',
      );

      debugPrint(
        'BACKEND OWNER ID: '
        '$backendOwnerId',
      );

      debugPrint(
        'BACKEND AUTH UID: '
        '$backendAuthUid',
      );

      debugPrint(
        'BACKEND PROFILE COMPLETED: '
        '$backendProfileCompleted',
      );

      debugPrint(
        'BACKEND ACTIVE: '
        '$backendIsActive',
      );

      debugPrint(
        'CUSTOM TOKEN RECEIVED: '
        '${firebaseCustomToken.isNotEmpty}',
      );

      // ========================================================
      // 6. EXISTING OWNER
      // ========================================================

      if (backendExists) {
        // ------------------------------------------------------
        // Existing owner must have exact document ID.
        // ------------------------------------------------------

        if (backendOwnerDocumentId.isEmpty) {
          throw Exception(
            'Existing owner document ID was not received from the server.',
          );
        }

        // ------------------------------------------------------
        // Existing owner must have Firebase custom token.
        // ------------------------------------------------------

        if (firebaseCustomToken.isEmpty) {
          throw Exception(
            'Existing owner authentication token was not received from the server.',
          );
        }

        // ------------------------------------------------------
        // Existing owner must have original Firebase auth UID.
        // ------------------------------------------------------

        if (backendAuthUid.isEmpty) {
          throw Exception(
            'Existing owner Firebase authUid is missing.',
          );
        }

        // ------------------------------------------------------
        // IMPORTANT:
        //
        // NO anonymous login.
        // NO temporary Firebase UID.
        // NO phoneAccounts mapping.
        // NO new owner document.
        //
        // Sign in as the ORIGINAL Firebase user.
        // ------------------------------------------------------

        debugPrint(
          'SIGNING IN EXISTING OWNER WITH CUSTOM TOKEN',
        );

        final UserCredential credential =
            await _auth.signInWithCustomToken(
          firebaseCustomToken,
        );

        final User? firebaseUser =
            credential.user;

        if (firebaseUser == null) {
          throw Exception(
            'Firebase owner authentication failed.',
          );
        }

        final String currentFirebaseUid =
            firebaseUser.uid.trim();

        debugPrint(
          'FIREBASE AUTHENTICATED UID: '
          '$currentFirebaseUid',
        );

        // ------------------------------------------------------
        // Verify original Firebase identity.
        // ------------------------------------------------------

        if (currentFirebaseUid !=
            backendAuthUid) {
          debugPrint(
            'FIREBASE UID MISMATCH',
          );

          debugPrint(
            'Expected: $backendAuthUid',
          );

          debugPrint(
            'Actual: $currentFirebaseUid',
          );

          await _auth.signOut();

          throw Exception(
            'Firebase owner identity verification failed.',
          );
        }

        debugPrint(
          'EXISTING OWNER FIREBASE IDENTITY VERIFIED',
        );

        // ======================================================
        // 7. READ EXACT OWNER DOCUMENT
        //
        // IMPORTANT:
        //
        // We DO NOT query:
        //
        // owners.where(mainPhone...)
        //
        // because backend already identified the exact
        // owner document.
        //
        // We directly read:
        //
        // owners/{ownerDocumentId}
        //
        // ======================================================

        debugPrint(
          'READING EXACT OWNER DOCUMENT: '
          '$backendOwnerDocumentId',
        );

        final Map<String, dynamic>?
            existingOwner =
            await _findExistingOwner(
          backendOwnerDocumentId,
        );

        if (existingOwner == null) {
          await _auth.signOut();

          throw Exception(
            'Your existing owner account could not be found.',
          );
        }

        final String documentId =
            existingOwner['documentId']
                    ?.toString()
                    .trim() ??
                '';

        final dynamic rawOwnerData =
            existingOwner['data'];

        if (rawOwnerData is! Map) {
          await _auth.signOut();

          throw Exception(
            'Owner profile data is invalid.',
          );
        }

        final Map<String, dynamic>
            ownerData =
            Map<String, dynamic>.from(
          rawOwnerData,
        );

        // ======================================================
        // 8. GET PERMANENT OWNER ID
        // ======================================================

        final String ownerId =
            ownerData['ownerId']
                    ?.toString()
                    .trim() ??
                backendOwnerId;

        if (ownerId.isEmpty) {
          await _auth.signOut();

          throw Exception(
            'Existing owner was found, but ownerId is missing.',
          );
        }

        // ======================================================
        // 9. PROFILE STATUS
        // ======================================================

        final bool profileCompleted =
            ownerData['profileCompleted'] == null
                ? backendProfileCompleted
                : _isTrueValue(
                    ownerData['profileCompleted'],
                  );

        final bool isActive =
            ownerData['isActive'] == null
                ? backendIsActive
                : _isTrueValue(
                    ownerData['isActive'],
                  );

        final String ownerAuthUid =
            ownerData['authUid']
                    ?.toString()
                    .trim() ??
                '';

        final String ownerUid =
            ownerData['uid']
                    ?.toString()
                    .trim() ??
                '';

        debugPrint(
          '==================================================',
        );

        debugPrint(
          'EXACT EXISTING OWNER FOUND',
        );

        debugPrint(
          'OWNER DOCUMENT: $documentId',
        );

        debugPrint(
          'PERMANENT OWNER ID: $ownerId',
        );

        debugPrint(
          'OWNER authUid: $ownerAuthUid',
        );

        debugPrint(
          'OWNER uid: $ownerUid',
        );

        debugPrint(
          'PROFILE COMPLETED: $profileCompleted',
        );

        debugPrint(
          'OWNER ACTIVE: $isActive',
        );

        debugPrint(
          'FIREBASE CURRENT UID: '
          '$currentFirebaseUid',
        );

        debugPrint(
          '==================================================',
        );

        // ======================================================
        // 10. VERIFY OWNER DOCUMENT IDENTITY
        // ======================================================

        if (ownerAuthUid.isNotEmpty &&
            ownerAuthUid !=
                currentFirebaseUid) {
          await _auth.signOut();

          throw Exception(
            'Owner Firebase identity does not match the existing account.',
          );
        }

        if (ownerUid.isNotEmpty &&
            ownerAuthUid.isEmpty &&
            ownerUid !=
                currentFirebaseUid) {
          await _auth.signOut();

          throw Exception(
            'Owner Firebase identity does not match the existing account.',
          );
        }

        // ======================================================
        // 11. VERIFY OWNER IS ACTIVE
        // ======================================================

        if (!isActive) {
          await _auth.signOut();

          throw Exception(
            'This owner account is currently inactive.',
          );
        }

        // ======================================================
        // 12. SAVE LOCAL OWNER LOGIN STATE
        // ======================================================

        final SharedPreferences prefs =
            await SharedPreferences
                .getInstance();

        await prefs.setString(
          'tempVerifiedPhone',
          verifiedPhone,
        );

        await prefs.setBool(
          'tempOtpVerified',
          true,
        );

        await prefs.setBool(
          'tempExistingAccount',
          true,
        );

        await prefs.setString(
          'tempOwnerId',
          ownerId,
        );

        await prefs.setString(
          'tempRole',
          'owner',
        );

        await prefs.setBool(
          'tempProfileCompleted',
          profileCompleted,
        );

        // ------------------------------------------------------
        // Do NOT store temporary Firebase UID.
        // FirebaseAuth already contains the original UID.
        // ------------------------------------------------------

        await prefs.remove(
          'tempAccountUid',
        );

        debugPrint(
          'EXISTING OWNER LOGIN COMPLETE',
        );

        debugPrint(
          'FIXED OWNER ID: $ownerId',
        );

        debugPrint(
          'FIXED FIREBASE UID: '
          '$currentFirebaseUid',
        );

        if (!mounted) {
          return;
        }

        if (profileCompleted) {
          _showMessage(
            'OTP verified. Welcome back!',
          );
        } else {
          _showMessage(
            'OTP verified. Please complete your profile.',
          );
        }

        await Future<void>.delayed(
          const Duration(
            milliseconds: 500,
          ),
        );

        if (!mounted) {
          return;
        }

        Navigator.of(context)
            .pushNamedAndRemoveUntil(
          '/',
          (route) => false,
        );

        return;
      }

      // ========================================================
      // 13. NEW OWNER
      // ========================================================
      //
      // Backend did not find this phone in owners.
      //
      // Existing owner identity is NOT reused.
      // No temporary owner mapping is created.
      //
      // Profile Setup is responsible for creating the new
      // owner account.
      // ========================================================

      debugPrint(
        'NEW OWNER ACCOUNT',
      );

      // --------------------------------------------------------
      // Prevent accidental reuse of an old Firebase session.
      // --------------------------------------------------------

      if (_auth.currentUser != null) {
        debugPrint(
          'SIGNING OUT OLD FIREBASE SESSION BEFORE NEW OWNER SETUP',
        );

        await _auth.signOut();
      }

      final SharedPreferences prefs =
          await SharedPreferences
              .getInstance();

      await prefs.setString(
        'tempVerifiedPhone',
        verifiedPhone,
      );

      await prefs.setBool(
        'tempOtpVerified',
        true,
      );

      await prefs.setBool(
        'tempExistingAccount',
        false,
      );

      await prefs.setString(
        'tempOwnerId',
        '',
      );

      await prefs.setString(
        'tempRole',
        'owner',
      );

      await prefs.setBool(
        'tempProfileCompleted',
        false,
      );

      await prefs.remove(
        'tempAccountUid',
      );

      debugPrint(
        'NEW OWNER PROFILE SETUP REQUIRED',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'OTP verified. Please complete your profile.',
      );

      await Future<void>.delayed(
        const Duration(
          milliseconds: 500,
        ),
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context)
          .pushNamedAndRemoveUntil(
        '/',
        (route) => false,
      );
    } on FirebaseException catch (e) {
      debugPrint(
        'OWNER FIREBASE ERROR: ${e.code}',
      );

      debugPrint(
        'OWNER FIREBASE ERROR MESSAGE: '
        '${e.message}',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        _firebaseErrorMessage(e),
      );
    } catch (e) {
      debugPrint(
        'OTP VERIFICATION ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      final String error =
          e.toString().toLowerCase();

      if (error.contains('invalid') &&
          error.contains('otp')) {
        _showMessage(
          'Invalid OTP. Please check the code and try again.',
        );
      } else if (error.contains('expired') ||
          error.contains('session')) {
        _showMessage(
          'This OTP session has expired. Please request a new OTP.',
        );
      } else if (error.contains(
                'custom token',
              ) ||
              error.contains(
                'authentication token',
              )) {
        _showMessage(
          'Secure Firebase login could not be completed. Please try again.',
        );
      } else if (error.contains(
                'identity',
              ) ||
          error.contains(
                'authuid',
              )) {
        _showMessage(
          'Existing owner identity verification failed.',
        );
      } else if (error.contains(
                'permission-denied',
              ) ||
              error.contains(
                'permission denied',
              )) {
        _showMessage(
          'Firebase permission denied while checking your owner profile.',
        );
      } else if (error.contains('not found') &&
          error.contains('owner')) {
        _showMessage(
          'Your owner account could not be found. Please try again.',
        );
      } else if (error.contains('access token') ||
          error.contains('access-token') ||
          error.contains('token')) {
        _showMessage(
          'OTP verified, but secure login could not be completed. Please try again.',
        );
      } else if (error.contains('network') ||
          error.contains('socket') ||
          error.contains('connection') ||
          error.contains('timeout')) {
        _showMessage(
          'Network error. Please check your internet connection.',
        );
      } else {
        _showMessage(
          e.toString().replaceFirst(
                'Exception: ',
                '',
              ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  // ============================================================
  // FIND EXISTING OWNER
  // ============================================================
  //
  // IMPORTANT:
  // Backend already found the exact owner document.
  //
  // We do NOT query owners by phone.
  //
  // We directly read:
  //
  // owners/{ownerDocumentId}
  //
  // ============================================================

  Future<Map<String, dynamic>?>
      _findExistingOwner(
    String ownerDocumentId,
  ) async {
    final String documentId =
        ownerDocumentId.trim();

    if (documentId.isEmpty) {
      debugPrint(
        'OWNER DOCUMENT ID IS EMPTY',
      );

      return null;
    }

    debugPrint(
      'READING EXACT OWNER DOCUMENT: '
      '$documentId',
    );

    final DocumentSnapshot<
        Map<String, dynamic>>
        snapshot =
        await _firestore
            .collection('owners')
            .doc(documentId)
            .get();

    if (!snapshot.exists) {
      debugPrint(
        'OWNER DOCUMENT DOES NOT EXIST: '
        '$documentId',
      );

      return null;
    }

    final Map<String, dynamic> data =
        snapshot.data() ??
            <String, dynamic>{};

    debugPrint(
      'OWNER DOCUMENT READ SUCCESSFULLY',
    );

    debugPrint(
      'OWNER DOCUMENT ID: '
      '${snapshot.id}',
    );

    return {
      'documentId': snapshot.id,
      'data': data,
    };
  }

  // ============================================================
  // BACKEND CUSTOMER CHECK
  // ============================================================

  Future<Map<String, dynamic>>
      _checkCustomerWithBackend({
    required String accessToken,
    required String phoneNumber,
  }) async {
    try {
      final Uri uri = Uri.parse(
        '$_backendUrl/customer/check',
      );

      debugPrint(
        'BACKEND CUSTOMER CHECK STARTED',
      );

      final http.Response response =
          await http
              .post(
                uri,
                headers: const {
                  'Content-Type':
                      'application/json',
                  'Accept':
                      'application/json',
                },
                body: jsonEncode({
                  'accessToken':
                      accessToken,
                  'phoneNumber':
                      phoneNumber,
                }),
              )
              .timeout(
                const Duration(
                  seconds: 30,
                ),
              );

      debugPrint(
        'BACKEND STATUS: '
        '${response.statusCode}',
      );

      dynamic decoded;

      try {
        decoded =
            jsonDecode(
          response.body,
        );
      } catch (_) {
        throw Exception(
          'Dojo Platform backend returned an invalid response.',
        );
      }

      if (decoded is! Map) {
        throw Exception(
          'Dojo Platform backend returned an invalid response.',
        );
      }

      final Map<String, dynamic>
          data =
          Map<String, dynamic>.from(
        decoded,
      );

      debugPrint(
        'BACKEND RESPONSE KEYS: '
        '${data.keys.toList()}',
      );

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        final String message =
            data['message']
                    ?.toString()
                    .trim() ??
                '';

        final String error =
            data['error']
                    ?.toString()
                    .trim() ??
                '';

        final String reason =
            message.isNotEmpty
                ? message
                : error.isNotEmpty
                    ? error
                    : 'Backend request failed with HTTP ${response.statusCode}.';

        throw Exception(
          reason,
        );
      }

      return data;
    } on Exception {
      rethrow;
    } catch (e) {
      debugPrint(
        'BACKEND CUSTOMER CHECK ERROR: $e',
      );

      throw Exception(
        'Unable to connect to Dojo Platform backend.',
      );
    }
  }

  // ============================================================
  // RESEND OTP
  // ============================================================

  Future<void> _resendOtp() async {
    if (_isResending ||
        _isVerifying) {
      return;
    }

    if (_reqId.trim().isEmpty) {
      _showMessage(
        'OTP session is invalid. Please request OTP again.',
      );

      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isResending = true;
    });

    try {
      final String? newReqId =
          await OtpService.instance.resendOtp(
        reqId: _reqId,
      );

      if (newReqId != null &&
          newReqId.trim().isNotEmpty) {
        _reqId =
            newReqId.trim();
      }

      _otpController.clear();

      if (!mounted) {
        return;
      }

      _showMessage(
        'OTP sent again successfully.',
      );

      _otpFocusNode.requestFocus();
    } catch (e) {
      debugPrint(
        'MSG91 RESEND ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      final String error =
          e.toString().toLowerCase();

      if (error.contains('expired') ||
          error.contains('session')) {
        _showMessage(
          'OTP session has expired. Please request a new OTP.',
        );
      } else if (error.contains('network') ||
          error.contains('socket') ||
          error.contains('connection') ||
          error.contains('timeout')) {
        _showMessage(
          'Network error. Please check your internet connection.',
        );
      } else {
        _showMessage(
          e.toString().replaceFirst(
                'Exception: ',
                '',
              ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  // ============================================================
  // TRUE VALUE
  // ============================================================

  bool _isTrueValue(
    dynamic value,
  ) {
    if (value == true) {
      return true;
    }

    if (value is String) {
      final String text =
          value.trim().toLowerCase();

      return text == 'true' ||
          text == 'success' ||
          text == 'verified' ||
          text == '1';
    }

    if (value is num) {
      return value != 0;
    }

    return false;
  }

  // ============================================================
  // NORMALIZE INDIAN PHONE
  // ============================================================

  String? _normalizeIndianPhone(
    String value,
  ) {
    String phone =
        value.trim().replaceAll(
              RegExp(r'[^0-9+]'),
              '',
            );

    if (phone.startsWith('+91')) {
      phone =
          phone.substring(3);
    } else if (
        phone.startsWith('91') &&
        phone.length == 12) {
      phone =
          phone.substring(2);
    }

    if (phone.length != 10 ||
        !RegExp(
          r'^[6-9][0-9]{9}$',
        ).hasMatch(phone)) {
      return null;
    }

    return '+91$phone';
  }

  // ============================================================
  // FIREBASE ERROR
  // ============================================================

  String _firebaseErrorMessage(
    FirebaseException e,
  ) {
    switch (e.code) {
      case 'permission-denied':
        return 'Firebase permission denied while checking your owner profile.';

      case 'unauthenticated':
        return 'Firebase authentication is required.';

      case 'unavailable':
        return 'Firebase is temporarily unavailable. Please try again.';

      case 'deadline-exceeded':
        return 'The Firebase request took too long. Please try again.';

      case 'failed-precondition':
        return 'Firebase configuration is incomplete.';

      default:
        final String message =
            e.message?.trim() ?? '';

        return message.isNotEmpty
            ? message
            : 'Unable to access your account.';
    }
  }

  // ============================================================
  // SHOW MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        behavior:
            SnackBarBehavior.floating,
        margin:
            const EdgeInsets.all(16),
        backgroundColor:
            const Color(0xFF263746),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(12),
        ),
        content:
            Text(
          message,
          style:
              const TextStyle(
            color:
                Colors.white,
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DISPLAY PHONE
  // ============================================================

  String _displayPhoneNumber() {
    final String raw =
        widget.phoneNumber.trim();

    String clean =
        raw.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (clean.length == 12 &&
        clean.startsWith('91')) {
      clean =
          clean.substring(2);
    }

    if (clean.length == 10) {
      return '+91 '
          '${clean.substring(0, 5)} '
          '${clean.substring(5)}';
    }

    return raw.isEmpty
        ? 'Mobile number'
        : raw;
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _otpController.dispose();
    _otpFocusNode.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    const Color primary =
        AppColors.primary;

    const Color background =
        Color(0xFFF7F9FC);

    const Color textColor =
        Color(0xFF263746);

    const Color secondaryText =
        Color(0xFF64748B);

    const Color cardColor =
        Colors.white;

    const Color borderColor =
        Color(0xFFDDE2E8);

    const Color inputBackground =
        Color(0xFFFAFBFC);

    return Scaffold(
      backgroundColor:
          background,
      appBar: AppBar(
        backgroundColor:
            background,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor:
            textColor,
        toolbarHeight: 55,
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context)
                .unfocus();
          },
          child:
              SingleChildScrollView(
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior
                    .onDrag,
            padding:
                const EdgeInsets.fromLTRB(
              22,
              10,
              22,
              30,
            ),
            child: Column(
              children: [
                const SizedBox(
                  height: 12,
                ),
                Container(
                  height: 78,
                  width: 78,
                  decoration:
                      BoxDecoration(
                    color: primary,
                    borderRadius:
                        BorderRadius.circular(
                      24,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            primary.withValues(
                          alpha: 0.22,
                        ),
                        blurRadius: 18,
                        offset:
                            const Offset(
                          0,
                          8,
                        ),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons
                        .verified_user_rounded,
                    color:
                        Colors.white,
                    size: 38,
                  ),
                ),
                const SizedBox(
                  height: 26,
                ),
                const Text(
                  'Verify your number',
                  textAlign:
                      TextAlign.center,
                  style:
                      TextStyle(
                    color:
                        textColor,
                    fontSize:
                        27,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                const SizedBox(
                  height: 9,
                ),
                const Text(
                  'Enter the 6-digit OTP sent to',
                  textAlign:
                      TextAlign.center,
                  style:
                      TextStyle(
                    color:
                        secondaryText,
                    fontSize:
                        14,
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  _displayPhoneNumber(),
                  textAlign:
                      TextAlign.center,
                  style:
                      const TextStyle(
                    color:
                        textColor,
                    fontSize:
                        15,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
                Container(
                  width:
                      double.infinity,
                  padding:
                      const EdgeInsets.fromLTRB(
                    18,
                    20,
                    18,
                    20,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        cardColor,
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                    border:
                        Border.all(
                      color:
                          borderColor,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black
                                .withValues(
                          alpha: 0.045,
                        ),
                        blurRadius: 18,
                        offset:
                            const Offset(
                          0,
                          6,
                        ),
                      ),
                    ],
                  ),
                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      const Text(
                        'One-Time Password',
                        style:
                            TextStyle(
                          color:
                              textColor,
                          fontSize:
                              15,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      TextField(
                        controller:
                            _otpController,
                        focusNode:
                            _otpFocusNode,
                        autofocus:
                            true,
                        enabled:
                            !_isVerifying,
                        keyboardType:
                            TextInputType.number,
                        textInputAction:
                            TextInputAction.done,
                        maxLength:
                            6,
                        textAlign:
                            TextAlign.center,
                        inputFormatters: [
                          FilteringTextInputFormatter
                              .digitsOnly,
                        ],
                        onChanged:
                            (String value) {
                          if (value.length ==
                                  6 &&
                              !_isVerifying) {
                            FocusScope.of(
                              context,
                            ).unfocus();
                          }
                        },
                        onSubmitted:
                            (_) {
                          if (!_isVerifying) {
                            _verifyOtp();
                          }
                        },
                        style:
                            const TextStyle(
                          color:
                              textColor,
                          fontSize:
                              25,
                          fontWeight:
                              FontWeight.w800,
                          letterSpacing:
                              10,
                        ),
                        decoration:
                            InputDecoration(
                          hintText:
                              '------',
                          hintStyle:
                              const TextStyle(
                            color:
                                Color(
                              0xFF9AA6B5,
                            ),
                            fontSize:
                                24,
                            letterSpacing:
                                9,
                          ),
                          counterText:
                              '',
                          filled:
                              true,
                          fillColor:
                              inputBackground,
                          contentPadding:
                              const EdgeInsets
                                  .symmetric(
                            vertical:
                                17,
                          ),
                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              14,
                            ),
                            borderSide:
                                const BorderSide(
                              color:
                                  borderColor,
                            ),
                          ),
                          enabledBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              14,
                            ),
                            borderSide:
                                const BorderSide(
                              color:
                                  borderColor,
                            ),
                          ),
                          focusedBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              14,
                            ),
                            borderSide:
                                const BorderSide(
                              color:
                                  primary,
                              width:
                                  2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 18,
                      ),
                      SizedBox(
                        width:
                            double.infinity,
                        height:
                            54,
                        child:
                            ElevatedButton(
                          onPressed:
                              _isVerifying
                                  ? null
                                  : _verifyOtp,
                          style:
                              ElevatedButton
                                  .styleFrom(
                            backgroundColor:
                                primary,
                            foregroundColor:
                                Colors.white,
                            disabledBackgroundColor:
                                primary
                                    .withValues(
                              alpha:
                                  0.55,
                            ),
                            elevation:
                                0,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                14,
                              ),
                            ),
                          ),
                          child:
                              _isVerifying
                                  ? const SizedBox(
                                      height:
                                          23,
                                      width:
                                          23,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth:
                                            2.5,
                                        color:
                                            Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Verify & Continue',
                                      style:
                                          TextStyle(
                                        fontSize:
                                            16,
                                        fontWeight:
                                            FontWeight
                                                .w800,
                                      ),
                                    ),
                        ),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      Center(
                        child:
                            TextButton(
                          onPressed:
                              (_isResending ||
                                      _isVerifying)
                                  ? null
                                  : _resendOtp,
                          child:
                              _isResending
                                  ? const SizedBox(
                                      height:
                                          19,
                                      width:
                                          19,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth:
                                            2,
                                      ),
                                    )
                                  : const Text(
                                      'Resend OTP',
                                      style:
                                          TextStyle(
                                        color:
                                            primary,
                                        fontWeight:
                                            FontWeight
                                                .w800,
                                      ),
                                    ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                const Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .center,
                  children: [
                    Icon(
                      Icons
                          .lock_outline_rounded,
                      size:
                          15,
                      color:
                          secondaryText,
                    ),
                    SizedBox(
                      width:
                          6,
                    ),
                    Text(
                      'Secure phone verification',
                      style:
                          TextStyle(
                        color:
                            secondaryText,
                        fontSize:
                            12,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 8,
                ),
                const Text(
                  'Dojo Platform',
                  textAlign:
                      TextAlign.center,
                  style:
                      TextStyle(
                    color:
                        secondaryText,
                    fontSize:
                        13,
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
