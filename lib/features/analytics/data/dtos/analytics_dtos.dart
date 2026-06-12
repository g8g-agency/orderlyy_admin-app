class SalesDigestDto {
  final double totalRevenue;
  final int totalOrders;
  final double averageOrderValue;
  final double totalDiscount;

  const SalesDigestDto({
    required this.totalRevenue,
    required this.totalOrders,
    required this.averageOrderValue,
    required this.totalDiscount,
  });
}

class DashboardAnalyticsDto {
  final SalesDigestDto salesDigest;
  final List<PopularItemDto> popularItems;
  final List<HourlyTrendDto> hourlyTrends;
  final String generatedAt;

  const DashboardAnalyticsDto({
    required this.salesDigest,
    required this.popularItems,
    required this.hourlyTrends,
    required this.generatedAt,
  });

  // Maps flat backend response to nested DTO
  factory DashboardAnalyticsDto.fromBackend(Map<String, dynamic> json) {
    return DashboardAnalyticsDto(
      salesDigest: SalesDigestDto(
        totalRevenue: (json['total_revenue_amount'] as num?)?.toDouble() ?? 0.0,
        totalOrders: json['total_order_count'] as int? ?? 0,
        averageOrderValue: (json['average_order_value_amount'] as num?)?.toDouble() ?? 0.0,
        totalDiscount: (json['total_discount_amount'] as num?)?.toDouble() ?? 0.0,
      ),
      popularItems: [],   // backend doesn't provide yet — empty for pilot
      hourlyTrends: [],   // backend doesn't provide yet — empty for pilot
      generatedAt: json['generated_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }
}

class PopularItemDto {
  final String name;
  final int count;
  final double totalRevenue;

  const PopularItemDto({
    required this.name,
    required this.count,
    required this.totalRevenue,
  });
}

class HourlyTrendDto {
  final String hour;
  final int orderCount;

  const HourlyTrendDto({required this.hour, required this.orderCount});
}
