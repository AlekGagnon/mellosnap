import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../pages/camera_page.dart';

/// Persistance du rouleau actif par utilisateur (manifest + JPEG sur disque).
class RollRepository {
  RollRepository._();

  static const _rollsRoot = 'mellosnap_rolls';
  static const _activeFolder = 'active';
  static const _manifestFile = 'manifest.json';

  static bool isRollComplete(List<String> paths) =>
      paths.length >= CameraPage.maxPhotos;

  static bool isRollIncomplete(List<String> paths) =>
      paths.isNotEmpty && !isRollComplete(paths);

  static Future<Directory> _activeDirectory(String userId) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(
      p.join(docs.path, _rollsRoot, userId, _activeFolder),
    );
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<File> _manifestFileFor(String userId) async {
    final dir = await _activeDirectory(userId);
    return File(p.join(dir.path, _manifestFile));
  }

  /// Sauvegarde une photo JPEG (bytes) et met à jour le manifeste.
  static Future<String> savePhotoFromBytes({
    required String userId,
    required List<int> bytes,
    required int photoIndex,
    required List<String> existingPaths,
  }) async {
    final dir = await _activeDirectory(userId);
    final filePath = p.join(
      dir.path,
      'photo_${photoIndex}_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await File(filePath).writeAsBytes(bytes);

    final updated = [...existingPaths, filePath];
    await _writeManifest(userId, updated);
    return filePath;
  }

  /// Sauvegarde une photo et met à jour le manifeste.
  static Future<String> savePhoto({
    required String userId,
    required String tempPath,
    required int photoIndex,
    required List<String> existingPaths,
  }) async {
    final dir = await _activeDirectory(userId);
    final filePath = p.join(
      dir.path,
      'photo_${photoIndex}_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await File(tempPath).copy(filePath);

    final updated = [...existingPaths, filePath];
    await _writeManifest(userId, updated);
    return filePath;
  }

  static Future<void> _writeManifest(
    String userId,
    List<String> photoPaths, {
    String? rollId,
  }) async {
    final manifest = await _manifestFileFor(userId);
    String? existingRollId;
    if (await manifest.exists()) {
      try {
        final decoded = jsonDecode(await manifest.readAsString());
        if (decoded is Map<String, dynamic>) {
          existingRollId = decoded['rollId'] as String?;
        }
      } catch (_) {}
    }

    final data = {
      'photoPaths': photoPaths,
      'rollId': rollId ??
          existingRollId ??
          '${userId}_${DateTime.now().millisecondsSinceEpoch}',
      'updatedAt': DateTime.now().toIso8601String(),
    };
    await manifest.writeAsString(jsonEncode(data));
  }

  /// Identifiant stable du rouleau actif (manifest local).
  static Future<String?> getRollId(String userId) async {
    final manifest = await _manifestFileFor(userId);
    if (!await manifest.exists()) return null;

    try {
      final decoded = jsonDecode(await manifest.readAsString());
      if (decoded is! Map<String, dynamic>) return null;
      return decoded['rollId'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Charge le rouleau actif ; filtre les fichiers manquants.
  static Future<List<String>> loadActiveRoll(String userId) async {
    final manifest = await _manifestFileFor(userId);
    if (!await manifest.exists()) return [];

    try {
      final decoded = jsonDecode(await manifest.readAsString());
      if (decoded is! Map<String, dynamic>) return [];

      final raw = decoded['photoPaths'];
      if (raw is! List) return [];

      final paths = raw.whereType<String>().toList();
      final existing = <String>[];
      for (final path in paths) {
        if (await File(path).exists()) {
          existing.add(path);
        }
      }

      if (existing.length != paths.length) {
        await _writeManifest(userId, existing);
      }
      return existing;
    } catch (_) {
      return [];
    }
  }

  /// Supprime le rouleau actif (manifeste + fichiers).
  static Future<void> clearActiveRoll(String userId) async {
    final dir = await _activeDirectory(userId);
    if (await dir.exists()) {
      await for (final entity in dir.list()) {
        await entity.delete(recursive: true);
      }
    }
  }
}
