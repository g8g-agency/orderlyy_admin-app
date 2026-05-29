class RuntimeEventDto {
  final String eventType;
  final String timestamp;
  final String? surface;
  final String? domain;
  final String correlationId;
  final String? incidentId;
  final String? parentCorrelationId;
  final String? replayChainId;
  final String? certificationRunId;
  final String? mutationId;
  final String severity;
  final String? aggregateId;
  final int? sequence;
  final Map<String, dynamic> metadata;

  RuntimeEventDto({
    required this.eventType,
    required this.timestamp,
    this.surface,
    this.domain,
    required this.correlationId,
    this.incidentId,
    this.parentCorrelationId,
    this.replayChainId,
    this.certificationRunId,
    this.mutationId,
    required this.severity,
    this.aggregateId,
    this.sequence,
    required this.metadata,
  });

  factory RuntimeEventDto.fromJson(Map<String, dynamic> json) {
    // Extract known top-level fields and put the rest in metadata
    final metadata = Map<String, dynamic>.from(json);
    metadata.remove('event_type');
    metadata.remove('timestamp');
    metadata.remove('surface');
    metadata.remove('domain');

    metadata.remove('correlation_id');
    metadata.remove('incident_id');
    metadata.remove('parent_correlation_id');
    metadata.remove('replay_chain_id');
    metadata.remove('certification_run_id');
    metadata.remove('mutation_id');
    metadata.remove('severity');
    metadata.remove('aggregate_id');
    metadata.remove('sequence');

    return RuntimeEventDto(
      eventType: json['event_type'] as String? ?? 'UNKNOWN',
      timestamp: (json['event_timestamp'] ?? json['timestamp']) as String? ?? '',
      surface: json['runtime_surface'] as String?,
      domain: json['domain'] as String?,
      correlationId: json['correlation_id'] as String? ?? '',
      incidentId: json['incident_id'] as String?,
      parentCorrelationId: json['parent_correlation_id'] as String?,
      replayChainId: json['replay_chain_id'] as String?,
      certificationRunId: json['certification_run_id'] as String?,
      mutationId: json['mutation_id'] as String?,
      severity: json['severity'] as String? ?? 'INFO',
      aggregateId: json['aggregate_id'] as String?,
      sequence: json['sequence'] as int?,
      metadata: metadata,
    );
  }
}
