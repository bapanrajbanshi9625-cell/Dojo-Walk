import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_colors.dart';
import '../services/otp_service.dart';

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

  static const String _backendUrl =
      'https://dojo-platform-backend.onrender.com';

  @override
  void initState() {
    super.initState();

    _reqId = widget.reqId.trim();

    debugPrint(
      'OTP SCREEN REQ ID: $_reqId',
    );
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

    if (!RegExp(
      r'^[0-9]{6}$',
    ).hasMatch(otp)) {
      _showMessage(
        'Please enter the complete 6-digit OTP.',
      );

      if (mounted) {
        _otpFocusNode.requestFocus();
      }

      return;
    }

    if (_reqId.trim().isEmpty) {
      _showMessage(
        'OTP session is invalid. Please request a new OTP.',
      );

      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      // ========================================================
      // 1. MSG91 OTP VERIFICATION
      // ========================================================

      debugPrint(
        'STARTING MSG91 OTP VERIFICATION',
      );

      final String accessToken =
          await OtpService.instance.verifyOtp(
        reqId: _reqId,
        otp: otp,
      );

      if (accessToken.trim().isEmpty) {
        throw Exception(
          'Secure access token was not received.',
        );
      }

      debugPrint(
        'MSG91 OTP VERIFICATION SUCCESS',
      );

      // ========================================================
      // 2. NORMALIZE PHONE
      // ========================================================

      final String? phone =
          _normalizeIndianPhone(
        widget.phoneNumber,
      );

      if (phone == null) {
        throw Exception(
          'Invalid mobile number.',
        );
      }

      debugPrint(
        'LOGIN PHONE AVAILABLE',
      );

      // ========================================================
      // 3. CHECK CUSTOMER THROUGH BACKEND
      // ========================================================

      final Map<String, dynamic> backendData =
          await _checkCustomerWithBackend(
        accessToken: accessToken,
        phoneNumber: phone,
      );

      // ========================================================
      // 4. BACKEND SUCCESS
      // ========================================================

      final bool backendSuccess =
          _isTrueValue(
        backendData['success'],
      );

      debugPrint(
        'BACKEND SUCCESS: $backendSuccess',
      );

      if (!backendSuccess) {
        final String backendMessage =
            backendData['message']
                    ?.toString()
                    .trim() ??
                '';

        throw Exception(
          backendMessage.isNotEmpty
              ? backendMessage
              : 'Secure account verification failed.',
        );
      }

      // ========================================================
      // 5. BACKEND DATA
      // ========================================================

      final bool exists =
          _isTrueValue(
        backendData['exists'],
      );

      final bool profileCompleted =
          _isTrueValue(
        backendData['profileCompleted'],
      );

      final String ownerId =
          backendData['ownerId']
                  ?.toString()
                  .trim() ??
              '';

      final String authUid =
          backendData['authUid']
                  ?.toString()
                  .trim() ??
              '';

      final String role =
          backendData['role']
                  ?.toString()
                  .trim() ??
              'owner';

      final String backendPhone =
          backendData['phone']
                  ?.toString()
                  .trim() ??
              '';

      final String verifiedPhone =
          backendPhone.isNotEmpty
              ? backendPhone
              : phone;

      debugPrint(
        'BACKEND EXISTS: $exists',
      );

      debugPrint(
        'BACKEND PROFILE COMPLETED: '
        '$profileCompleted',
      );

      debugPrint(
        'BACKEND ROLE: $role',
      );

      // ========================================================
      // 6. FIREBASE TEMPORARY SESSION
      // ========================================================

      final FirebaseAuth auth =
          FirebaseAuth.instance;

      User? firebaseUser =
          auth.currentUser;

      if (firebaseUser == null) {
        debugPrint(
          'CREATING TEMPORARY FIREBASE SESSION',
        );

        final UserCredential credential =
            await auth.signInAnonymously();

        firebaseUser =
            credential.user;
      }

      if (firebaseUser == null) {
        throw Exception(
          'Unable to create temporary Firebase session.',
        );
      }

      final String temporaryUid =
          firebaseUser.uid.trim();

      if (temporaryUid.isEmpty) {
        throw Exception(
          'Temporary Firebase UID is missing.',
        );
      }

      // ========================================================
      // 7. SAVE LOGIN STATE
      // ========================================================

      final SharedPreferences prefs =
          await SharedPreferences.getInstance();

      await prefs.setString(
        'tempVerifiedPhone',
        verifiedPhone,
      );

      await prefs.setBool(
        'tempOtpVerified',
        true,
      );

      await prefs.setBool(
        'tempExistingAccount',
        exists,
      );

      await prefs.setString(
        'tempOwnerId',
        ownerId,
      );

      await prefs.setString(
        'tempRole',
        role,
      );

      // ========================================================
      // 8. EXISTING ACCOUNT
      // ========================================================

      if (exists) {
        final String accountUid =
            authUid.isNotEmpty
                ? authUid
                : temporaryUid;

        await prefs.setString(
          'tempAccountUid',
          accountUid,
        );

        debugPrint(
          'EXISTING OWNER FOUND',
        );

        if (!mounted) {
          return;
        }

        if (profileCompleted) {
          _showMessage(
            'OTP verified. Welcome back!',
          );
        } else {
          _showMessage(
            'OTP verified. Please complete your profile.',
          );
        }

        await Future<void>.delayed(
          const Duration(
            milliseconds: 500,
          ),
        );

        if (!mounted) {
          return;
        }

        Navigator.of(context)
            .pushNamedAndRemoveUntil(
          '/',
          (route) => false,
        );

        return;
      }

      // ========================================================
      // 9. NEW ACCOUNT
      // ========================================================

      await prefs.setString(
        'tempAccountUid',
        temporaryUid,
      );

      await prefs.setString(
        'tempOwnerId',
        '',
      );

      await prefs.setBool(
        'tempExistingAccount',
        false,
      );

      await prefs.setBool(
        'tempOtpVerified',
        true,
      );

      await prefs.setString(
        'tempVerifiedPhone',
        verifiedPhone,
      );

      debugPrint(
        'NEW OWNER ACCOUNT',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'OTP verified. Please complete your profile.',
      );

      await Future<void>.delayed(
        const Duration(
          milliseconds: 500,
        ),
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context)
          .pushNamedAndRemoveUntil(
        '/',
        (route) => false,
      );
    } on FirebaseException catch (e) {
      debugPrint(
        'OWNER FIREBASE ERROR: ${e.code}',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        _firebaseErrorMessage(e),
      );
    } catch (e) {
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
      } else if (error.contains('access token') ||
          error.contains('access-token') ||
          error.contains('token')) {
        _showMessage(
          'OTP verified, but secure login could not be completed. Please try again.',
        );
      } else if (error.contains('network') ||
          error.contains('socket') ||
          error.contains('connection') ||
          error.contains('timeout')) {
        _showMessage(
          'Network error. Please check your internet connection.',
        );
      } else {
        _showMessage(
          e.toString().replaceFirst(
                'Exception: ',
                '',
              ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  // ============================================================
  // BACKEND CUSTOMER CHECK
  // ============================================================

  Future<Map<String, dynamic>>
      _checkCustomerWithBackend({
    required String accessToken,
    required String phoneNumber,
  }) async {
    try {
      final Uri uri = Uri.parse(
        '$_backendUrl/customer/check',
      );

      debugPrint(
        'BACKEND CUSTOMER CHECK STARTED',
      );

      final http.Response response =
          await http
              .post(
                uri,
                headers: const {
                  'Content-Type':
                      'application/json',
                  'Accept':
                      'application/json',
                },
                body: jsonEncode({
                  'accessToken':
                      accessToken,
                  'phoneNumber':
                      phoneNumber,
                }),
              )
              .timeout(
                const Duration(
                  seconds: 30,
                ),
              );

      debugPrint(
        'BACKEND STATUS: '
        '${response.statusCode}',
      );

      dynamic decoded;

      try {
        decoded =
            jsonDecode(
          response.body,
        );
      } catch (_) {
        throw Exception(
          'Dojo Platform backend returned an invalid response.',
        );
      }

      if (decoded is! Map) {
        throw Exception(
          'Dojo Platform backend returned an invalid response.',
        );
      }

      final Map<String, dynamic> data =
          Map<String, dynamic>.from(
        decoded,
      );

      debugPrint(
        'BACKEND RESPONSE KEYS: '
        '${data.keys.toList()}',
      );

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        final String message =
            data['message']
                    ?.toString()
                    .trim() ??
                '';

        final String error =
            data['error']
                    ?.toString()
                    .trim() ??
                '';

        final String reason =
            message.isNotEmpty
                ? message
                : error.isNotEmpty
                    ? error
                    : 'Backend request failed with HTTP ${response.statusCode}.';

        throw Exception(
          reason,
        );
      }

      return data;
    } on Exception {
      rethrow;
    } catch (e) {
      debugPrint(
        'BACKEND CUSTOMER CHECK ERROR: $e',
      );

      throw Exception(
        'Unable to connect to Dojo Platform backend.',
      );
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

    if (_reqId.trim().isEmpty) {
      _showMessage(
        'OTP session is invalid. Please request OTP again.',
      );

      return;
    }

    if (!mounted) {
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

      if (newReqId != null &&
          newReqId.trim().isNotEmpty) {
        _reqId =
            newReqId.trim();
      }

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
      } else if (error.contains('network') ||
          error.contains('socket') ||
          error.contains('connection') ||
          error.contains('timeout')) {
        _showMessage(
          'Network error. Please check your internet connection.',
        );
      } else {
        _showMessage(
          e.toString().replaceFirst(
                'Exception: ',
                '',
              ),
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
  // TRUE VALUE
  // ============================================================

  bool _isTrueValue(
    dynamic value,
  ) {
    if (value == true) {
      return true;
    }

    if (value is String) {
      final String text =
          value.trim().toLowerCase();

      return text == 'true' ||
          text == 'success' ||
          text == 'verified' ||
          text == '1';
    }

    if (value is num) {
      return value != 0;
    }

    return false;
  }

  // ============================================================
  // NORMALIZE INDIAN PHONE
  // ============================================================

  String? _normalizeIndianPhone(
    String value,
  ) {
    String phone =
        value.trim().replaceAll(
              RegExp(r'[^0-9+]'),
              '',
            );

    if (phone.startsWith('+91')) {
      phone =
          phone.substring(3);
    } else if (
        phone.startsWith('91') &&
        phone.length == 12) {
      phone =
          phone.substring(2);
    }

    if (phone.length != 10 ||
        !RegExp(
          r'^[6-9][0-9]{9}$',
        ).hasMatch(phone)) {
      return null;
    }

    return '+91$phone';
  }

  // ============================================================
  // FIREBASE ERROR
  // ============================================================

  String _firebaseErrorMessage(
    FirebaseException e,
  ) {
    switch (e.code) {
      case 'permission-denied':
        return 'Firebase permission denied.';

      case 'unauthenticated':
        return 'Firebase authentication is required.';

      case 'unavailable':
        return 'Firebase is temporarily unavailable. Please try again.';

      case 'deadline-exceeded':
        return 'The Firebase request took too long. Please try again.';

      case 'failed-precondition':
        return 'Firebase configuration is incomplete.';

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
        content:
            Text(
          message,
          style:
              const TextStyle(
            color:
                Colors.white,
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

    String clean =
        raw.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (clean.length == 12 &&
        clean.startsWith('91')) {
      clean =
          clean.substring(2);
    }

    if (clean.length == 10) {
      return '+91 '
          '${clean.substring(0, 5)} '
          '${clean.substring(5)}';
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
                const Text(
                  'Verify your number',
                  textAlign:
                      TextAlign.center,
                  style:
                      TextStyle(
                    color:
                        textColor,
                    fontSize:
                        27,
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
                  style:
                      TextStyle(
                    color:
                        secondaryText,
                    fontSize:
                        14,
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
                    color:
                        textColor,
                    fontSize:
                        15,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
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
                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      const Text(
                        'One-Time Password',
                        style:
                            TextStyle(
                          color:
                              textColor,
                          fontSize:
                              15,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      TextField(
                        controller:
                            _otpController,
                        focusNode:
                            _otpFocusNode,
                        autofocus:
                            true,
                        enabled:
                            !_isVerifying,
                        keyboardType:
                            TextInputType.number,
                        textInputAction:
                            TextInputAction.done,
                        maxLength:
                            6,
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
                          fontSize:
                              25,
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
                            fontSize:
                                24,
                            letterSpacing:
                                9,
                          ),
                          counterText:
                              '',
                          filled:
                              true,
                          fillColor:
                              inputBackground,
                          contentPadding:
                              const EdgeInsets
                                  .symmetric(
                            vertical:
                                17,
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
                              width:
                                  2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 18,
                      ),
                      SizedBox(
                        width:
                            double.infinity,
                        height:
                            54,
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
                              alpha:
                                  0.55,
                            ),
                            elevation:
                                0,
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
                                      height:
                                          23,
                                      width:
                                          23,
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
                                      height:
                                          19,
                                      width:
                                          19,
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
                const Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .center,
                  children: [
                    Icon(
                      Icons
                          .lock_outline_rounded,
                      size:
                          15,
                      color:
                          secondaryText,
                    ),
                    SizedBox(
                      width:
                          6,
                    ),
                    Text(
                      'Secure phone verification',
                      style:
                          TextStyle(
                        color:
                            secondaryText,
                        fontSize:
                            12,
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
                  style:
                      TextStyle(
                    color:
                        secondaryText,
                    fontSize:
                        13,
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
