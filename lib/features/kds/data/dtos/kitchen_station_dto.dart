class KitchenStationDto {
  final String id;
  final String tenantId;
  final String branchId;
  final String name;
  final String? description;
  final bool isDefault;
  final bool isActive;
  final int displayOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const KitchenStationDto({
    required this.id,
    required this.tenantId,
    required this.branchId,
    required this.name,
    this.description,
    required this.isDefault,
    required this.isActive,
    required this.displayOrder,
    this.createdAt,
    this.updatedAt,
  });

  factory KitchenStationDto.fromJson(Map<String, dynamic> json) {
    return KitchenStationDto(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      branchId: json['branch_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      displayOrder: json['display_order'] as int? ?? 0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'tenant_id': tenantId,
      'branch_id': branchId,
      'name': name,
      if (description != null) 'description': description,
      'is_default': isDefault,
      'is_active': isActive,
      'display_order': displayOrder,
    };
  }

  KitchenStationDto copyWith({
    String? id,
    String? tenantId,
    String? branchId,
    String? name,
    String? description,
    bool? isDefault,
    bool? isActive,
    int? displayOrder,
  }) {
    return KitchenStationDto(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      branchId: branchId ?? this.branchId,
      name: name ?? this.name,
      description: description ?? this.description,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
