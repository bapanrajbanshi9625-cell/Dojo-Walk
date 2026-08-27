// File:
// lib/features/profile/change_mobile/change_mobile_otp_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'change_mobile_service.dart';

class ChangeMobileOtpScreen extends StatefulWidget {
  final String newPhoneNumber;
  final String verificationId;
  final String ownerId;
  final int? resendToken;
  final ValueChanged<String>? onChanged;

  const ChangeMobileOtpScreen({
    super.key,
    required this.newPhoneNumber,
    required this.verificationId,
    required this.ownerId,
    this.resendToken,
    this.onChanged,
  });

  @override
  State<ChangeMobileOtpScreen> createState() =>
      _ChangeMobileOtpScreenState();
}

class _ChangeMobileOtpScreenState
    extends State<ChangeMobileOtpScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color orange =
      Color(0xFFF4511E);

  static const Color navy =
      Color(0xFF263746);

  static const Color background =
      Color(0xFFEDEFF2);

  static const Color lightOrange =
      Color(0xFFFFF1E8);

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _otpController =
      TextEditingController();

  final FocusNode _otpFocusNode =
      FocusNode();

  final ChangeMobileService _service =
      ChangeMobileService.instance;

  // ============================================================
  // STATE
  // ============================================================

  late String _verificationId;

  int? _resendToken;

  bool _isVerifying = false;
  bool _isResending = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _verificationId =
        widget.verificationId;

    _resendToken =
        widget.resendToken;

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _otpFocusNode.requestFocus();
    });
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
  // VERIFY OTP
  // ============================================================

  Future<void> _verifyOtp() async {
    if (_isVerifying ||
        _isResending) {
      return;
    }

    final String otp =
        _otpController.text.trim();

    if (otp.isEmpty) {
      _showMessage(
        'Please enter the 6-digit OTP.',
      );

      _otpFocusNode.requestFocus();
      return;
    }

    if (!RegExp(
      r'^[0-9]{6}$',
    ).hasMatch(otp)) {
      _showMessage(
        'Please enter a valid 6-digit OTP.',
      );

      _otpFocusNode.requestFocus();
      return;
    }

    if (_verificationId.trim().isEmpty) {
      _showMessage(
        'OTP session expired. Please request a new OTP.',
      );
      return;
    }

    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'Your login session has expired. Please login again.',
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      // ----------------------------------------------------------
      // CREATE PHONE CREDENTIAL
      // ----------------------------------------------------------

      final PhoneAuthCredential credential =
          _service.createCredential(
        verificationId:
            _verificationId,
        smsCode: otp,
      );

      // ----------------------------------------------------------
      // COMPLETE MOBILE CHANGE
      // ----------------------------------------------------------

      await _service.completeMobileChange(
        ownerId: widget.ownerId,
        credential: credential,
        newPhoneNumber:
            widget.newPhoneNumber,
      );

      if (!mounted) {
        return;
      }

      // ----------------------------------------------------------
      // UPDATE LOCAL CALLBACK
      // ----------------------------------------------------------

      widget.onChanged?.call(
        widget.newPhoneNumber,
      );

      // ----------------------------------------------------------
      // SUCCESS MESSAGE
      // ----------------------------------------------------------

      _showMessage(
        'Mobile number updated successfully.',
      );

      await Future<void>.delayed(
        const Duration(
          milliseconds: 700,
        ),
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(
        context,
        true,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }

      _showFirebaseAuthError(e);
    } on FirebaseException catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        e.message?.trim().isNotEmpty == true
            ? e.message!.trim()
            : 'Could not update mobile number.',
      );
    } catch (e) {
      debugPrint(
        'Verify Mobile OTP Error: $e',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Could not update mobile number. Please try again.',
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
  // FIREBASE AUTH ERROR
  // ============================================================

  void _showFirebaseAuthError(
    FirebaseAuthException e,
  ) {
    String message =
        'Could not verify OTP.';

    switch (e.code) {
      case 'invalid-verification-code':
        message =
            'Invalid OTP. Please check the OTP and try again.';
        break;

      case 'session-expired':
        message =
            'OTP expired. Please request a new OTP.';
        break;

      case 'credential-already-in-use':
        message =
            'This mobile number is already linked to another account.';
        break;

      case 'provider-already-linked':
        message =
            'This mobile number is already linked.';
        break;

      case 'requires-recent-login':
        message =
            'For security, please login again before changing your mobile number.';
        break;

      case 'invalid-phone-number':
        message =
            'The mobile number is invalid.';
        break;

      case 'too-many-requests':
        message =
            'Too many attempts. Please try again later.';
        break;

      case 'quota-exceeded':
        message =
            'OTP limit reached. Please try again later.';
        break;

      case 'network-request-failed':
        message =
            'Network error. Please check your internet connection.';
        break;

      default:
        if (e.message != null &&
            e.message!.trim().isNotEmpty) {
          message = e.message!.trim();
        }
    }

    _showMessage(message);
  }

  // ============================================================
  // RESEND OTP
  // ============================================================

  Future<void> _resendOtp() async {
    if (_isResending ||
        _isVerifying) {
      return;
    }

    final String phone =
        widget.newPhoneNumber.trim();

    if (phone.isEmpty) {
      _showMessage(
        'Mobile number is missing.',
      );
      return;
    }

    setState(() {
      _isResending = true;
    });

    try {
      await _service.sendOtp(
        phoneNumber: phone,

        // --------------------------------------------------------
        // NEW VERIFICATION ID
        // --------------------------------------------------------

        onCodeSent: (
          String verificationId,
        ) {
          if (!mounted) {
            return;
          }

          if (verificationId
              .trim()
              .isEmpty) {
            _showMessage(
              'Could not create a new OTP session.',
            );
            return;
          }

          setState(() {
            _verificationId =
                verificationId;

            _otpController.clear();
          });

          _showMessage(
            'New OTP sent successfully.',
          );

          _otpFocusNode.requestFocus();
        },

        // --------------------------------------------------------
        // VERIFICATION FAILED
        // --------------------------------------------------------

        onVerificationFailed: (
          FirebaseAuthException error,
        ) {
          if (!mounted) {
            return;
          }

          _showFirebaseAuthError(
            error,
          );
        },

        // --------------------------------------------------------
        // DO NOT AUTO UPDATE
        // --------------------------------------------------------

        onVerificationCompleted: (
          PhoneAuthCredential credential,
        ) {
          // Intentionally empty.
          //
          // Mobile number must NOT be changed
          // automatically.
          //
          // User must manually enter the OTP
          // and press "Verify & Update".
        },
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }

      _showFirebaseAuthError(e);
    } catch (e) {
      debugPrint(
        'Resend Mobile OTP Error: $e',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Could not resend OTP. Please try again.',
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

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
          ),
          behavior:
              SnackBarBehavior.floating,
          margin:
              const EdgeInsets.all(14),
          duration:
              const Duration(
            seconds: 3,
          ),
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          background,

      // ==========================================================
      // APP BAR
      // ==========================================================

      appBar: AppBar(
        backgroundColor:
            orange,
        foregroundColor:
            Colors.white,
        elevation: 0,
        centerTitle: false,
        title:
            const Text(
          'Verify Mobile Number',
          style: TextStyle(
            fontSize: 18,
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ),

      // ==========================================================
      // BODY
      // ==========================================================

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            24,
            20,
            30,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.center,
            children: [
              // ====================================================
              // ICON
              // ====================================================

              Container(
                width: 72,
                height: 72,
                decoration:
                    BoxDecoration(
                  color:
                      lightOrange,
                  borderRadius:
                      BorderRadius.circular(
                    22,
                  ),
                ),
                child:
                    const Icon(
                  Icons
                      .phone_android_rounded,
                  color:
                      orange,
                  size: 36,
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // ====================================================
              // TITLE
              // ====================================================

              const Text(
                'Enter OTP',
                textAlign:
                    TextAlign.center,
                style:
                    TextStyle(
                  fontSize: 25,
                  fontWeight:
                      FontWeight.w900,
                  color: navy,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              // ====================================================
              // DESCRIPTION
              // ====================================================

              Text(
                'We sent a 6-digit OTP to\n'
                '${widget.newPhoneNumber}',
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color:
                      Colors.grey,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              const SizedBox(
                height: 28,
              ),

              // ====================================================
              // OTP FIELD
              // ====================================================

              TextField(
                controller:
                    _otpController,
                focusNode:
                    _otpFocusNode,
                keyboardType:
                    TextInputType.number,
                textInputAction:
                    TextInputAction.done,
                textAlign:
                    TextAlign.center,
                maxLength: 6,
                autofocus: true,

                enabled:
                    !_isVerifying &&
                    !_isResending,

                inputFormatters: [
                  FilteringTextInputFormatter
                      .digitsOnly,
                ],

                onChanged: (
                  String value,
                ) {
                  if (value.length == 6 &&
                      !_isVerifying &&
                      !_isResending) {
                    // Do not auto-submit.
                    //
                    // User explicitly presses
                    // Verify & Update.
                  }
                },

                onSubmitted: (_) {
                  _verifyOtp();
                },

                style:
                    const TextStyle(
                  fontSize: 25,
                  fontWeight:
                      FontWeight.w800,
                  letterSpacing: 8,
                  color: navy,
                ),

                decoration:
                    InputDecoration(
                  counterText: '',
                  hintText:
                      '••••••',
                  hintStyle:
                      TextStyle(
                    color:
                        Colors.grey.shade400,
                    letterSpacing: 8,
                  ),
                  filled: true,
                  fillColor:
                      Colors.white,
                  contentPadding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 18,
                    vertical: 18,
                  ),

                  prefixIcon:
                      const Icon(
                    Icons
                        .lock_outline_rounded,
                    color:
                        orange,
                  ),

                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                    borderSide:
                        BorderSide.none,
                  ),

                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                    borderSide:
                        BorderSide.none,
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
                          orange,
                      width: 1.4,
                    ),
                  ),

                  disabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                    borderSide:
                        BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(
                height: 22,
              ),

              // ====================================================
              // VERIFY BUTTON
              // ====================================================

              SizedBox(
                width:
                    double.infinity,
                height: 52,
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
                        orange,
                    foregroundColor:
                        Colors.white,
                    disabledBackgroundColor:
                        orange.withOpacity(
                      0.55,
                    ),
                    disabledForegroundColor:
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

                  child:
                      _isVerifying
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(
                                color:
                                    Colors.white,
                                strokeWidth:
                                    2.3,
                              ),
                            )
                          : const Text(
                              'Verify & Update',
                              style:
                                  TextStyle(
                                fontSize:
                                    15,
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              // ====================================================
              // RESEND
              // ====================================================

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  const Text(
                    "Didn't receive OTP?",
                    style:
                        TextStyle(
                      color:
                          Colors.grey,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),

                  const SizedBox(
                    width: 5,
                  ),

                  TextButton(
                    onPressed:
                        (_isResending ||
                                _isVerifying)
                            ? null
                            : _resendOtp,

                    style:
                        TextButton.styleFrom(
                      foregroundColor:
                          orange,
                    ),

                    child:
                        _isResending
                            ? const SizedBox(
                                width: 17,
                                height: 17,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,
                                  color:
                                      orange,
                                ),
                              )
                            : const Text(
                                'Resend OTP',
                                style:
                                    TextStyle(
                                  color:
                                      orange,
                                  fontWeight:
                                      FontWeight.w800,
                                ),
                              ),
                  ),
                ],
              ),

              const SizedBox(
                height: 8,
              ),

              // ====================================================
              // SECURITY NOTE
              // ====================================================

              const Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons
                        .verified_user_outlined,
                    size: 15,
                    color:
                        Colors.grey,
                  ),
                  SizedBox(
                    width: 6,
                  ),
                  Text(
                    'Your number will be updated securely.',
                    textAlign:
                        TextAlign.center,
                    style:
                        TextStyle(
                      fontSize: 11,
                      color:
                          Colors.grey,
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
