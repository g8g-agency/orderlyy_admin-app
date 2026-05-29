import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../data/repositories/runtime_observability_repository.dart';
import '../../../../core/network/api_exception.dart';

class CertificationState {
  final bool isSimulating;
  final String? lastResult;
  final String? lastRunId;
  final String? error;

  CertificationState({this.isSimulating = false, this.lastResult, this.lastRunId, this.error});

  CertificationState copyWith({
    bool? isSimulating,
    String? lastResult,
    String? lastRunId,
    String? error,
    bool clearError = false,
  }) {
    return CertificationState(
      isSimulating: isSimulating ?? this.isSimulating,
      lastResult: lastResult ?? this.lastResult,
      lastRunId: lastRunId ?? this.lastRunId,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final runtimeCertificationProvider =
    StateNotifierProvider<RuntimeCertificationNotifier, CertificationState>((
      ref,
    ) {
      final repository = ref.watch(runtimeObservabilityRepositoryProvider);
      return RuntimeCertificationNotifier(repository);
    });

class RuntimeCertificationNotifier extends StateNotifier<CertificationState> {
  final RuntimeObservabilityRepository _repository;

  RuntimeCertificationNotifier(this._repository) : super(CertificationState());
  Future<void> executeScenario(String scenarioId) async {
    state = state.copyWith(isSimulating: true, clearError: true);

    final result = await _repository.executeCertificationScenario(scenarioId);

    if (result is Success<Map<String, dynamic>>) {
      final data = result.value;
      final success = data['success'] as bool? ?? false;
      final scenarioIdResp = data['scenarioId'];
      final timestampResp = data['timestamp'];
      final tenantId = data['snapshot']?['tenant_id'] ?? '${scenarioIdResp}_$timestampResp';
      
      state = state.copyWith(
        isSimulating: false,
        lastResult: 'Scenario $scenarioId ${success ? 'PASSED' : 'FAILED'}',
        lastRunId: tenantId,
      );
    } else if (result is Failure<Map<String, dynamic>>) {
      state = state.copyWith(isSimulating: false, error: result.error.message);
    }
  }
}
