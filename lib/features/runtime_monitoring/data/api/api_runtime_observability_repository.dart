import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../dtos/runtime_event_dto.dart';
import '../dtos/runtime_snapshot_dto.dart';
import '../repositories/runtime_observability_repository.dart';

class GraphCursorResponse {
  final List<RuntimeEventDto> nodes;
  final String? nextCursor;
  final bool hasMore;

  GraphCursorResponse({
    required this.nodes,
    this.nextCursor,
    required this.hasMore,
  });

  factory GraphCursorResponse.fromJson(Map<String, dynamic> json) {
    return GraphCursorResponse(
      nodes: (json['nodes'] as List).map((e) => RuntimeEventDto.fromJson(e)).toList(),
      nextCursor: json['nextCursor'],
      hasMore: json['hasMore'] ?? false,
    );
  }
}

class ApiRuntimeObservabilityRepository
    implements RuntimeObservabilityRepository {
  final DioClient _dioClient;
  final SupabaseClient _supabase;
  RealtimeChannel? _telemetryChannel;
  final _eventStreamController = StreamController<RuntimeEventDto>.broadcast();

  ApiRuntimeObservabilityRepository(this._dioClient, this._supabase);

  @override
  Future<Result<RuntimeSnapshotDto>> getHealthSnapshot() async {
    try {
      final response = await _dioClient.get(
        '${ApiConstants.apiVersion}/runtime/observability/snapshot',
      );

      if (response.data['success'] == true) {
        return Success(RuntimeSnapshotDto.fromJson(response.data['data']));
      } else {
        final errorMessage =
            response.data['error']?['message'] ??
            'Failed to fetch runtime snapshot';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<RuntimeEventDto>>> getEventBuffer() async {
    try {
      final response = await _dioClient.get(
        '${ApiConstants.apiVersion}/runtime/observability/events',
      );

      if (response.data['success'] == true) {
        final data = response.data['data'] as List<dynamic>? ?? [];
        final events = data
            .map(
              (json) => RuntimeEventDto.fromJson(json as Map<String, dynamic>),
            )
            .toList();
        return Success(events);
      } else {
        final errorMessage =
            response.data['error']?['message'] ??
            'Failed to fetch runtime events';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  @override
  Stream<RuntimeEventDto> streamRuntimeEvents() {
    if (_telemetryChannel == null) {
      _telemetryChannel = _supabase.channel('runtime_telemetry_stream');

      _telemetryChannel!
          .onBroadcast(
            event: 'telemetry_event',
            callback: (payload) {
              try {
                final eventDto = RuntimeEventDto.fromJson(payload);
                _eventStreamController.add(eventDto);
              } catch (e) {
                // Ignore malformed broadcast events
              }
            },
          )
          .subscribe();
    }

    return _eventStreamController.stream;
  }

  @override
  Future<Result<void>> simulateChaosEvent({
    required String testName,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final response = await _dioClient.post(
        '${ApiConstants.apiVersion}/runtime/certify/simulate',
        data: {'test': testName, 'payload': payload},
      );

      if (response.data['success'] == true) {
        return const Success(null);
      } else {
        final errorMessage =
            response.data['error']?['message'] ??
            'Failed to simulate chaos event';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> executeCertificationScenario(String scenarioId) async {
    try {
      final response = await _dioClient.post(
        '${ApiConstants.apiVersion}/runtime/observability/certify/$scenarioId',
      );

      if (response.data['success'] == true) {
        return Success(response.data['data']);
      } else {
        final errorMessage =
            response.data['error']?['message'] ??
            'Failed to execute certification scenario';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getReplayTraceWindow(String runId, {int startIndex = 0, int endIndex = 50, String direction = 'asc'}) async {
    try {
      final response = await _dioClient.get(
        '${ApiConstants.apiVersion}/runtime/observability/replay/$runId/window',
        queryParameters: {
          'start_index': startIndex,
          'end_index': endIndex,
          'direction': direction,
        },
      );

      if (response.data['success'] == true) {
        return Success(response.data['data']);
      } else {
        final errorMessage =
            response.data['error']?['message'] ??
            'Failed to fetch replay trace window';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Result<RuntimeEventDto>> getGraphNode(String correlationId) async {
    try {
      final response = await _dioClient.get(
        '${ApiConstants.apiVersion}/runtime/observability/graph/node/$correlationId',
      );
      if (response.data['success'] == true) {
        return Success(RuntimeEventDto.fromJson(response.data['data']));
      } else {
        final errorMessage =
            response.data['error']?['message'] ?? 'Failed to load graph node';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Result<GraphCursorResponse>> getGraphChildren(
    String correlationId, {
    int limit = 20,
    int cursor = 0,
  }) async {
    try {
      final response = await _dioClient.get(
        '${ApiConstants.apiVersion}/runtime/observability/graph/children/$correlationId',
        queryParameters: {'limit': limit, 'cursor': cursor},
      );
      if (response.data['success'] == true) {
        return Success(GraphCursorResponse.fromJson(response.data['data']));
      } else {
        final errorMessage =
            response.data['error']?['message'] ?? 'Failed to load graph children';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }
}
