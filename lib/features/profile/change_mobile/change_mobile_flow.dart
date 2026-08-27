// File:
// lib/features/profile/change_mobile/change_mobile_flow.dart

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
  static const Color orange =
      Color(0xFFF4511E);

  static const Color navy =
      Color(0xFF263746);

  static const Color background =
      Color(0xFFEDEFF2);

  static const Color lightOrange =
      Color(0xFFFFF1E8);

  final TextEditingController _phoneController =
      TextEditingController();

  final FocusNode _phoneFocusNode =
      FocusNode();

  final ChangeMobileService _service =
      ChangeMobileService.instance;

  bool _isSendingOtp = false;

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
    String clean =
        value.replaceAll(
      RegExp(r'[^0-9+]'),
      '',
    );

    if (clean.startsWith('+91')) {
      return clean;
    }

    clean =
        clean.replaceAll(
      '+',
      '',
    );

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
    final String clean =
        value.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    String tenDigit = clean;

    if (clean.length == 12 &&
        clean.startsWith('91')) {
      tenDigit =
          clean.substring(2);
    }

    if (tenDigit.length != 10) {
      return false;
    }

    return RegExp(
      r'^[6-9][0-9]{9}$',
    ).hasMatch(tenDigit);
  }

  // ============================================================
  // FORMAT PHONE FOR DISPLAY
  // ============================================================

  String _displayPhone(
    String value,
  ) {
    final String clean =
        value.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    String tenDigit = clean;

    if (clean.length >= 10) {
      tenDigit =
          clean.substring(
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

    if (enteredNumber.isEmpty) {
      _showMessage(
        'Please enter your new mobile number.',
      );

      _phoneFocusNode.requestFocus();
      return;
    }

    if (!_isValidIndianMobile(
      enteredNumber,
    )) {
      _showMessage(
        'Please enter a valid 10-digit Indian mobile number.',
      );

      _phoneFocusNode.requestFocus();
      return;
    }

    final String newPhone =
        _cleanPhone(
      enteredNumber,
    );

    final String currentPhone =
        _cleanPhone(
      widget.currentNumber,
    );

    if (newPhone == currentPhone) {
      _showMessage(
        'New mobile number must be different from your current number.',
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
      _isSendingOtp = true;
    });

    String? verificationId;
    int? resendToken;

    try {
      await _service.sendOtp(
        phoneNumber: newPhone,

        onCodeSent: (
          String id,
        ) {
          verificationId = id;
        },

        onVerificationFailed: (
          FirebaseAuthException error,
        ) {
          throw error;
        },

        onVerificationCompleted: (
          PhoneAuthCredential credential,
        ) {
          // Do not automatically update.
          //
          // The user must explicitly complete
          // the OTP verification screen.
        },
      );

      if (!mounted) {
        return;
      }

      // Firebase calls codeSent asynchronously.
      //
      // Give the callback a short opportunity to
      // populate the verification ID.
      if (verificationId == null ||
          verificationId!.isEmpty) {
        _showMessage(
          'OTP request started. Please wait for the OTP.',
        );
        return;
      }

      final String ownerId =
          await _getOwnerId();

      if (!mounted) {
        return;
      }

      if (ownerId.isEmpty) {
        _showMessage(
          'Owner ID was not found.',
        );
        return;
      }

      final bool? changed =
          await Navigator.push<bool>(
        context,
        MaterialPageRoute<bool>(
          builder: (_) =>
              ChangeMobileOtpScreen(
            newPhoneNumber:
                newPhone,
            verificationId:
                verificationId!,
            ownerId:
                ownerId,
            resendToken:
                resendToken,
            onChanged:
                widget.onChanged,
          ),
        ),
      );

      if (changed == true &&
          mounted) {
        Navigator.pop(
          context,
          true,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }

      String message =
          'Could not send OTP.';

      if (e.code ==
          'invalid-phone-number') {
        message =
            'Please enter a valid mobile number.';
      } else if (e.code ==
          'too-many-requests') {
        message =
            'Too many attempts. Please try again later.';
      } else if (e.code ==
          'quota-exceeded') {
        message =
            'OTP limit reached. Please try again later.';
      } else if (e.message != null &&
          e.message!.trim().isNotEmpty) {
        message =
            e.message!.trim();
      }

      _showMessage(message);
    } catch (e) {
      debugPrint(
        'Send Mobile OTP Error: $e',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Could not send OTP.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSendingOtp = false;
        });
      }
    }
  }

  // ============================================================
  // OWNER ID
  // ============================================================

  Future<String> _getOwnerId() async {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return '';
    }

    try {
      final dynamic result =
          await _findOwnerIdFromFirestore(
        user.uid,
      );

      return result;
    } catch (e) {
      debugPrint(
        'Get Owner ID Error: $e',
      );

      return '';
    }
  }

  Future<String> _findOwnerIdFromFirestore(
    String uid,
  ) async {
    // This flow intentionally uses the
    // Firebase UID first.
    //
    // OwnerIdService remains the source of truth
    // in ProfileScreen. If your project already
    // exposes that service, replace this lookup
    // with OwnerIdService.instance.getExistingOwnerId().
    //
    // The import is kept here so the flow remains
    // independent from ProfileScreen.

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('owners')
              .where(
                'uid',
                isEqualTo: uid,
              )
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.id;
      }
    } catch (e) {
      debugPrint(
        'Owner UID lookup failed: $e',
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
              // SEND OTP
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
