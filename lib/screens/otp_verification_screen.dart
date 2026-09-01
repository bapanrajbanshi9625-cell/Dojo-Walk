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

  late String _currentReqId;

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

  Future<void> _verifyOtp() async {
    if (_isVerifying || _isResending) {
      return;
    }

    final String otp = _otpController.text.trim();

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
      // MSG91 OTP VERIFICATION
      // ========================================================

      final String msg91Result =
          await OtpService.instance.verifyOtp(
        reqId: _currentReqId,
        otp: otp,
      );

      final String accessToken =
          msg91Result.trim();

      // The OtpService returns "verified" when MSG91 did not
      // provide an access token. Firebase authentication cannot
      // continue without the access token.
      if (accessToken.isEmpty ||
          accessToken.toLowerCase() == 'verified') {
        throw Exception(
          'OTP verified, but MSG91 access token was not received. '
          'Please try again.',
        );
      }

      // ========================================================
      // FIREBASE CLOUD FUNCTION
      // ========================================================

      final HttpsCallable function =
          FirebaseFunctions.instanceFor(
        region: 'us-central1',
      ).httpsCallable(
        'createFirebaseToken',
      );

      final HttpsCallableResult<dynamic> result =
          await function.call(
        <String, dynamic>{
          'accessToken': accessToken,
        },
      );

      if (result.data is! Map) {
        throw Exception(
          'Invalid authentication response from server.',
        );
      }

      final Map<String, dynamic> data =
          Map<String, dynamic>.from(
        result.data as Map,
      );

      final dynamic tokenValue =
          data['customToken'];

      if (tokenValue == null) {
        throw Exception(
          'Firebase authentication token was not received.',
        );
      }

      final String customToken =
          tokenValue.toString().trim();

      if (customToken.isEmpty) {
        throw Exception(
          'Firebase authentication token is empty.',
        );
      }

      // ========================================================
      // FIREBASE AUTHENTICATION
      // ========================================================

      await FirebaseAuth.instance
          .signInWithCustomToken(customToken);

      final User? user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception(
          'Firebase authentication failed.',
        );
      }

      // ========================================================
      // GO TO SPLASH
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

      _showMessage(
        e.message?.trim().isNotEmpty == true
            ? e.message!.trim()
            : 'Unable to authenticate your account.',
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        e.message?.trim().isNotEmpty == true
            ? e.message!.trim()
            : 'Firebase authentication failed.',
      );
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

  @override
  Widget build(BuildContext context) {
    final Color primary = AppColors.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Verify OTP',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF263746),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),

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
                'Enter the 6-digit OTP sent to',
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

              TextField(
                controller: _otpController,
                focusNode: _otpFocusNode,
                enabled:
                    !_isVerifying &&
                    !_isResending,
                keyboardType:
                    TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                inputFormatters: [
                  FilteringTextInputFormatter
                      .digitsOnly,
                ],
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 8,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '------',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                    ),
                  ),
                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                    borderSide: BorderSide(
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

              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed:
                      _isVerifying ||
                              _isResending
                          ? null
                          : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        Colors.grey.shade300,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
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

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive the OTP?",
                    style: TextStyle(
                      color: Colors.grey.shade600,
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
                            style: TextStyle(
                              color: primary,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              Container(
                padding:
                    const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius:
                      BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
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
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
