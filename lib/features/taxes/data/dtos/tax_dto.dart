class TaxProfileDto {
  final String id;
  final String tenantId;
  final String name;
  final String? description;
  final String calculationMode;
  final int priority;
  final bool isActive;
  final int versionNum;
  final int effectiveBasisPoints;

  const TaxProfileDto({
    required this.id,
    required this.tenantId,
    required this.name,
    this.description,
    this.calculationMode = 'exclusive',
    this.priority = 100,
    this.isActive = true,
    this.versionNum = 1,
    this.effectiveBasisPoints = 0,
  });

  factory TaxProfileDto.fromJson(Map<String, dynamic> json) {
    return TaxProfileDto(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      calculationMode: json['calculation_mode'] as String? ?? 'exclusive',
      priority: json['priority'] as int? ?? 100,
      isActive: json['is_active'] as bool? ?? true,
      versionNum: json['version_num'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'tenant_id': tenantId,
      'name': name,
      if (description != null) 'description': description,
      'calculation_mode': calculationMode,
      'priority': priority,
      'is_active': isActive,
      'version_num': versionNum,
    };
  }

  TaxProfileDto copyWith({
    String? id,
    String? tenantId,
    String? name,
    String? description,
    String? calculationMode,
    int? priority,
    bool? isActive,
    int? versionNum,
    int? effectiveBasisPoints,
  }) {
    return TaxProfileDto(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      description: description ?? this.description,
      calculationMode: calculationMode ?? this.calculationMode,
      priority: priority ?? this.priority,
      isActive: isActive ?? this.isActive,
      versionNum: versionNum ?? this.versionNum,
      effectiveBasisPoints: effectiveBasisPoints ?? this.effectiveBasisPoints,
    );
  }
}

class TaxRateDto {
  final String id;
  final String tenantId;
  final String taxProfileId;
  final String name;
  final int rateBasisPoints;
  final int priority;
  final DateTime effectiveFrom;
  final DateTime? effectiveTo;
  final bool isActive;

  const TaxRateDto({
    required this.id,
    required this.tenantId,
    required this.taxProfileId,
    required this.name,
    required this.rateBasisPoints,
    this.priority = 100,
    required this.effectiveFrom,
    this.effectiveTo,
    this.isActive = true,
  });

  factory TaxRateDto.fromJson(Map<String, dynamic> json) {
    return TaxRateDto(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      taxProfileId: json['tax_profile_id'] as String,
      name: json['name'] as String,
      rateBasisPoints: json['rate_basis_points'] as int,
      priority: json['priority'] as int? ?? 100,
      effectiveFrom: DateTime.parse(json['effective_from'] as String),
      effectiveTo: json['effective_to'] != null ? DateTime.parse(json['effective_to'] as String) : null,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
