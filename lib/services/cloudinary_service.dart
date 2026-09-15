import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class CloudinaryService {
  CloudinaryService._();

  static final CloudinaryService instance =
      CloudinaryService._();

  static const String _cloudName = 'kdkwevh4';
  static const String _uploadPreset = 'dojo_walk';

  // ============================================================
  // IMAGE
  // ============================================================

  Future<String> uploadImage({
    required File file,
  }) async {
    return _uploadFile(
      file: file,
      resourceType: 'image',
    );
  }

  // ============================================================
  // VIDEO
  // ============================================================

  Future<String> uploadVideo({
    required File file,
  }) async {
    return _uploadFile(
      file: file,
      resourceType: 'video',
    );
  }

  // ============================================================
  // VOICE / AUDIO
  // ============================================================

  Future<String> uploadVoice({
    required File file,
  }) async {
    // Cloudinary stores audio using the video resource type.
    return _uploadFile(
      file: file,
      resourceType: 'video',
    );
  }

  // ============================================================
  // COMMON UPLOAD
  // ============================================================

  Future<String> _uploadFile({
    required File file,
    required String resourceType,
  }) async {
    if (!await file.exists()) {
      throw StateError(
        'Upload file does not exist.',
      );
    }

    final Uri uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/'
      '$_cloudName/$resourceType/upload',
    );

    final http.MultipartRequest request =
        http.MultipartRequest(
      'POST',
      uri,
    );

    request.fields['upload_preset'] =
        _uploadPreset;

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
      ),
    );

    final http.StreamedResponse response =
        await request.send();

    final String responseBody =
        await response.stream.bytesToString();

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      String message =
          'Cloudinary upload failed.';

      try {
        final dynamic decoded =
            jsonDecode(responseBody);

        if (decoded is Map<String, dynamic>) {
          final dynamic error =
              decoded['error'];

          if (error is Map<String, dynamic>) {
            final dynamic messageValue =
                error['message'];

            if (messageValue != null) {
              message =
                  messageValue.toString();
            }
          }
        }
      } catch (_) {}

      throw StateError(
        '$message '
        '(HTTP ${response.statusCode})',
      );
    }

    final dynamic decoded =
        jsonDecode(responseBody);

    if (decoded is! Map<String, dynamic>) {
      throw StateError(
        'Invalid Cloudinary response.',
      );
    }

    final String secureUrl =
        decoded['secure_url']
                ?.toString()
                .trim() ??
            '';

    if (secureUrl.isEmpty) {
      throw StateError(
        'Cloudinary did not return a secure URL.',
      );
    }

    return secureUrl;
  }
}
