import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/crud/mutation_handler.dart';
import '../../../../core/auth/app_auth_provider.dart';
import '../../domain/entities/branch_entity.dart';
import 'branch_providers.dart';

class BranchMutationNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  BranchMutationNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> createBranch(
    String name,
    String timezone, {
    String? address,
    String? phone,
    String? email,
    String? region,
  }) async {
    state = const AsyncValue.loading();
    final ctx = _ref.read(appContextProvider);
    if (ctx == null) {
      state = AsyncValue.error('No tenant context', StackTrace.current);
      return;
    }

    try {
      final repo = _ref.read(branchRepositoryProvider);
      final handler = _ref.read(mutationHandlerProvider);

      await handler.executeOptimistic<BranchEntity>(
        operationName: 'CreateBranch',
        optimisticUpdate: () async {
          // In a real optimistic scenario, we could prepend a dummy entity.
          // For now, we just proceed.
        },
        networkCall: () => repo.createBranch(
          tenantId: ctx.tenant.id,
          name: name,
          timezone: timezone,
          address: address,
          phone: phone,
          email: email,
          region: region,
        ),
        onSuccess: (result) async {
          _ref.invalidate(branchesProvider);
          state = const AsyncValue.data(null);
        },
        rollback: (error) async {
          state = AsyncValue.error(error, StackTrace.current);
        },
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateBranch(
    String branchId,
    String name,
    String timezone,
    BranchStatus status, {
    String? address,
    String? phone,
    String? email,
    String? region,
  }) async {
    state = const AsyncValue.loading();
    final ctx = _ref.read(appContextProvider);
    if (ctx == null) {
      state = AsyncValue.error('No tenant context', StackTrace.current);
      return;
    }

    try {
      final repo = _ref.read(branchRepositoryProvider);
      final handler = _ref.read(mutationHandlerProvider);

      await handler.executeOptimistic<BranchEntity>(
        operationName: 'UpdateBranch',
        optimisticUpdate: () async {
          // Optimistic UI updates
        },
        networkCall: () => repo.updateBranch(
          tenantId: ctx.tenant.id,
          branchId: branchId,
          name: name,
          timezone: timezone,
          status: status,
          address: address,
          phone: phone,
          email: email,
          region: region,
        ),
        onSuccess: (result) async {
          _ref.invalidate(branchesProvider);
          state = const AsyncValue.data(null);
        },
        rollback: (error) async {
          state = AsyncValue.error(error, StackTrace.current);
        },
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteBranch(String branchId) async {
    state = const AsyncValue.loading();
    final ctx = _ref.read(appContextProvider);
    if (ctx == null) {
      state = AsyncValue.error('No tenant context', StackTrace.current);
      return;
    }

    try {
      final repo = _ref.read(branchRepositoryProvider);
      final handler = _ref.read(mutationHandlerProvider);

      await handler.executeOptimistic<void>(
        operationName: 'DeleteBranch',
        optimisticUpdate: () async {},
        networkCall: () => repo.deleteBranch(ctx.tenant.id, branchId),
        onSuccess: (_) async {
          _ref.invalidate(branchesProvider);
          state = const AsyncValue.data(null);
        },
        rollback: (error) async {
          state = AsyncValue.error(error, StackTrace.current);
        },
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final branchMutationProvider =
    StateNotifierProvider<BranchMutationNotifier, AsyncValue<void>>((ref) {
  return BranchMutationNotifier(ref);
});
