import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/repositories/runtime_observability_repository.dart';
import '../../data/dtos/runtime_snapshot_dto.dart';

final runtimeHealthProvider =
    StateNotifierProvider<
      RuntimeHealthNotifier,
      AsyncValue<RuntimeSnapshotDto>
    >((ref) {
      final repository = ref.watch(runtimeObservabilityRepositoryProvider);
      return RuntimeHealthNotifier(repository);
    });

class RuntimeHealthNotifier
    extends StateNotifier<AsyncValue<RuntimeSnapshotDto>> {
  final RuntimeObservabilityRepository _repository;
  Timer? _pollingTimer;

  RuntimeHealthNotifier(this._repository) : super(const AsyncValue.loading()) {
    _startPolling();
  }

  void _startPolling() {
    _fetchSnapshot();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _fetchSnapshot(),
    );
  }

  Future<void> _fetchSnapshot() async {
    final result = await _repository.getHealthSnapshot();
    if (result is Success<RuntimeSnapshotDto>) {
      state = AsyncValue.data(result.value);
    } else if (result is Failure<RuntimeSnapshotDto>) {
      // Don't override existing data with a transient network error if we can help it
      if (!state.hasValue) {
        state = AsyncValue.error(result.error, StackTrace.current);
      }
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}
