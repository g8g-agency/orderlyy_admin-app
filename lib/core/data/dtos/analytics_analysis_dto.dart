/// DTO for the deep business analytics analysis endpoint (/analytics/analysis)
class AnalyticsAnalysisDto {
  final String tenantId;
  final String branchId;
  final String startDate;
  final String endDate;
  final int totalOrders;
  final int totalRevenueMinor;
  final List<RevenueTrendDto> revenueTrends;
  final List<TopItemDto> topItems;
  final List<PeakHourDto> peakHours;
  final List<OrderSourceDto> orderSources;
  final DateTime generatedAt;

  const AnalyticsAnalysisDto({
    required this.tenantId,
    required this.branchId,
    required this.startDate,
    required this.endDate,
    required this.totalOrders,
    required this.totalRevenueMinor,
    required this.revenueTrends,
    required this.topItems,
    required this.peakHours,
    required this.orderSources,
    required this.generatedAt,
  });

  factory AnalyticsAnalysisDto.fromJson(Map<String, dynamic> json) {
    return AnalyticsAnalysisDto(
      tenantId: json['tenant_id'] as String? ?? '',
      branchId: json['branch_id'] as String? ?? '',
      startDate: json['start_date'] as String? ?? '',
      endDate: json['end_date'] as String? ?? '',
      totalOrders: (json['total_orders'] as num?)?.toInt() ?? 0,
      totalRevenueMinor: (json['total_revenue_minor'] as num?)?.toInt() ?? 0,
      revenueTrends: ((json['revenue_trends'] as List<dynamic>?) ?? [])
          .map((e) => RevenueTrendDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      topItems: ((json['top_items'] as List<dynamic>?) ?? [])
          .map((e) => TopItemDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      peakHours: ((json['peak_hours'] as List<dynamic>?) ?? [])
          .map((e) => PeakHourDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      orderSources: ((json['order_sources'] as List<dynamic>?) ?? [])
          .map((e) => OrderSourceDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      generatedAt: DateTime.tryParse(json['generated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class RevenueTrendDto {
  final String date;
  final int revenueMinor;
  final int orderCount;

  const RevenueTrendDto({
    required this.date,
    required this.revenueMinor,
    required this.orderCount,
  });

  factory RevenueTrendDto.fromJson(Map<String, dynamic> json) => RevenueTrendDto(
        date: json['date'] as String? ?? '',
        revenueMinor: (json['revenue_minor'] as num?)?.toInt() ?? 0,
        orderCount: (json['order_count'] as num?)?.toInt() ?? 0,
      );
}

class TopItemDto {
  final String name;
  final int qty;
  final int revenueMinor;

  const TopItemDto({
    required this.name,
    required this.qty,
    required this.revenueMinor,
  });

  factory TopItemDto.fromJson(Map<String, dynamic> json) => TopItemDto(
        name: json['name'] as String? ?? 'Unknown',
        qty: (json['qty'] as num?)?.toInt() ?? 0,
        revenueMinor: (json['revenue_minor'] as num?)?.toInt() ?? 0,
      );
}

class PeakHourDto {
  final int hour;
  final int orderCount;
  final int revenueMinor;

  const PeakHourDto({
    required this.hour,
    required this.orderCount,
    required this.revenueMinor,
  });

  factory PeakHourDto.fromJson(Map<String, dynamic> json) => PeakHourDto(
        hour: (json['hour'] as num?)?.toInt() ?? 0,
        orderCount: (json['order_count'] as num?)?.toInt() ?? 0,
        revenueMinor: (json['revenue_minor'] as num?)?.toInt() ?? 0,
      );

  String get label {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final suffix = hour < 12 ? 'AM' : 'PM';
    return '$h$suffix';
  }
}

class OrderSourceDto {
  final String source;
  final int count;
  final int revenueMinor;

  const OrderSourceDto({
    required this.source,
    required this.count,
    required this.revenueMinor,
  });

  factory OrderSourceDto.fromJson(Map<String, dynamic> json) => OrderSourceDto(
        source: json['source'] as String? ?? 'unknown',
        count: (json['count'] as num?)?.toInt() ?? 0,
        revenueMinor: (json['revenue_minor'] as num?)?.toInt() ?? 0,
      );

  String get displayName {
    switch (source) {
      case 'qr_scan': return 'QR Scan';
      case 'pos': return 'POS Terminal';
      case 'staff': return 'Staff Order';
      case 'online': return 'Online';
      default: return source.replaceAll('_', ' ').toUpperCase();
    }
  }
}
