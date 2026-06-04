import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import 'presentation/state/analytics_providers.dart';
import 'data/dtos/analytics_dtos.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(dashboardAnalyticsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Business Intelligence',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20.sp,
            fontWeight: FontWeight.w800,
            color: AppTheme.onSurface,
          ),
        ),
        backgroundColor: AppTheme.background,
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: analyticsAsync.when(
          data: (data) => _buildDashboard(context, data),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 48.r),
                SizedBox(height: 16.h),
                Text(
                  'Failed to load analytics',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onSurface,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  err.toString(),
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.secondary),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),
                ElevatedButton(
                  onPressed: () => ref.refresh(dashboardAnalyticsProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, DashboardAnalyticsDto data) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 100.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Summary Cards ──
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'Total Revenue',
                  value: '\$${(data.salesDigest.totalRevenue / 100).toStringAsFixed(2)}',
                  icon: Icons.attach_money_rounded,
                  color: const Color(0xFF16A34A),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _SummaryCard(
                  title: 'Total Orders',
                  value: '${data.salesDigest.totalOrders}',
                  icon: Icons.receipt_long_rounded,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'Pending Orders',
                  value: '${data.salesDigest.pendingOrders}',
                  icon: Icons.pending_actions_rounded,
                  color: const Color(0xFFD97706),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _SummaryCard(
                  title: 'Peak Hour',
                  value: _getPeakHourString(data.hourlyTrends),
                  icon: Icons.access_time_rounded,
                  color: const Color(0xFF4F46E5),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 32.h),

          // ── Hourly Trends Chart ──
          Text(
            'Order Volume Over Time',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: AppTheme.onSurface,
            ),
          ),
          SizedBox(height: 16.h),
          _buildHourlyChart(data.hourlyTrends),

          SizedBox(height: 32.h),

          // ── Popular Items ──
          Text(
            'Best Selling Items',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: AppTheme.onSurface,
            ),
          ),
          SizedBox(height: 16.h),
          _buildPopularItems(data.popularItems),
        ],
      ),
    );
  }

  String _getPeakHourString(List<HourlyTrendDto> trends) {
    if (trends.isEmpty) return 'N/A';
    int max = 0;
    String peak = 'N/A';
    for (var t in trends) {
      if (t.orderCount > max) {
        max = t.orderCount;
        peak = t.hour;
      }
    }
    return max > 0 ? '$peak ($max)' : 'N/A';
  }

  Widget _buildHourlyChart(List<HourlyTrendDto> trends) {
    if (trends.isEmpty || trends.every((t) => t.orderCount == 0)) {
      return Container(
        height: 200.h,
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppTheme.surfaceContainerHigh),
        ),
        child: Center(
          child: Text(
            'No order data available yet.',
            style: GoogleFonts.plusJakartaSans(color: AppTheme.secondary),
          ),
        ),
      );
    }

    // Process trends to map coordinates (x: hour int, y: count)
    // Only show hours that have some context (e.g. 0 to 23).
    final spots = trends.map((t) {
      final h = double.tryParse(t.hour.split(':').first) ?? 0.0;
      return FlSpot(h, t.orderCount.toDouble());
    }).toList();

    return Container(
      height: 240.h,
      padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppTheme.surfaceContainerHigh),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(color: AppTheme.surfaceContainerHigh, strokeWidth: 1);
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 4,
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      '${value.toInt()}:00',
                      style: GoogleFonts.plusJakartaSans(fontSize: 10.sp, color: AppTheme.secondary),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  if (value % 1 != 0) return const SizedBox.shrink(); // only whole numbers
                  return Text(
                    value.toInt().toString(),
                    style: GoogleFonts.plusJakartaSans(fontSize: 10.sp, color: AppTheme.secondary),
                  );
                },
                reservedSize: 32,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: 23,
          minY: 0,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppTheme.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.white,
                    strokeWidth: 2,
                    strokeColor: AppTheme.primary,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.primary.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularItems(List<PopularItemDto> items) {
    if (items.isEmpty) {
      return Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppTheme.surfaceContainerHigh),
        ),
        child: Center(
          child: Text(
            'No items sold yet.',
            style: GoogleFonts.plusJakartaSans(color: AppTheme.secondary),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppTheme.surfaceContainerHigh),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, index) => const Divider(height: 1, color: AppTheme.surfaceContainerHigh),
        itemBuilder: (context, index) {
          final item = items[index];
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryContainer.withValues(alpha: 0.2),
                  radius: 16.r,
                  child: Text(
                    '#${index + 1}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      Text(
                        '${item.count} sold',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.sp,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$${(item.totalRevenue / 100).toStringAsFixed(2)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppTheme.surfaceContainerHigh),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, size: 16.r, color: color),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.secondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              color: AppTheme.onSurface,
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
