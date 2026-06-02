import 'package:flutter/foundation.dart';

class SupabaseConstants {
  // Remote Supabase instance used by the rest of the workspace
  static const String _remoteUrl = 'YOUR_SUPABASE_URL';
  static const String _remoteAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  // Local Supabase emulator settings (commented/kept for toggling)
  static String get _localUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:54321';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:54321'; // Android emulator localhost
    }
    return 'http://127.0.0.1:54321';
  }
  static const String _localAnonKey =
      'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH';

  // Toggle this flag to switch between Remote and Local emulator environments
  static const bool useLocalEmulator = false;

  static String get supabaseUrl => useLocalEmulator ? _localUrl : _remoteUrl;

  static const String supabaseAnonKey = useLocalEmulator ? _localAnonKey : _remoteAnonKey;
}
