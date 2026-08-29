import 'package:flutter/material.dart';
import 'package:sendotp_flutter_sdk/sendotp_flutter_sdk.dart';

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

  // ============================================================
  // MSG91 OTP CONFIGURATION
  // ============================================================

  static const String _widgetId =
      '3668426c306d353733343031';

  // IMPORTANT:
  // Use the CURRENT AuthToken generated for THIS OTP Widget.
  //
  // MSG91:
  // OTP -> Widget -> Mobile Integration
  //
  // Security:
  // If this token has been exposed publicly, regenerate it
  // in MSG91 and replace the value below.
  static const String _authToken =
      '565278AGmr6TyWn6a91bf8aP1';

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    OTPWidget.initializeWidget(
      _widgetId,
      _authToken,
    );

    debugPrint(
      'MSG91 OTP widget initialized.',
    );
  }

  // ============================================================
  // SEND OTP
  // ============================================================

  Future<void> _sendOtp() async {
    if (_isSendingOtp) {
      return;
    }

    // ----------------------------------------------------------
    // GET USER INPUT
    // ----------------------------------------------------------

    final String phone =
        _phoneController.text.trim();

    // ----------------------------------------------------------
    // VALIDATE 10-DIGIT INDIAN MOBILE NUMBER
    // ----------------------------------------------------------

    if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(phone)) {
      _showMessage(
        'Please enter a valid 10-digit mobile number.',
      );
      return;
    }

    // ----------------------------------------------------------
    // LOADING
    // ----------------------------------------------------------

    setState(() {
      _isSendingOtp = true;
    });

    // ----------------------------------------------------------
    // INDIA COUNTRY CODE
    // ----------------------------------------------------------
    //
    // UI:
    // +91 | 9625813987
    //
    // User enters only:
    // 9625813987
    //
    // MSG91 receives:
    // 919625813987
    //
    // No "+" is added to the identifier.
    // ----------------------------------------------------------

    final String identifier = '91$phone';

    try {
      final Map<String, dynamic> payload =
          <String, dynamic>{
        'identifier': identifier,
      };

      debugPrint(
        'MSG91 sending OTP to: $identifier',
      );

      final Map<String, dynamic>? response =
          await OTPWidget.sendOTP(payload);

      debugPrint(
        '================================================',
      );
      debugPrint(
        'MSG91 SEND OTP RESPONSE: $response',
      );
      debugPrint(
        '================================================',
      );

      // --------------------------------------------------------
      // NULL RESPONSE
      // --------------------------------------------------------

      if (response == null) {
        _finishLoading();

        _showMessage(
          'MSG91 did not return a response. Please try again.',
        );

        return;
      }

      // --------------------------------------------------------
      // RESPONSE TYPE
      // --------------------------------------------------------

      final String type =
          response['type']
                  ?.toString()
                  .trim()
                  .toLowerCase() ??
              '';

      // --------------------------------------------------------
      // SUCCESS
      // --------------------------------------------------------

      if (type == 'success') {
        final String? reqId =
            _extractRequestId(response);

        debugPrint(
          'MSG91 OTP SUCCESS.',
        );

        debugPrint(
          'MSG91 REQUEST ID: $reqId',
        );

        // ------------------------------------------------------
        // ALREADY VERIFIED / ACCESS TOKEN
        // ------------------------------------------------------

        if (response.containsKey('access-token')) {
          _finishLoading();

          _showMessage(
            'Mobile number is already verified.',
          );

          return;
        }

        // ------------------------------------------------------
        // REQUEST ID MISSING
        // ------------------------------------------------------

        if (reqId == null || reqId.isEmpty) {
          _finishLoading();

          _showMessage(
            'OTP was sent, but request ID was not received.',
          );

          return;
        }

        // ------------------------------------------------------
        // OTP SENT SUCCESSFULLY
        // ------------------------------------------------------

        _finishLoading();

        if (!mounted) {
          return;
        }

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) {
              return OtpVerificationScreen(
                phoneNumber: phone,
                reqId: reqId,
              );
            },
          ),
        );

        return;
      }

      // --------------------------------------------------------
      // ERROR RESPONSE
      // --------------------------------------------------------

      debugPrint(
        'MSG91 OTP FAILED.',
      );

      debugPrint(
        'MSG91 ERROR RESPONSE: $response',
      );

      _finishLoading();

      _showMessage(
        _extractErrorMessage(response),
      );
    } catch (e, stackTrace) {
      debugPrint(
        '================================================',
      );

      debugPrint(
        'MSG91 SEND OTP EXCEPTION: $e',
      );

      debugPrint(
        'MSG91 STACK TRACE: $stackTrace',
      );

      debugPrint(
        '================================================',
      );

      _finishLoading();

      _showMessage(
        'Failed to send OTP. Please try again.',
      );
    }
  }

  // ============================================================
  // EXTRACT REQUEST ID
  // ============================================================

  String? _extractRequestId(
    Map<String, dynamic> response,
  ) {
    final List<dynamic> possibleValues =
        <dynamic>[
      response['reqId'],
      response['req_id'],
      response['requestId'],
      response['request_id'],
      response['message'],
    ];

    for (final dynamic value
        in possibleValues) {
      if (value == null) {
        continue;
      }

      final String text =
          value.toString().trim();

      if (text.isNotEmpty) {
        return text;
      }
    }

    return null;
  }

  // ============================================================
  // EXTRACT ERROR MESSAGE
  // ============================================================

  String _extractErrorMessage(
    Map<String, dynamic> response,
  ) {
    final List<dynamic> possibleMessages =
        <dynamic>[
      response['message'],
      response['error'],
      response['description'],
      response['error_message'],
      response['errorMessage'],
    ];

    for (final dynamic value
        in possibleMessages) {
      if (value == null) {
        continue;
      }

      final String text =
          value.toString().trim();

      if (text.isNotEmpty) {
        return 'OTP could not be sent: $text';
      }
    }

    return 'OTP could not be sent. Please try again.';
  }

  // ============================================================
  // STOP LOADING
  // ============================================================

  void _finishLoading() {
    if (!mounted) {
      return;
    }

    setState(() {
      _isSendingOtp = false;
    });
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
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
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
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics:
              const BouncingScrollPhysics(),
          padding:
              const EdgeInsets.fromLTRB(
            20,
            30,
            20,
            25,
          ),
          child: Column(
            children: [
              // ==================================================
              // LOGO
              // ==================================================

              Container(
                height: 96,
                width: 96,
                decoration:
                    BoxDecoration(
                  color:
                      AppColors.primary,
                  shape:
                      BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color:
                          AppColors.primary
                              .withValues(
                        alpha: 0.22,
                      ),
                      blurRadius: 22,
                      offset:
                          const Offset(0, 8),
                    ),
                  ],
                ),
                child:
                    const Icon(
                  Icons.pets,
                  size: 52,
                  color:
                      Colors.white,
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              // ==================================================
              // APP NAME
              // ==================================================

              const Text(
                'Dojo Walk',
                style:
                    TextStyle(
                  color:
                      textColor,
                  fontSize: 31,
                  fontWeight:
                      FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(
                height: 5,
              ),

              const Text(
                'Dog walking made simple',
                style:
                    TextStyle(
                  color:
                      secondaryText,
                  fontSize: 15,
                  fontWeight:
                      FontWeight.w500,
                ),
              ),

              const SizedBox(
                height: 42,
              ),

              // ==================================================
              // LOGIN CARD
              // ==================================================

              Container(
                width:
                    double.infinity,
                padding:
                    const EdgeInsets.fromLTRB(
                  20,
                  25,
                  20,
                  24,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      cardColor,
                  borderRadius:
                      BorderRadius.circular(
                    24,
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
                        alpha: 0.06,
                      ),
                      blurRadius: 20,
                      offset:
                          const Offset(0, 8),
                    ),
                  ],
                ),
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mobile Number',
                      style:
                          TextStyle(
                        color:
                            textColor,
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    // ==========================================
                    // PHONE INPUT
                    // ==========================================

                    Container(
                      height: 60,
                      decoration:
                          BoxDecoration(
                        color:
                            inputBackground,
                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),
                        border:
                            Border.all(
                          color:
                              borderColor,
                        ),
                      ),
                      child:
                          Row(
                        children: [
                          // ====================================
                          // PHONE ICON
                          // ====================================

                          Container(
                            width: 50,
                            height: 46,
                            margin:
                                const EdgeInsets.only(
                              left: 6,
                            ),
                            decoration:
                                BoxDecoration(
                              color:
                                  AppColors.primary
                                      .withValues(
                                alpha:
                                    0.10,
                              ),
                              borderRadius:
                                  BorderRadius.circular(
                                13,
                              ),
                            ),
                            child:
                                const Icon(
                              Icons.phone,
                              color:
                                  AppColors.primary,
                              size: 23,
                            ),
                          ),

                          const SizedBox(
                            width: 12,
                          ),

                          // ====================================
                          // HARD-CODED INDIA CODE
                          // ====================================

                          const Text(
                            '+91',
                            style:
                                TextStyle(
                              color:
                                  textColor,
                              fontSize:
                                  16,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),

                          const SizedBox(
                            width: 10,
                          ),

                          // ====================================
                          // DIVIDER
                          // ====================================

                          Container(
                            height: 30,
                            width: 1,
                            color:
                                borderColor,
                          ),

                          const SizedBox(
                            width: 10,
                          ),

                          // ====================================
                          // NUMBER INPUT
                          // ====================================

                          Expanded(
                            child:
                                TextField(
                              controller:
                                  _phoneController,
                              keyboardType:
                                  TextInputType.number,
                              textInputAction:
                                  TextInputAction.done,
                              maxLength:
                                  10,
                              enabled:
                                  !_isSendingOtp,
                              style:
                                  const TextStyle(
                                color:
                                    textColor,
                                fontSize:
                                    16,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                              decoration:
                                  const InputDecoration(
                                hintText:
                                    'Enter mobile number',
                                hintStyle:
                                    TextStyle(
                                  color:
                                      Color(
                                    0xFF9AA6B5,
                                  ),
                                  fontSize:
                                      14,
                                  fontWeight:
                                      FontWeight.w500,
                                ),
                                border:
                                    InputBorder.none,
                                counterText:
                                    '',
                                contentPadding:
                                    EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    // ==========================================
                    // GET OTP BUTTON
                    // ==========================================

                    SizedBox(
                      width:
                          double.infinity,
                      height: 58,
                      child:
                          ElevatedButton(
                        onPressed:
                            _isSendingOtp
                                ? null
                                : _sendOtp,
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              AppColors.primary,
                          disabledBackgroundColor:
                              AppColors.primary
                                  .withValues(
                            alpha: 0.65,
                          ),
                          foregroundColor:
                              Colors.white,
                          elevation: 3,
                          shadowColor:
                              AppColors.primary
                                  .withValues(
                            alpha: 0.30,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              16,
                            ),
                          ),
                        ),
                        child:
                            _isSendingOtp
                                ? const SizedBox(
                                    height: 23,
                                    width: 23,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth:
                                          2.5,
                                      color:
                                          Colors.white,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment
                                            .center,
                                    children: [
                                      Icon(
                                        Icons
                                            .sms_outlined,
                                        size: 23,
                                      ),
                                      SizedBox(
                                        width: 10,
                                      ),
                                      Text(
                                        'Get OTP',
                                        style:
                                            TextStyle(
                                          fontSize:
                                              17,
                                          fontWeight:
                                              FontWeight
                                                  .w900,
                                        ),
                                      ),
                                    ],
                                  ),
                      ),
                    ),

                    const SizedBox(
                      height: 22,
                    ),

                    // ==========================================
                    // OTP INFO
                    // ==========================================

                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 42,
                          width: 42,
                          decoration:
                              const BoxDecoration(
                            color:
                                Color(
                              0xFFF1F4F7,
                            ),
                            shape:
                                BoxShape.circle,
                          ),
                          child:
                              const Icon(
                            Icons
                                .verified_user_outlined,
                            color:
                                secondaryText,
                            size: 21,
                          ),
                        ),

                        const SizedBox(
                          width: 12,
                        ),

                        const Expanded(
                          child:
                              Text(
                            'We will send a one-time password '
                            '(OTP) to verify your mobile number.',
                            style:
                                TextStyle(
                              color:
                                  secondaryText,
                              fontSize:
                                  12,
                              height:
                                  1.55,
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

              const SizedBox(
                height: 40,
              ),

              // ==================================================
              // FOOTER DIVIDER
              // ==================================================

              Row(
                children: [
                  Expanded(
                    child:
                        Container(
                      height: 1,
                      color:
                          borderColor,
                    ),
                  ),

                  Container(
                    margin:
                        const EdgeInsets.symmetric(
                      horizontal: 12,
                    ),
                    height: 7,
                    width: 7,
                    decoration:
                        const BoxDecoration(
                      color:
                          AppColors.primary,
                      shape:
                          BoxShape.circle,
                    ),
                  ),

                  Expanded(
                    child:
                        Container(
                      height: 1,
                      color:
                          borderColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 18,
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
                      15,
                  fontWeight:
                      FontWeight.w500,
                ),
              ),

              const SizedBox(
                height: 5,
              ),

              const Text(
                'Secure Mobile login',
                textAlign:
                    TextAlign.center,
                style:
                    TextStyle(
                  color:
                      secondaryText,
                  fontSize:
                      13,
                  fontWeight:
                      FontWeight.w400,
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
