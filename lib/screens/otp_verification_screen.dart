// lib/screens/otp_verification_screen.dart

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final TextEditingController _otpController =
      TextEditingController();

  final OtpService _otpService = OtpService();

  bool _isVerifying = false;
  bool _isResending = false;

  String _currentReqId = '';

  @override
  void initState() {
    super.initState();

    _currentReqId = widget.reqId;
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  // ============================================================
  // VERIFY OTP
  // ============================================================

  Future<void> _verifyOtp() async {
    if (_isVerifying) return;

    final String otp = _otpController.text.trim();

    if (otp.length != 6) {
      _showMessage(
        'Please enter the 6-digit OTP.',
      );
      return;
    }

    if (_currentReqId.trim().isEmpty) {
      _showMessage(
        'OTP session expired. Please request a new OTP.',
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      // ----------------------------------------------------------
      // STEP 1
      // Verify OTP through MSG91
      // ----------------------------------------------------------

      final String msg91Result =
          await _otpService.verifyOtp(
        reqId: _currentReqId,
        otp: otp,
      );

      final String accessToken =
          msg91Result.trim();

      // ----------------------------------------------------------
      // IMPORTANT
      // ----------------------------------------------------------
      // OtpService must return the REAL MSG91 access token.
      //
      // "verified" is NOT a Firebase token.
      // ----------------------------------------------------------

      if (accessToken.isEmpty ||
          accessToken == 'verified') {
        throw Exception(
          'MSG91 verification succeeded but no access token was returned.',
        );
      }

      // ----------------------------------------------------------
      // STEP 2
      // Send MSG91 access token to Cloud Function
      // ----------------------------------------------------------

      final FirebaseFunctions functions =
          FirebaseFunctions.instanceFor(
        region: 'us-central1',
      );

      final HttpsCallable callable =
          functions.httpsCallable(
        'createFirebaseToken',
      );

      final HttpsCallableResult result =
          await callable.call(
        <String, dynamic>{
          'accessToken': accessToken,
        },
      );

      final dynamic rawData = result.data;

      if (rawData is! Map) {
        throw Exception(
          'Invalid response from authentication server.',
        );
      }

      final Map<String, dynamic> data =
          Map<String, dynamic>.from(rawData);

      final dynamic customTokenValue =
          data['customToken'];

      if (customTokenValue is! String ||
          customTokenValue.trim().isEmpty) {
        throw Exception(
          'Firebase custom token was not returned.',
        );
      }

      final String customToken =
          customTokenValue.trim();

      // ----------------------------------------------------------
      // STEP 3
      // Sign in to Firebase using custom token
      // ----------------------------------------------------------

      await FirebaseAuth.instance
          .signInWithCustomToken(customToken);

      // ----------------------------------------------------------
      // STEP 4
      // Confirm Firebase session
      // ----------------------------------------------------------

      final User? firebaseUser =
          FirebaseAuth.instance.currentUser;

      if (firebaseUser == null) {
        throw Exception(
          'Firebase login could not be completed.',
        );
      }

      // ----------------------------------------------------------
      // STEP 5
      // Splash will now check:
      //
      // Firebase UID
      //      ↓
      // phoneAccounts/{uid}
      //      ↓
      // ownerId
      //      ↓
      // owners/{ownerId}
      //      ↓
      // profileCompleted
      // ----------------------------------------------------------

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const SplashScreen(),
        ),
        (route) => false,
      );
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;

      _showMessage(
        _cloudFunctionErrorMessage(e),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      _showMessage(
        _firebaseAuthErrorMessage(e),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      _showMessage(
        _firebaseErrorMessage(e),
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        _generalErrorMessage(e),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isVerifying = false;
      });
    }
  }

  // ============================================================
  // RESEND OTP
  // ============================================================

  Future<void> _resendOtp() async {
    if (_isResending || _isVerifying) return;

    setState(() {
      _isResending = true;
    });

    try {
      final String? newReqId =
          await _otpService.resendOtp(
        identifier: '91${widget.phoneNumber}',
      );

      if (newReqId == null ||
          newReqId.trim().isEmpty) {
        throw Exception(
          'MSG91 did not return a new request ID.',
        );
      }

      _currentReqId = newReqId.trim();

      _otpController.clear();

      if (!mounted) return;

      _showMessage(
        'A new OTP has been sent.',
        success: true,
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      _showMessage(
        _firebaseErrorMessage(e),
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        _generalErrorMessage(e),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isResending = false;
      });
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool success = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor:
              success ? Colors.green : Colors.redAccent,
        ),
      );
  }

  // ============================================================
  // FIREBASE AUTH ERROR
  // ============================================================

  String _firebaseAuthErrorMessage(
    FirebaseAuthException e,
  ) {
    switch (e.code) {
      case 'invalid-custom-token':
        return 'Firebase authentication token is invalid.';

      case 'custom-token-mismatch':
        return 'Firebase authentication configuration mismatch.';

      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';

      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      default:
        return e.message ??
            'Firebase authentication failed.';
    }
  }

  // ============================================================
  // FIREBASE ERROR
  // ============================================================

  String _firebaseErrorMessage(
    FirebaseException e,
  ) {
    switch (e.code) {
      case 'permission-denied':
        return 'Unable to access your account. Please check Firebase permissions.';

      case 'unavailable':
        return 'Firebase is temporarily unavailable. Please try again.';

      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';

      default:
        return e.message ??
            'Unable to access your Firebase account.';
    }
  }

  // ============================================================
  // CLOUD FUNCTION ERROR
  // ============================================================

  String _cloudFunctionErrorMessage(
    FirebaseFunctionsException e,
  ) {
    switch (e.code) {
      case 'unauthenticated':
        return 'MSG91 authentication could not be verified.';

      case 'not-found':
        return 'No Dojo owner account is linked to this mobile number.';

      case 'permission-denied':
        return 'This owner account is not authorized.';

      case 'failed-precondition':
        return 'Your Dojo owner account is not configured correctly.';

      case 'invalid-argument':
        return 'Invalid authentication information.';

      case 'unavailable':
        return 'Authentication server is temporarily unavailable.';

      case 'internal':
        return 'Server error. Please try again.';

      default:
        return e.message ??
            'Unable to complete authentication.';
    }
  }

  // ============================================================
  // GENERAL ERROR
  // ============================================================

  String _generalErrorMessage(Object error) {
    final String text = error.toString();

    if (text.contains('access token')) {
      return 'MSG91 verification did not return a valid access token.';
    }

    if (text.contains('request ID')) {
      return 'OTP session expired. Please request a new OTP.';
    }

    return 'Unable to complete OTP verification. Please try again.';
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final ThemeData theme =
        Theme.of(context);

    return Scaffold(
      backgroundColor:
          const Color(0xFFF6F7F9),

      appBar: AppBar(
        elevation: 0,
        backgroundColor:
            const Color(0xFFF97316),
        foregroundColor: Colors.white,
        title: const Text(
          'Verify OTP',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 430,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [

                  // ------------------------------------------------
                  // ICON
                  // ------------------------------------------------

                  Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFFFFE7D5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.sms_rounded,
                      size: 38,
                      color:
                          Color(0xFFF97316),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ------------------------------------------------
                  // TITLE
                  // ------------------------------------------------

                  const Text(
                    'Enter verification code',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      color:
                          Color(0xFF17202A),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'We sent a 6-digit OTP to',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    '+91 ${widget.phoneNumber}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color:
                          Color(0xFFF97316),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ------------------------------------------------
                  // OTP FIELD
                  // ------------------------------------------------

                  TextField(
                    controller: _otpController,
                    autofocus: true,
                    enabled: !_isVerifying,
                    keyboardType:
                        TextInputType.number,
                    textInputAction:
                        TextInputAction.done,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    obscureText: false,
                    inputFormatters: [
                      FilteringTextInputFormatter
                          .digitsOnly,
                    ],
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 10,
                    ),
                    decoration:
                        InputDecoration(
                      counterText: '',
                      hintText: '------',
                      hintStyle:
                          TextStyle(
                        color:
                            Colors.grey.shade400,
                        letterSpacing: 8,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),
                        borderSide:
                            BorderSide(
                          color:
                              Colors.grey.shade300,
                        ),
                      ),
                      enabledBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),
                        borderSide:
                            BorderSide(
                          color:
                              Colors.grey.shade300,
                        ),
                      ),
                      focusedBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),
                        borderSide:
                            const BorderSide(
                          color:
                              Color(0xFFF97316),
                          width: 2,
                        ),
                      ),
                    ),
                    onSubmitted: (_) {
                      _verifyOtp();
                    },
                  ),

                  const SizedBox(height: 22),

                  // ------------------------------------------------
                  // VERIFY BUTTON
                  // ------------------------------------------------

                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed:
                          _isVerifying
                              ? null
                              : _verifyOtp,
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(
                          0xFFF97316,
                        ),
                        disabledBackgroundColor:
                            Colors.orange.shade200,
                        foregroundColor:
                            Colors.white,
                        elevation: 0,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                        ),
                      ),
                      child: _isVerifying
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation<
                                        Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Verify OTP & Login',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ------------------------------------------------
                  // RESEND
                  // ------------------------------------------------

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Text(
                        'Didn't receive the OTP?',
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              Colors.grey.shade600,
                        ),
                      ),
                      TextButton(
                        onPressed:
                            (_isResending ||
                                    _isVerifying)
                                ? null
                                : _resendOtp,
                        child: _isResending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Resend',
                                style:
                                    TextStyle(
                                  fontWeight:
                                      FontWeight.w700,
                                  color:
                                      Color(
                                    0xFFF97316,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ------------------------------------------------
                  // SECURITY MESSAGE
                  // ------------------------------------------------

                  Container(
                    padding:
                        const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          const Color(
                        0xFFFFF7ED,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                      border: Border.all(
                        color:
                            const Color(
                          0xFFFED7AA,
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons
                              .security_rounded,
                          size: 20,
                          color:
                              Color(
                            0xFFF97316,
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: Text(
                            'Your OTP is used only to securely verify your Dojo account.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color:
                                  theme
                                      .colorScheme
                                      .onSurface
                                      .withValues(
                                        alpha: 0.65,
                                      ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
