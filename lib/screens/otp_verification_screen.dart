import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_colors.dart';
import '../services/owner_id_service.dart';
import 'main_navigation_screen.dart';
import 'profile_setup.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
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

  // ============================================================
  // VERIFY OTP
  // ============================================================

  Future<void> _verifyOtp() async {
    final String otp =
        _otpController.text.trim();

    if (otp.length != 6) {
      _showMessage(
        'Please enter the complete 6-digit OTP.',
      );

      if (mounted) {
        _otpFocusNode.requestFocus();
      }

      return;
    }

    if (_isVerifying) {
      return;
    }

    final String verificationId =
        widget.verificationId.trim();

    if (verificationId.isEmpty) {
      _showMessage(
        'Verification session is invalid. Please request a new OTP.',
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      // ========================================================
      // 1. CREATE PHONE CREDENTIAL
      // ========================================================

      final PhoneAuthCredential credential =
          PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      // ========================================================
      // 2. FIREBASE PHONE LOGIN
      // ========================================================

      final UserCredential userCredential =
          await FirebaseAuth.instance
              .signInWithCredential(
        credential,
      );

      final User? user =
          userCredential.user;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message:
              'Firebase user was not found after OTP verification.',
        );
      }

      // ========================================================
      // 3. FIREBASE UID
      // ========================================================

      final String uid =
          user.uid.trim();

      if (uid.isEmpty) {
        throw FirebaseAuthException(
          code: 'invalid-user',
          message:
              'Firebase UID was not found.',
        );
      }

      // ========================================================
      // 4. VERIFIED PHONE NUMBER
      // ========================================================

      String phoneNumber =
          user.phoneNumber?.trim() ?? '';

      if (phoneNumber.isEmpty) {
        phoneNumber =
            widget.phoneNumber.trim();

        if (phoneNumber.isNotEmpty &&
            !phoneNumber.startsWith('+')) {
          phoneNumber =
              '+91$phoneNumber';
        }
      }

      if (phoneNumber.isEmpty) {
        throw FirebaseAuthException(
          code: 'phone-not-found',
          message:
              'Verified mobile number was not found.',
        );
      }

      // ========================================================
      // 5. GET / CREATE OWNER ID
      // ========================================================

      final String ownerId =
          await OwnerIdService.instance
              .getOrCreateOwnerId(
        uid: uid,
        phoneNumber: phoneNumber,
      );

      final String cleanOwnerId =
          ownerId.trim();

      if (cleanOwnerId.isEmpty) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'owner-id-missing',
          message:
              'Owner ID could not be created.',
        );
      }

      debugPrint(
        'Owner ID: $cleanOwnerId',
      );

      // ========================================================
      // 6. LOAD OWNER PROFILE
      // ========================================================
      //
      // ProfileSetupService saves:
      //
      // owners/{ownerId}
      //
      // ========================================================

      final DocumentSnapshot<
              Map<String, dynamic>>
          profileSnapshot =
          await FirebaseFirestore.instance
              .collection('owners')
              .doc(cleanOwnerId)
              .get();

      // ========================================================
      // 7. PROFILE DATA
      // ========================================================

      final Map<String, dynamic>? data =
          profileSnapshot.data();

      // ========================================================
      // 8. ACTIVE STATUS
      // ========================================================

      final bool isActive =
          data?['isActive'] != false;

      if (!isActive) {
        await FirebaseAuth.instance
            .signOut();

        if (!mounted) {
          return;
        }

        _showInactiveDialog(
          cleanOwnerId,
        );

        return;
      }

      // ========================================================
      // 9. PROFILE COMPLETED
      // ========================================================

      final bool profileCompleted =
          data?['profileCompleted'] == true;

      if (!mounted) {
        return;
      }

      // ========================================================
      // 10. PROFILE NOT COMPLETED
      // ========================================================

      if (!profileCompleted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const ProfileSetupScreen(),
          ),
          (route) => false,
        );

        return;
      }

      // ========================================================
      // 11. PROFILE COMPLETED → MAIN APP
      // ========================================================

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const MainNavigationScreen(),
        ),
        (route) => false,
      );
    }

    // ==========================================================
    // FIREBASE AUTH ERROR
    // ==========================================================

    on FirebaseAuthException catch (e) {
      debugPrint(
        'Owner OTP Auth Error: ${e.code}',
      );

      String message;

      switch (e.code) {
        case 'invalid-verification-code':
          message =
              'Invalid OTP. Please check the code and try again.';
          break;

        case 'session-expired':
          message =
              'This OTP has expired. Please request a new OTP.';
          break;

        case 'invalid-verification-id':
          message =
              'Verification session expired. Please request a new OTP.';
          break;

        case 'credential-already-in-use':
          message =
              'This mobile number is already linked to another account.';
          break;

        case 'too-many-requests':
          message =
              'Too many attempts. Please try again later.';
          break;

        case 'network-request-failed':
          message =
              'Network error. Please check your internet connection.';
          break;

        case 'user-not-found':
          message =
              'Unable to complete phone verification. Please try again.';
          break;

        case 'invalid-user':
          message =
              'Unable to identify your account. Please try again.';
          break;

        case 'phone-not-found':
          message =
              'Verified mobile number was not found.';
          break;

        default:
          message =
              e.message?.trim().isNotEmpty == true
                  ? e.message!.trim()
                  : 'OTP verification failed. Please try again.';
      }

      if (!mounted) {
        return;
      }

      _showMessage(message);
    }

    // ==========================================================
    // FIRESTORE / FIREBASE ERROR
    // ==========================================================

    on FirebaseException catch (e) {
      debugPrint(
        'Owner Firebase Error: ${e.code}',
      );

      if (!mounted) {
        return;
      }

      String message;

      switch (e.code) {
        case 'permission-denied':
          message =
              'Unable to access your Owner profile. Please check your account permissions.';
          break;

        case 'unavailable':
          message =
              'Firebase is temporarily unavailable. Please check your internet connection and try again.';
          break;

        case 'deadline-exceeded':
          message =
              'The request took too long. Please check your internet connection and try again.';
          break;

        case 'owner-id-missing':
          message =
              e.message ??
                  'Owner ID could not be found.';
          break;

        default:
          message =
              e.message?.trim().isNotEmpty == true
                  ? e.message!.trim()
                  : 'Unable to load your Owner profile. Please try again.';
      }

      _showMessage(message);
    }

    // ==========================================================
    // GENERAL ERROR
    // ==========================================================

    catch (e) {
      debugPrint(
        'Owner OTP Error: $e',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Something went wrong. Please try again.',
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
  // INACTIVE OWNER DIALOG
  // ============================================================

  void _showInactiveDialog(
    String ownerId,
  ) {
    final ThemeData theme =
        Theme.of(context);

    final Color primary =
        theme.colorScheme.primary;

    final Color textColor =
        theme.colorScheme.onSurface;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
              theme.cardColor,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.block_rounded,
                color:
                    theme.colorScheme.error,
                size: 25,
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Text(
                  'Account Inactive',
                  style: TextStyle(
                    color: textColor,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Your Owner ID $ownerId is currently inactive.\n\n'
            'Please contact support to activate your account.',
            style: TextStyle(
              color:
                  textColor.withOpacity(0.75),
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: Text(
                'OK',
                style: TextStyle(
                  color: primary,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );
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

    final ThemeData theme =
        Theme.of(context);

    final Color backgroundColor =
        theme.colorScheme.onSurface;

    final Color foregroundColor =
        theme.colorScheme.surface;

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
            backgroundColor,
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(12),
        ),
        content: Text(
          message,
          style: TextStyle(
            color: foregroundColor,
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

    if (clean.length > 10) {
      final String last10 =
          clean.substring(
        clean.length - 10,
      );

      return '+91 '
          '${last10.substring(0, 5)} '
          '${last10.substring(5)}';
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
    final ThemeData theme =
        Theme.of(context);

    final Color primary =
        theme.colorScheme.primary;

    final Color background =
        theme.scaffoldBackgroundColor;

    final Color textColor =
        theme.colorScheme.onSurface;

    final Color secondaryText =
        theme.colorScheme.onSurface
            .withOpacity(0.65);

    final Color cardColor =
        theme.cardColor;

    final Color borderColor =
        theme.dividerColor;

    return Scaffold(
      backgroundColor:
          background,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor:
            background,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor:
            textColor,
        automaticallyImplyLeading:
            true,
        toolbarHeight: 55,
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context)
                .unfocus();
          },
          child: SingleChildScrollView(
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
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  height: 12,
                ),

                // ==================================================
                // TOP ICON
                // ==================================================

                Center(
                  child: Container(
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
                          color: primary
                              .withOpacity(
                            0.22,
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
                    child: Icon(
                      Icons
                          .verified_user_rounded,
                      color: theme
                          .colorScheme
                          .onPrimary,
                      size: 38,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 26,
                ),

                // ==================================================
                // TITLE
                // ==================================================

                Center(
                  child: Text(
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
                ),

                const SizedBox(
                  height: 9,
                ),

                // ==================================================
                // SUBTITLE
                // ==================================================

                Center(
                  child: Text(
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
                ),

                const SizedBox(
                  height: 5,
                ),

                // ==================================================
                // PHONE
                // ==================================================

                Center(
                  child: Text(
                    _displayPhoneNumber(),
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight:
                          FontWeight.w800,
                    ),
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
                    color: cardColor,
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                    border:
                        Border.all(
                      color: borderColor,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withOpacity(
                          0.045,
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
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'One-Time Password',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      // ==================================================
                      // OTP FIELD
                      // ==================================================

                      TextField(
                        controller:
                            _otpController,
                        focusNode:
                            _otpFocusNode,
                        autofocus: true,
                        enabled:
                            !_isVerifying,
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
                        onChanged: (value) {
                          if (value.length ==
                                  6 &&
                              !_isVerifying) {
                            FocusScope.of(
                              context,
                            ).unfocus();
                          }
                        },
                        onSubmitted: (_) {
                          if (!_isVerifying) {
                            _verifyOtp();
                          }
                        },
                        style: TextStyle(
                          color: textColor,
                          fontSize: 25,
                          fontWeight:
                              FontWeight.w800,
                          letterSpacing: 10,
                        ),
                        decoration:
                            InputDecoration(
                          hintText:
                              '------',
                          hintStyle:
                              TextStyle(
                            color:
                                secondaryText
                                    .withOpacity(
                              0.35,
                            ),
                            fontSize: 24,
                            letterSpacing: 9,
                          ),
                          counterText: '',
                          filled: true,
                          fillColor:
                              theme
                                  .inputDecorationTheme
                                  .fillColor ??
                              cardColor,
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
                                BorderSide(
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
                                BorderSide(
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
                                BorderSide(
                              color: primary,
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
                                BorderSide(
                              color:
                                  borderColor
                                      .withOpacity(
                                0.65,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      // ==================================================
                      // VERIFY BUTTON
                      // ==================================================

                      SizedBox(
                        width:
                            double.infinity,
                        height: 54,
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
                                theme
                                    .colorScheme
                                    .onPrimary,
                            disabledBackgroundColor:
                                primary
                                    .withOpacity(
                              0.55,
                            ),
                            disabledForegroundColor:
                                theme
                                    .colorScheme
                                    .onPrimary
                                    .withOpacity(
                              0.9,
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
                                  ? SizedBox(
                                      height: 23,
                                      width: 23,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth:
                                            2.5,
                                        color:
                                            theme
                                                .colorScheme
                                                .onPrimary,
                                      ),
                                    )
                                  : Text(
                                      'Verify & Continue',
                                      style:
                                          TextStyle(
                                        color: theme
                                            .colorScheme
                                            .onPrimary,
                                        fontSize:
                                            16,
                                        fontWeight:
                                            FontWeight.w800,
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
                // SECURITY INFO
                // ==================================================

                Center(
                  child: Row(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      Icon(
                        Icons
                            .lock_outline_rounded,
                        size: 15,
                        color:
                            secondaryText,
                      ),
                      const SizedBox(
                        width: 6,
                      ),
                      Text(
                        'Secure phone verification',
                        style: TextStyle(
                          color:
                              secondaryText,
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                Center(
                  child: Text(
                    'Your Firebase UID is kept in the backend.',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      color:
                          secondaryText,
                      fontSize: 11,
                    ),
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
