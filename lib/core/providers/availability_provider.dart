import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dtos/availability_dto.dart';
import '../data/repositories/availability_repository.dart';
import '../network/api_exception.dart';
import 'repository_providers.dart';

// ── Availability State ────────────────────────────────────────────────────────
class AvailabilityState {
  final bool isLoading;
  final String? error;

  // Normalized map for RESOLVED projections ONLY.
  // entityId -> ResolvedAvailabilityProjectionDto
  final Map<String, ResolvedAvailabilityProjectionDto> resolvedAvailability;

  const AvailabilityState({
    this.isLoading = false,
    this.error,
    this.resolvedAvailability = const {},
  });

  AvailabilityState copyWith({
    bool? isLoading,
    String? error,
    Map<String, ResolvedAvailabilityProjectionDto>? resolvedAvailability,
  }) {
    return AvailabilityState(
      isLoading: isLoading ?? this.isLoading,
      error: error, // Intentional overwrite
      resolvedAvailability: resolvedAvailability ?? this.resolvedAvailability,
    );
  }
}

// ── Availability Notifier ─────────────────────────────────────────────────────
class AvailabilityNotifier extends StateNotifier<AvailabilityState> {
  final AvailabilityRepository _repository;

  AvailabilityNotifier(this._repository) : super(const AvailabilityState());

  /// Fetches the backend-resolved availability for an entity.
  /// No frontend timezone logic, merging, or fallback handling.
  Future<void> fetchResolvedAvailability(String entityId, String entityType) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getResolvedAvailability(entityId, entityType);

    if (result is Success<ResolvedAvailabilityProjectionDto>) {
      final newResolved = Map<String, ResolvedAvailabilityProjectionDto>.from(state.resolvedAvailability);
      newResolved[entityId] = result.data;
      state = state.copyWith(isLoading: false, resolvedAvailability: newResolved);
    } else if (result is Failure<ResolvedAvailabilityProjectionDto>) {
      state = state.copyWith(isLoading: false, error: result.failure.message);
    }
  }

  /// Appends a new availability rule. Triggers immediate deterministic reload of projection.
  Future<Result<AvailabilityRuleDto>> addAvailabilityRule(AvailabilityRuleDto rule) async {
    final result = await _repository.addAvailabilityRule(rule);

    if (result is Success<AvailabilityRuleDto>) {
      await fetchResolvedAvailability(rule.entityId, rule.entityType);
    } else if (result is Failure<AvailabilityRuleDto>) {
      if (result.failure.code == ApiErrorCode.conflict) {
        // Deterministic reload on OCC Conflict
        await fetchResolvedAvailability(rule.entityId, rule.entityType);
      }
    }

    return result;
  }

  Future<Result<AvailabilityRuleDto>> updateAvailabilityRule(AvailabilityRuleDto rule) async {
    final result = await _repository.updateAvailabilityRule(rule);

    if (result is Success<AvailabilityRuleDto>) {
      await fetchResolvedAvailability(rule.entityId, rule.entityType);
    } else if (result is Failure<AvailabilityRuleDto>) {
      if (result.failure.code == ApiErrorCode.conflict) {
        await fetchResolvedAvailability(rule.entityId, rule.entityType);
      }
    }

    return result;
  }

  Future<Result<void>> deleteAvailabilityRule(String ruleId, int currentVersion, String entityId, String entityType) async {
    final result = await _repository.deleteAvailabilityRule(ruleId, currentVersion);

    if (result is Success<void> || (result is Failure<void> && result.failure.code == ApiErrorCode.conflict)) {
      // Refresh the projection to get the latest backend evaluation
      await fetchResolvedAvailability(entityId, entityType);
    }

    return result;
  }

  /// Realtime Hook
  void reconcileRemoteUpdate(String affectedEntityId, String entityType) {
    // Completely invalidate the projection and ask the backend for the new resolution
    fetchResolvedAvailability(affectedEntityId, entityType);
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────
final availabilityProvider = StateNotifierProvider<AvailabilityNotifier, AvailabilityState>((ref) {
  final repo = ref.watch(availabilityRepositoryProvider);
  return AvailabilityNotifier(repo);
});

// Selector for a specific entity's resolved availability
final resolvedAvailabilityProvider = Provider.family<ResolvedAvailabilityProjectionDto?, String>((ref, entityId) {
  final state = ref.watch(availabilityProvider);
  return state.resolvedAvailability[entityId];
});

// Fetch raw rules for configuration UI (un-cached here to avoid stale lifecycle bugs)
final rawAvailabilityRulesProvider = FutureProvider.family<List<AvailabilityRuleDto>, Map<String, String>>((ref, params) async {
  final repo = ref.watch(availabilityRepositoryProvider);
  final entityId = params['entityId']!;
  final entityType = params['entityType']!;
  
  final result = await repo.getAvailabilityRules(entityId, entityType);
  if (result is Success<List<AvailabilityRuleDto>>) {
    return result.data;
  } else {
    throw Exception((result as Failure).failure.message);
  }
});
