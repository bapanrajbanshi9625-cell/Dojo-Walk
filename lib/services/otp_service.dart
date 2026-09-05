import 'package:sendotp_flutter_sdk/sendotp_flutter_sdk.dart';

/// ============================================================
/// OTP SERVICE
/// ============================================================
///
/// Responsibility:
/// - Verify OTP with MSG91
/// - Extract MSG91 access token
/// - Resend OTP
///
/// This service does NOT:
/// - Handle Firebase Auth
/// - Create Owner ID
/// - Read Owner profile
/// - Navigate screens
///
/// Flow:
///
/// OtpVerificationScreen
///        ↓
/// OtpService
///        ↓
/// MSG91
///        ↓
/// Verification result + access token
///
/// ============================================================

class OtpService {
  OtpService._();

  static final OtpService instance = OtpService._();

  // ============================================================
  // VERIFY OTP
  // ============================================================

  Future<String> verifyOtp({
    required String reqId,
    required String otp,
  }) async {
    final String cleanReqId = reqId.trim();
    final String cleanOtp = otp.trim();

    // ----------------------------------------------------------
    // VALIDATE REQUEST ID
    // ----------------------------------------------------------

    if (cleanReqId.isEmpty) {
      throw Exception(
        'OTP session is invalid. Please request a new OTP.',
      );
    }

    // ----------------------------------------------------------
    // VALIDATE OTP
    // ----------------------------------------------------------

    if (!RegExp(r'^[0-9]{6}$').hasMatch(cleanOtp)) {
      throw Exception(
        'Please enter the complete 6-digit OTP.',
      );
    }

    // ----------------------------------------------------------
    // MSG91 VERIFY REQUEST
    // ----------------------------------------------------------

    final Map<String, dynamic> request = <String, dynamic>{
      'reqId': cleanReqId,
      'otp': cleanOtp,
    };

    try {
      final dynamic response = await OTPWidget.verifyOTP(request);

      // --------------------------------------------------------
      // SAFE DEBUG
      // --------------------------------------------------------
      //
      // Never print the complete response because it may contain
      // a sensitive access token.
      //

      print(
        'MSG91 VERIFY RESPONSE TYPE: '
        '${response.runtimeType}',
      );

      // --------------------------------------------------------
      // RESPONSE MUST BE MAP
      // --------------------------------------------------------

      if (response is! Map) {
        throw Exception(
          'Invalid OTP verification response.',
        );
      }

      final Map<String, dynamic> result =
          Map<String, dynamic>.from(response);

      // IMPORTANT:
      // Only keys are printed. Token/OTP values are never printed.
      print(
        'MSG91 VERIFY RESPONSE KEYS: '
        '${result.keys.toList()}',
      );

      // --------------------------------------------------------
      // READ STATUS
      // --------------------------------------------------------

      final dynamic success = result['success'];
      final dynamic verified = result['verified'];
      final dynamic type = result['type'];
      final dynamic status = result['status'];

      final String typeText =
          type?.toString().trim().toLowerCase() ?? '';

      final String statusText =
          status?.toString().trim().toLowerCase() ?? '';

      // --------------------------------------------------------
      // DETERMINE OTP SUCCESS
      // --------------------------------------------------------

      final bool isVerified =
          success == true ||
          verified == true ||
          typeText == 'success' ||
          typeText == 'verified' ||
          statusText == 'success' ||
          statusText == 'verified';

      if (!isVerified) {
        final String errorMessage =
            _extractErrorMessage(result);

        if (errorMessage.isNotEmpty) {
          throw Exception(
            'OTP verification failed: $errorMessage',
          );
        }

        throw Exception(
          'Invalid OTP. Please check the OTP and try again.',
        );
      }

      print('MSG91 OTP VERIFIED SUCCESSFULLY');

      // --------------------------------------------------------
      // EXTRACT ACCESS TOKEN
      // --------------------------------------------------------

      final String? accessToken =
          _extractAccessToken(result);

      if (accessToken == null || accessToken.isEmpty) {
        print(
          'MSG91 OTP VERIFIED BUT ACCESS TOKEN '
          'WAS NOT RETURNED.',
        );

        throw Exception(
          'OTP verified successfully, but secure access token was not received. Please try again.',
        );
      }

      // Never print the actual token.
      print('MSG91 ACCESS TOKEN RECEIVED');

      return accessToken;
    } catch (e) {
      print('MSG91 VERIFY OTP ERROR: $e');

      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Could not verify OTP. Please try again.',
      );
    }
  }

  // ============================================================
  // EXTRACT ACCESS TOKEN
  // ============================================================

  String? _extractAccessToken(
    Map<String, dynamic> result,
  ) {
    // ----------------------------------------------------------
    // ROOT LEVEL
    // ----------------------------------------------------------

    final String? rootToken = _findTokenInMap(result);

    if (rootToken != null) {
      return rootToken;
    }

    // ----------------------------------------------------------
    // MESSAGE
    // ----------------------------------------------------------
    //
    // MSG91 may return the verification token in a field that
    // differs from the normal accessToken naming.
    //
    // We only accept the value if it looks like a JWT.
    //

    final dynamic message = result['message'];

    if (message is String) {
      final String messageToken = message.trim();

      if (_looksLikeJwt(messageToken)) {
        return messageToken;
      }
    }

    // ----------------------------------------------------------
    // RECURSIVE NESTED SEARCH
    // ----------------------------------------------------------

    final String? nestedToken =
        _findTokenRecursively(result);

    if (nestedToken != null) {
      return nestedToken;
    }

    return null;
  }

  // ============================================================
  // FIND TOKEN IN MAP
  // ============================================================

  String? _findTokenInMap(
    Map<dynamic, dynamic> map,
  ) {
    final List<String> tokenKeys = <String>[
      'accessToken',
      'access_token',
      'access-token',
      'token',
      'jwt',
    ];

    for (final String key in tokenKeys) {
      final dynamic value = map[key];

      if (value == null) {
        continue;
      }

      if (value is String) {
        final String token = value.trim();

        if (token.isNotEmpty) {
          return token;
        }
      }
    }

    return null;
  }

  // ============================================================
  // RECURSIVE TOKEN SEARCH
  // ============================================================

  String? _findTokenRecursively(
    dynamic value, {
    int depth = 0,
  }) {
    // Prevent unexpectedly deep recursion.
    if (depth > 5) {
      return null;
    }

    if (value is Map) {
      final String? directToken =
          _findTokenInMap(value);

      if (directToken != null) {
        return directToken;
      }

      for (final dynamic nestedValue in value.values) {
        final String? token =
            _findTokenRecursively(
          nestedValue,
          depth: depth + 1,
        );

        if (token != null) {
          return token;
        }
      }
    }

    if (value is List) {
      for (final dynamic item in value) {
        final String? token =
            _findTokenRecursively(
          item,
          depth: depth + 1,
        );

        if (token != null) {
          return token;
        }
      }
    }

    return null;
  }

  // ============================================================
  // JWT CHECK
  // ============================================================

  bool _looksLikeJwt(String value) {
    final String token = value.trim();

    if (token.isEmpty) {
      return false;
    }

    final List<String> parts = token.split('.');

    return parts.length == 3 &&
        parts.every(
          (String part) => part.trim().isNotEmpty,
        );
  }

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  String _extractErrorMessage(
    Map<String, dynamic> result,
  ) {
    final List<dynamic> possibleMessages = <dynamic>[
      result['message'],
      result['error'],
      result['description'],
      result['msg'],
    ];

    for (final dynamic value in possibleMessages) {
      if (value == null) {
        continue;
      }

      if (value is Map) {
        final dynamic nested =
            value['message'] ??
            value['error'] ??
            value['description'];

        if (nested != null) {
          final String nestedText =
              nested.toString().trim();

          if (nestedText.isNotEmpty) {
            return nestedText;
          }
        }

        continue;
      }

      final String text = value.toString().trim();

      if (text.isNotEmpty) {
        return text;
      }
    }

    return '';
  }

  // ============================================================
  // RESEND OTP
  // ============================================================

  Future<String?> resendOtp({
    required String reqId,
  }) async {
    final String cleanReqId = reqId.trim();

    // ----------------------------------------------------------
    // VALIDATE REQUEST ID
    // ----------------------------------------------------------

    if (cleanReqId.isEmpty) {
      throw Exception(
        'OTP session is invalid. Please request a new OTP.',
      );
    }

    try {
      final Map<String, dynamic> request =
          <String, dynamic>{
        'reqId': cleanReqId,
      };

      final dynamic response =
          await OTPWidget.retryOTP(request);

      print(
        'MSG91 RETRY RESPONSE TYPE: '
        '${response.runtimeType}',
      );

      // --------------------------------------------------------
      // RESPONSE
      // --------------------------------------------------------

      if (response is! Map) {
        throw Exception(
          'OTP resend failed. Please try again.',
        );
      }

      final Map<String, dynamic> result =
          Map<String, dynamic>.from(response);

      // Safe debugging: keys only.
      print(
        'MSG91 RETRY RESPONSE KEYS: '
        '${result.keys.toList()}',
      );

      // --------------------------------------------------------
      // CHECK RETRY STATUS
      // --------------------------------------------------------

      final dynamic type = result['type'];
      final dynamic success = result['success'];
      final dynamic status = result['status'];

      final String typeText =
          type?.toString().trim().toLowerCase() ?? '';

      final String statusText =
          status?.toString().trim().toLowerCase() ?? '';

      final bool retrySuccess =
          success == true ||
          typeText == 'success' ||
          statusText == 'success';

      if (!retrySuccess) {
        final String errorMessage =
            _extractErrorMessage(result);

        if (errorMessage.isNotEmpty) {
          throw Exception(
            'Could not resend OTP: $errorMessage',
          );
        }

        throw Exception(
          'OTP resend failed. Please try again.',
        );
      }

      // --------------------------------------------------------
      // NEW REQUEST ID
      // --------------------------------------------------------

      final dynamic newReqIdValue =
          result['reqId'] ??
          result['req_id'] ??
          result['requestId'] ??
          result['request_id'] ??
          result['requestID'];

      if (newReqIdValue != null) {
        final String newReqId =
            newReqIdValue.toString().trim();

        if (newReqId.isNotEmpty) {
          print(
            'MSG91 NEW REQUEST ID RECEIVED',
          );

          return newReqId;
        }
      }

      print(
        'MSG91 OTP RESENT SUCCESSFULLY',
      );

      return null;
    } catch (e) {
      print(
        'MSG91 RETRY OTP ERROR: $e',
      );

      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Could not resend OTP. Please try again.',
      );
    }
  }
}
