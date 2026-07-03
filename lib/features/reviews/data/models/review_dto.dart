class ReviewDto {
  final String id;
  final String tenantId;
  final String branchId;
  final String orderId;
  final String? phone;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  
  // Joined fields
  final String? tableId;

  const ReviewDto({
    required this.id,
    required this.tenantId,
    required this.branchId,
    required this.orderId,
    this.phone,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.tableId,
  });

  factory ReviewDto.fromJson(Map<String, dynamic> json) {
    String? tableId;
    
    // Extract table_id from joined orders
    if (json['orders'] != null && json['orders'] is Map) {
      final orders = json['orders'] as Map<String, dynamic>;
      tableId = orders['table_id'] as String?;
    }

    return ReviewDto(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      branchId: json['branch_id'] as String,
      orderId: json['order_id'] as String,
      phone: json['phone'] as String?,
      rating: json['rating'] as int? ?? 5,
      comment: json['comment'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString()).toLocal()
          : DateTime.now(),
      tableId: tableId,
    );
  }
}
