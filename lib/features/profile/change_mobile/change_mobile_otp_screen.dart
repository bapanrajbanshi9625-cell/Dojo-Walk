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
  static const Color orange =
      Color(0xFFF4511E);

  static const Color navy =
      Color(0xFF263746);

  static const Color background =
      Color(0xFFEDEFF2);

  static const Color lightOrange =
      Color(0xFFFFF1E8);

  final TextEditingController _otpController =
      TextEditingController();

  final FocusNode _otpFocusNode =
      FocusNode();

  final ChangeMobileService _service =
      ChangeMobileService.instance;

  String _verificationId = '';

  int? _resendToken;

  bool _isVerifying = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();

    _verificationId =
        widget.verificationId;

    _resendToken =
        widget.resendToken;
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

    if (otp.length != 6) {
      _showMessage(
        'Please enter the 6-digit OTP.',
      );
      return;
    }

    if (_verificationId.isEmpty) {
      _showMessage(
        'OTP session expired. Please request a new OTP.',
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      final PhoneAuthCredential credential =
          _service.createCredential(
        verificationId:
            _verificationId,
        smsCode: otp,
      );

      await _service.completeMobileChange(
        ownerId: widget.ownerId,
        credential: credential,
        newPhoneNumber:
            widget.newPhoneNumber,
      );

      if (!mounted) {
        return;
      }

      widget.onChanged?.call(
        widget.newPhoneNumber,
      );

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
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }

      String message =
          'Could not verify OTP.';

      if (e.code ==
          'invalid-verification-code') {
        message =
            'Invalid OTP. Please check and try again.';
      } else if (e.code ==
          'session-expired') {
        message =
            'OTP expired. Please request a new OTP.';
      } else if (e.code ==
          'credential-already-in-use') {
        message =
            'This mobile number is already linked to another account.';
      } else if (e.code ==
          'provider-already-linked') {
        message =
            'This mobile number is already linked.';
      } else if (e.message != null &&
          e.message!.trim().isNotEmpty) {
        message = e.message!.trim();
      }

      _showMessage(message);
    } on FirebaseException catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        e.message ??
            'Could not update mobile number.',
      );
    } catch (e) {
      debugPrint(
        'Verify Mobile OTP Error: $e',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Could not update mobile number.',
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
    if (_isResending) {
      return;
    }

    setState(() {
      _isResending = true;
    });

    try {
      await _service.sendOtp(
        phoneNumber:
            widget.newPhoneNumber,

        onCodeSent: (
          String verificationId,
        ) {
          if (!mounted) {
            return;
          }

          setState(() {
            _verificationId =
                verificationId;
          });

          _showMessage(
            'New OTP sent successfully.',
          );
        },

        onVerificationFailed: (
          FirebaseAuthException error,
        ) {
          if (!mounted) {
            return;
          }

          _showMessage(
            error.message ??
                'Could not send OTP.',
          );
        },

        onVerificationCompleted: (
          PhoneAuthCredential credential,
        ) {
          // Do not automatically change the
          // mobile number here.
          //
          // The user must explicitly verify
          // the OTP/change flow.
        },
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _showMessage(
          e.message ??
              'Could not resend OTP.',
        );
      }
    } catch (e) {
      debugPrint(
        'Resend OTP Error: $e',
      );

      if (mounted) {
        _showMessage(
          'Could not resend OTP.',
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
          content: Text(message),
          behavior:
              SnackBarBehavior.floating,
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

      appBar: AppBar(
        backgroundColor:
            orange,
        foregroundColor:
            Colors.white,
        elevation: 0,
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

              const Text(
                'Enter OTP',
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

              Text(
                'We sent a 6-digit OTP to\n${widget.newPhoneNumber}',
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
                  hintText: '••••••',
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
                  border:
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
                      _isVerifying
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
                    'Didn't receive OTP?',
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
                        _isResending
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
            ],
          ),
        ),
      ),
    );
  }
}
