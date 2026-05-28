import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dtos/tax_dto.dart';
import '../data/repositories/tax_repository.dart';
import '../network/api_exception.dart';
import 'repository_providers.dart';

// ── Tax State ─────────────────────────────────────────────────────────────────
class TaxState {
  final bool isLoading;
  final String? error;
  
  // Normalized store for tax profiles
  final Map<String, TaxProfileDto> profilesById;
  
  // Normalized store for resolved projections ONLY
  // entityId -> ResolvedTaxProjectionDto
  final Map<String, ResolvedTaxProjectionDto> resolvedTaxes;

  const TaxState({
    this.isLoading = false,
    this.error,
    this.profilesById = const {},
    this.resolvedTaxes = const {},
  });

  TaxState copyWith({
    bool? isLoading,
    String? error,
    Map<String, TaxProfileDto>? profilesById,
    Map<String, ResolvedTaxProjectionDto>? resolvedTaxes,
  }) {
    return TaxState(
      isLoading: isLoading ?? this.isLoading,
      error: error, // intentionally overwriting to allow clearing
      profilesById: profilesById ?? this.profilesById,
      resolvedTaxes: resolvedTaxes ?? this.resolvedTaxes,
    );
  }
}

// ── Tax Notifier ──────────────────────────────────────────────────────────────
class TaxNotifier extends StateNotifier<TaxState> {
  final TaxRepository _repository;

  TaxNotifier(this._repository) : super(const TaxState());

  /// Loads the normalized dictionary of all Tax Profiles
  Future<void> loadTaxProfiles({bool forceRefresh = false}) async {
    if (state.isLoading) return;
    if (state.profilesById.isNotEmpty && !forceRefresh) return;

    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getTaxProfiles();

    if (result is Success<List<TaxProfileDto>>) {
      final newProfiles = forceRefresh ? <String, TaxProfileDto>{} : Map<String, TaxProfileDto>.from(state.profilesById);
      for (final profile in result.data) {
        newProfiles[profile.id] = profile;
      }
      state = state.copyWith(isLoading: false, profilesById: newProfiles);
    } else if (result is Failure<List<TaxProfileDto>>) {
      state = state.copyWith(isLoading: false, error: result.failure.message);
    }
  }

  /// Fetches resolved tax projections for a given entity.
  /// No frontend math is performed here; we rely strictly on backend resolution.
  Future<void> fetchResolvedTax(String entityId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getResolvedTax(entityId);

    if (result is Success<ResolvedTaxProjectionDto>) {
      final newResolved = Map<String, ResolvedTaxProjectionDto>.from(state.resolvedTaxes);
      newResolved[entityId] = result.data;
      state = state.copyWith(isLoading: false, resolvedTaxes: newResolved);
    } else if (result is Failure<ResolvedTaxProjectionDto>) {
      state = state.copyWith(isLoading: false, error: result.failure.message);
    }
  }

  Future<Result<TaxProfileDto>> createTaxProfile(TaxProfileDto profile) async {
    final result = await _repository.createTaxProfile(profile);

    if (result is Success<TaxProfileDto>) {
      final newProfiles = Map<String, TaxProfileDto>.from(state.profilesById);
      newProfiles[result.data.id] = result.data;
      state = state.copyWith(profilesById: newProfiles);
    }

    return result;
  }

  Future<Result<TaxProfileDto>> updateTaxProfile(TaxProfileDto profile) async {
    final result = await _repository.updateTaxProfile(profile);

    if (result is Success<TaxProfileDto>) {
      final newProfiles = Map<String, TaxProfileDto>.from(state.profilesById);
      newProfiles[result.data.id] = result.data;
      state = state.copyWith(profilesById: newProfiles);
    } else if (result is Failure<TaxProfileDto>) {
      if (result.failure.code == ApiErrorCode.conflict) {
        // Deterministic reload on OCC Conflict
        await loadTaxProfiles(forceRefresh: true);
      }
    }

    return result;
  }

  Future<Result<void>> deleteTaxProfile(String profileId) async {
    final profile = state.profilesById[profileId];
    if (profile == null) return Failure(ApiFailure('Tax Profile not found locally'));

    final result = await _repository.deleteTaxProfile(profileId, profile.versionNum);

    if (result is Success<void>) {
      final newProfiles = Map<String, TaxProfileDto>.from(state.profilesById);
      newProfiles.remove(profileId);
      state = state.copyWith(profilesById: newProfiles);
    } else if (result is Failure<void>) {
      if (result.failure.code == ApiErrorCode.conflict) {
        await loadTaxProfiles(forceRefresh: true);
      }
    }

    return result;
  }

  /// Realtime reconciliation hook. Triggered when tax configurations update.
  void reconcileRemoteTaxProfile(TaxProfileDto remoteProfile) {
    final newProfiles = Map<String, TaxProfileDto>.from(state.profilesById);
    if (remoteProfile.deletedAt != null) {
      newProfiles.remove(remoteProfile.id);
    } else {
      newProfiles[remoteProfile.id] = remoteProfile;
    }
    state = state.copyWith(profilesById: newProfiles);
  }

  /// Realtime hook for entity tax assignments.
  /// Directly invalidates and fetches projection instead of local patching.
  void reconcileRemoteTaxAssignment(String affectedEntityId) {
    fetchResolvedTax(affectedEntityId);
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────
final taxProvider = StateNotifierProvider<TaxNotifier, TaxState>((ref) {
  final repo = ref.watch(taxRepositoryProvider);
  return TaxNotifier(repo);
});

// Selector for resolved tax projection
final resolvedTaxProvider = Provider.family<ResolvedTaxProjectionDto?, String>((ref, entityId) {
  final state = ref.watch(taxProvider);
  return state.resolvedTaxes[entityId];
});
