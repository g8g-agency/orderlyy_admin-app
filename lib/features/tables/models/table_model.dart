class RestaurantTable {
  final String id;
  final String tenantId;
  final String branchId;
  final String tableNumber;
  final String? tableName;
  final DateTime? deletedAt;

  const RestaurantTable({
    required this.id,
    required this.tenantId,
    required this.branchId,
    required this.tableNumber,
    this.tableName,
    this.deletedAt,
  });

  String get qrUrl =>
      'https://app.orderlyy.com/t/$id'; // permanent, never changes

  factory RestaurantTable.fromJson(Map<String, dynamic> json) =>
      RestaurantTable(
        id: json['id'] as String,
        tenantId: json['tenant_id'] as String,
        branchId: json['branch_id'] as String,
        tableNumber: json['table_number'].toString(),
        tableName: json['display_name'] as String?,
        deletedAt: json['deleted_at'] != null
            ? DateTime.parse(json['deleted_at'] as String)
            : null,
      );
}
