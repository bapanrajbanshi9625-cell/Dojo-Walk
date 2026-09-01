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
  final TextEditingController _otpController =
      TextEditingController();

  final FocusNode _otpFocusNode = FocusNode();

  bool _isVerifying = false;
  bool _isResending = false;

  String _currentReqId = '';

  @override
  void initState() {
    super.initState();

    _currentReqId = widget.reqId.trim();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
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

    if (!RegExp(r'^[0-9]{6}$').hasMatch(otp)) {
      _showMessage(
        'Please enter the complete 6-digit OTP.',
      );
      return;
    }

    if (_currentReqId.isEmpty) {
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
      // STEP 1
      // MSG91 OTP VERIFY
      // ========================================================

      final String result =
          await OtpService.instance.verifyOtp(
        reqId: _currentReqId,
        otp: otp,
      );

      // ========================================================
      // IMPORTANT
      //
      // 'verified' means OTP was verified but MSG91 did not
      // return an access token.
      //
      // Without access token we cannot securely create the
      // Firebase custom token.
      // ========================================================

      if (result.trim().isEmpty ||
          result.trim().toLowerCase() == 'verified') {
        throw Exception(
          'OTP verified, but MSG91 access token was not received. '
          'Please try again.',
        );
      }

      final String msg91AccessToken =
          result.trim();

      // ========================================================
      // STEP 2
      // CALL FIREBASE CLOUD FUNCTION
      // ========================================================

      final HttpsCallable callable =
          FirebaseFunctions.instanceFor(
        region: 'us-central1',
      ).httpsCallable(
        'createFirebaseToken',
      );

      final HttpsCallableResult<dynamic> response =
          await callable.call(
        <String, dynamic>{
          'accessToken': msg91AccessToken,
        },
      );

      // ========================================================
      // STEP 3
      // READ CUSTOM TOKEN
      // ========================================================

      final dynamic responseData =
          response.data;

      if (responseData is! Map) {
        throw Exception(
          'Invalid authentication response from server.',
        );
      }

      final Map<String, dynamic> data =
          Map<String, dynamic>.from(
        responseData,
      );

      final dynamic customTokenValue =
          data['customToken'];

      if (customTokenValue == null) {
        throw Exception(
          'Firebase authentication token was not received.',
        );
      }

      final String customToken =
          customTokenValue.toString().trim();

      if (customToken.isEmpty) {
        throw Exception(
          'Firebase authentication token is empty.',
        );
      }

      // ========================================================
      // STEP 4
      // FIREBASE AUTH
      // ========================================================

      await FirebaseAuth.instance
          .signInWithCustomToken(customToken);

      // ========================================================
      // VERIFY FIREBASE SESSION
      // ========================================================

      final User? user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception(
          'Firebase authentication failed.',
        );
      }

      // ========================================================
      // SUCCESS
      //
      // SplashScreen will now see:
      //
      // FirebaseAuth.currentUser != null
      //
      // and can safely read:
      //
      // phoneAccounts/{uid}
      // owners/{ownerId}
      // ========================================================

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const SplashScreen(),
        ),
        (route) => false,
      );
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) {
        return;
      }

      String message =
          'Unable to authenticate your account.';

      if (e.message != null &&
          e.message!.trim().isNotEmpty) {
        message = e.message!.trim();
      }

      _showMessage(message);
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }

      String message =
          'Firebase authentication failed.';

      if (e.message != null &&
          e.message!.trim().isNotEmpty) {
        message = e.message!.trim();
      }

      _showMessage(message);
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
      );
    } finally {
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

    if (_currentReqId.isEmpty) {
      _showMessage(
        'OTP session is invalid. Please request a new OTP.',
      );
      return;
    }

    setState(() {
      _isResending = true;
    });

    try {
      final String? newReqId =
          await OtpService.instance.resendOtp(
        reqId: _currentReqId,
      );

      if (newReqId == null ||
          newReqId.trim().isEmpty) {
        throw Exception(
          'OTP resend failed. Please try again.',
        );
      }

      _currentReqId = newReqId.trim();

      _otpController.clear();

      if (!mounted) {
        return;
      }

      _showMessage(
        'A new OTP has been sent.',
      );

      _otpFocusNode.requestFocus();
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
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
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final Color primary =
        AppColors.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text(
          'Verify OTP',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),

              // ==================================================
              // TITLE
              // ==================================================

              const Text(
                'Enter OTP',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF263746),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'We sent a 6-digit verification code to',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                widget.phoneNumber,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF263746),
                ),
              ),

              const SizedBox(height: 40),

              // ==================================================
              // OTP FIELD
              // ==================================================

              TextField(
                controller: _otpController,
                focusNode: _otpFocusNode,
                keyboardType:
                    TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                enabled:
                    !_isVerifying &&
                    !_isResending,
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
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '------',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade300,
                    letterSpacing: 8,
                  ),
                  filled: true,
                  fillColor:
                      Colors.grey.shade50,
                  contentPadding:
                      const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                    borderSide:
                        BorderSide(
                      color:
                          Colors.grey.shade300,
                    ),
                  ),
                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                    borderSide:
                        BorderSide(
                      color:
                          Colors.grey.shade300,
                    ),
                  ),
                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                    borderSide:
                        BorderSide(
                      color: primary,
                      width: 2,
                    ),
                  ),
                ),
                onSubmitted: (_) {
                  _verifyOtp();
                },
              ),

              const SizedBox(height: 24),

              // ==================================================
              // VERIFY BUTTON
              // ==================================================

              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed:
                      _isVerifying ||
                              _isResending
                          ? null
                          : _verifyOtp,
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor:
                        Colors.white,
                    disabledBackgroundColor:
                        Colors.grey.shade300,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                    elevation: 0,
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          height: 24,
                          width: 24,
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
                          'Verify OTP',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 22),

              // ==================================================
              // RESEND
              // ==================================================

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Text(
                    'Didn't receive the OTP?',
                    style: TextStyle(
                      color:
                          Colors.grey.shade600,
                    ),
                  ),
                  TextButton(
                    onPressed:
                        _isVerifying ||
                                _isResending
                            ? null
                            : _resendOtp,
                    child: _isResending
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Resend',
                            style:
                                TextStyle(
                              color: primary,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // ==================================================
              // SECURITY MESSAGE
              // ==================================================

              Container(
                padding:
                    const EdgeInsets.all(16),
                decoration:
                    BoxDecoration(
                  color:
                      Colors.grey.shade50,
                  borderRadius:
                      BorderRadius.circular(14),
                  border: Border.all(
                    color:
                        Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons
                          .verified_user_outlined,
                      color: primary,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your OTP is securely verified through MSG91.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Colors
                              .grey.shade700,
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
    );
  }
}
