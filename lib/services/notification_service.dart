import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import 'roll_repository.dart';

/// OneSignal push: identity (Supabase user id) + tags for re-engagement.
///
/// Tags used by OneSignal Journeys / segments:
/// - `roll_status`: none | in_progress | complete | format | checkout
/// - `photos_taken`: "0".."24"
/// - `order_status`: none | pending | paid
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  bool _initialized = false;

  bool get isConfigured {
    final id = dotenv.env['ONESIGNAL_APP_ID']?.trim() ?? '';
    return id.isNotEmpty && !id.startsWith('your_');
  }

  Future<void> initialize() async {
    if (_initialized || !isConfigured) return;

    final appId = dotenv.env['ONESIGNAL_APP_ID']!.trim();
    try {
      if (kDebugMode) {
        OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      }
      OneSignal.initialize(appId);
      _initialized = true;
    } catch (e, st) {
      debugPrint('OneSignal init failed: $e\n$st');
    }
  }

  /// Call after sign-in / session restore.
  Future<void> loginUser({
    required String userId,
    String? email,
  }) async {
    if (!_initialized) return;
    try {
      await OneSignal.login(userId);
      if (email != null && email.isNotEmpty) {
        await OneSignal.User.addEmail(email);
      }
      await syncFromActiveRoll(userId);
    } catch (e, st) {
      debugPrint('OneSignal login failed: $e\n$st');
    }
  }

  Future<void> logoutUser() async {
    if (!_initialized) return;
    try {
      await OneSignal.logout();
    } catch (e, st) {
      debugPrint('OneSignal logout failed: $e\n$st');
    }
  }

  Future<bool> requestPermission() async {
    if (!_initialized) return false;
    try {
      return await OneSignal.Notifications.requestPermission(true);
    } catch (e, st) {
      debugPrint('OneSignal permission failed: $e\n$st');
      return false;
    }
  }

  Future<bool> get notificationsEnabled async {
    if (!_initialized) return false;
    try {
      return OneSignal.User.pushSubscription.optedIn ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    if (!_initialized) return;
    try {
      if (enabled) {
        await requestPermission();
        await OneSignal.User.pushSubscription.optIn();
      } else {
        await OneSignal.User.pushSubscription.optOut();
      }
    } catch (e, st) {
      debugPrint('OneSignal opt-in/out failed: $e\n$st');
    }
  }

  Future<void> syncFromActiveRoll(String userId) async {
    if (!_initialized) return;
    try {
      final state = await RollRepository.loadActiveRollState(userId);
      final count = state.photoPaths.length;
      final String rollStatus;
      if (count == 0) {
        rollStatus = 'none';
      } else if (state.stage != null) {
        rollStatus = state.stage!.storageValue;
      } else if (RollRepository.isRollComplete(state.photoPaths)) {
        rollStatus = 'complete';
      } else {
        rollStatus = 'in_progress';
      }

      await _setTags({
        'roll_status': rollStatus,
        'photos_taken': '$count',
      });
    } catch (e, st) {
      debugPrint('OneSignal sync roll failed: $e\n$st');
    }
  }

  Future<void> tagRollProgress({
    required int photosTaken,
    String? rollStatus,
  }) async {
      await _setTags({
        'roll_status': ?rollStatus,
        'photos_taken': '$photosTaken',
      });
  }

  Future<void> tagRollStage(RollStage stage) async {
    await _setTags({'roll_status': stage.storageValue});
  }

  Future<void> tagOrderStatus(String status) async {
    await _setTags({'order_status': status});
  }

  Future<void> clearRollTags() async {
    await _setTags({
      'roll_status': 'none',
      'photos_taken': '0',
      'order_status': 'none',
    });
  }

  Future<void> _setTags(Map<String, String> tags) async {
    if (!_initialized || tags.isEmpty) return;
    try {
      await OneSignal.User.addTags(tags);
    } catch (e, st) {
      debugPrint('OneSignal tags failed: $e\n$st');
    }
  }
}
