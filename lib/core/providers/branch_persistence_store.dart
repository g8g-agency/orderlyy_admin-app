import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'repository_providers.dart';

abstract class BranchPersistenceStore {
  Future<String?> getPersistedBranchId();
  Future<void> persistBranchId(String branchId);
  Future<void> clearPersistedBranchId();
}

class SharedPrefsBranchStore implements BranchPersistenceStore {
  final SharedPreferences _prefs;
  static const _key = 'current_branch_id';

  SharedPrefsBranchStore(this._prefs);

  @override
  Future<String?> getPersistedBranchId() async {
    return _prefs.getString(_key);
  }

  @override
  Future<void> persistBranchId(String branchId) async {
    await _prefs.setString(_key, branchId);
  }

  @override
  Future<void> clearPersistedBranchId() async {
    await _prefs.remove(_key);
  }
}

final branchPersistenceStoreProvider = Provider<BranchPersistenceStore>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SharedPrefsBranchStore(prefs);
});
