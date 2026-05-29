/// Represents a precomputed daily analytics projection.
/// The frontend NEVER computes these values from raw orders.
class DailySummaryProjectionDto {
  final String tenantId;
  final String? branchId;
  final DateTime date;

  // MINOR UNITS
  final int totalRevenueAmount;
  final int totalTaxAmount;
  final int totalDiscountAmount;

  final int totalOrderCount;
  final int averageOrderValueAmount;

  final DateTime generatedAt;

  const DailySummaryProjectionDto({
    required this.tenantId,
    this.branchId,
    required this.date,
    required this.totalRevenueAmount,
    required this.totalTaxAmount,
    required this.totalDiscountAmount,
    required this.totalOrderCount,
    required this.averageOrderValueAmount,
    required this.generatedAt,
  });

  factory DailySummaryProjectionDto.fromJson(Map<String, dynamic> json) {
    return DailySummaryProjectionDto(
      tenantId: json['tenant_id'] as String,
      branchId: json['branch_id'] as String?,
      date: DateTime.parse(json['date'] as String),
      totalRevenueAmount: (json['total_revenue_amount'] as num?)?.toInt() ?? 0,
      totalTaxAmount: (json['total_tax_amount'] as num?)?.toInt() ?? 0,
      totalDiscountAmount:
          (json['total_discount_amount'] as num?)?.toInt() ?? 0,
      totalOrderCount: (json['total_order_count'] as num?)?.toInt() ?? 0,
      averageOrderValueAmount:
          (json['average_order_value_amount'] as num?)?.toInt() ?? 0,
      generatedAt: DateTime.parse(json['generated_at'] as String),
    );
  }
}
