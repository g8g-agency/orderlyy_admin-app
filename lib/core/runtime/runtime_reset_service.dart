import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized service for destroying runtime state deterministically.
class RuntimeResetService {
  /// Destroys all runtime state, projections, and caches.
  /// Used during user mismatch or explicit logout.
  static Future<void> fullReset() async {
    debugPrint('[RuntimeReset] 🔥 Commencing full runtime reset...');
    await _clearHiveBoxes();
    await _clearSharedPreferences();
    debugPrint('[RuntimeReset] ✅ Full runtime reset complete.');
  }

  /// Clears operational runtime views (projections, observability) but retains session context.
  /// Used during onboarding skips or minor context refreshes.
  static Future<void> clearRuntimeViews() async {
    debugPrint('[RuntimeReset] 🧹 Clearing runtime views...');
    await _clearHiveBoxes();
    debugPrint('[RuntimeReset] ✅ Runtime views cleared.');
  }

  static Future<void> _clearHiveBoxes() async {
    try {
      if (Hive.isBoxOpen('api_cache')) {
        await Hive.box<String>('api_cache').clear();
      }
      if (Hive.isBoxOpen('offline_writes')) {
        await Hive.box<String>('offline_writes').clear();
      }
      if (Hive.isBoxOpen('app_snapshot_cache')) {
        await Hive.box('app_snapshot_cache').clear();
      }
    } catch (e) {
      debugPrint('[RuntimeReset] ⚠️ Failed to clear Hive boxes: $e');
    }
  }

  static Future<void> _clearSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Preserve system flutter flags and the bootstrap user identity tracker.
      final keysToRemove = prefs.getKeys().where(
        (k) => !k.startsWith('flutter.') && k != 'bootstrap_last_user_id',
      ).toList();

      for (final key in keysToRemove) {
        await prefs.remove(key);
      }
      debugPrint('[RuntimeReset] Cleared ${keysToRemove.length} preferences.');
    } catch (e) {
      debugPrint('[RuntimeReset] ⚠️ Failed to clear SharedPreferences: $e');
    }
  }
}
