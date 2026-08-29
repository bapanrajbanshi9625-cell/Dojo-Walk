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
  // MSG91 CONFIGURATION
  // ============================================================

  static const String widgetId =
      '3668426c306d353733343031';

  // IMPORTANT:
  // Use the CURRENT AuthToken generated for THIS SAME MSG91 OTP Widget.
  //
  // Do NOT use an old token.
  // Do NOT paste a token belonging to another widget.
  static const String authToken =
      '565278TUyruRuC6a92a86dP1';

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    OTPWidget.initializeWidget(
      widgetId,
      authToken,
    );

    debugPrint(
      'MSG91 OTP Widget initialized.',
    );
  }

  // ============================================================
  // SEND OTP
  // ============================================================

  Future<void> handleSendOtp() async {
    if (_isSendingOtp) {
      return;
    }

    final String phoneNumber =
        _phoneController.text.trim();

    // ==========================================================
    // VALIDATE MOBILE NUMBER
    // ==========================================================

    if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(phoneNumber)) {
      _showMessage(
        'Please enter a valid 10-digit mobile number.',
      );
      return;
    }

    setState(() {
      _isSendingOtp = true;
    });

    // ==========================================================
    // MSG91 IDENTIFIER
    // ==========================================================
    //
    // User enters:
    // 9625813987
    //
    // MSG91 receives:
    // 919625813987
    //
    // No "+".
    // ==========================================================

    final Map<String, dynamic> data =
        <String, dynamic>{
      'identifier': '91$phoneNumber',
    };

    try {
      debugPrint(
        '================================================',
      );

      debugPrint(
        'MSG91 SEND OTP',
      );

      debugPrint(
        'MSG91 IDENTIFIER: ${data['identifier']}',
      );

      debugPrint(
        'MSG91 WIDGET ID: $widgetId',
      );

      debugPrint(
        '================================================',
      );

      // ========================================================
      // SEND OTP
      // ========================================================

      final Map<String, dynamic>? response =
          await OTPWidget.sendOTP(data);

      // ========================================================
      // DEBUG RESPONSE
      // ========================================================

      debugPrint(
        '================================================',
      );

      debugPrint(
        'MSG91 RESPONSE: $response',
      );

      debugPrint(
        'MSG91 RESPONSE TYPE: ${response?.runtimeType}',
      );

      if (response != null) {
        debugPrint(
          'MSG91 RESPONSE KEYS: ${response.keys.toList()}',
        );
      }

      debugPrint(
        '================================================',
      );

      if (!mounted) {
        return;
      }

      // ========================================================
      // NULL RESPONSE
      // ========================================================

      if (response == null) {
        _showMessage(
          'MSG91 did not return a response.',
        );
        return;
      }

      // ========================================================
      // RESPONSE TYPE
      // ========================================================

      final String type =
          response['type']
                  ?.toString()
                  .trim()
                  .toLowerCase() ??
              '';

      debugPrint(
        'MSG91 TYPE VALUE: $type',
      );

      // ========================================================
      // SUCCESS
      // ========================================================

      if (type == 'success') {
        final String? reqId =
            _getRequestId(response);

        debugPrint(
          'MSG91 OTP SUCCESS',
        );

        debugPrint(
          'MSG91 REQUEST ID: $reqId',
        );

        // ======================================================
        // REQUEST ID MISSING
        // ======================================================

        if (reqId == null || reqId.isEmpty) {
          _showMessage(
            'OTP sent, but request ID was not received.',
          );
          return;
        }

        // ======================================================
        // OPEN OTP VERIFICATION SCREEN
        // ======================================================

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) {
              return OtpVerificationScreen(
                phoneNumber: phoneNumber,
                reqId: reqId,
              );
            },
          ),
        );

        return;
      }

      // ========================================================
      // ERROR RESPONSE
      // ========================================================

      debugPrint(
        'MSG91 OTP FAILED',
      );

      debugPrint(
        'MSG91 ERROR RESPONSE: $response',
      );

      _showMessage(
        _getErrorMessage(response),
      );
    } catch (e, stackTrace) {
      // ========================================================
      // EXCEPTION
      // ========================================================

      debugPrint(
        '================================================',
      );

      debugPrint(
        'MSG91 OTP EXCEPTION: $e',
      );

      debugPrint(
        'MSG91 STACK TRACE: $stackTrace',
      );

      debugPrint(
        '================================================',
      );

      if (mounted) {
        _showMessage(
          'OTP could not be sent. Please try again.',
        );
      }
    } finally {
      // ========================================================
      // STOP LOADING
      // ========================================================

      if (mounted) {
        setState(() {
          _isSendingOtp = false;
        });
      }
    }
  }

  // ============================================================
  // GET REQUEST ID
  // ============================================================

  String? _getRequestId(
    Map<String, dynamic> response,
  ) {
    // ==========================================================
    // DIRECT REQUEST ID
    // ==========================================================

    final List<dynamic> directValues =
        <dynamic>[
      response['reqId'],
      response['req_id'],
      response['requestId'],
      response['request_id'],
      response['requestID'],
    ];

    for (final dynamic value in directValues) {
      final String? result =
          _cleanRequestId(value);

      if (result != null) {
        return result;
      }
    }

    // ==========================================================
    // NESTED DATA
    // ==========================================================

    final dynamic data =
        response['data'];

    if (data is Map) {
      final List<dynamic> nestedValues =
          <dynamic>[
        data['reqId'],
        data['req_id'],
        data['requestId'],
        data['request_id'],
        data['requestID'],
      ];

      for (final dynamic value in nestedValues) {
        final String? result =
            _cleanRequestId(value);

        if (result != null) {
          return result;
        }
      }
    }

    // ==========================================================
    // NESTED REQUEST
    // ==========================================================

    final dynamic request =
        response['request'];

    if (request is Map) {
      final List<dynamic> requestValues =
          <dynamic>[
        request['reqId'],
        request['req_id'],
        request['requestId'],
        request['request_id'],
        request['requestID'],
      ];

      for (final dynamic value in requestValues) {
        final String? result =
            _cleanRequestId(value);

        if (result != null) {
          return result;
        }
      }
    }

    return null;
  }

  // ============================================================
  // CLEAN REQUEST ID
  // ============================================================

  String? _cleanRequestId(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is Map) {
      final dynamic nested =
          value['reqId'] ??
          value['req_id'] ??
          value['requestId'] ??
          value['request_id'] ??
          value['requestID'];

      if (nested != null) {
        return _cleanRequestId(nested);
      }

      return null;
    }

    final String text =
        value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    return text;
  }

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  String _getErrorMessage(
    Map<String, dynamic> response,
  ) {
    final List<dynamic> values =
        <dynamic>[
      response['message'],
      response['error'],
      response['description'],
      response['error_message'],
      response['errorMessage'],
      response['msg'],
      response['details'],
    ];

    for (final dynamic value in values) {
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
  // SHOW MESSAGE
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
          behavior: SnackBarBehavior.floating,
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
                          AppColors.primary.withValues(
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
                  letterSpacing:
                      -0.5,
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
                          Colors.black.withValues(
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
                                alpha: 0.10,
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

                          Container(
                            height: 30,
                            width: 1,
                            color:
                                borderColor,
                          ),

                          const SizedBox(
                            width: 10,
                          ),

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
                                : handleSendOtp,
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
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.sms_outlined,
                                        size: 23,
                                      ),
                                      SizedBox(
                                        width: 10,
                                      ),
                                      Text(
                                        'Get OTP',
                                        style:
                                            TextStyle(
                                          fontSize: 17,
                                          fontWeight:
                                              FontWeight.w900,
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
                    // OTP INFORMATION
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
                                Color(0xFFF1F4F7),
                            shape:
                                BoxShape.circle,
                          ),
                          child:
                              const Icon(
                            Icons.verified_user_outlined,
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
              // FOOTER
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
