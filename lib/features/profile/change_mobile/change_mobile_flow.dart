// File:
// lib/features/profile/change_mobile/change_mobile_flow.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'change_mobile_otp_screen.dart';
import 'change_mobile_service.dart';

class ChangeMobileFlow extends StatefulWidget {
  final String currentNumber;
  final ValueChanged<String>? onChanged;

  const ChangeMobileFlow({
    super.key,
    required this.currentNumber,
    this.onChanged,
  });

  @override
  State<ChangeMobileFlow> createState() =>
      _ChangeMobileFlowState();
}

class _ChangeMobileFlowState
    extends State<ChangeMobileFlow> {
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

  final TextEditingController _phoneController =
      TextEditingController();

  final FocusNode _phoneFocusNode =
      FocusNode();

  final ChangeMobileService _service =
      ChangeMobileService.instance;

  bool _isSendingOtp = false;

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  // ============================================================
  // CLEAN PHONE NUMBER
  // ============================================================

  String _cleanPhone(String value) {
    String clean = value.replaceAll(
      RegExp(r'[^0-9+]'),
      '',
    );

    if (clean.startsWith('+91')) {
      return clean;
    }

    clean = clean.replaceAll('+', '');

    if (clean.length == 10) {
      return '+91$clean';
    }

    if (clean.startsWith('91') &&
        clean.length == 12) {
      return '+$clean';
    }

    return '+$clean';
  }

  // ============================================================
  // VALIDATE INDIAN MOBILE
  // ============================================================

  bool _isValidIndianMobile(
    String value,
  ) {
    final String clean = value.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    String tenDigit = clean;

    if (clean.length == 12 &&
        clean.startsWith('91')) {
      tenDigit = clean.substring(2);
    }

    if (tenDigit.length != 10) {
      return false;
    }

    return RegExp(
      r'^[6-9][0-9]{9}$',
    ).hasMatch(tenDigit);
  }

  // ============================================================
  // DISPLAY PHONE
  // ============================================================

  String _displayPhone(
    String value,
  ) {
    final String clean = value.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    String tenDigit = clean;

    if (clean.length >= 10) {
      tenDigit = clean.substring(
        clean.length - 10,
      );
    }

    if (tenDigit.length == 10) {
      return '+91 '
          '${tenDigit.substring(0, 5)} '
          '${tenDigit.substring(5)}';
    }

    return value;
  }

  // ============================================================
  // SEND OTP
  // ============================================================

  Future<void> _sendOtp() async {
    if (_isSendingOtp) {
      return;
    }

    final String enteredNumber =
        _phoneController.text.trim();

    // ----------------------------------------------------------
    // EMPTY
    // ----------------------------------------------------------

    if (enteredNumber.isEmpty) {
      _showMessage(
        'Please enter your new mobile number.',
      );

      _phoneFocusNode.requestFocus();
      return;
    }

    // ----------------------------------------------------------
    // VALIDATE
    // ----------------------------------------------------------

    if (!_isValidIndianMobile(
      enteredNumber,
    )) {
      _showMessage(
        'Please enter a valid 10-digit Indian mobile number.',
      );

      _phoneFocusNode.requestFocus();
      return;
    }

    // ----------------------------------------------------------
    // CLEAN PHONE
    // ----------------------------------------------------------

    final String newPhone =
        _cleanPhone(enteredNumber);

    final String currentPhone =
        _cleanPhone(widget.currentNumber);

    // ----------------------------------------------------------
    // SAME NUMBER
    // ----------------------------------------------------------

    if (newPhone == currentPhone) {
      _showMessage(
        'New mobile number must be different from your current number.',
      );
      return;
    }

    // ----------------------------------------------------------
    // CURRENT USER
    // ----------------------------------------------------------

    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'Your login session has expired. Please login again.',
      );
      return;
    }

    // ----------------------------------------------------------
    // START LOADING
    // ----------------------------------------------------------

    setState(() {
      _isSendingOtp = true;
    });

    try {
      // ========================================================
      // REQUEST OTP
      // ========================================================

      final Completer<
          String> verificationCompleter =
          Completer<String>();

      int? resendToken;

      await _service.sendOtp(
        phoneNumber: newPhone,

        // ------------------------------------------------------
        // RESEND TOKEN
        // ------------------------------------------------------

        onResendToken: (
          int? token,
        ) {
          resendToken = token;
        },

        // ------------------------------------------------------
        // CODE SENT
        // ------------------------------------------------------

        onCodeSent: (
          String verificationId,
        ) {
          if (!verificationCompleter
              .isCompleted) {
            verificationCompleter.complete(
              verificationId,
            );
          }
        },

        // ------------------------------------------------------
        // VERIFICATION FAILED
        // ------------------------------------------------------

        onVerificationFailed: (
          FirebaseAuthException error,
        ) {
          if (!verificationCompleter
              .isCompleted) {
            verificationCompleter.completeError(
              error,
            );
          }
        },

        // ------------------------------------------------------
        // AUTO VERIFICATION
        // ------------------------------------------------------

        onVerificationCompleted: (
          PhoneAuthCredential credential,
        ) {
          // Intentionally ignored.
          //
          // The mobile number must only be
          // changed after explicit OTP verification.
        },
      );

      // ========================================================
      // WAIT FOR CODE SENT
      // ========================================================

      final String verificationId =
          await verificationCompleter.future
              .timeout(
        const Duration(
          seconds: 30,
        ),
      );

      if (!mounted) {
        return;
      }

      if (verificationId.trim().isEmpty) {
        _showMessage(
          'Could not start OTP verification. Please try again.',
        );
        return;
      }

      // ========================================================
      // GET OWNER ID
      // ========================================================

      final String ownerId =
          await _getOwnerId();

      if (!mounted) {
        return;
      }

      if (ownerId.isEmpty) {
        _showMessage(
          'Owner profile was not found.',
        );
        return;
      }

      // ========================================================
      // OPEN OTP SCREEN
      // ========================================================

      final bool? changed =
          await Navigator.push<bool>(
        context,
        MaterialPageRoute<bool>(
          builder: (_) =>
              ChangeMobileOtpScreen(
            newPhoneNumber:
                newPhone,
            verificationId:
                verificationId,
            ownerId:
                ownerId,
            resendToken:
                resendToken,
            onChanged:
                widget.onChanged,
          ),
        ),
      );

      // ========================================================
      // SUCCESS
      // ========================================================

      if (changed == true &&
          mounted) {
        Navigator.pop(
          context,
          true,
        );
      }
    }

    // ==========================================================
    // FIREBASE AUTH ERROR
    // ==========================================================

    on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }

      String message =
          'Could not send OTP.';

      switch (e.code) {
        case 'invalid-phone-number':
          message =
              'Please enter a valid mobile number.';
          break;

        case 'too-many-requests':
          message =
              'Too many attempts. Please try again later.';
          break;

        case 'quota-exceeded':
          message =
              'OTP limit reached. Please try again later.';
          break;

        case 'operation-not-allowed':
          message =
              'Phone authentication is not enabled in Firebase.';
          break;

        case 'network-request-failed':
          message =
              'Network error. Please check your internet connection.';
          break;

        default:
          if (e.message != null &&
              e.message!.trim().isNotEmpty) {
            message =
                e.message!.trim();
          }
      }

      _showMessage(message);
    }

    // ==========================================================
    // TIMEOUT
    // ==========================================================

    on TimeoutException {
      if (!mounted) {
        return;
      }

      _showMessage(
        'OTP request timed out. Please try again.',
      );
    }

    // ==========================================================
    // OTHER ERROR
    // ==========================================================

    catch (e) {
      debugPrint(
        'Send Mobile OTP Error: $e',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Could not send OTP. Please try again.',
      );
    }

    // ==========================================================
    // STOP LOADING
    // ==========================================================

    finally {
      if (mounted) {
        setState(() {
          _isSendingOtp = false;
        });
      }
    }
  }

  // ============================================================
  // GET OWNER ID
  // ============================================================

  Future<String> _getOwnerId() async {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return '';
    }

    final String uid =
        user.uid.trim();

    if (uid.isEmpty) {
      return '';
    }

    try {
      return await _findOwnerIdFromFirestore(
        uid,
      );
    } catch (e) {
      debugPrint(
        'Get Owner ID Error: $e',
      );

      return '';
    }
  }

  // ============================================================
  // FIND OWNER ID
  //
  // ACTUAL FIRESTORE:
  //
  // owners/{document}
  //
  // authUid:  Firebase UID
  // ownerId:  OWN26GH0004
  // mainPhone: +91...
  //
  // ============================================================

  Future<String>
      _findOwnerIdFromFirestore(
    String uid,
  ) async {
    final String cleanUid =
        uid.trim();

    if (cleanUid.isEmpty) {
      return '';
    }

    // ----------------------------------------------------------
    // FIRST:
    // Check owners/{uid}
    // ----------------------------------------------------------

    try {
      final DocumentSnapshot<
          Map<String, dynamic>> directDoc =
          await FirebaseFirestore.instance
              .collection('owners')
              .doc(cleanUid)
              .get();

      if (directDoc.exists) {
        final Map<String, dynamic>? data =
            directDoc.data();

        if (data != null) {
          final dynamic ownerId =
              data['ownerId'];

          if (ownerId is String &&
              ownerId.trim().isNotEmpty) {
            return ownerId.trim();
          }
        }
      }
    } catch (e) {
      debugPrint(
        'Direct owner document lookup failed: $e',
      );
    }

    // ----------------------------------------------------------
    // SECOND:
    // Search authUid field
    //
    // IMPORTANT:
    // Firestore field is authUid, NOT uid.
    // ----------------------------------------------------------

    try {
      final QuerySnapshot<
          Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('owners')
              .where(
                'authUid',
                isEqualTo: cleanUid,
              )
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        final Map<String, dynamic> data =
            snapshot.docs.first.data();

        final dynamic ownerId =
            data['ownerId'];

        if (ownerId is String &&
            ownerId.trim().isNotEmpty) {
          return ownerId.trim();
        }

        // Fallback if ownerId field is missing.
        return snapshot.docs.first.id;
      }
    } catch (e) {
      debugPrint(
        'authUid owner lookup failed: $e',
      );
    }

    return '';
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
          content:
              Text(message),
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
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 18,
          bottom:
              MediaQuery.of(context)
                      .viewInsets
                      .bottom +
                  20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // ==================================================
              // HEADER
              // ==================================================

              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration:
                        BoxDecoration(
                      color:
                          lightOrange,
                      borderRadius:
                          BorderRadius.circular(
                        13,
                      ),
                    ),
                    child:
                        const Icon(
                      Icons
                          .phone_android_rounded,
                      color:
                          orange,
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  const Expanded(
                    child: Text(
                      'Change Mobile Number',
                      style:
                          TextStyle(
                        fontSize: 21,
                        fontWeight:
                            FontWeight.w800,
                        color: navy,
                      ),
                    ),
                  ),

                  IconButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                      );
                    },
                    icon:
                        const Icon(
                      Icons
                          .close_rounded,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 20,
              ),

              // ==================================================
              // CURRENT NUMBER
              // ==================================================

              const Text(
                'Current Mobile Number',
                style:
                    TextStyle(
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w700,
                  color: navy,
                ),
              ),

              const SizedBox(
                height: 7,
              ),

              Container(
                width:
                    double.infinity,
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 14,
                  vertical: 15,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFF5F5F5,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons
                          .phone_outlined,
                      color:
                          Colors.grey,
                    ),

                    const SizedBox(
                      width: 12,
                    ),

                    Expanded(
                      child: Text(
                        _displayPhone(
                          widget
                              .currentNumber,
                        ),
                        style:
                            const TextStyle(
                          fontSize: 15,
                          fontWeight:
                              FontWeight.w700,
                          color:
                              navy,
                        ),
                      ),
                    ),

                    const Icon(
                      Icons
                          .lock_outline_rounded,
                      size: 19,
                      color:
                          Colors.grey,
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              // ==================================================
              // NEW NUMBER
              // ==================================================

              const Text(
                'New Mobile Number',
                style:
                    TextStyle(
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w700,
                  color: navy,
                ),
              ),

              const SizedBox(
                height: 7,
              ),

              TextField(
                controller:
                    _phoneController,
                focusNode:
                    _phoneFocusNode,
                keyboardType:
                    TextInputType.phone,
                textInputAction:
                    TextInputAction.done,
                maxLength: 10,
                inputFormatters: [
                  FilteringTextInputFormatter
                      .digitsOnly,
                ],
                decoration:
                    InputDecoration(
                  counterText: '',
                  hintText:
                      'Enter 10-digit mobile number',
                  prefixIcon:
                      const Icon(
                    Icons
                        .phone_android_outlined,
                    color:
                        orange,
                  ),
                  prefixText:
                      '+91  ',
                  filled: true,
                  fillColor:
                      const Color(
                    0xFFF8F8F8,
                  ),
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                    borderSide:
                        BorderSide.none,
                  ),
                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                    borderSide:
                        const BorderSide(
                      color:
                          orange,
                      width: 1.3,
                    ),
                  ),
                ),
                onSubmitted: (_) {
                  _sendOtp();
                },
              ),

              const SizedBox(
                height: 10,
              ),

              const Text(
                'An OTP will be sent to this number for verification.',
                style:
                    TextStyle(
                  fontSize: 12,
                  color:
                      Colors.grey,
                  fontWeight:
                      FontWeight.w500,
                ),
              ),

              const SizedBox(
                height: 22,
              ),

              // ==================================================
              // SEND OTP BUTTON
              // ==================================================

              SizedBox(
                width:
                    double.infinity,
                height: 50,
                child:
                    ElevatedButton(
                  onPressed:
                      _isSendingOtp
                          ? null
                          : _sendOtp,
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
                      _isSendingOtp
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
                              'Send OTP',
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
                height: 8,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
