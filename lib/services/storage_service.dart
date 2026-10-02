import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/garbage_record.dart';

class StorageService {
  // ============================================================
  // CONSTANTS
  // ============================================================

  static const String _bucketName = 'garbage-images';

  // Signed URL validity: 1 hour
  static const int _signedUrlExpirySeconds = 60 * 60;

  static final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================
  // GET CURRENT USER
  // ============================================================

  static User _getCurrentUser() {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    return user;
  }

  // ============================================================
  // UPLOAD ONE IMAGE
  // ============================================================

  static Future<String> uploadImage(File imageFile) async {
    final user = _getCurrentUser();

    final fileName = 'garbage_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final filePath = '${user.id}/$fileName';

    await _supabase.storage
        .from(_bucketName)
        .upload(
          filePath,
          imageFile,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: false,
          ),
        );

    return filePath;
  }

  // ============================================================
  // CREATE GARBAGE REPORT
  // ============================================================

  static Future<void> createGarbageReport({
    required String recordId,
    required List<File> images,
    required double latitude,
    required double longitude,
    required String area,
    required String pinCode,
    required String roadName,
    required String description,
  }) async {
    final user = _getCurrentUser();

    // ----------------------------------------------------------
    // Validate images
    // ----------------------------------------------------------

    if (images.isEmpty) {
      throw Exception('At least one image is required.');
    }

    if (images.length > 5) {
      throw Exception('Maximum 5 images are allowed.');
    }

    final uploadedPaths = <String>[];

    try {
      // ========================================================
      // 1. CREATE GARBAGE RECORD
      // ========================================================

      await _supabase.from('garbage_records').insert({
        'id': recordId,
        'user_id': user.id,
        'latitude': latitude,
        'longitude': longitude,
        'area': area,
        'pin_code': pinCode,
        'road_name': roadName,
        'description': description,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });

      // ========================================================
      // 2. UPLOAD ALL IMAGES
      // ========================================================

      for (int i = 0; i < images.length; i++) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';

        final imagePath = '${user.id}/$recordId/$fileName';

        // ------------------------------------------------------
        // Upload image to Supabase Storage
        // ------------------------------------------------------

        await _supabase.storage
            .from(_bucketName)
            .upload(
              imagePath,
              images[i],
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: false,
              ),
            );

        uploadedPaths.add(imagePath);

        // ------------------------------------------------------
        // Store image information in garbage_images
        // ------------------------------------------------------

        await _supabase.from('garbage_images').insert({
          'garbage_record_id': recordId,
          'image_path': imagePath,
          'photo_order': i + 1,
        });
      }
    } catch (e) {
      // ========================================================
      // ROLLBACK
      // ========================================================

      // --------------------------------------------------------
      // Remove uploaded images from Storage
      // --------------------------------------------------------

      if (uploadedPaths.isNotEmpty) {
        try {
          await _supabase.storage.from(_bucketName).remove(uploadedPaths);
        } catch (_) {
          // Ignore cleanup error
        }
      }

      // --------------------------------------------------------
      // Remove garbage_images rows
      // --------------------------------------------------------

      try {
        await _supabase
            .from('garbage_images')
            .delete()
            .eq('garbage_record_id', recordId);
      } catch (_) {
        // Ignore cleanup error
      }

      // --------------------------------------------------------
      // Remove garbage_records row
      // --------------------------------------------------------

      try {
        await _supabase
            .from('garbage_records')
            .delete()
            .eq('id', recordId)
            .eq('user_id', user.id);
      } catch (_) {
        // Ignore cleanup error
      }

      rethrow;
    }
  }

  // ============================================================
  // GET ALL CLOUD RECORDS
  // ============================================================

  static Future<List<GarbageRecord>> getCloudRecords() async {
    final user = _getCurrentUser();

    // ==========================================================
    // GET RECORDS + ALL IMAGES
    // ==========================================================

    final response = await _supabase
        .from('garbage_records')
        .select('''
          id,
          user_id,
          latitude,
          longitude,
          area,
          pin_code,
          road_name,
          description,
          timestamp,
          garbage_images (
            id,
            image_path,
            photo_order,
            created_at
          )
        ''')
        .eq('user_id', user.id)
        .order('timestamp', ascending: false);

    final List<GarbageRecord> records = [];

    // ==========================================================
    // PROCESS EACH GARBAGE RECORD
    // ==========================================================

    for (final data in response) {
      // --------------------------------------------------------
      // Get image rows
      // --------------------------------------------------------

      final imageRows = List<dynamic>.from(
        (data['garbage_images'] as List<dynamic>?) ?? [],
      );

      // --------------------------------------------------------
      // Sort images according to photo_order
      // --------------------------------------------------------

      imageRows.sort((a, b) {
        final orderA = (a['photo_order'] as num?)?.toInt() ?? 0;

        final orderB = (b['photo_order'] as num?)?.toInt() ?? 0;

        return orderA.compareTo(orderB);
      });

      // --------------------------------------------------------
      // Create signed URLs
      // --------------------------------------------------------

      final List<String> imageUrls = [];

      for (final imageRow in imageRows) {
        final imagePath = imageRow['image_path']?.toString();

        if (imagePath == null || imagePath.isEmpty) {
          continue;
        }

        try {
          final signedUrl = await _supabase.storage
              .from(_bucketName)
              .createSignedUrl(imagePath, _signedUrlExpirySeconds);

          imageUrls.add(signedUrl);
        } catch (_) {
          // Skip invalid/deleted image
        }
      }

      // --------------------------------------------------------
      // Create GarbageRecord object
      // --------------------------------------------------------

      records.add(
        GarbageRecord(
          id: data['id'].toString(),

          userId: data['user_id'].toString(),

          latitude: (data['latitude'] as num).toDouble(),

          longitude: (data['longitude'] as num).toDouble(),

          area: data['area']?.toString() ?? '',

          pinCode: data['pin_code']?.toString() ?? '',

          roadName: data['road_name']?.toString() ?? '',

          description: data['description']?.toString() ?? '',

          timestamp: DateTime.parse(data['timestamp'].toString()),

          // IMPORTANT:
          // All photos belonging to the same garbage record
          // are stored inside this single list.
          imagePaths: imageUrls,
        ),
      );
    }

    return records;
  }

  // ============================================================
  // DELETE ONE PHOTO
  // ============================================================
  //
  // This deletes ONLY the selected photo.
  //
  // The other photos belonging to the same garbage report
  // remain untouched.
  //
  // ============================================================

  static Future<void> deleteCloudImage({
    required String recordId,
    required String imagePath,
  }) async {
    final user = _getCurrentUser();

    if (imagePath.isEmpty) {
      throw Exception('Invalid image path.');
    }

    // ==========================================================
    // 1. DELETE IMAGE FROM STORAGE
    // ==========================================================

    await _supabase.storage.from(_bucketName).remove([imagePath]);

    // ==========================================================
    // 2. DELETE IMAGE DATABASE ROW
    // ==========================================================

    await _supabase
        .from('garbage_images')
        .delete()
        .eq('garbage_record_id', recordId)
        .eq('image_path', imagePath);

    // ==========================================================
    // 3. CHECK IF ANY PHOTOS REMAIN
    // ==========================================================

    final remainingImages = await _supabase
        .from('garbage_images')
        .select('id')
        .eq('garbage_record_id', recordId);

    // ==========================================================
    // 4. IF NO PHOTOS REMAIN, DELETE THE WHOLE RECORD
    // ==========================================================

    if (remainingImages.isEmpty) {
      await _supabase
          .from('garbage_records')
          .delete()
          .eq('id', recordId)
          .eq('user_id', user.id);
    }
  }

  // ============================================================
  // DELETE COMPLETE CLOUD RECORD
  // ============================================================

  static Future<void> deleteCloudRecord(String recordId) async {
    final user = _getCurrentUser();

    // ==========================================================
    // 1. GET ALL IMAGE PATHS
    // ==========================================================

    final response = await _supabase
        .from('garbage_images')
        .select('image_path')
        .eq('garbage_record_id', recordId);

    final List<String> imagePaths = [];

    for (final row in response) {
      final path = row['image_path']?.toString();

      if (path != null && path.isNotEmpty) {
        imagePaths.add(path);
      }
    }

    // ==========================================================
    // 2. DELETE ALL IMAGES FROM STORAGE
    // ==========================================================

    if (imagePaths.isNotEmpty) {
      await _supabase.storage.from(_bucketName).remove(imagePaths);
    }

    // ==========================================================
    // 3. DELETE ALL garbage_images ROWS
    // ==========================================================

    await _supabase
        .from('garbage_images')
        .delete()
        .eq('garbage_record_id', recordId);

    // ==========================================================
    // 4. DELETE garbage_records ROW
    // ==========================================================

    await _supabase
        .from('garbage_records')
        .delete()
        .eq('id', recordId)
        .eq('user_id', user.id);
  }
}
