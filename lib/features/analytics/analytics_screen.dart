import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/analytics_analysis_provider.dart';
import '../../core/providers/branch_context_service.dart';
import '../../core/data/dtos/analytics_analysis_dto.dart';

// ─── Date Range Options ────────────────────────────────────────────────────────
enum DateRangeOption { today, last7Days, last30Days }

extension DateRangeOptionExt on DateRangeOption {
  String get label {
    switch (this) {
      case DateRangeOption.today: return 'Today';
      case DateRangeOption.last7Days: return 'Last 7 Days';
      case DateRangeOption.last30Days: return 'Last 30 Days';
    }
  }

  DateTime get startDate {
    final now = DateTime.now();
    switch (this) {
      case DateRangeOption.today:
        return DateTime(now.year, now.month, now.day);
      case DateRangeOption.last7Days:
        return DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
      case DateRangeOption.last30Days:
        return DateTime(now.year, now.month, now.day).subtract(const Duration(days: 29));
    }
  }

  DateTime get endDate => DateTime.now();
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  DateRangeOption _selectedRange = DateRangeOption.today;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  void _fetch() {
    final branch = ref.read(currentBranchProvider).value;
    if (branch == null) return;
    ref.read(analyticsAnalysisProvider.notifier).fetch(
      branchId: branch.id,
      startDate: _selectedRange.startDate,
      endDate: _selectedRange.endDate,
    );
  }

  String _fmtCurrency(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}k';
    return '₹${v.toStringAsFixed(0)}';
  }

  Color get _primary => AppTheme.primary;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final state = ref.watch(analyticsAnalysisProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLowest,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.bar_chart_rounded, color: _primary, size: 24.r),
            SizedBox(width: 8.w),
            Text(
              'ANALYTICS',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _fetch(),
          color: _primary,
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
            children: [
              // ── Header ──────────────────────────────────────────────────
              Text(
                'Business Insights',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Understand performance and make better decisions.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.sp,
                  color: AppTheme.secondary,
                ),
              ),
              SizedBox(height: 16.h),

              // ── Date Range Selector ──────────────────────────────────────
              _buildDateRangeSelector(textColor, surfaceColor),
              SizedBox(height: 20.h),

              if (state.isLoading)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(60.r),
                    child: Column(
                      children: [
                        CircularProgressIndicator(color: _primary),
                        SizedBox(height: 16.h),
                        Text('Crunching numbers…',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.sp, color: AppTheme.secondary)),
                      ],
                    ),
                  ),
                )
              else if (state.error != null)
                _buildError(state.error!)
              else if (state.data != null)
                _buildContent(state.data!, textColor, surfaceColor, isDark)
              else
                _buildEmpty(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Date Range Selector ────────────────────────────────────────────────────
  Widget _buildDateRangeSelector(Color textColor, Color surfaceColor) {
    return Container(
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppTheme.surfaceContainerHigh),
      ),
      child: Row(
        children: DateRangeOption.values.map((option) {
          final selected = _selectedRange == option;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (_selectedRange != option) {
                  setState(() => _selectedRange = option);
                  _fetch();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(vertical: 8.h),
                decoration: BoxDecoration(
                  color: selected ? _primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(9.r),
                ),
                child: Text(
                  option.label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppTheme.secondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Main Content ───────────────────────────────────────────────────────────
  Widget _buildContent(AnalyticsAnalysisDto data, Color textColor, Color surfaceColor, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overview cards
        _buildOverviewCards(data, textColor, surfaceColor)
            .animate().fadeIn(duration: 300.ms).slideY(begin: 0.1),
        SizedBox(height: 24.h),

        // Total Sales Trends
        _buildSectionHeader('Total Sales Trend', Icons.show_chart_rounded, const Color(0xFF10B981), textColor),
        SizedBox(height: 16.h),
        _buildRevenueTrends(data.revenueTrends, surfaceColor, textColor)
            .animate().fadeIn(delay: 100.ms, duration: 300.ms).slideY(begin: 0.1),
        SizedBox(height: 24.h),

        // Top Selling Items
        _buildSectionHeader('Top Selling Items', Icons.restaurant_menu_rounded,
            _primary, textColor),
        SizedBox(height: 12.h),
        _buildTopItems(data.topItems, surfaceColor, textColor)
            .animate().fadeIn(delay: 200.ms, duration: 300.ms).slideY(begin: 0.1),
        SizedBox(height: 24.h),

        // Peak Hours
        _buildSectionHeader('Peak Hours', Icons.schedule_rounded,
            const Color(0xFFF59E0B), textColor),
        SizedBox(height: 12.h),
        _buildPeakHours(data.peakHours, surfaceColor, textColor)
            .animate().fadeIn(delay: 300.ms, duration: 300.ms).slideY(begin: 0.1),
        SizedBox(height: 24.h),

        // Order Sources
        _buildSectionHeader('Order Sources', Icons.devices_rounded,
            const Color(0xFF8B5CF6), textColor),
        SizedBox(height: 12.h),
        _buildOrderSources(data.orderSources, surfaceColor, textColor)
            .animate().fadeIn(delay: 400.ms, duration: 300.ms).slideY(begin: 0.1),
        SizedBox(height: 16.h),

        // Footer
        Center(
          child: Text(
            'Last updated: ${data.generatedAt.toLocal().toString().split('.')[0]}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.sp, color: AppTheme.secondary),
          ),
        ),
        SizedBox(height: 16.h),
      ],
    );
  }

  // ── Overview Cards ─────────────────────────────────────────────────────────
  Widget _buildOverviewCards(AnalyticsAnalysisDto data, Color textColor, Color surfaceColor) {
    return Row(
      children: [
        Expanded(child: _overviewCard(
          label: 'Total Sales',
          value: _fmtCurrency(data.totalRevenueMinor / 100),
          icon: Icons.payments_rounded,
          color: const Color(0xFF10B981),
          surfaceColor: surfaceColor,
          textColor: textColor,
        )),
        SizedBox(width: 12.w),
        Expanded(child: _overviewCard(
          label: 'Total Orders',
          value: data.totalOrders.toString(),
          icon: Icons.receipt_long_rounded,
          color: _primary,
          surfaceColor: surfaceColor,
          textColor: textColor,
        )),
      ],
    );
  }

  Widget _overviewCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color surfaceColor,
    required Color textColor,
  }) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppTheme.surfaceContainerHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: color, size: 18.r),
          ),
          SizedBox(height: 12.h),
          Text(label, style: GoogleFonts.plusJakartaSans(
            fontSize: 11.sp, fontWeight: FontWeight.w600, color: AppTheme.secondary)),
          SizedBox(height: 2.h),
          Text(value, style: GoogleFonts.plusJakartaSans(
            fontSize: 22.sp, fontWeight: FontWeight.w800, color: textColor, letterSpacing: -0.5)),
        ],
      ),
    );
  }

  // ── Section Header ─────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, IconData icon, Color color, Color textColor) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6.r),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: color, size: 16.r),
        ),
        SizedBox(width: 10.w),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ],
    );
  }

  // ── Total Sales Trend — Area / Line Chart ─────────────────────────────────
  Widget _buildRevenueTrends(List<RevenueTrendDto> trends, Color surfaceColor, Color textColor) {
    if (trends.isEmpty) return _buildEmptySection('No sales data for this period');

    final activeTrends = trends.where((t) => t.revenueMinor > 0).toList();

    // If only one day selected (Today), show a simple totals card instead
    if (trends.length == 1) {
      final t = trends.first;
      return Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppTheme.surfaceContainerHigh),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.payments_rounded, color: const Color(0xFF10B981), size: 28.r),
            ),
            SizedBox(width: 16.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Today\'s Total Sales',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.sp, color: AppTheme.secondary, fontWeight: FontWeight.w600)),
                SizedBox(height: 4.h),
                Text(_fmtCurrency(t.revenueMinor / 100),
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 28.sp, fontWeight: FontWeight.w800,
                        color: const Color(0xFF10B981), letterSpacing: -1)),
                SizedBox(height: 2.h),
                Text('${t.orderCount} order${t.orderCount != 1 ? 's' : ''}',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.sp, color: AppTheme.secondary)),
              ],
            ),
          ],
        ),
      );
    }

    final maxRevenue = trends.map((t) => t.revenueMinor).reduce((a, b) => a > b ? a : b);
    final totalRevenue = trends.fold(0, (s, t) => s + t.revenueMinor);

    return Container(
      padding: EdgeInsets.fromLTRB(16.r, 16.r, 16.r, 12.r),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppTheme.surfaceContainerHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Sales', style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.sp, color: AppTheme.secondary, fontWeight: FontWeight.w600)),
                  Text(_fmtCurrency(totalRevenue / 100), style: GoogleFonts.plusJakartaSans(
                      fontSize: 20.sp, fontWeight: FontWeight.w800,
                      color: const Color(0xFF10B981), letterSpacing: -0.5)),
                ],
              ),
              if (activeTrends.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text('${activeTrends.length} active day${activeTrends.length != 1 ? 's' : ''}',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.sp, fontWeight: FontWeight.w700,
                          color: const Color(0xFF10B981))),
                ),
            ],
          ),
          SizedBox(height: 16.h),
          // Area chart via CustomPaint
          SizedBox(
            height: 110.h,
            child: CustomPaint(
              size: Size(double.infinity, 110.h),
              painter: _AreaChartPainter(
                values: trends.map((t) => t.revenueMinor.toDouble()).toList(),
                maxValue: maxRevenue.toDouble(),
                lineColor: const Color(0xFF10B981),
                fillColor: const Color(0xFF10B981).withValues(alpha: 0.15),
                dotColor: const Color(0xFF10B981),
                gridColor: AppTheme.surfaceContainerHigh,
              ),
            ),
          ),
          SizedBox(height: 8.h),
          // Date labels — show only first, middle, last to avoid clutter
          Row(
            children: [
              _dateLabel(trends.first.date, trends.length),
              const Spacer(),
              if (trends.length > 2)
                _dateLabel(trends[trends.length ~/ 2].date, trends.length),
              const Spacer(),
              _dateLabel(trends.last.date, trends.length),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dateLabel(String date, int total) {
    final parts = date.split('-');
    final label = total <= 7 ? '${parts[2]}/${parts[1]}' : '${parts[2]}/${parts[1]}';
    return Text(label,
        style: GoogleFonts.plusJakartaSans(fontSize: 10.sp, color: AppTheme.secondary));
  }

  // ── Top Items ──────────────────────────────────────────────────────────────
  Widget _buildTopItems(List<TopItemDto> items, Color surfaceColor, Color textColor) {
    if (items.isEmpty) return _buildEmptySection('No items sold in this period');

    final maxQty = items.map((i) => i.qty).reduce((a, b) => a > b ? a : b);

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppTheme.surfaceContainerHigh),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final frac = maxQty > 0 ? item.qty / maxQty : 0.0;
          final isLast = i == items.length - 1;

          return Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : Border(
                      bottom: BorderSide(color: AppTheme.surfaceContainerHigh)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24.w,
                      alignment: Alignment.center,
                      child: Text(
                        '#${i + 1}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w800,
                          color: i == 0 ? const Color(0xFFF59E0B) : AppTheme.secondary,
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        item.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '×${item.qty}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: _primary,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      _fmtCurrency(item.revenueMinor / 100),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4.r),
                  child: LinearProgressIndicator(
                    value: frac,
                    minHeight: 4.h,
                    backgroundColor: AppTheme.surfaceContainerHigh,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      i == 0 ? const Color(0xFFF59E0B) : _primary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Peak Hours — Horizontal bar list ─────────────────────────────────────
  Widget _buildPeakHours(List<PeakHourDto> hours, Color surfaceColor, Color textColor) {
    final activeHours = hours.where((h) => h.orderCount > 0).toList()
      ..sort((a, b) => b.orderCount.compareTo(a.orderCount));

    if (activeHours.isEmpty) return _buildEmptySection('No orders recorded in this period');

    final maxCount = activeHours.first.orderCount;
    // Show top 8 busiest hours max
    final displayHours = activeHours.take(8).toList();
    final peakHour = displayHours.first;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppTheme.surfaceContainerHigh),
      ),
      child: Column(
        children: [
          // Peak badge at top
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
              border: Border(bottom: BorderSide(color: AppTheme.surfaceContainerHigh)),
            ),
            child: Row(
              children: [
                Icon(Icons.local_fire_department_rounded,
                    color: const Color(0xFFF59E0B), size: 18.r),
                SizedBox(width: 8.w),
                Text('Peak time: ',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.sp, color: AppTheme.secondary, fontWeight: FontWeight.w600)),
                Text(peakHour.label,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.sp, fontWeight: FontWeight.w800,
                        color: const Color(0xFFF59E0B))),
                Text('  •  ${peakHour.orderCount} order${peakHour.orderCount != 1 ? 's' : ''}',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.sp, color: AppTheme.secondary)),
              ],
            ),
          ),
          // Horizontal bar rows
          ...displayHours.asMap().entries.map((entry) {
            final i = entry.key;
            final h = entry.value;
            final frac = maxCount > 0 ? h.orderCount / maxCount : 0.0;
            final isPeak = i == 0;
            final barColor = isPeak
                ? const Color(0xFFF59E0B)
                : const Color(0xFFF59E0B).withValues(alpha: 0.35 + (0.5 * (1 - frac)));
            final isLast = i == displayHours.length - 1;

            return Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : Border(bottom: BorderSide(
                        color: AppTheme.surfaceContainerHigh, width: 0.5)),
              ),
              child: Row(
                children: [
                  // Time label
                  SizedBox(
                    width: 42.w,
                    child: Text(
                      h.label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.sp,
                        fontWeight: isPeak ? FontWeight.w800 : FontWeight.w600,
                        color: isPeak ? const Color(0xFFF59E0B) : textColor,
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  // Horizontal bar
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6.r),
                      child: Stack(
                        children: [
                          // Background track
                          Container(
                            height: 20.h,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                          ),
                          // Fill
                          AnimatedContainer(
                            duration: Duration(milliseconds: 400 + i * 80),
                            curve: Curves.easeOut,
                            height: 20.h,
                            width: double.infinity,
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: frac,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: barColor,
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  // Count chip
                  Container(
                    width: 28.w,
                    alignment: Alignment.center,
                    child: Text(
                      '${h.orderCount}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        color: isPeak ? const Color(0xFFF59E0B) : textColor,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Order Sources ──────────────────────────────────────────────────────────
  Widget _buildOrderSources(List<OrderSourceDto> sources, Color surfaceColor, Color textColor) {
    if (sources.isEmpty) return _buildEmptySection('No order source data available');

    final totalOrders = sources.fold(0, (sum, s) => sum + s.count);
    final colors = [
      const Color(0xFF8B5CF6),
      _primary,
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
    ];

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppTheme.surfaceContainerHigh),
      ),
      child: Column(
        children: sources.asMap().entries.map((entry) {
          final i = entry.key;
          final source = entry.value;
          final color = colors[i % colors.length];
          final pct = totalOrders > 0 ? (source.count / totalOrders * 100).toStringAsFixed(0) : '0';
          final isLast = i == sources.length - 1;

          return Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : Border(bottom: BorderSide(color: AppTheme.surfaceContainerHigh)),
            ),
            child: Row(
              children: [
                Container(
                  width: 10.w,
                  height: 10.w,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        source.displayName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4.r),
                        child: LinearProgressIndicator(
                          value: totalOrders > 0 ? source.count / totalOrders : 0,
                          minHeight: 4.h,
                          backgroundColor: AppTheme.surfaceContainerHigh,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${source.count} orders',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    Text(
                      '$pct%  •  ${_fmtCurrency(source.revenueMinor / 100)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.sp,
                        color: AppTheme.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _buildEmptySection(String message) {
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppTheme.surfaceContainerHigh),
      ),
      child: Center(
        child: Text(
          message,
          style: GoogleFonts.plusJakartaSans(fontSize: 13.sp, color: AppTheme.secondary),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(60.r),
        child: Text(
          'Select a date range to view insights.',
          style: GoogleFonts.plusJakartaSans(fontSize: 14.sp, color: AppTheme.secondary),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 32.r),
          SizedBox(height: 12.h),
          Text(
            'Failed to load analytics',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700, color: AppTheme.error),
          ),
          SizedBox(height: 8.h),
          Text(
            error,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp, color: AppTheme.error.withValues(alpha: 0.8)),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          ElevatedButton.icon(
            onPressed: _fetch,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Area Chart Painter ───────────────────────────────────────────────────────
class _AreaChartPainter extends CustomPainter {
  final List<double> values;
  final double maxValue;
  final Color lineColor;
  final Color fillColor;
  final Color dotColor;
  final Color gridColor;

  _AreaChartPainter({
    required this.values,
    required this.maxValue,
    required this.lineColor,
    required this.fillColor,
    required this.dotColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final width = size.width;
    final height = size.height;
    
    // Draw horizontal grid lines
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
      
    final steps = 4;
    for (int i = 0; i <= steps; i++) {
      final y = height - (i * height / steps);
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }

    if (values.length == 1) {
      // If only one value, draw a straight line
      final y = height - (maxValue > 0 ? (values[0] / maxValue) * height : 0);
      final p1 = Offset(0, y);
      final p2 = Offset(width, y);
      
      final linePaint = Paint()
        ..color = lineColor
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;
        
      canvas.drawLine(p1, p2, linePaint);
      
      final dotPaint = Paint()..color = dotColor;
      canvas.drawCircle(Offset(width / 2, y), 5.0, dotPaint);
      return;
    }

    final points = <Offset>[];
    final dx = width / (values.length - 1);
    
    for (int i = 0; i < values.length; i++) {
      final x = i * dx;
      final y = height - (maxValue > 0 ? (values[i] / maxValue) * height : 0);
      points.add(Offset(x, y));
    }

    // Create Path for the line
    final linePath = Path();
    linePath.moveTo(points[0].dx, points[0].dy);
    
    for (int i = 1; i < points.length; i++) {
      // Cubic bezier curve for smooth lines
      final p0 = points[i - 1];
      final p1 = points[i];
      final controlPointX = p0.dx + (p1.dx - p0.dx) / 2;
      
      linePath.cubicTo(
        controlPointX, p0.dy,
        controlPointX, p1.dy,
        p1.dx, p1.dy,
      );
    }

    // Create Path for the fill area
    final fillPath = Path.from(linePath);
    fillPath.lineTo(width, height);
    fillPath.lineTo(0, height);
    fillPath.close();

    // Draw Fill
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          fillColor.withValues(alpha: 0.5),
          fillColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.fill;
      
    canvas.drawPath(fillPath, fillPaint);

    // Draw Line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
      
    canvas.drawPath(linePath, linePaint);

    // Draw Dots on data points
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final dotBorderPaint = Paint()
      ..color = dotColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (final point in points) {
      canvas.drawCircle(point, 4.0, dotPaint);
      canvas.drawCircle(point, 4.0, dotBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AreaChartPainter oldDelegate) {
    return true; // Simple repaint always
  }
}
