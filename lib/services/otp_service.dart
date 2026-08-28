import 'package:sendotp_flutter_sdk/sendotp_flutter_sdk.dart';

/// ============================================================
/// OTP SERVICE
/// ============================================================
///
/// जिम्मेदारी:
/// - MSG91 OTP verify करना
/// - MSG91 OTP resend करना
///
/// यह service:
/// - Firebase Auth को नहीं संभालती
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
///
/// ============================================================

class OtpService {
  OtpService._();

  static final OtpService instance =
      OtpService._();

  // ============================================================
  // VERIFY OTP
  // ============================================================

  Future<bool> verifyOtp({
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

    if (!RegExp(r'^[0-9]{6}$')
        .hasMatch(cleanOtp)) {
      throw Exception(
        'Please enter the complete 6-digit OTP.',
      );
    }

    // ----------------------------------------------------------
    // MSG91 VERIFY REQUEST
    // ----------------------------------------------------------

    final Map<String, dynamic> request =
        <String, dynamic>{
      'reqId': cleanReqId,
      'otp': cleanOtp,
    };

    try {
      final dynamic response =
          await OTPWidget.verifyOTP(request);

      // --------------------------------------------------------
      // DEBUG
      // --------------------------------------------------------

      print(
        '==============================================',
      );

      print(
        'MSG91 VERIFY OTP RESPONSE: $response',
      );

      print(
        'MSG91 VERIFY OTP RESPONSE TYPE: '
        '${response.runtimeType}',
      );

      print(
        '==============================================',
      );

      // --------------------------------------------------------
      // RESPONSE CHECK
      // --------------------------------------------------------

      if (response is Map) {
        final Map<String, dynamic> result =
            Map<String, dynamic>.from(
          response,
        );

        final dynamic success =
            result['success'];

        final dynamic verified =
            result['verified'];

        final dynamic type =
            result['type'];

        final dynamic status =
            result['status'];

        // ------------------------------------------------------
        // BOOLEAN SUCCESS
        // ------------------------------------------------------

        if (success == true ||
            verified == true) {
          print(
            'MSG91 OTP VERIFIED SUCCESSFULLY',
          );

          return true;
        }

        // ------------------------------------------------------
        // STRING STATUS
        // ------------------------------------------------------

        final String typeText =
            type?.toString().trim().toLowerCase() ??
                '';

        final String statusText =
            status?.toString().trim().toLowerCase() ??
                '';

        if (typeText == 'success' ||
            typeText == 'verified' ||
            statusText == 'success' ||
            statusText == 'verified') {
          print(
            'MSG91 OTP VERIFIED SUCCESSFULLY',
          );

          return true;
        }

        // ------------------------------------------------------
        // MSG91 ERROR MESSAGE
        // ------------------------------------------------------

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
      }

      // --------------------------------------------------------
      // UNKNOWN RESPONSE
      // --------------------------------------------------------

      throw Exception(
        'Invalid OTP. Please check the OTP and try again.',
      );
    } catch (e) {
      print(
        'MSG91 VERIFY OTP ERROR: $e',
      );

      // Already formatted error
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
      // --------------------------------------------------------
      // MSG91 RETRY
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
        'MSG91 RETRY OTP RESPONSE: $response',
      );

      print(
        'MSG91 RETRY OTP RESPONSE TYPE: '
        '${response.runtimeType}',
      );

      print(
        '==============================================',
      );

      // --------------------------------------------------------
      // EXTRACT NEW REQUEST ID
      // --------------------------------------------------------

      if (response is Map) {
        final Map<String, dynamic> result =
            Map<String, dynamic>.from(
          response,
        );

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
              'MSG91 NEW REQUEST ID: $newReqId',
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
