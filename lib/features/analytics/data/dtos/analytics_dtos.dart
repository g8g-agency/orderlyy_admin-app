class SalesDigestDto {
  final double totalRevenue;
  final int totalOrders;
  final int pendingOrders;

  const SalesDigestDto({
    required this.totalRevenue,
    required this.totalOrders,
    required this.pendingOrders,
  });

  factory SalesDigestDto.fromJson(Map<String, dynamic> json) => SalesDigestDto(
        totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
        totalOrders: json['totalOrders'] as int? ?? 0,
        pendingOrders: json['pendingOrders'] as int? ?? 0,
      );
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

  factory PopularItemDto.fromJson(Map<String, dynamic> json) => PopularItemDto(
        name: json['name'] as String? ?? 'Unknown',
        count: json['count'] as int? ?? 0,
        totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      );
}

class HourlyTrendDto {
  final String hour;
  final int orderCount;

  const HourlyTrendDto({
    required this.hour,
    required this.orderCount,
  });

  factory HourlyTrendDto.fromJson(Map<String, dynamic> json) => HourlyTrendDto(
        hour: json['hour'] as String? ?? '00:00',
        orderCount: json['orderCount'] as int? ?? 0,
      );
}

class DashboardAnalyticsDto {
  final SalesDigestDto salesDigest;
  final List<PopularItemDto> popularItems;
  final List<HourlyTrendDto> hourlyTrends;

  const DashboardAnalyticsDto({
    required this.salesDigest,
    required this.popularItems,
    required this.hourlyTrends,
  });

  factory DashboardAnalyticsDto.fromJson(Map<String, dynamic> json) {
    return DashboardAnalyticsDto(
      salesDigest: SalesDigestDto.fromJson(json['salesDigest'] as Map<String, dynamic>? ?? {}),
      popularItems: (json['popularItems'] as List<dynamic>?)
              ?.map((e) => PopularItemDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      hourlyTrends: (json['hourlyTrends'] as List<dynamic>?)
              ?.map((e) => HourlyTrendDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
