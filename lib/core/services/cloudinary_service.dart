import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class CloudinaryService {
  CloudinaryService._();

  static const String cloudName = 'YOUR_CLOUD_NAME';
  static const String uploadPreset = 'dojo_walker';

  static Future<String> uploadImage({
    required File file,
    String? folder,
  }) async {
    if (cloudName == 'YOUR_CLOUD_NAME') {
      throw Exception('Cloudinary Cloud Name is not configured.');
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri);

    request.fields['upload_preset'] = uploadPreset;

    if (folder != null && folder.trim().isNotEmpty) {
      request.fields['folder'] = folder.trim();
    }

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Cloudinary upload failed';

      try {
        final data = jsonDecode(response.body);

        if (data is Map<String, dynamic>) {
          final error = data['error'];

          if (error is Map<String, dynamic>) {
            message = error['message']?.toString() ?? message;
          }
        }
      } catch (_) {
        // Keep default error message.
      }

      throw Exception('$message (${response.statusCode})');
    }

    final data = jsonDecode(response.body);

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid Cloudinary response.');
    }

    final secureUrl = data['secure_url']?.toString();

    if (secureUrl == null || secureUrl.isEmpty) {
      throw Exception('Cloudinary did not return an image URL.');
    }

    return secureUrl;
  }
}
