import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/garbage_record.dart';

class StorageService {
  static const String _boxName = 'garbage_records';
  static const String _bucketName = 'garbage-images';

  static final SupabaseClient _supabase = Supabase.instance.client;

  // ------------------------------------------------------------
  // OLD LOCAL STORAGE
  // ------------------------------------------------------------

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_boxName);
  }

  static Future<String> saveImage(File imageFile) async {
    final directory = await getApplicationDocumentsDirectory();

    final imageDirectory = Directory('${directory.path}/garbage_images');

    if (!await imageDirectory.exists()) {
      await imageDirectory.create(recursive: true);
    }

    final fileName = 'garbage_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final savedImage = await imageFile.copy('${imageDirectory.path}/$fileName');

    return savedImage.path;
  }

  static Future<void> saveRecord(GarbageRecord record) async {
    final box = Hive.box(_boxName);

    await box.put(record.id, record.toMap());
  }

  static List<GarbageRecord> getAllRecords() {
    final box = Hive.box(_boxName);

    final records = box.values
        .map((data) => GarbageRecord.fromMap(data))
        .toList();

    records.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return records;
  }

  static Future<void> deleteRecord(String id) async {
    final box = Hive.box(_boxName);

    final data = box.get(id);

    if (data != null) {
      final record = GarbageRecord.fromMap(data);

      final imageFile = File(record.imagePath);

      if (await imageFile.exists()) {
        await imageFile.delete();
      }
    }

    await box.delete(id);
  }

  // ------------------------------------------------------------
  // SUPABASE STORAGE
  // ------------------------------------------------------------

  /// Upload an image to Supabase Storage.
  ///
  /// Path:
  ///
  /// garbage-images/
  ///     user_id/
  ///         image_id.jpg
  ///
  static Future<String> uploadImage(File imageFile) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    final userId = user.id;

    final fileName = 'garbage_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final filePath = '$userId/$fileName';

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

  // ------------------------------------------------------------
  // SAVE CLOUD RECORD
  // ------------------------------------------------------------

  /// Saves image information, GPS coordinates, area and time.
  static Future<void> saveCloudRecord({
    required String id,
    required String imagePath,
    required double latitude,
    required double longitude,
    required String area,
    required DateTime timestamp,
  }) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    await _supabase.from('garbage_records').insert({
      'id': id,
      'user_id': user.id,
      'image_path': imagePath,
      'latitude': latitude,
      'longitude': longitude,
      'area': area,
      'timestamp': timestamp.toUtc().toIso8601String(),
    });
  }

  // ------------------------------------------------------------
  // GET CLOUD RECORDS
  // ------------------------------------------------------------

  static Future<List<GarbageRecord>> getCloudRecords() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    final response = await _supabase
        .from('garbage_records')
        .select()
        .eq('user_id', user.id)
        .order('timestamp', ascending: false);

    final List<GarbageRecord> records = [];

    for (final data in response) {
      final imagePath = data['image_path'] as String;

      final signedUrl = await _supabase.storage
          .from(_bucketName)
          .createSignedUrl(imagePath, 60 * 60);

      records.add(
        GarbageRecord(
          id: data['id'] as String,
          imagePath: signedUrl,
          latitude: (data['latitude'] as num).toDouble(),
          longitude: (data['longitude'] as num).toDouble(),
          area: data['area']?.toString() ?? 'Unknown Area',
          timestamp: DateTime.parse(data['timestamp'] as String),
        ),
      );
    }

    return records;
  }

  // ------------------------------------------------------------
  // DELETE CLOUD RECORD
  // ------------------------------------------------------------

  static Future<void> deleteCloudRecord(String id) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    // Get image path before deleting database record.
    final response = await _supabase
        .from('garbage_records')
        .select('image_path')
        .eq('id', id)
        .eq('user_id', user.id)
        .maybeSingle();

    if (response == null) {
      throw Exception('Photo record not found.');
    }

    final imagePath = response['image_path'] as String;

    // Delete image from Supabase Storage.
    await _supabase.storage.from(_bucketName).remove([imagePath]);

    // Delete database record.
    await _supabase
        .from('garbage_records')
        .delete()
        .eq('id', id)
        .eq('user_id', user.id);
  }
}
