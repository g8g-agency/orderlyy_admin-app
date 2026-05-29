import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dtos/pricing_dto.dart';
import '../data/repositories/pricing_repository.dart';
import '../network/api_exception.dart';
import 'repository_providers.dart';

// ── Pricing State ─────────────────────────────────────────────────────────────
class PricingState {
  final bool isLoading;
  final String? error;

  // Normalized store for RESOLVED projections ONLY.
  // entityId -> ResolvedPriceProjectionDto
  final Map<String, ResolvedPriceProjectionDto> resolvedPrices;

  const PricingState({
    this.isLoading = false,
    this.error,
    this.resolvedPrices = const {},
  });

  PricingState copyWith({
    bool? isLoading,
    String? error,
    Map<String, ResolvedPriceProjectionDto>? resolvedPrices,
  }) {
    return PricingState(
      isLoading: isLoading ?? this.isLoading,
      error: error, // overwrite intentionally
      resolvedPrices: resolvedPrices ?? this.resolvedPrices,
    );
  }
}

// ── Pricing Notifier ──────────────────────────────────────────────────────────
class PricingNotifier extends StateNotifier<PricingState> {
  final PricingRepository _repository;

  PricingNotifier(this._repository) : super(const PricingState());

  /// Fetches the resolved pricing for a specific list of entities.
  /// DO NOT aggressively cache. Re-fetching ensures backend resolution.
  Future<void> fetchResolvedPrices(List<String> entityIds) async {
    if (entityIds.isEmpty) return;

    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getResolvedPrices(entityIds);

    if (result is Success<List<ResolvedPriceProjectionDto>>) {
      final newResolved = Map<String, ResolvedPriceProjectionDto>.from(
        state.resolvedPrices,
      );
      for (final projection in result.value) {
        newResolved[projection.entityId] = projection;
      }
      state = state.copyWith(isLoading: false, resolvedPrices: newResolved);
    } else if (result is Failure<List<ResolvedPriceProjectionDto>>) {
      state = state.copyWith(isLoading: false, error: result.error.message);
    }
  }

  /// Appends a new pricing record (immutable history).
  /// If it succeeds, it triggers a reload of the resolved price projection.
  Future<Result<PricingRecordDto>> addPricingRecord(
    PricingRecordDto record,
  ) async {
    final result = await _repository.addPricingRecord(record);

    if (result is Success<PricingRecordDto>) {
      // Deterministic reload of the projection for this entity
      await fetchResolvedPrices([record.entityId]);
    } else if (result is Failure<PricingRecordDto>) {
      if (result.error.code == ApiErrorCode.conflict) {
        // Deterministic reload on OCC Conflict
        await fetchResolvedPrices([record.entityId]);
      }
    }

    return result;
  }

  /// Realtime reconciliation method. Call this when a pricing websocket event occurs.
  void reconcileRemoteUpdate(String affectedEntityId) {
    // We do NOT mutate the UI directly from the transport payload for pricing.
    // We immediately invalidate and request the backend to re-resolve the projection.
    fetchResolvedPrices([affectedEntityId]);
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────
final pricingProvider = StateNotifierProvider<PricingNotifier, PricingState>((
  ref,
) {
  final repo = ref.watch(pricingRepositoryProvider);
  return PricingNotifier(repo);
});

// Selector for a specific entity's resolved price
final resolvedPriceProvider =
    Provider.family<ResolvedPriceProjectionDto?, String>((ref, entityId) {
      final state = ref.watch(pricingProvider);
      return state.resolvedPrices[entityId];
    });

// Provider for fetching immutable history (not cached in notifier to avoid stale memory leaks)
final pricingHistoryFutureProvider =
    FutureProvider.family<List<PricingRecordDto>, String>((
      ref,
      entityId,
    ) async {
      final repo = ref.watch(pricingRepositoryProvider);
      final result = await repo.getPricingHistory(entityId);

      if (result is Success<List<PricingRecordDto>>) {
        return result.value;
      } else {
        throw Exception((result as Failure).error.message);
      }
    });
