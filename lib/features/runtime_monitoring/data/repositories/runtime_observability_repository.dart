import '../../../../core/network/api_exception.dart';
import '../dtos/runtime_event_dto.dart';
import '../dtos/runtime_incident_dto.dart';
import '../dtos/runtime_snapshot_dto.dart';
import '../api/api_runtime_observability_repository.dart' show GraphCursorResponse;

abstract class RuntimeObservabilityRepository {
  /// Fetches a high-level point-in-time snapshot of the runtime health
  Future<Result<RuntimeSnapshotDto>> getHealthSnapshot();

  /// Subscribes to the live realtime telemetry stream
  Stream<RuntimeEventDto> streamRuntimeEvents();

  /// Fetches recent events from the buffer
  Future<Result<List<RuntimeEventDto>>> getEventBuffer();

  /// Fetches an individual graph node
  Future<Result<RuntimeEventDto>> getGraphNode(String correlationId);

  /// Fetches children of a graph node
  Future<Result<GraphCursorResponse>> getGraphChildren(String correlationId, {int limit = 20, int cursor = 0});

  /// Executes a simulated chaos event for certification validation
  Future<Result<void>> simulateChaosEvent({
    required String testName,
    required Map<String, dynamic> payload,
  });

  /// Executes a certification scenario
  Future<Result<Map<String, dynamic>>> executeCertificationScenario(String scenarioId);

  /// Fetches a paginated window of a replay trace
  Future<Result<Map<String, dynamic>>> getReplayTraceWindow(String runId, {int startIndex = 0, int endIndex = 50, String direction = 'asc'});
}
