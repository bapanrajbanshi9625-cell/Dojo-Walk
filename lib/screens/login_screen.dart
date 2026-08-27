import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import 'otp_verification_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController =
      TextEditingController();

  bool _isSendingOtp = false;

  // =====================================================
  // SEND OTP
  // =====================================================

  Future<void> _sendOtp() async {
    final String phone = _phoneController.text.trim();

    if (phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a valid 10-digit mobile number',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSendingOtp = true;
    });

    final String fullPhoneNumber = '+91$phone';

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: fullPhoneNumber,

        // =================================================
        // AUTOMATIC VERIFICATION
        // =================================================

        verificationCompleted:
            (PhoneAuthCredential credential) async {
          // Android automatic verification.
          //
          // We intentionally do not navigate here.
          // The normal OTP/profile flow remains controlled.
        },

        // =================================================
        // VERIFICATION FAILED
        // =================================================

        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;

          String message;

          switch (e.code) {
            case 'invalid-phone-number':
              message = 'Invalid mobile number.';
              break;

            case 'too-many-requests':
              message =
                  'Too many attempts. Please try again later.';
              break;

            case 'quota-exceeded':
              message =
                  'SMS quota exceeded. Please try again later.';
              break;

            default:
              message = e.message ??
                  'Failed to send OTP. Please try again.';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              behavior: SnackBarBehavior.floating,
            ),
          );

          setState(() {
            _isSendingOtp = false;
          });
        },

        // =================================================
        // OTP SENT
        // =================================================

        codeSent: (
          String verificationId,
          int? resendToken,
        ) {
          if (!mounted) return;

          setState(() {
            _isSendingOtp = false;
          });

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpVerificationScreen(
                phoneNumber: phone,
                verificationId: verificationId,
              ),
            ),
          );
        },

        // =================================================
        // AUTO RETRIEVAL TIMEOUT
        // =================================================

        codeAutoRetrievalTimeout: (String verificationId) {
          // verificationId is already handled by codeSent.
        },
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSendingOtp = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Something went wrong. Please try again.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    const Color background = Color(0xFFF7F9FC);
    const Color textColor = Color(0xFF263746);
    const Color secondaryText = Color(0xFF64748B);
    const Color cardColor = Colors.white;
    const Color borderColor = Color(0xFFDDE2E8);
    const Color inputBackground = Color(0xFFFAFBFC);

    return Scaffold(
      backgroundColor: background,

      // ===================================================
      // BODY
      // ===================================================

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            20,
            30,
            20,
            25,
          ),
          child: Column(
            children: [
              // ===========================================
              // DOJO WALK LOGO
              // ===========================================

              Container(
                height: 96,
                width: 96,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.22),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.pets,
                  size: 52,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 18),

              // ===========================================
              // APP NAME
              // ===========================================

              const Text(
                'Dojo Walk',
                style: TextStyle(
                  color: textColor,
                  fontSize: 31,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                'Dog walking made simple',
                style: TextStyle(
                  color: secondaryText,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 42),

              // ===========================================
              // LOGIN CARD
              // ===========================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  20,
                  25,
                  20,
                  24,
                ),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: borderColor,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // =====================================
                    // MOBILE NUMBER
                    // =====================================

                    const Text(
                      'Mobile Number',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // =====================================
                    // PHONE FIELD
                    // =====================================

                    Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: inputBackground,
                        borderRadius:
                            BorderRadius.circular(16),
                        border: Border.all(
                          color: borderColor,
                        ),
                      ),
                      child: Row(
                        children: [
                          // PHONE ICON
                          Container(
                            width: 50,
                            height: 46,
                            margin: const EdgeInsets.only(
                              left: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary
                                  .withOpacity(0.10),
                              borderRadius:
                                  BorderRadius.circular(13),
                            ),
                            child: const Icon(
                              Icons.phone,
                              color: AppColors.primary,
                              size: 23,
                            ),
                          ),

                          const SizedBox(width: 12),

                          // COUNTRY CODE
                          const Text(
                            '+91',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),

                          const SizedBox(width: 12),

                          Container(
                            height: 30,
                            width: 1,
                            color: borderColor,
                          ),

                          const SizedBox(width: 10),

                          // PHONE INPUT
                          Expanded(
                            child: TextField(
                              controller:
                                  _phoneController,
                              keyboardType:
                                  TextInputType.phone,
                              maxLength: 10,
                              style: const TextStyle(
                                color: textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration:
                                  const InputDecoration(
                                hintText:
                                    'Enter mobile number',
                                hintStyle: TextStyle(
                                  color:
                                      Color(0xFF9AA6B5),
                                  fontSize: 14,
                                  fontWeight:
                                      FontWeight.w500,
                                ),
                                border: InputBorder.none,
                                counterText: '',
                                contentPadding:
                                    EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // =====================================
                    // GET OTP BUTTON
                    // =====================================

                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        onPressed: _isSendingOtp
                            ? null
                            : _sendOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              AppColors.primary,
                          disabledBackgroundColor:
                              AppColors.primary
                                  .withOpacity(0.65),
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shadowColor:
                              AppColors.primary
                                  .withOpacity(0.30),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(16),
                          ),
                        ),
                        child: _isSendingOtp
                            ? const SizedBox(
                                height: 23,
                                width: 23,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.sms_outlined,
                                    size: 23,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Get OTP',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight:
                                          FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // =====================================
                    // OTP INFORMATION
                    // =====================================

                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 42,
                          width: 42,
                          decoration:
                              const BoxDecoration(
                            color: Color(0xFFF1F4F7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons
                                .verified_user_outlined,
                            color: secondaryText,
                            size: 21,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'We will send a one-time password (OTP) '
                            'to verify your mobile number.',
                            style: TextStyle(
                              color: secondaryText,
                              fontSize: 12,
                              height: 1.55,
                              fontWeight:
                                  FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // ===========================================
              // FOOTER DIVIDER
              // ===========================================

              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      color: borderColor,
                    ),
                  ),
                  Container(
                    margin:
                        const EdgeInsets.symmetric(
                      horizontal: 12,
                    ),
                    height: 7,
                    width: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: borderColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ===========================================
              // FOOTER
              // ===========================================

              const Text(
                'Dojo Platform',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: secondaryText,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                'Secure Mobile login',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: secondaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
