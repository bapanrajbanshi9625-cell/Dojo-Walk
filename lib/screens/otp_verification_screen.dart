import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sendotp_flutter_sdk/sendotp_flutter_sdk.dart';

import '../core/constants/app_colors.dart';
import '../services/owner_id_service.dart';
import 'main_navigation_screen.dart';
import 'profile_setup.dart';

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

  final FocusNode _otpFocusNode = FocusNode();

  bool _isVerifying = false;
  bool _isResending = false;

  String _reqId = '';

  @override
  void initState() {
    super.initState();

    _reqId = widget.reqId.trim();
  }

  // ============================================================
  // VERIFY MSG91 OTP
  // ============================================================

  Future<void> _verifyOtp() async {
    final String otp = _otpController.text.trim();

    if (otp.length != 6) {
      _showMessage(
        'Please enter the complete 6-digit OTP.',
      );

      if (mounted) {
        _otpFocusNode.requestFocus();
      }

      return;
    }

    if (_isVerifying) {
      return;
    }

    if (_reqId.isEmpty) {
      _showMessage(
        'OTP session is invalid. Please request a new OTP.',
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      // ========================================================
      // 1. VERIFY OTP WITH MSG91
      // ========================================================

      final Map<String, dynamic> data = {
        'reqId': _reqId,
        'otp': otp,
      };

      final dynamic response =
          await OTPWidget.verifyOTP(data);

      debugPrint(
        'MSG91 VERIFY OTP RESPONSE: $response',
      );

      // ========================================================
      // 2. CHECK RESPONSE
      // ========================================================

      bool verified = false;

      if (response is Map) {
        final dynamic type =
            response['type'] ??
            response['status'] ??
            response['message'];

        final String result =
            type?.toString().toLowerCase() ?? '';

        if (result.contains('success') ||
            result == 'success' ||
            result == 'verified') {
          verified = true;
        }

        // Some MSG91 SDK responses expose success
        // through a boolean.
        if (response['success'] == true ||
            response['verified'] == true) {
          verified = true;
        }
      }

      // Some SDK versions return a successful response
      // that is not represented as a simple Map.
      if (!verified && response != null) {
        final String responseText =
            response.toString().toLowerCase();

        if (responseText.contains('success') ||
            responseText.contains('verified')) {
          verified = true;
        }
      }

      if (!verified) {
        throw Exception(
          'Invalid OTP. Please check the OTP and try again.',
        );
      }

      // ========================================================
      // 3. OTP VERIFIED
      // ========================================================

      debugPrint(
        'MSG91 OTP VERIFIED SUCCESSFULLY',
      );

      // ========================================================
      // 4. CREATE / RESTORE FIREBASE SESSION
      // ========================================================
      //
      // MSG91 verification does not create a Firebase
      // PhoneAuth user. We therefore create an anonymous
      // Firebase session so the existing Firestore/Owner
      // flow can continue.
      //
      // The verified phone number remains the application's
      // logical login identifier.
      // ========================================================

      User? user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        final UserCredential credential =
            await FirebaseAuth.instance
                .signInAnonymously();

        user = credential.user;
      }

      if (user == null) {
        throw FirebaseAuthException(
          code: 'firebase-user-missing',
          message:
              'Unable to create Firebase session.',
        );
      }

      final String uid = user.uid.trim();

      if (uid.isEmpty) {
        throw FirebaseAuthException(
          code: 'invalid-user',
          message:
              'Firebase UID was not found.',
        );
      }

      debugPrint(
        'Firebase UID: $uid',
      );

      // ========================================================
      // 5. NORMALIZE PHONE NUMBER
      // ========================================================

      String phoneNumber =
          widget.phoneNumber.trim();

      phoneNumber = phoneNumber.replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );

      if (phoneNumber.length > 10) {
        phoneNumber =
            phoneNumber.substring(
          phoneNumber.length - 10,
        );
      }

      if (phoneNumber.length != 10) {
        throw FirebaseAuthException(
          code: 'phone-not-found',
          message:
              'Verified mobile number was not found.',
        );
      }

      final String fullPhoneNumber =
          '+91$phoneNumber';

      // ========================================================
      // 6. GET / CREATE OWNER ID
      // ========================================================

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

      debugPrint(
        'Owner ID: $cleanOwnerId',
      );

      // ========================================================
      // 7. LOAD OWNER PROFILE
      // ========================================================

      final DocumentSnapshot<
          Map<String, dynamic>> profileSnapshot =
          await FirebaseFirestore.instance
              .collection('owners')
              .doc(cleanOwnerId)
              .get();

      // ========================================================
      // 8. PROFILE DATA
      // ========================================================

      final Map<String, dynamic>? profileData =
         profileSnapshot.data();

      // ========================================================
      // 9. ACTIVE STATUS
      // ========================================================

      final bool isActive =
          data?['isActive'] != false;

      if (!isActive) {
        await FirebaseAuth.instance.signOut();

        if (!mounted) {
          return;
        }

        _showInactiveDialog(
          cleanOwnerId,
        );

        return;
      }

      // ========================================================
      // 10. PROFILE COMPLETED
      // ========================================================

      final bool profileCompleted =
          data?['profileCompleted'] == true;

      if (!mounted) {
        return;
      }

      // ========================================================
      // 11. PROFILE NOT COMPLETED
      // ========================================================

      if (!profileCompleted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const ProfileSetupScreen(),
          ),
          (route) => false,
        );

        return;
      }

      // ========================================================
      // 12. PROFILE COMPLETED
      // ========================================================

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const MainNavigationScreen(),
        ),
        (route) => false,
      );
    }

    // ==========================================================
    // FIREBASE AUTH ERROR
    // ==========================================================

    on FirebaseAuthException catch (e) {
      debugPrint(
        'Owner Firebase Auth Error: ${e.code}',
      );

      if (!mounted) {
        return;
      }

      String message;

      switch (e.code) {
        case 'invalid-user':
          message =
              'Unable to identify your account. Please try again.';
          break;

        case 'firebase-user-missing':
          message =
              'Unable to create your login session. Please try again.';
          break;

        case 'phone-not-found':
          message =
              'Verified mobile number was not found.';
          break;

        case 'network-request-failed':
          message =
              'Network error. Please check your internet connection.';
          break;

        case 'too-many-requests':
          message =
              'Too many attempts. Please try again later.';
          break;

        default:
          message =
              e.message?.trim().isNotEmpty == true
                  ? e.message!.trim()
                  : 'Login failed. Please try again.';
      }

      _showMessage(message);
    }

    // ==========================================================
    // FIREBASE / FIRESTORE ERROR
    // ==========================================================

    on FirebaseException catch (e) {
      debugPrint(
        'Owner Firebase Error: ${e.code}',
      );

      if (!mounted) {
        return;
      }

      String message;

      switch (e.code) {
        case 'permission-denied':
          message =
              'Unable to access your Owner profile. Please check your account permissions.';
          break;

        case 'unavailable':
          message =
              'Firebase is temporarily unavailable. Please check your internet connection.';
          break;

        case 'deadline-exceeded':
          message =
              'The request took too long. Please try again.';
          break;

        case 'owner-id-missing':
          message =
              e.message ??
                  'Owner ID could not be created.';
          break;

        default:
          message =
              e.message?.trim().isNotEmpty == true
                  ? e.message!.trim()
                  : 'Unable to load your Owner profile.';
      }

      _showMessage(message);
    }

    // ==========================================================
    // MSG91 / GENERAL ERROR
    // ==========================================================

    catch (e) {
      debugPrint(
        'MSG91 OTP Verification Error: $e',
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
      } else {
        _showMessage(
          'OTP verification failed. Please try again.',
        );
      }
    }

    // ==========================================================
    // STOP LOADING
    // ==========================================================

    finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  // ============================================================
  // RESEND OTP
  // ============================================================

  Future<void> _resendOtp() async {
    if (_isResending || _isVerifying) {
      return;
    }

    setState(() {
      _isResending = true;
    });

    try {
      final dynamic response =
          await OTPWidget.retryOTP({
        'reqId': _reqId,
      });

      debugPrint(
        'MSG91 RETRY OTP RESPONSE: $response',
      );

      String? newReqId;

      if (response is Map) {
        final dynamic value =
            response['reqId'] ??
            response['req_id'] ??
            response['requestId'];

        if (value != null) {
          newReqId = value.toString();
        }
      }

      if (newReqId != null &&
          newReqId.trim().isNotEmpty) {
        _reqId = newReqId.trim();
      }

      if (!mounted) {
        return;
      }

      _otpController.clear();

      _showMessage(
        'OTP sent again successfully.',
      );

      _otpFocusNode.requestFocus();
    } catch (e) {
      debugPrint(
        'MSG91 RESEND OTP ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to resend OTP. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  // ============================================================
  // INACTIVE OWNER DIALOG
  // ============================================================

  void _showInactiveDialog(
    String ownerId,
  ) {
    const Color primary =
        AppColors.primary;

    const Color textColor =
        Color(0xFF263746);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
              Colors.white,

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),

          title: const Row(
            children: [
              Icon(
                Icons.block_rounded,
                color: Colors.red,
                size: 25,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Account Inactive',
                  style: TextStyle(
                    color: textColor,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          content: Text(
            'Your Owner ID $ownerId is currently inactive.\n\n'
            'Please contact support to activate your account.',
            style: const TextStyle(
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text(
                'OK',
                style: TextStyle(
                  color: primary,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // MESSAGE
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
        content: Text(
          message,
          style:
              const TextStyle(
            color: Colors.white,
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

    final String clean =
        raw.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (clean.length == 10) {
      return '+91 '
          '${clean.substring(0, 5)} '
          '${clean.substring(5)}';
    }

    if (clean.length > 10) {
      final String last10 =
          clean.substring(
        clean.length - 10,
      );

      return '+91 '
          '${last10.substring(0, 5)} '
          '${last10.substring(5)}';
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

                // ==================================================
                // ICON
                // ==================================================

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
                        color: primary
                            .withOpacity(
                          0.22,
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

                // ==================================================
                // TITLE
                // ==================================================

                const Text(
                  'Verify your number',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 27,
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
                  style: TextStyle(
                    color:
                        secondaryText,
                    fontSize: 14,
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
                    color: textColor,
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height: 30,
                ),

                // ==================================================
                // OTP CARD
                // ==================================================

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
                        color: Colors
                            .black
                            .withOpacity(
                          0.045,
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

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [
                      const Text(
                        'One-Time Password',
                        style: TextStyle(
                          color:
                              textColor,
                          fontSize: 15,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      // ==========================================
                      // OTP INPUT
                      // ==========================================

                      TextField(
                        controller:
                            _otpController,

                        focusNode:
                            _otpFocusNode,

                        autofocus: true,

                        enabled:
                            !_isVerifying,

                        keyboardType:
                            TextInputType.number,

                        textInputAction:
                            TextInputAction.done,

                        maxLength: 6,

                        textAlign:
                            TextAlign.center,

                        inputFormatters: [
                          FilteringTextInputFormatter
                              .digitsOnly,
                        ],

                        onChanged:
                            (value) {
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
                          fontSize: 25,
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
                            fontSize: 24,
                            letterSpacing:
                                9,
                          ),

                          counterText:
                              '',

                          filled: true,

                          fillColor:
                              inputBackground,

                          contentPadding:
                              const EdgeInsets
                                  .symmetric(
                            vertical: 17,
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
                              width: 2,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      // ==========================================
                      // VERIFY BUTTON
                      // ==========================================

                      SizedBox(
                        width:
                            double.infinity,
                        height: 54,

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
                                    .withOpacity(
                              0.55,
                            ),
                            elevation: 0,
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
                                      height: 23,
                                      width: 23,
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

                      // ==========================================
                      // RESEND
                      // ==========================================

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
                                      height: 19,
                                      width: 19,
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

                // ==================================================
                // SECURITY
                // ==================================================

                const Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .center,
                  children: [
                    Icon(
                      Icons
                          .lock_outline_rounded,
                      size: 15,
                      color:
                          secondaryText,
                    ),
                    SizedBox(
                      width: 6,
                    ),
                    Text(
                      'Secure phone verification',
                      style:
                          TextStyle(
                        color:
                            secondaryText,
                        fontSize: 12,
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
                  style: TextStyle(
                    color:
                        secondaryText,
                    fontSize: 13,
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
