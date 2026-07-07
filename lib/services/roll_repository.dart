import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/order_checkout.dart';
import '../pages/camera_page.dart';

/// Étape du parcours après la capture (persistée dans le manifeste).
enum RollStage {
  complete,
  format,
  checkout;

  static RollStage? fromString(String? value) {
    switch (value) {
      case 'complete':
        return RollStage.complete;
      case 'format':
        return RollStage.format;
      case 'checkout':
        return RollStage.checkout;
      default:
        return null;
    }
  }

  String get storageValue => name;
}

/// État du rouleau actif (photos + étape + brouillon checkout).
class ActiveRollState {
  const ActiveRollState({
    required this.photoPaths,
    this.rollId,
    this.stage,
    this.checkoutDraft,
  });

  final List<String> photoPaths;
  final String? rollId;
  final RollStage? stage;
  final Map<String, dynamic>? checkoutDraft;

  bool get isEmpty => photoPaths.isEmpty;

  bool get isComplete => RollRepository.isRollComplete(photoPaths);

  bool get isIncomplete => RollRepository.isRollIncomplete(photoPaths);

  OrderCheckout? toCheckoutOrder() {
    final draft = checkoutDraft;
    final id = rollId;
    if (draft == null || id == null) return null;

    final title = draft['formatTitle'] as String?;
    final subtitle = draft['formatSubtitle'] as String?;
    final subtotal = draft['subtotal'];
    final formatName = draft['format'] as String?;
    if (title == null || subtitle == null || subtotal == null || formatName == null) {
      return null;
    }

    final subtotalValue = subtotal is num
        ? subtotal.toDouble()
        : double.tryParse(subtotal.toString());
    if (subtotalValue == null) return null;

    return OrderCheckout(
      formatTitle: title,
      formatSubtitle: subtitle,
      subtotal: subtotalValue,
      rollId: id,
      format: PrintFormat.values.firstWhere(
        (f) => f.name == formatName,
        orElse: () => OrderCheckout.formatFromTitle(title),
      ),
    );
  }
}

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

  static Future<Map<String, dynamic>> _readManifestData(String userId) async {
    final manifest = await _manifestFileFor(userId);
    if (!await manifest.exists()) return {};

    try {
      final decoded = jsonDecode(await manifest.readAsString());
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return {};
  }

  static Future<void> _writeManifestData(
    String userId,
    Map<String, dynamic> data,
  ) async {
    final manifest = await _manifestFileFor(userId);
    await manifest.writeAsString(jsonEncode(data));
  }

  static Future<void> _writeManifest(
    String userId,
    List<String> photoPaths, {
    String? rollId,
    RollStage? stage,
    Map<String, dynamic>? checkoutDraft,
    bool clearCheckoutDraft = false,
  }) async {
    final existing = await _readManifestData(userId);
    final existingRollId = existing['rollId'] as String?;
    final existingStage = RollStage.fromString(existing['stage'] as String?);
    final existingDraft = existing['checkoutDraft'];

    RollStage? resolvedStage = stage ?? existingStage;
    Object? resolvedDraft = checkoutDraft ?? existingDraft;

    if (photoPaths.length < CameraPage.maxPhotos) {
      resolvedStage = null;
      resolvedDraft = null;
    } else if (resolvedStage == null) {
      resolvedStage = RollStage.complete;
    }

    if (clearCheckoutDraft) {
      resolvedDraft = null;
    }

    final data = <String, dynamic>{
      'photoPaths': photoPaths,
      'rollId': rollId ??
          existingRollId ??
          '${userId}_${DateTime.now().millisecondsSinceEpoch}',
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (resolvedStage != null) {
      data['stage'] = resolvedStage.storageValue;
    }
    if (resolvedDraft is Map<String, dynamic>) {
      data['checkoutDraft'] = resolvedDraft;
    }

    await _writeManifestData(userId, data);
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

  static Future<void> setRollStage(
    String userId,
    RollStage stage, {
    Map<String, dynamic>? checkoutDraft,
  }) async {
    final paths = await loadActiveRoll(userId);
    if (!isRollComplete(paths)) return;

    await _writeManifest(
      userId,
      paths,
      stage: stage,
      checkoutDraft: checkoutDraft,
      clearCheckoutDraft:
          stage != RollStage.checkout && checkoutDraft == null,
    );
  }

  static Future<void> saveCheckoutDraft(
    String userId,
    OrderCheckout order,
  ) async {
    await setRollStage(
      userId,
      RollStage.checkout,
      checkoutDraft: {
        'formatTitle': order.formatTitle,
        'formatSubtitle': order.formatSubtitle,
        'subtotal': order.subtotal,
        'format': order.format.name,
      },
    );
  }

  /// Identifiant stable du rouleau actif (manifest local).
  static Future<String?> getRollId(String userId) async {
    final data = await _readManifestData(userId);
    return data['rollId'] as String?;
  }

  /// Charge le rouleau actif ; filtre les fichiers manquants.
  static Future<List<String>> loadActiveRoll(String userId) async {
    final state = await loadActiveRollState(userId);
    return state.photoPaths;
  }

  /// Charge photos, étape et brouillon checkout depuis le manifeste.
  static Future<ActiveRollState> loadActiveRollState(String userId) async {
    final data = await _readManifestData(userId);
    if (data.isEmpty) {
      return const ActiveRollState(photoPaths: []);
    }

    final raw = data['photoPaths'];
    if (raw is! List) {
      return const ActiveRollState(photoPaths: []);
    }

    final paths = raw.whereType<String>().toList();
    final existing = <String>[];
    for (final path in paths) {
      if (await File(path).exists()) {
        existing.add(path);
      }
    }

    if (existing.length != paths.length) {
      await _writeManifest(
        userId,
        existing,
        rollId: data['rollId'] as String?,
        stage: RollStage.fromString(data['stage'] as String?),
        checkoutDraft: data['checkoutDraft'] is Map<String, dynamic>
            ? data['checkoutDraft'] as Map<String, dynamic>
            : null,
      );
    }

    final draft = data['checkoutDraft'];
    return ActiveRollState(
      photoPaths: existing,
      rollId: data['rollId'] as String?,
      stage: RollStage.fromString(data['stage'] as String?),
      checkoutDraft: draft is Map<String, dynamic> ? draft : null,
    );
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
