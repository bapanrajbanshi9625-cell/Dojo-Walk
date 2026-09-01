import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_colors.dart';
import '../services/otp_service.dart';
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
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _otpController =
      TextEditingController();

  final FocusNode _otpFocusNode =
      FocusNode();

  // ============================================================
  // STATE
  // ============================================================

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
    if (_isVerifying || _isResending) {
      return;
    }

    final String otp =
        _otpController.text.trim();

    // ==========================================================
    // VALIDATE OTP
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

    // ==========================================================
    // VALIDATE REQUEST ID
    // ==========================================================

    if (_reqId.isEmpty) {
      _showMessage(
        'OTP session is invalid. Please request a new OTP.',
      );

      return;
    }

    // ==========================================================
    // START LOADING
    // ==========================================================

    setState(() {
      _isVerifying = true;
    });

    FocusScope.of(context).unfocus();

    try {
      // ========================================================
      // STEP 1
      // MSG91 OTP VERIFICATION
      // ========================================================

      final String accessToken =
          await OtpService.instance.verifyOtp(
        reqId: _reqId,
        otp: otp,
      );

      // ========================================================
      // ACCESS TOKEN IS REQUIRED
      // ========================================================
      //
      // "verified" only means OTP was verified.
      // It is NOT a Firebase authentication session.
      //
      // ========================================================

      if (accessToken.trim().isEmpty ||
          accessToken.trim() == 'verified') {
        throw Exception(
          'MSG91 access token was not returned.',
        );
      }

      // ========================================================
      // STEP 2
      // CALL FIREBASE CLOUD FUNCTION
      // ========================================================

      final HttpsCallable callable =
          FirebaseFunctions.instance
              .httpsCallable(
        'createFirebaseToken',
      );

      final HttpsCallableResult<dynamic>
          functionResult =
          await callable.call(
        <String, dynamic>{
          'accessToken':
              accessToken.trim(),
        },
      );

      // ========================================================
      // STEP 3
      // READ FUNCTION RESPONSE
      // ========================================================

      if (functionResult.data == null) {
        throw Exception(
          'Firebase authentication response is empty.',
        );
      }

      final Map<String, dynamic> data =
          Map<String, dynamic>.from(
        functionResult.data as Map,
      );

      final bool success =
          data['success'] == true;

      final String customToken =
          data['customToken']
                  ?.toString()
                  .trim() ??
              '';

      if (!success ||
          customToken.isEmpty) {
        throw Exception(
          'Firebase authentication token was not returned.',
        );
      }

      // ========================================================
      // STEP 4
      // FIREBASE AUTHENTICATION
      // ========================================================
      //
      // This creates the real Firebase Auth session.
      //
      // SplashScreen can now safely read:
      //
      // phoneAccounts/{uid}
      //
      // ========================================================

      final UserCredential
          credential =
          await FirebaseAuth.instance
              .signInWithCustomToken(
        customToken,
      );

      final User? firebaseUser =
          credential.user;

      if (firebaseUser == null) {
        throw Exception(
          'Firebase user session could not be created.',
        );
      }

      // ========================================================
      // STEP 5
      // SUCCESS
      // ========================================================

      debugPrint(
        'Firebase authentication successful.',
      );

      if (!mounted) {
        return;
      }

      // ========================================================
      // STEP 6
      // SPLASH
      // ========================================================
      //
      // Splash now runs with an authenticated Firebase user.
      //
      // Expected flow:
      //
      // FirebaseAuth.currentUser
      //       ↓
      // phoneAccounts/{uid}
      //       ↓
      // ownerId
      //       ↓
      // owners/{ownerId}
      //       ↓
      // profileCompleted
      //       ↓
      // ProfileSetupScreen / MainNavigationScreen
      //
      // ========================================================

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => SplashScreen(
            phoneNumber:
                widget.phoneNumber,
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
        'FIREBASE AUTH ERROR: ${e.code}',
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
        'FIREBASE ERROR: ${e.code}',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        _firebaseErrorMessage(e),
      );
    }

    // ==========================================================
    // CLOUD FUNCTION ERROR
    // ==========================================================

    on FirebaseFunctionsException catch (e) {
      debugPrint(
        'CLOUD FUNCTION ERROR: ${e.code}',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        _cloudFunctionErrorMessage(e),
      );
    }

    // ==========================================================
    // FIREBASE AUTH ERROR
    // ==========================================================

    on FirebaseAuthException catch (e) {
      debugPrint(
        'FIREBASE AUTH ERROR: ${e.code}',
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
        'FIREBASE ERROR: ${e.code}',
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

      _showMessage(
        'Unable to complete login. Please try again.',
      );
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
  // ============================================================
  // RESEND OTP
  // ============================================================

  Future<void> _resendOtp() async {
    if (_isResending || _isVerifying) {
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
      final String? newReqId =
          await OtpService.instance.resendOtp(
        reqId: _reqId,
      );

      // ========================================================
      // UPDATE REQUEST ID
      // ========================================================

      if (newReqId != null &&
          newReqId.trim().isNotEmpty) {
        _reqId = newReqId.trim();
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
    }

    // ==========================================================
    // ERROR
    // ==========================================================

    catch (e) {
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
          'OTP session has expired. Please request OTP again.',
        );
      } else if (error.contains('network') ||
          error.contains('internet')) {
        _showMessage(
          'Network error. Please check your internet connection.',
        );
      } else if (error.contains('too many')) {
        _showMessage(
          'Too many OTP requests. Please wait and try again.',
        );
      } else {
        _showMessage(
          'Unable to resend OTP. Please try again.',
        );
      }
    }

    // ==========================================================
    // STOP RESEND LOADING
    // ==========================================================

    finally {
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

      case 'operation-not-allowed':
        return 'Firebase Authentication is not enabled.';

      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';

      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      case 'invalid-credential':
        return 'Authentication session is invalid. Please try again.';

      default:
        return 'Firebase authentication failed. Please try again.';
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
        return 'Firebase permission denied. Please check your account access.';

      case 'unavailable':
        return 'Firebase is temporarily unavailable. Please try again.';

      case 'deadline-exceeded':
        return 'The Firebase request took too long. Please try again.';

      case 'not-found':
        return 'Your account information was not found.';

      default:
        return 'Unable to access your account. Please try again.';
    }
  }

  // ============================================================
  // CLOUD FUNCTION ERROR MESSAGE
  // ============================================================

  String _cloudFunctionErrorMessage(
    FirebaseFunctionsException e,
  ) {
    switch (e.code) {
      case 'unauthenticated':
        return 'MSG91 verification failed. Please verify the OTP again.';

      case 'permission-denied':
        return 'This mobile number is not linked to the correct Dojo account.';

      case 'not-found':
        return 'No Dojo owner account is linked to this mobile number.';

      case 'failed-precondition':
        return 'Your Dojo account is not configured correctly.';

      case 'invalid-argument':
        return 'Invalid authentication information. Please try again.';

      case 'unavailable':
        return 'Authentication service is temporarily unavailable.';

      case 'deadline-exceeded':
        return 'Authentication request timed out. Please try again.';

      default:
        return e.message ??
            'Unable to complete Firebase authentication.';
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
                            !_isVerifying &&
                                !_isResending,
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
                              !_isVerifying &&
                              !_isResending) {
                            FocusScope.of(
                              context,
                            ).unfocus();
                          }
                        },
                        onSubmitted:
                            (_) {
                          if (!_isVerifying &&
                              !_isResending) {
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
                          disabledBorder:
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
                              (_isVerifying ||
                                      _isResending)
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
