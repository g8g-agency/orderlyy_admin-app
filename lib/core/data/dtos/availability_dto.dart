class AvailabilityRuleDto {
  final String id;
  final String tenantId;
  final String entityId;
  final String entityType; // e.g., 'menu_item', 'category'
  
  // Note: UI may configure raw strings/rules, but backend owns parsing & evaluating them.
  final String ruleType; // e.g. 'always', 'schedule', 'custom'
  final Map<String, dynamic>? scheduleConfig; // Opaque config interpreted by backend
  
  final int versionNum;
  final DateTime createdAt;

  const AvailabilityRuleDto({
    required this.id,
    required this.tenantId,
    required this.entityId,
    required this.entityType,
    required this.ruleType,
    this.scheduleConfig,
    required this.versionNum,
    required this.createdAt,
  });

  factory AvailabilityRuleDto.fromJson(Map<String, dynamic> json) {
    return AvailabilityRuleDto(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      entityId: json['entity_id'] as String,
      entityType: json['entity_type'] as String,
      ruleType: json['rule_type'] as String,
      scheduleConfig: json['schedule_config'] as Map<String, dynamic>?,
      versionNum: json['version_num'] as int? ?? 1,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'tenant_id': tenantId,
    'entity_id': entityId,
    'entity_type': entityType,
    'rule_type': ruleType,
    'schedule_config': scheduleConfig,
    'version_num': versionNum, // sent for OCC
  };
}

/// A projection representing the currently active availability for an entity.
/// Computed exclusively by the backend (timezone, precedence, overlapping windows).
class ResolvedAvailabilityProjectionDto {
  final String entityId;
  final bool isCurrentlyAvailable;
  
  // Frontend purely displays this localized, NO evaluation logic locally.
  final DateTime? availableUntil;
  final DateTime? nextAvailableAt;

  const ResolvedAvailabilityProjectionDto({
    required this.entityId,
    required this.isCurrentlyAvailable,
    this.availableUntil,
    this.nextAvailableAt,
  });

  factory ResolvedAvailabilityProjectionDto.fromJson(Map<String, dynamic> json) {
    return ResolvedAvailabilityProjectionDto(
      entityId: json['entity_id'] as String,
      isCurrentlyAvailable: json['is_currently_available'] as bool? ?? false,
      availableUntil: json['available_until'] != null ? DateTime.parse(json['available_until'] as String) : null,
      nextAvailableAt: json['next_available_at'] != null ? DateTime.parse(json['next_available_at'] as String) : null,
    );
  }
}
