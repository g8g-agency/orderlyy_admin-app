import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'runtime_health_provider.dart';

class MutationPipelineMetrics {
  final int submitted;
  final int acknowledged;
  final int confirmed;
  final int stalled;
  final int failed;
  final int rejected;

  final double successRate;
  final bool hasStalled;

  MutationPipelineMetrics({
    required this.submitted,
    required this.acknowledged,
    required this.confirmed,
    required this.stalled,
    required this.failed,
    required this.rejected,
  }) : successRate = submitted > 0 ? (confirmed / submitted) * 100 : 100.0,
       hasStalled = stalled > 0;
}

final mutationPipelineProvider = Provider<MutationPipelineMetrics?>((ref) {
  final healthState = ref.watch(runtimeHealthProvider);

  return healthState.when(
    data: (snapshot) => MutationPipelineMetrics(
      submitted: snapshot.mutationSubmitted,
      acknowledged: snapshot.mutationAcknowledged,
      confirmed: snapshot.mutationConfirmed,
      stalled: snapshot.mutationStalled,
      failed: snapshot.mutationFailed,
      rejected: snapshot.mutationRejected,
    ),
    loading: () => null,
    error: (_, _) => null,
  );
});
