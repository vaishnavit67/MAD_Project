import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'mongodb_service.dart';
import 'auth_service.dart';
import '../core/theme/lf_colors.dart';

class ImageUploadResult {
  final bool success;
  final String? url;
  final String? errorMessage;
  final XFile? localFile;

  ImageUploadResult({
    required this.success,
    this.url,
    this.errorMessage,
    this.localFile,
  });
}

class ImageUploadService {
  static final ImageUploadService _instance = ImageUploadService._internal();
  factory ImageUploadService() => _instance;
  static ImageUploadService get instance => _instance;
  ImageUploadService._internal();

  final ImagePicker _picker = ImagePicker();

  String get _uploadEndpoint => '${MongoDbService.instance.backendUrl}/api/upload';

  /// Show standard modal bottom sheet to select Camera or Gallery
  Future<XFile?> pickImageWithSourceSelection(BuildContext context) async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Image Source',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: LFColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Take a real-time photo with camera or choose from gallery',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: LFColors.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: LFColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt_rounded, color: LFColors.primary),
              ),
              title: const Text(
                'Take Photo (Device Camera)',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              subtitle: const Text('Capture photo directly with phone camera', style: TextStyle(fontSize: 12)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            const Divider(height: 12),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library_rounded, color: Color(0xFF10B981)),
              ),
              title: const Text(
                'Choose from Gallery',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              subtitle: const Text('Pick existing image from media library', style: TextStyle(fontSize: 12)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return null;

    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      return file;
    } catch (e) {
      debugPrint('[ImagePicker Error]: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not access ${source == ImageSource.camera ? 'camera' : 'gallery'}: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return null;
    }
  }

  /// Upload an XFile image to the backend /api/upload endpoint
  Future<ImageUploadResult> uploadImage(XFile imageFile) async {
    try {
      final uri = Uri.parse(_uploadEndpoint);
      final request = http.MultipartRequest('POST', uri);

      final token = AuthService.effectiveToken;
      if (token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      final bytes = await imageFile.readAsBytes();
      final mimeType = imageFile.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: imageFile.name.isNotEmpty ? imageFile.name : 'upload.jpg',
          contentType: MediaType.parse(mimeType),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        String? uploadedUrl = data['url']?.toString();
        final String? relativeUrl = data['relativeUrl']?.toString();

        // If returned absolute url contains localhost and we are targeting 10.0.2.2 or custom IP
        if (relativeUrl != null && relativeUrl.isNotEmpty) {
          uploadedUrl = '${MongoDbService.instance.backendUrl}$relativeUrl';
        }

        return ImageUploadResult(
          success: true,
          url: uploadedUrl,
          localFile: imageFile,
        );
      } else {
        String msg = 'Failed to upload image. (Status: ${response.statusCode})';
        try {
          final data = jsonDecode(response.body);
          if (data['message'] != null) msg = data['message'];
        } catch (_) {}
        return ImageUploadResult(
          success: false,
          errorMessage: msg,
          localFile: imageFile,
        );
      }
    } catch (e) {
      debugPrint('[Upload Image Error]: $e');
      return ImageUploadResult(
        success: false,
        errorMessage: 'Network error uploading image: $e',
        localFile: imageFile,
      );
    }
  }
}
