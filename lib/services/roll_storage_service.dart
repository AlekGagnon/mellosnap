import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'roll_repository.dart';

/// Upload des photos du rouleau vers Supabase Storage (`rolls/{userId}/{rollId}/N.jpg`).
class RollStorageService {
  RollStorageService._();

  static SupabaseClient get _client => Supabase.instance.client;
  static const _bucket = 'rolls';

  /// Envoie les photos locales vers Storage (1.jpg … 24.jpg).
  static Future<void> uploadActiveRoll({
    required String userId,
    required String rollId,
  }) async {
    final paths = await RollRepository.loadActiveRoll(userId);
    if (paths.isEmpty) {
      throw Exception('No photos to upload.');
    }

    for (var i = 0; i < paths.length; i++) {
      final file = File(paths[i]);
      if (!await file.exists()) continue;

      final storagePath = '$userId/$rollId/${i + 1}.jpg';
      await _client.storage.from(_bucket).upload(
            storagePath,
            file,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );
    }
  }
}
