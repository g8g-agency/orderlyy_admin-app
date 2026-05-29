class RuntimeIncidentDto {
  final String incidentId;
  final String severity;
  final String status;
  final String? domain;
  final String? surface;
  final String triggeredAt;
  final String? resolvedAt;
  final String? correlationId;
  final String? rootEventType;
  final Map<String, dynamic> metadata;

  RuntimeIncidentDto({
    required this.incidentId,
    required this.severity,
    required this.status,
    this.domain,
    this.surface,
    required this.triggeredAt,
    this.resolvedAt,
    this.correlationId,
    this.rootEventType,
    required this.metadata,
  });

  factory RuntimeIncidentDto.fromJson(Map<String, dynamic> json) {
    final metadata = Map<String, dynamic>.from(json);
    metadata.remove('incident_id');
    metadata.remove('severity');
    metadata.remove('status');
    metadata.remove('domain');
    metadata.remove('surface');
    metadata.remove('triggered_at');
    metadata.remove('resolved_at');
    metadata.remove('correlation_id');
    metadata.remove('root_event_type');

    return RuntimeIncidentDto(
      incidentId: json['incident_id'] as String? ?? '',
      severity: json['severity'] as String? ?? 'INFO',
      status: json['status'] as String? ?? 'OPEN',
      domain: json['domain'] as String?,
      surface: json['surface'] as String?,
      triggeredAt: json['triggered_at'] as String? ?? '',
      resolvedAt: json['resolved_at'] as String?,
      correlationId: json['correlation_id'] as String?,
      rootEventType: json['root_event_type'] as String?,
      metadata: metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'incident_id': incidentId,
        'severity': severity,
        'status': status,
        if (domain != null) 'domain': domain,
        if (surface != null) 'surface': surface,
        'triggered_at': triggeredAt,
        if (resolvedAt != null) 'resolved_at': resolvedAt,
        if (correlationId != null) 'correlation_id': correlationId,
        if (rootEventType != null) 'root_event_type': rootEventType,
        ...metadata,
      };
}
