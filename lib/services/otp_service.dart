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

  static final OtpService instance = OtpService._();

  // ============================================================
  // VERIFY OTP
  // ============================================================

  Future<bool> verifyOtp({
    required String reqId,
    required String otp,
  }) async {
    final String cleanReqId = reqId.trim();
    final String cleanOtp = otp.trim();

    if (cleanReqId.isEmpty) {
      throw Exception(
        'OTP session is invalid. Please request a new OTP.',
      );
    }

    if (cleanOtp.length != 6) {
      throw Exception(
        'Please enter the complete 6-digit OTP.',
      );
    }

    // ----------------------------------------------------------
    // MSG91 VERIFY
    // ----------------------------------------------------------

    final Map<String, dynamic> request = {
      'reqId': cleanReqId,
      'otp': cleanOtp,
    };

    final dynamic response =
        await OTPWidget.verifyOTP(request);

    // ----------------------------------------------------------
    // DEBUG
    // ----------------------------------------------------------

    print(
      'MSG91 VERIFY OTP RESPONSE: $response',
    );

    // ----------------------------------------------------------
    // CHECK RESPONSE
    // ----------------------------------------------------------

    bool verified = false;

    if (response is Map) {
      final dynamic type =
          response['type'] ??
          response['status'] ??
          response['message'];

      final String result =
          type?.toString().toLowerCase() ?? '';

      if (result.contains('success') ||
          result == 'verified') {
        verified = true;
      }

      // Some MSG91 SDK responses use boolean values.
      if (response['success'] == true ||
          response['verified'] == true) {
        verified = true;
      }
    }

    // ----------------------------------------------------------
    // FALLBACK
    // ----------------------------------------------------------

    if (!verified && response != null) {
      final String responseText =
          response.toString().toLowerCase();

      if (responseText.contains('success') ||
          responseText.contains('verified')) {
        verified = true;
      }
    }

    if (!verified) {
      throw Exception(
        'Invalid OTP. Please check the OTP and try again.',
      );
    }

    print(
      'MSG91 OTP VERIFIED SUCCESSFULLY',
    );

    return true;
  }

  // ============================================================
  // RESEND OTP
  // ============================================================

  Future<String?> resendOtp({
    required String reqId,
  }) async {
    final String cleanReqId = reqId.trim();

    if (cleanReqId.isEmpty) {
      throw Exception(
        'OTP session is invalid. Please request a new OTP.',
      );
    }

    // ----------------------------------------------------------
    // MSG91 RETRY
    // ----------------------------------------------------------

    final dynamic response =
        await OTPWidget.retryOTP({
      'reqId': cleanReqId,
    });

    // ----------------------------------------------------------
    // DEBUG
    // ----------------------------------------------------------

    print(
      'MSG91 RETRY OTP RESPONSE: $response',
    );

    // ----------------------------------------------------------
    // GET NEW REQUEST ID
    // ----------------------------------------------------------

    String? newReqId;

    if (response is Map) {
      final dynamic value =
          response['reqId'] ??
          response['req_id'] ??
          response['requestId'];

      if (value != null) {
        final String valueString =
            value.toString().trim();

        if (valueString.isNotEmpty) {
          newReqId = valueString;
        }
      }
    }

    return newReqId;
  }
}
