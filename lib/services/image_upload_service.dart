import 'dart:io';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_config.dart';
import 'connection_service.dart';

class ImageUploadService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final ConnectionService _connectionService = ConnectionService();
  
  static const String _bucketName = 'profile-images';
  static const int _maxImageSize = 5 * 1024 * 1024; // 5MB
  static final List<String> _allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];

  /// Upload profile image to Supabase Storage
  /// Returns the public URL of the uploaded image
  Future<String?> uploadProfileImage(File imageFile, String userId) async {
    try {
      // Validate file
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }

      // Check file size
      final fileSize = await imageFile.length();
      if (fileSize > _maxImageSize) {
        throw Exception('Image file is too large. Maximum size is 5MB.');
      }

      // Check file extension
      final fileName = imageFile.path.split('/').last.toLowerCase();
      final extension = fileName.split('.').last;
      if (!_allowedExtensions.contains(extension)) {
        throw Exception('Invalid image format. Allowed formats: ${_allowedExtensions.join(", ")}');
      }

      // Generate unique file name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '${userId}_$timestamp.$extension';
      final filePath = 'profiles/$uniqueFileName';

      // Read file bytes
      final fileBytes = await imageFile.readAsBytes();

      // Upload to Supabase Storage with retry logic
      final uploadUrl = await _connectionService.executeWithRetry(
        () async {
          // Ensure bucket exists (create if it doesn't)
          try {
            await _supabase.storage.from(_bucketName).list();
          } catch (e) {
            // Bucket might not exist, but we'll try to upload anyway
            // The error will be caught if upload fails
            print('Note: Bucket check failed, proceeding with upload: $e');
          }

          // Upload file
          await _supabase.storage
              .from(_bucketName)
              .uploadBinary(
                filePath,
                fileBytes,
                fileOptions: FileOptions(
                  upsert: true,
                  contentType: 'image/$extension',
                ),
              )
              .timeout(
                const Duration(seconds: 30),
                onTimeout: () {
                  throw TimeoutException('Image upload timeout. Please try again.');
                },
              );

          // Get public URL
          final publicUrl = _supabase.storage
              .from(_bucketName)
              .getPublicUrl(filePath);

          return publicUrl;
        },
        maxRetries: 3,
        timeout: const Duration(seconds: 35),
      );

      return uploadUrl;
    } on TimeoutException {
      throw 'Image upload timeout. Please check your internet connection and try again.';
    } catch (e) {
      if (e is StorageException) {
        throw 'Failed to upload image: ${e.message}';
      }
      throw 'Image upload failed: ${e.toString()}';
    }
  }

  /// Delete profile image from Supabase Storage
  Future<bool> deleteProfileImage(String imageUrl) async {
    try {
      // Extract file path from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      // Find the path after the bucket name
      final bucketIndex = pathSegments.indexOf(_bucketName);
      if (bucketIndex == -1 || bucketIndex >= pathSegments.length - 1) {
        return false;
      }
      
      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');

      // Delete file
      await _connectionService.executeWithRetry(
        () async {
          await _supabase.storage
              .from(_bucketName)
              .remove([filePath])
              .timeout(
                const Duration(seconds: 15),
                onTimeout: () {
                  throw TimeoutException('Image deletion timeout.');
                },
              );
        },
        maxRetries: 2,
        timeout: const Duration(seconds: 20),
      );

      return true;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }

  /// Compress image (basic implementation - can be enhanced)
  /// For now, we rely on image_picker's maxWidth/maxHeight settings
  Future<File> compressImage(File imageFile) async {
    // Image compression can be added here using packages like flutter_image_compress
    // For now, return the original file
    return imageFile;
  }
}

