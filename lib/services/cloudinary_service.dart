import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/constants/cloudinary_config.dart';

class CloudinaryService {
  Future<String> uploadImage(
    File file, {
    required String folder,
    required String fileName,
  }) async {
    if (!CloudinaryConfig.isConfigured) {
      throw Exception(
        'Cloudinary not configured. Set cloudName and uploadPreset in '
        'lib/core/constants/cloudinary_config.dart',
      );
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
      ..fields['folder'] = folder
      ..fields['public_id'] = fileName
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode != 200) {
      throw Exception('Image upload failed. Check Cloudinary preset and internet.');
    }

    final json = jsonDecode(body) as Map<String, dynamic>;
    final url = json['secure_url'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception('Cloudinary did not return an image URL');
    }
    return url;
  }

  Future<String> uploadAudio(
    File file, {
    required String folder,
    required String fileName,
  }) async {
    if (!CloudinaryConfig.isConfigured) {
      throw Exception(
        'Cloudinary not configured. Set cloudName and uploadPreset in '
        'lib/core/constants/cloudinary_config.dart',
      );
    }

    // Cloudinary uses the /video/upload endpoint for audio files
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/video/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
      ..fields['folder'] = folder
      ..fields['public_id'] = fileName
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode != 200) {
      throw Exception('Audio upload failed. Check Cloudinary preset and internet.');
    }

    final json = jsonDecode(body) as Map<String, dynamic>;
    final url = json['secure_url'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception('Cloudinary did not return an audio URL');
    }
    return url;
  }
}
