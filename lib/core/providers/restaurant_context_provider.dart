import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dtos/restaurant_context_dto.dart';
import '../data/api/api_restaurant_context_repository.dart';
import '../network/network_providers.dart';
import '../network/api_exception.dart';
import 'repository_providers.dart';

final restaurantContextRepositoryProvider =
    Provider<RestaurantContextRepository>((ref) {
      final dioClient = ref.watch(dioClientProvider);
      return ApiRestaurantContextRepository(dioClient);
    });

class RestaurantContextState {
  final bool isLoading;
  final String? error;
  final RestaurantContextDto? context;

  const RestaurantContextState({
    this.isLoading = false,
    this.error,
    this.context,
  });

  RestaurantContextState copyWith({
    bool? isLoading,
    String? error,
    RestaurantContextDto? context,
  }) {
    return RestaurantContextState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      context: context ?? this.context,
    );
  }
}

class RestaurantContextNotifier extends StateNotifier<RestaurantContextState> {
  final RestaurantContextRepository _repository;
  final Ref _ref;

  RestaurantContextNotifier(this._repository, this._ref)
    : super(const RestaurantContextState());

  Future<void> bootstrapContext({String? branchId}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.fetchContext(branchId: branchId);

    if (result is Success<RestaurantContextDto>) {
      state = state.copyWith(isLoading: false, context: result.value);
    } else if (result is Failure<RestaurantContextDto>) {
      state = state.copyWith(isLoading: false, error: result.error.message);

      // Invalidate session if context fails due to auth or permissions
      if (result.error.code == ApiErrorCode.unauthorized ||
          result.error.code == ApiErrorCode.forbidden) {
        _ref.read(authRepositoryProvider).signOut();
      }
    }
  }

  void clear() {
    state = const RestaurantContextState();
  }

  bool hasCapability(String code) {
    if (state.context == null) return false;
    return state.context!.capabilities.any((c) => c.code == code);
  }

  bool hasFeature(String featureKey) {
    if (state.context == null) return false;
    return state.context!.featureAccess.any(
      (f) => f.featureKey == featureKey && f.isEnabled,
    );
  }

  BranchDto? get activeBranch => state.context?.activeBranch;
  TenantDto? get activeTenant => state.context?.activeTenant;
}

final restaurantContextProvider =
    StateNotifierProvider<RestaurantContextNotifier, RestaurantContextState>((
      ref,
    ) {
      final repository = ref.watch(restaurantContextRepositoryProvider);
      return RestaurantContextNotifier(repository, ref);
    });

// Helper Providers for easy access
final activeBranchProvider = Provider<BranchDto?>((ref) {
  return ref.watch(restaurantContextProvider).context?.activeBranch;
});

final activeTenantProvider = Provider<TenantDto?>((ref) {
  return ref.watch(restaurantContextProvider).context?.activeTenant;
});
