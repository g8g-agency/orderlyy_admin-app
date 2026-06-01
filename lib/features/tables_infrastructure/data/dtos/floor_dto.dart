class FloorDto {
  final String id;
  final String tenantId;
  final String branchId;
  final String name;
  final int sortOrder;
  final int versionNum;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FloorDto({
    required this.id,
    required this.tenantId,
    required this.branchId,
    required this.name,
    required this.sortOrder,
    this.versionNum = 1,
    this.createdAt,
    this.updatedAt,
  });

  FloorDto copyWith({
    String? id,
    String? tenantId,
    String? branchId,
    String? name,
    int? sortOrder,
    int? versionNum,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FloorDto(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      branchId: branchId ?? this.branchId,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      versionNum: versionNum ?? this.versionNum,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory FloorDto.fromJson(Map<String, dynamic> json) => FloorDto(
        id: json['id'] as String,
        tenantId: json['tenant_id'] as String,
        branchId: json['branch_id'] as String,
        name: json['name'] as String,
        sortOrder: json['sort_order'] as int? ?? 0,
        versionNum: json['version_num'] as int? ?? 1,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenant_id': tenantId,
        'branch_id': branchId,
        'name': name,
        'sort_order': sortOrder,
        'version_num': versionNum,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };
}
