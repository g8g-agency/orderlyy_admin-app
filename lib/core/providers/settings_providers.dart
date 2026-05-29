import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dtos/settings_dto.dart';
import '../data/repositories/settings_repository.dart';
import '../network/api_exception.dart';
import 'repository_providers.dart';

class SettingsState {
  final bool isLoading;
  final String? error;

  // Normalized cache for configuration.
  // Keyed by 'tenant' or 'branch_$id'
  final Map<String, TenantSettingsDto> settingsCache;

  const SettingsState({
    this.isLoading = false,
    this.error,
    this.settingsCache = const {},
  });

  SettingsState copyWith({
    bool? isLoading,
    String? error,
    Map<String, TenantSettingsDto>? settingsCache,
  }) {
    return SettingsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      settingsCache: settingsCache ?? this.settingsCache,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SettingsRepository _repository;

  SettingsNotifier(this._repository) : super(const SettingsState());

  /// Fetches settings configuration.
  /// The backend resolves whether to return tenant-wide defaults or branch overrides.
  Future<void> fetchSettings({
    String? branchId,
    bool forceRefresh = false,
  }) async {
    final cacheKey = branchId == null ? 'tenant' : 'branch_$branchId';

    if (state.isLoading) return;
    if (state.settingsCache.containsKey(cacheKey) && !forceRefresh) return;

    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getSettings(branchId: branchId);

    if (result is Success<TenantSettingsDto>) {
      final newCache = Map<String, TenantSettingsDto>.from(state.settingsCache);
      newCache[cacheKey] = result.value;
      state = state.copyWith(isLoading: false, settingsCache: newCache);
    } else if (result is Failure<TenantSettingsDto>) {
      state = state.copyWith(isLoading: false, error: result.error.message);
    }
  }

  /// Updates settings.
  /// Strictly protected by OCC to prevent concurrent admin overwrites.
  Future<Result<TenantSettingsDto>> updateSettings(
    TenantSettingsDto settings,
  ) async {
    final result = await _repository.updateSettings(settings);

    if (result is Success<TenantSettingsDto>) {
      final cacheKey = settings.branchId == null
          ? 'tenant'
          : 'branch_${settings.branchId}';
      final newCache = Map<String, TenantSettingsDto>.from(state.settingsCache);
      newCache[cacheKey] = result.value;
      state = state.copyWith(settingsCache: newCache);
    } else if (result is Failure<TenantSettingsDto>) {
      if (result.error.code == ApiErrorCode.conflict) {
        // Deterministic reload on 409 OCC Conflict
        await fetchSettings(branchId: settings.branchId, forceRefresh: true);
      }
    }

    return result;
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) {
    final repo = ref.watch(settingsRepositoryProvider);
    return SettingsNotifier(repo);
  },
);

final activeSettingsProvider = Provider.family<TenantSettingsDto?, String?>((
  ref,
  branchId,
) {
  final state = ref.watch(settingsProvider);
  final cacheKey = branchId == null ? 'tenant' : 'branch_$branchId';
  return state.settingsCache[cacheKey];
});
