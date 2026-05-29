import 'runtime_domain_health.dart';

class DivergenceAlertDto {
  final String incidentId;
  final String eventType;
  final String severity;
  final String? domain;
  final String runtimeSurface;
  final String timestamp;
  final int count;
  final Map<String, dynamic> metadata;

  DivergenceAlertDto({
    required this.incidentId,
    required this.eventType,
    required this.severity,
    this.domain,
    required this.runtimeSurface,
    required this.timestamp,
    required this.count,
    required this.metadata,
  });

  factory DivergenceAlertDto.fromJson(Map<String, dynamic> json) {
    return DivergenceAlertDto(
      incidentId: json['incident_id'] as String? ?? '',
      eventType: json['event_type'] as String? ?? '',
      severity: json['severity'] as String? ?? 'INFO',
      domain: json['domain'] as String?,
      runtimeSurface: json['runtime_surface'] as String? ?? 'UNKNOWN',
      timestamp: json['timestamp'] as String? ?? '',
      count: json['count'] as int? ?? 1,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }
}

class RuntimeInstabilitySnapshotDto {
  final int reconnectScore;
  final int mutationScore;
  final int projectionScore;
  final int transportScore;
  final int duplicateScore;
  final String overallHealth;

  RuntimeInstabilitySnapshotDto({
    required this.reconnectScore,
    required this.mutationScore,
    required this.projectionScore,
    required this.transportScore,
    required this.duplicateScore,
    required this.overallHealth,
  });

  factory RuntimeInstabilitySnapshotDto.fromJson(Map<String, dynamic> json) {
    return RuntimeInstabilitySnapshotDto(
      reconnectScore: json['reconnectScore'] as int? ?? 0,
      mutationScore: json['mutationScore'] as int? ?? 0,
      projectionScore: json['projectionScore'] as int? ?? 0,
      transportScore: json['transportScore'] as int? ?? 0,
      duplicateScore: json['duplicateScore'] as int? ?? 0,
      overallHealth: json['overallHealth'] as String? ?? 'HEALTHY',
    );
  }
}

class SurfaceConvergenceStateDto {
  final String surface;
  final int watermark;
  final int lag;
  final bool isStale;
  final String lastSeenTimestamp;
  final int reconnectAttempts;

  SurfaceConvergenceStateDto({
    required this.surface,
    required this.watermark,
    required this.lag,
    required this.isStale,
    required this.lastSeenTimestamp,
    required this.reconnectAttempts,
  });

  factory SurfaceConvergenceStateDto.fromJson(Map<String, dynamic> json) {
    return SurfaceConvergenceStateDto(
      surface: json['surface'] as String? ?? '',
      watermark: json['watermark'] as int? ?? 0,
      lag: json['lag'] as int? ?? 0,
      isStale: json['isStale'] as bool? ?? false,
      lastSeenTimestamp: json['lastSeenTimestamp'] as String? ?? '',
      reconnectAttempts: json['reconnectAttempts'] as int? ?? 0,
    );
  }
}

class RuntimeConvergenceSnapshotDto {
  final Map<String, SurfaceConvergenceStateDto> surfaces;

  RuntimeConvergenceSnapshotDto({required this.surfaces});

  factory RuntimeConvergenceSnapshotDto.fromJson(Map<String, dynamic> json) {
    final surfacesJson = json['surfaces'] as Map<String, dynamic>? ?? {};
    final surfacesMap = <String, SurfaceConvergenceStateDto>{};
    surfacesJson.forEach((key, value) {
      if (value != null) {
        surfacesMap[key] = SurfaceConvergenceStateDto.fromJson(value as Map<String, dynamic>);
      }
    });
    return RuntimeConvergenceSnapshotDto(surfaces: surfacesMap);
  }
}

class RuntimeSnapshotDto {
  final String transportState;
  final String? lastConnectionId;
  final bool isDegraded;
  final bool isRecovering;
  final bool isRealtimeConnected;
  final bool degradedPollingActive;
  final int reconnectAttempts;
  final int reconnectFailures;

  final int staleRejected;
  final int debounceCollapses;
  final int invalidationsEmitted;
  final int sequenceGaps;
  final int malformedEvents;

  final int mutationSubmitted;
  final int mutationAcknowledged;
  final int mutationConfirmed;
  final int mutationStalled;
  final int mutationFailed;
  final int mutationRejected;

  final int bufferSize;
  final int droppedEvents;
  final int bufferOverflows;

  final Map<String, RuntimeDomainHealth> domains;
  final List<DivergenceAlertDto> activeAlerts;
  final RuntimeInstabilitySnapshotDto? instability;
  final RuntimeConvergenceSnapshotDto? convergence;

  RuntimeSnapshotDto({
    required this.transportState,
    this.lastConnectionId,
    required this.isDegraded,
    required this.isRecovering,
    required this.isRealtimeConnected,
    required this.degradedPollingActive,
    required this.reconnectAttempts,
    required this.reconnectFailures,
    required this.staleRejected,
    required this.debounceCollapses,
    required this.invalidationsEmitted,
    required this.sequenceGaps,
    required this.malformedEvents,
    required this.mutationSubmitted,
    required this.mutationAcknowledged,
    required this.mutationConfirmed,
    required this.mutationStalled,
    required this.mutationFailed,
    required this.mutationRejected,
    required this.bufferSize,
    required this.droppedEvents,
    required this.bufferOverflows,
    required this.domains,
    this.activeAlerts = const [],
    this.instability,
    this.convergence,
  });

  factory RuntimeSnapshotDto.fromJson(Map<String, dynamic> json) {
    final domainsJson = json['domains'] as Map<String, dynamic>? ?? {};
    final domainsMap = <String, RuntimeDomainHealth>{};

    domainsJson.forEach((key, value) {
      if (value != null) {
        domainsMap[key] = RuntimeDomainHealth.fromJson(
          value as Map<String, dynamic>,
        );
      }
    });

    final activeAlertsJson = json['activeAlerts'] as List<dynamic>? ?? [];
    final activeAlerts = activeAlertsJson
        .map((e) => DivergenceAlertDto.fromJson(e as Map<String, dynamic>))
        .toList();

    RuntimeInstabilitySnapshotDto? instability;
    if (json['instability'] != null) {
      instability = RuntimeInstabilitySnapshotDto.fromJson(
          json['instability'] as Map<String, dynamic>);
    }

    RuntimeConvergenceSnapshotDto? convergence;
    if (json['convergence'] != null) {
      convergence = RuntimeConvergenceSnapshotDto.fromJson(
          json['convergence'] as Map<String, dynamic>);
    }

    return RuntimeSnapshotDto(
      transportState: json['transportState'] as String? ?? 'DISCONNECTED',
      lastConnectionId: json['lastConnectionId'] as String?,
      isDegraded: json['isDegraded'] as bool? ?? false,
      isRecovering: json['isRecovering'] as bool? ?? false,
      isRealtimeConnected: json['isRealtimeConnected'] as bool? ?? false,
      degradedPollingActive: json['degradedPollingActive'] as bool? ?? false,
      reconnectAttempts: json['reconnectAttempts'] as int? ?? 0,
      reconnectFailures: json['reconnectFailures'] as int? ?? 0,
      staleRejected: json['staleRejected'] as int? ?? 0,
      debounceCollapses: json['debounceCollapses'] as int? ?? 0,
      invalidationsEmitted: json['invalidationsEmitted'] as int? ?? 0,
      sequenceGaps: json['sequenceGaps'] as int? ?? 0,
      malformedEvents: json['malformedEvents'] as int? ?? 0,
      mutationSubmitted: json['mutationSubmitted'] as int? ?? 0,
      mutationAcknowledged: json['mutationAcknowledged'] as int? ?? 0,
      mutationConfirmed: json['mutationConfirmed'] as int? ?? 0,
      mutationStalled: json['mutationStalled'] as int? ?? 0,
      mutationFailed: json['mutationFailed'] as int? ?? 0,
      mutationRejected: json['mutationRejected'] as int? ?? 0,
      bufferSize: json['bufferSize'] as int? ?? 0,
      droppedEvents: json['droppedEvents'] as int? ?? 0,
      bufferOverflows: json['bufferOverflows'] as int? ?? 0,
      domains: domainsMap,
      activeAlerts: activeAlerts,
      instability: instability,
      convergence: convergence,
    );
  }
}
