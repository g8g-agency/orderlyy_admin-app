import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'runtime_switch_state.dart';
import '../providers/branch_context_service.dart';

final runtimeSwitchStateProvider = StateProvider<RuntimeSwitchState>(
  (ref) => RuntimeSwitchState.idle,
);

class BranchRuntimeCoordinator {
  final Ref _ref;

  BranchRuntimeCoordinator(this._ref);

  Future<void> switchBranch(String newBranchId) async {
    debugPrint('[BranchRuntimeCoordinator] Switching branch to $newBranchId');

    _ref.read(runtimeSwitchStateProvider.notifier).state =
        RuntimeSwitchState.switching;

    try {
      // Simplification Strategy: Directly update currentBranchProvider
      // Without locks, without freezing, without realtime teardown, without epoch enforcement
      await _ref.read(currentBranchProvider.notifier).setBranch(newBranchId);

      // We can also invalidate data providers here if needed,
      // but currentBranchProvider changing should already trigger downstream invalidation
      // if they watch it correctly.
    } catch (e, st) {
      debugPrint('[BranchRuntimeCoordinator] Switch failed: $e\n$st');
      _ref.read(runtimeSwitchStateProvider.notifier).state =
          RuntimeSwitchState.failed;
    } finally {
      _ref.read(runtimeSwitchStateProvider.notifier).state =
          RuntimeSwitchState.idle;
    }
  }
}

final branchRuntimeCoordinatorProvider = Provider<BranchRuntimeCoordinator>((
  ref,
) {
  return BranchRuntimeCoordinator(ref);
});
