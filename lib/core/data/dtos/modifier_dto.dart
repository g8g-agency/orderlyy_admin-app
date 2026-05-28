class ModifierGroupDto {
  final String id;
  final String tenantId;
  final String name;
  final String? description;
  final int minSelections;
  final int maxSelections;
  final bool isRequired;
  final bool isActive;
  final int versionNum;
  final DateTime? deletedAt;

  const ModifierGroupDto({
    required this.id,
    required this.tenantId,
    required this.name,
    this.description,
    required this.minSelections,
    required this.maxSelections,
    required this.isRequired,
    required this.isActive,
    required this.versionNum,
    this.deletedAt,
  });

  factory ModifierGroupDto.fromJson(Map<String, dynamic> json) {
    return ModifierGroupDto(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      minSelections: json['min_selections'] as int? ?? 0,
      maxSelections: json['max_selections'] as int? ?? 1,
      isRequired: json['is_required'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      versionNum: json['version_num'] as int? ?? 1,
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'tenant_id': tenantId,
    'name': name,
    'description': description,
    'min_selections': minSelections,
    'max_selections': maxSelections,
    'is_required': isRequired,
    'is_active': isActive,
    'version_num': versionNum, // sent for OCC
  };
}

class ModifierItemDto {
  final String id;
  final String tenantId;
  final String groupId; // Normalized reference to ModifierGroupDto
  final String name;
  final String? description;
  final bool isAvailable;
  final int versionNum;
  final DateTime? deletedAt;

  // PRICING IS NOT OWNED BY MODIFIERS.
  // We do NOT compute modifier pricing, combos, etc. here.
  // The backend pricing engine resolves that separately.

  const ModifierItemDto({
    required this.id,
    required this.tenantId,
    required this.groupId,
    required this.name,
    this.description,
    required this.isAvailable,
    required this.versionNum,
    this.deletedAt,
  });

  factory ModifierItemDto.fromJson(Map<String, dynamic> json) {
    return ModifierItemDto(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      groupId: json['group_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      isAvailable: json['is_available'] as bool? ?? true,
      versionNum: json['version_num'] as int? ?? 1,
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'tenant_id': tenantId,
    'group_id': groupId,
    'name': name,
    'description': description,
    'is_available': isAvailable,
    'version_num': versionNum, // sent for OCC
  };
}
