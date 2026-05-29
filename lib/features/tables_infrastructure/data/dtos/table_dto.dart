class TableDto {
  final String id;
  final String tenantId;
  final String branchId;
  final String tableNumber;
  final String? displayName;
  final int capacity;
  final String? qrCodeToken;
  final String? sectionId;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TableDto({
    required this.id,
    required this.tenantId,
    required this.branchId,
    required this.tableNumber,
    this.displayName,
    required this.capacity,
    this.qrCodeToken,
    this.sectionId,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  TableDto copyWith({
    String? id,
    String? tenantId,
    String? branchId,
    String? tableNumber,
    String? displayName,
    int? capacity,
    String? qrCodeToken,
    String? sectionId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TableDto(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      branchId: branchId ?? this.branchId,
      tableNumber: tableNumber ?? this.tableNumber,
      displayName: displayName ?? this.displayName,
      capacity: capacity ?? this.capacity,
      qrCodeToken: qrCodeToken ?? this.qrCodeToken,
      sectionId: sectionId ?? this.sectionId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory TableDto.fromJson(Map<String, dynamic> json) => TableDto(
    id: json['id'] as String,
    tenantId: json['tenant_id'] as String,
    branchId: json['branch_id'] as String,
    tableNumber: json['table_number'] as String,
    displayName: json['display_name'] as String?,
    capacity: json['capacity'] as int,
    qrCodeToken: json['qr_code_token'] as String?,
    sectionId: json['section_id'] as String?,
    isActive: json['is_active'] as bool? ?? true,
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
    'table_number': tableNumber,
    'display_name': displayName,
    'capacity': capacity,
    'qr_code_token': qrCodeToken,
    'section_id': sectionId,
    'is_active': isActive,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}
