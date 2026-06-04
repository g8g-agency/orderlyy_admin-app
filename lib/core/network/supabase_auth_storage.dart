import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'secure_storage.dart';

/// Supabase session persistence key (matches supabase_flutter defaults).
String supabasePersistSessionKey(String supabaseUrl) {
  final host = Uri.parse(supabaseUrl).host;
  final projectRef = host.split('.').first;
  return 'sb-$projectRef-auth-token';
}

/// Web: [SharedPreferencesLocalStorage] (localStorage). Mobile/desktop: secure storage.
LocalStorage createSupabaseLocalStorage(String supabaseUrl) {
  if (kIsWeb) {
    return SharedPreferencesLocalStorage(
      persistSessionKey: supabasePersistSessionKey(supabaseUrl),
    );
  }
  return const SecureLocalStorage();
}
