import 'package:flutter/foundation.dart';

class SupabaseConstants {
  // Remote Supabase instance (same project as table_os/.env)
  static const String _remoteUrl = 'https://mdwryhxnruprtuqonbwy.supabase.co';
  static const String _remoteAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1kd3J5aHhucnVwcnR1cW9uYnd5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ5NzU1MTEsImV4cCI6MjA5MDU1MTUxMX0.5hGdHHSzRnfENndmbL1pdiT2LsqhJCHkz1Fq2-8ADAY';

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
