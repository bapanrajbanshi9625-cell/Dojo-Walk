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

  static final OtpService instance =
      OtpService._();

  // ============================================================
  // VERIFY OTP
  // ============================================================

  /// Verifies OTP with MSG91.
  ///
  /// Returns:
  /// - Access token when MSG91 provides one.
  ///
  /// Throws:
  /// - Exception when OTP verification fails.
  /// - Exception when OTP is verified but no access token
  ///   is returned by the SDK response.
  Future<String> verifyOtp({
    required String reqId,
    required String otp,
  }) async {
    final String cleanReqId =
        reqId.trim();

    final String cleanOtp =
        otp.trim();

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

    if (!RegExp(
      r'^[0-9]{6}$',
    ).hasMatch(cleanOtp)) {
      throw Exception(
        'Please enter the complete 6-digit OTP.',
      );
    }

    // ----------------------------------------------------------
    // MSG91 VERIFY
    // ----------------------------------------------------------

    final Map<String, dynamic> request =
        <String, dynamic>{
      'reqId': cleanReqId,
      'otp': cleanOtp,
    };

    try {
      final dynamic response =
          await OTPWidget.verifyOTP(
        request,
      );

      // --------------------------------------------------------
      // DEBUG
      // --------------------------------------------------------
      //
      // Do NOT print complete response.
      // It may contain a sensitive access token.
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
          Map<String, dynamic>.from(
        response,
      );

      // --------------------------------------------------------
      // READ STATUS
      // --------------------------------------------------------

      final dynamic success =
          result['success'];

      final dynamic verified =
          result['verified'];

      final dynamic type =
          result['type'];

      final dynamic status =
          result['status'];

      final String typeText =
          type
                  ?.toString()
                  .trim()
                  .toLowerCase() ??
              '';

      final String statusText =
          status
                  ?.toString()
                  .trim()
                  .toLowerCase() ??
              '';

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
            _extractErrorMessage(
          result,
        );

        if (errorMessage.isNotEmpty) {
          throw Exception(
            'OTP verification failed: '
            '$errorMessage',
          );
        }

        throw Exception(
          'Invalid OTP. Please check the OTP and try again.',
        );
      }

      print(
        'MSG91 OTP VERIFIED SUCCESSFULLY',
      );

      // --------------------------------------------------------
      // EXTRACT ACCESS TOKEN
      // --------------------------------------------------------

      final String? accessToken =
          _extractAccessToken(
        result,
      );

      if (accessToken == null ||
          accessToken.isEmpty) {
        print(
          'MSG91 OTP VERIFIED BUT ACCESS TOKEN '
          'WAS NOT RETURNED.',
        );

        throw Exception(
          'OTP verified successfully, but secure access token was not received. Please try again.',
        );
      }

      print(
        'MSG91 ACCESS TOKEN RECEIVED',
      );

      // IMPORTANT:
      // Never print the actual token.

      return accessToken;
    } catch (e) {
      print(
        'MSG91 VERIFY OTP ERROR: $e',
      );

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

    final List<dynamic> possibleTokens =
        <dynamic>[
      result['accessToken'],
      result['access_token'],
      result['access-token'],
      result['token'],
      result['jwt'],
    ];

    for (final dynamic value
        in possibleTokens) {
      if (value == null) {
        continue;
      }

      final String token =
          value.toString().trim();

      if (token.isNotEmpty) {
        return token;
      }
    }

    // ----------------------------------------------------------
    // DATA LEVEL
    // ----------------------------------------------------------

    final dynamic data =
        result['data'];

    if (data is Map) {
      final List<dynamic> nestedTokens =
          <dynamic>[
        data['accessToken'],
        data['access_token'],
        data['access-token'],
        data['token'],
        data['jwt'],
      ];

      for (final dynamic value
          in nestedTokens) {
        if (value == null) {
          continue;
        }

        final String token =
            value.toString().trim();

        if (token.isNotEmpty) {
          return token;
        }
      }
    }

    return null;
  }

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  String _extractErrorMessage(
    Map<String, dynamic> result,
  ) {
    final List<dynamic> possibleMessages =
        <dynamic>[
      result['message'],
      result['error'],
      result['description'],
      result['msg'],
    ];

    for (final dynamic value
        in possibleMessages) {
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

      final String text =
          value.toString().trim();

      if (text.isNotEmpty) {
        return text;
      }
    }

    return '';
  }

  // ============================================================
  // RESEND OTP
  // ============================================================

  /// Resends OTP using the current MSG91 request ID.
  ///
  /// Returns:
  /// - New request ID when MSG91 returns one.
  /// - null when MSG91 successfully resends but does not
  ///   provide a new request ID.
  Future<String?> resendOtp({
    required String reqId,
  }) async {
    final String cleanReqId =
        reqId.trim();

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
          await OTPWidget.retryOTP(
        request,
      );

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
          Map<String, dynamic>.from(
        response,
      );

      // --------------------------------------------------------
      // CHECK RETRY STATUS
      // --------------------------------------------------------

      final dynamic type =
          result['type'];

      final dynamic success =
          result['success'];

      final dynamic status =
          result['status'];

      final String typeText =
          type
                  ?.toString()
                  .trim()
                  .toLowerCase() ??
              '';

      final String statusText =
          status
                  ?.toString()
                  .trim()
                  .toLowerCase() ??
              '';

      final bool retrySuccess =
          success == true ||
          typeText == 'success' ||
          statusText == 'success';

      if (!retrySuccess) {
        final String errorMessage =
            _extractErrorMessage(
          result,
        );

        if (errorMessage.isNotEmpty) {
          throw Exception(
            'Could not resend OTP: '
            '$errorMessage',
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
            newReqIdValue
                .toString()
                .trim();

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
