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
        widget.verificationId.trim();

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

    // ----------------------------------------------------------
    // OTP VALIDATION
    // ----------------------------------------------------------

    if (otp.isEmpty) {
      _showMessage(
        'Please enter the OTP.',
      );

      _otpFocusNode.requestFocus();
      return;
    }

    if (otp.length != 6) {
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
        'OTP must contain only 6 digits.',
      );

      _otpFocusNode.requestFocus();
      return;
    }

    // ----------------------------------------------------------
    // VERIFICATION ID VALIDATION
    // ----------------------------------------------------------

    if (_verificationId.isEmpty) {
      _showMessage(
        'OTP session expired. Please request a new OTP.',
      );
      return;
    }

    // ----------------------------------------------------------
    // OWNER ID VALIDATION
    // ----------------------------------------------------------

    if (widget.ownerId.trim().isEmpty) {
      _showMessage(
        'Owner ID was not found. Please try again.',
      );
      return;
    }

    // ----------------------------------------------------------
    // AUTH USER VALIDATION
    // ----------------------------------------------------------

    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'Your login session has expired. Please login again.',
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isVerifying = true;
    });

    try {
      // ========================================================
      // CREATE PHONE CREDENTIAL
      // ========================================================

      final PhoneAuthCredential credential =
          _service.createCredential(
        verificationId:
            _verificationId,
        smsCode:
            otp,
      );

      // ========================================================
      // COMPLETE MOBILE CHANGE
      //
      // 1. Firebase Auth phone
      // 2. owners/{owner document}
      //    mainPhone
      //    phone
      // ========================================================

      await _service.completeMobileChange(
        ownerId:
            widget.ownerId.trim(),
        credential:
            credential,
        newPhoneNumber:
            widget.newPhoneNumber.trim(),
      );

      if (!mounted) {
        return;
      }

      // ========================================================
      // CALLBACK
      // ========================================================

      widget.onChanged?.call(
        widget.newPhoneNumber.trim(),
      );

      // ========================================================
      // SUCCESS
      // ========================================================

      _showMessage(
        'Mobile number updated successfully.',
      );

      await Future<void>.delayed(
        const Duration(
          milliseconds: 500,
        ),
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(
        context,
        true,
      );
    }

    // ==========================================================
    // FIREBASE AUTH ERROR
    // ==========================================================

    on FirebaseAuthException catch (e) {
      debugPrint(
        'Change Mobile FirebaseAuth Error: '
        '${e.code} - ${e.message}',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        _authErrorMessage(e),
      );
    }

    // ==========================================================
    // FIREBASE GENERAL ERROR
    // ==========================================================

    on FirebaseException catch (e) {
      debugPrint(
        'Change Mobile Firebase Error: '
        '${e.code} - ${e.message}',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        e.message?.trim().isNotEmpty == true
            ? e.message!.trim()
            : 'Could not update mobile number.',
      );
    }

    // ==========================================================
    // OTHER ERROR
    // ==========================================================

    catch (e) {
      debugPrint(
        'Change Mobile OTP Error: $e',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Could not update mobile number. Please try again.',
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
  }

  // ============================================================
  // AUTH ERROR MESSAGE
  // ============================================================

  String _authErrorMessage(
    FirebaseAuthException e,
  ) {
    switch (e.code) {
      case 'invalid-verification-code':
        return 'Invalid OTP. Please check and try again.';

      case 'session-expired':
        return 'OTP expired. Please request a new OTP.';

      case 'invalid-verification-id':
        return 'OTP session is invalid. Please request a new OTP.';

      case 'credential-already-in-use':
        return 'This mobile number is already linked to another account.';

      case 'phone-number-already-exists':
        return 'This mobile number is already registered with another account.';

      case 'provider-already-linked':
        return 'This mobile number is already linked.';

      case 'requires-recent-login':
        return 'Please login again before changing your mobile number.';

      case 'user-disabled':
        return 'This account has been disabled.';

      case 'user-not-found':
        return 'Your account could not be found. Please login again.';

      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';

      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      case 'quota-exceeded':
        return 'OTP limit reached. Please try again later.';

      case 'operation-not-allowed':
        return 'Phone authentication is not enabled in Firebase.';

      case 'invalid-phone-number':
        return 'The mobile number is invalid.';

      default:
        if (e.message != null &&
            e.message!.trim().isNotEmpty) {
          return e.message!.trim();
        }

        return 'Could not verify OTP. Please try again.';
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
        phoneNumber:
            phone,

        // ------------------------------------------------------
        // RESEND TOKEN
        // ------------------------------------------------------

        onResendToken: (
          int? token,
        ) {
          _resendToken = token;
        },

        // ------------------------------------------------------
        // CODE SENT
        // ------------------------------------------------------

        onCodeSent: (
          String verificationId,
        ) {
          if (!mounted) {
            return;
          }

          final String newId =
              verificationId.trim();

          if (newId.isEmpty) {
            _showMessage(
              'Could not start the new OTP session.',
            );
            return;
          }

          setState(() {
            _verificationId =
                newId;
          });

          _otpController.clear();

          _otpFocusNode.requestFocus();

          _showMessage(
            'New OTP sent successfully.',
          );
        },

        // ------------------------------------------------------
        // VERIFICATION FAILED
        // ------------------------------------------------------

        onVerificationFailed: (
          FirebaseAuthException error,
        ) {
          if (!mounted) {
            return;
          }

          _showMessage(
            _authErrorMessage(error),
          );
        },

        // ------------------------------------------------------
        // AUTO VERIFICATION
        // ------------------------------------------------------

        onVerificationCompleted: (
          PhoneAuthCredential credential,
        ) {
          // ----------------------------------------------------
          // IMPORTANT
          //
          // Do NOT automatically update the phone number.
          // User must explicitly enter OTP and press:
          //
          // "Verify & Update"
          // ----------------------------------------------------
        },
      );
    }

    // ==========================================================
    // FIREBASE AUTH ERROR
    // ==========================================================

    on FirebaseAuthException catch (e) {
      debugPrint(
        'Resend Mobile OTP FirebaseAuth Error: '
        '${e.code} - ${e.message}',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        _authErrorMessage(e),
      );
    }

    // ==========================================================
    // OTHER ERROR
    // ==========================================================

    catch (e) {
      debugPrint(
        'Resend OTP Error: $e',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Could not resend OTP. Please try again.',
      );
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

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor:
            orange,
        foregroundColor:
            Colors.white,
        elevation: 0,
        title: const Text(
          'Verify Mobile Number',
          style: TextStyle(
            fontSize: 18,
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.center,
            children: [
              const SizedBox(
                height: 24,
              ),

              // ==================================================
              // ICON
              // ==================================================

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

              // ==================================================
              // TITLE
              // ==================================================

              const Text(
                'Enter OTP',
                textAlign:
                    TextAlign.center,
                style:
                    TextStyle(
                  fontSize: 25,
                  fontWeight:
                      FontWeight.w900,
                  color:
                      navy,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              // ==================================================
              // PHONE
              // ==================================================

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

              // ==================================================
              // OTP FIELD
              // ==================================================

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
                    // Keep automatic verification
                    // disabled. User explicitly presses
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
                  color:
                      navy,
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
                    letterSpacing:
                        8,
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
                ),
              ),

              const SizedBox(
                height: 22,
              ),

              // ==================================================
              // VERIFY BUTTON
              // ==================================================

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

              // ==================================================
              // RESEND
              // ==================================================

              Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .center,
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

              // ==================================================
              // SECURITY NOTE
              // ==================================================

              const Text(
                'Your mobile number will be updated only '
                'after successful OTP verification.',
                textAlign:
                    TextAlign.center,
                style:
                    TextStyle(
                  fontSize: 11,
                  height: 1.4,
                  color:
                      Colors.grey,
                  fontWeight:
                      FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
