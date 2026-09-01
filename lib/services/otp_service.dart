import 'package:sendotp_flutter_sdk/sendotp_flutter_sdk.dart';

/// ============================================================
/// OTP SERVICE
/// ============================================================
///
/// जिम्मेदारी:
/// - MSG91 OTP verify करना
/// - MSG91 OTP verification token निकालना
/// - MSG91 OTP resend करना
///
/// यह service:
/// - Firebase Auth को सीधे handle नहीं करती
/// - Owner ID नहीं बनाती
/// - Owner profile नहीं पढ़ती
/// - Navigation नहीं करती
///
/// Flow:
///
/// OtpVerificationScreen
///        ↓
/// OtpService
///        ↓
/// MSG91
///        ↓
/// verification result / access token
///
/// ============================================================

class OtpService {
  OtpService._();

  static final OtpService instance = OtpService._();

  // ============================================================
  // VERIFY OTP
  // ============================================================

  /// Verifies the OTP with MSG91.
  ///
  /// Returns:
  /// - MSG91 access token when one is returned.
  /// - 'verified' when OTP is successfully verified but
  ///   no token is returned by the SDK response.
  ///
  /// Throws an Exception when verification fails.
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
      final dynamic response =
          await OTPWidget.verifyOTP(request);

      // --------------------------------------------------------
      // DEBUG
      // --------------------------------------------------------
      //
      // IMPORTANT:
      // Do NOT print the complete response because it may contain
      // a sensitive MSG91 access token.
      //

      print(
        '==============================================',
      );

      print(
        'MSG91 VERIFY OTP RESPONSE TYPE: '
        '${response.runtimeType}',
      );

      print(
        '==============================================',
      );

      // --------------------------------------------------------
      // RESPONSE MUST BE A MAP
      // --------------------------------------------------------

      if (response is! Map) {
        throw Exception(
          'Invalid OTP verification response.',
        );
      }

      final Map<String, dynamic> result =
          Map<String, dynamic>.from(response);

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
      // DETERMINE SUCCESS
      // --------------------------------------------------------

      final bool isVerified =
          success == true ||
          verified == true ||
          typeText == 'success' ||
          typeText == 'verified' ||
          statusText == 'success' ||
          statusText == 'verified';

      if (!isVerified) {
        final dynamic message =
            result['message'] ??
            result['error'] ??
            result['description'];

        final String errorMessage =
            message?.toString().trim() ?? '';

        if (errorMessage.isNotEmpty) {
          throw Exception(
            'OTP verification failed: $errorMessage',
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
      //
      // MSG91 responses/configurations can expose the token using
      // different naming conventions.
      //
      // We check common possibilities.
      //

      final dynamic tokenValue =
          result['accessToken'] ??
          result['access_token'] ??
          result['access-token'] ??
          result['token'] ??
          result['jwt'];

      if (tokenValue != null) {
        final String token =
            tokenValue.toString().trim();

        if (token.isNotEmpty) {
          print(
            'MSG91 ACCESS TOKEN RECEIVED',
          );

          // IMPORTANT:
          // Never print the actual token.

          return token;
        }
      }

      // --------------------------------------------------------
      // TOKEN NOT PRESENT
      // --------------------------------------------------------
      //
      // OTP itself was successfully verified.
      //
      // We return a controlled value instead of treating the
      // verification as failed.
      //

      print(
        'MSG91 OTP VERIFIED WITHOUT ACCESS TOKEN',
      );

      return 'verified';
    } catch (e) {
      print(
        'MSG91 VERIFY OTP ERROR: $e',
      );

      // --------------------------------------------------------
      // PRESERVE OUR OWN ERRORS
      // --------------------------------------------------------

      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Could not verify OTP. Please try again.',
      );
    }
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
      // --------------------------------------------------------
      // MSG91 RETRY REQUEST
      // --------------------------------------------------------

      final Map<String, dynamic> request =
          <String, dynamic>{
        'reqId': cleanReqId,
      };

      final dynamic response =
          await OTPWidget.retryOTP(request);

      // --------------------------------------------------------
      // DEBUG
      // --------------------------------------------------------

      print(
        '==============================================',
      );

      print(
        'MSG91 RETRY OTP RESPONSE TYPE: '
        '${response.runtimeType}',
      );

      print(
        '==============================================',
      );

      // --------------------------------------------------------
      // RESPONSE MAP
      // --------------------------------------------------------

      if (response is Map) {
        final Map<String, dynamic> result =
            Map<String, dynamic>.from(response);

        // ------------------------------------------------------
        // NEW REQUEST ID
        // ------------------------------------------------------

        final dynamic value =
            result['reqId'] ??
            result['req_id'] ??
            result['requestId'] ??
            result['request_id'];

        if (value != null) {
          final String newReqId =
              value.toString().trim();

          if (newReqId.isNotEmpty) {
            print(
              'MSG91 NEW REQUEST ID RECEIVED',
            );

            return newReqId;
          }
        }

        // ------------------------------------------------------
        // RETRY ERROR
        // ------------------------------------------------------

        final dynamic message =
            result['message'] ??
            result['error'] ??
            result['description'];

        final String errorMessage =
            message?.toString().trim() ?? '';

        if (errorMessage.isNotEmpty) {
          throw Exception(
            'Could not resend OTP: $errorMessage',
          );
        }
      }

      // --------------------------------------------------------
      // NO REQUEST ID
      // --------------------------------------------------------

      throw Exception(
        'OTP resend failed. Please try again.',
      );
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
