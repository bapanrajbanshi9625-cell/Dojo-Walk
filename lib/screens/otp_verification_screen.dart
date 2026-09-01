import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sendotp_flutter_sdk/sendotp_flutter_sdk.dart';

import '../core/constants/app_colors.dart';
import 'splash_screen.dart';

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

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _reqId = widget.reqId.trim();
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

    // ==========================================================
    // OTP VALIDATION
    // ==========================================================

    if (otp.length != 6) {
      _showMessage(
        'Please enter the complete 6-digit OTP.',
      );

      if (mounted) {
        _otpFocusNode.requestFocus();
      }

      return;
    }

    if (_reqId.isEmpty) {
      _showMessage(
        'OTP session is invalid. Please request a new OTP.',
      );

      return;
    }

    // ==========================================================
    // START VERIFYING
    // ==========================================================

    setState(() {
      _isVerifying = true;
    });

    try {
      // ========================================================
      // 1. VERIFY OTP WITH MSG91
      // ========================================================

      final dynamic response =
          await OTPWidget.verifyOTP({
        'reqId': _reqId,
        'otp': otp,
      });

      debugPrint(
        'MSG91 VERIFY RESPONSE: $response',
      );

      // ========================================================
      // 2. CHECK OTP RESULT
      // ========================================================

      final bool verified =
          _isOtpVerified(response);

      if (!verified) {
        throw Exception(
          'Invalid OTP. Please check the OTP and try again.',
        );
      }

      debugPrint(
        'MSG91 OTP VERIFIED SUCCESSFULLY',
      );

      // ========================================================
      // 3. IMPORTANT
      // ========================================================
      //
      // OTP SCREEN DOES NOT:
      //
      // - create Firebase UID
      // - create Anonymous Firebase session
      // - create Owner ID
      // - call OwnerAuthService
      // - check profileCompleted
      // - check isActive
      // - open MainNavigationScreen
      // - open ProfileSetupScreen
      //
      // OTP SCREEN ONLY VERIFIES OTP.
      //
      // AFTER SUCCESS:
      // SplashScreen gets the verified phone number
      // and makes the complete account decision.
      //
      // ========================================================

      if (!mounted) {
        return;
      }

      // ========================================================
      // 4. GO TO SPLASH
      // ========================================================

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => SplashScreen(
            phoneNumber: widget.phoneNumber,
          ),
        ),
        (route) => false,
      );
    }

    // ==========================================================
    // FIREBASE AUTH ERROR
    // ==========================================================

    on FirebaseAuthException catch (e) {
      debugPrint(
        'OTP FIREBASE AUTH ERROR: ${e.code}',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        _firebaseAuthErrorMessage(e),
      );
    }

    // ==========================================================
    // FIREBASE ERROR
    // ==========================================================

    on FirebaseException catch (e) {
      debugPrint(
        'OTP FIREBASE ERROR: ${e.code}',
      );

      debugPrint(
        'OTP FIREBASE MESSAGE: ${e.message}',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        _firebaseErrorMessage(e),
      );
    }

    // ==========================================================
    // GENERAL ERROR
    // ==========================================================

    catch (e) {
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
      } else if (error.contains('permission-denied')) {
        _showMessage(
          'Firebase permission denied. Please check Firestore rules.',
        );
      } else if (error.contains('network')) {
        _showMessage(
          'Network error. Please check your internet connection.',
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
  // CHECK MSG91 OTP RESPONSE
  // ============================================================

  bool _isOtpVerified(
    dynamic response,
  ) {
    if (response == null) {
      return false;
    }

    // ==========================================================
    // MAP RESPONSE
    // ==========================================================

    if (response is Map) {
      final dynamic success =
          response['success'];

      final dynamic verified =
          response['verified'];

      if (success == true ||
          verified == true) {
        return true;
      }

      final dynamic type =
          response['type'];

      final dynamic status =
          response['status'];

      final dynamic message =
          response['message'];

      final String result =
          <dynamic>[
        type,
        status,
        message,
      ]
              .where(
                (dynamic value) =>
                    value != null,
              )
              .map(
                (dynamic value) =>
                    value
                        .toString()
                        .toLowerCase(),
              )
              .join(' ');

      if (result.contains('success') ||
          result.contains('verified')) {
        return true;
      }

      return false;
    }

    // ==========================================================
    // STRING / OTHER RESPONSE
    // ==========================================================

    final String responseText =
        response.toString().toLowerCase();

    return responseText.contains('success') ||
        responseText.contains('verified');
  }

  // ============================================================
  // RESEND OTP
  // ============================================================

  Future<void> _resendOtp() async {
    if (_isResending ||
        _isVerifying) {
      return;
    }

    if (_reqId.isEmpty) {
      _showMessage(
        'OTP session is invalid. Please request OTP again.',
      );

      return;
    }

    setState(() {
      _isResending = true;
    });

    try {
      // ========================================================
      // MSG91 RETRY
      // ========================================================

      final dynamic response =
          await OTPWidget.retryOTP({
        'reqId': _reqId,
      });

      debugPrint(
        'MSG91 RETRY RESPONSE: $response',
      );

      // ========================================================
      // GET NEW REQUEST ID
      // ========================================================

      String? newReqId;

      if (response is Map) {
        final dynamic value =
            response['reqId'] ??
                response['req_id'] ??
                response['requestId'];

        if (value != null) {
          final String valueString =
              value.toString().trim();

          if (valueString.isNotEmpty) {
            newReqId = valueString;
          }
        }
      }

      // ========================================================
      // UPDATE REQUEST ID
      // ========================================================

      if (newReqId != null) {
        _reqId = newReqId;
      }

      // ========================================================
      // CLEAR OLD OTP
      // ========================================================

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
      } else if (error.contains('network')) {
        _showMessage(
          'Network error. Please check your internet connection.',
        );
      } else {
        _showMessage(
          'Unable to resend OTP. Please try again.',
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
  // FIREBASE AUTH ERROR MESSAGE
  // ============================================================

  String _firebaseAuthErrorMessage(
    FirebaseAuthException e,
  ) {
    switch (e.code) {
      case 'invalid-user':
        return 'Unable to identify your account. Please try again.';

      case 'user-not-found':
        return 'Account not found. Please complete profile setup.';

      case 'invalid-phone-number':
      case 'invalid-phone':
        return 'Please enter a valid 10-digit mobile number.';

      case 'operation-not-allowed':
        return 'Firebase Authentication is not enabled.';

      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';

      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      default:
        final String message =
            e.message?.trim() ?? '';

        return message.isNotEmpty
            ? message
            : 'Firebase authentication failed. Please try again.';
    }
  }

  // ============================================================
  // FIREBASE ERROR MESSAGE
  // ============================================================

  String _firebaseErrorMessage(
    FirebaseException e,
  ) {
    switch (e.code) {
      case 'permission-denied':
        return 'Firebase permission denied. Please check Firestore rules.';

      case 'unavailable':
        return 'Firebase is temporarily unavailable. Please try again.';

      case 'deadline-exceeded':
        return 'The Firebase request took too long. Please try again.';

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

    if (clean.length == 12 &&
        clean.startsWith('91')) {
      final String number =
          clean.substring(2);

      return '+91 '
          '${number.substring(0, 5)} '
          '${number.substring(5)}';
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
                                    .withValues(
                              alpha: 0.55,
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
                      // RESEND OTP
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
