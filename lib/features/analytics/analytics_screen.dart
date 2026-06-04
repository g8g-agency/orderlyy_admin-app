import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/analytics_provider.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  final DateTime _today = DateTime.now().toUtc();
  
  @override
  void initState() {
    super.initState();
    // Fetch today's analytics on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsProvider.notifier).fetchDailySummary(
        date: _today,
      );
    });
  }

  String _fmtCurrency(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}k';
    return '₹${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
        
    final state = ref.watch(analyticsProvider);
    final summary = ref.watch(dailySummaryProvider({
      'date': _today,
      'branchId': null, // Tenant-wide for now
    }));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLowest,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.bar_chart_rounded, color: AppTheme.primary, size: 24.r),
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
          onRefresh: () => ref.read(analyticsProvider.notifier).fetchDailySummary(
            date: _today,
            forceRefresh: true,
          ),
          color: AppTheme.primary,
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
            children: [
              Text(
                'Today\'s Performance',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Metrics for the current operational day.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.sp,
                  color: AppTheme.secondary,
                ),
              ),
              SizedBox(height: 24.h),

              if (state.isLoading && summary == null)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.r),
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),
                )
              else if (state.error != null && summary == null)
                Container(
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
                          fontWeight: FontWeight.w700,
                          color: AppTheme.error,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        state.error!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.sp,
                          color: AppTheme.error.withValues(alpha: 0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16.h),
                      ElevatedButton(
                        onPressed: () => ref.read(analyticsProvider.notifier).fetchDailySummary(
                          date: _today,
                          forceRefresh: true,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.error,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        child: Text('Retry'),
                      )
                    ],
                  ),
                )
              else if (summary != null)
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context,
                            title: 'Gross Revenue',
                            value: _fmtCurrency(summary.totalRevenueAmount / 100),
                            icon: Icons.payments_rounded,
                            color: const Color(0xFF10B981),
                          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            title: 'Total Orders',
                            value: summary.totalOrderCount.toString(),
                            icon: Icons.receipt_long_rounded,
                            color: AppTheme.primary,
                          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context,
                            title: 'Avg Order Value',
                            value: _fmtCurrency(summary.averageOrderValueAmount / 100),
                            icon: Icons.show_chart_rounded,
                            color: const Color(0xFF8B5CF6),
                          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            title: 'Discounts',
                            value: _fmtCurrency(summary.totalDiscountAmount / 100),
                            icon: Icons.local_offer_rounded,
                            color: const Color(0xFFF59E0B),
                          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 14.r, color: AppTheme.secondary),
                        SizedBox(width: 6.w),
                        Text(
                          'Last generated: ${summary.generatedAt.toLocal().toString().split('.')[0]}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.sp,
                            color: AppTheme.secondary,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 500.ms),
                  ],
                )
              else
                 Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.r),
                    child: Text(
                      'No data available for today yet.',
                      style: GoogleFonts.plusJakartaSans(color: AppTheme.secondary),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final textColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurface
            : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppTheme.surfaceContainerHigh,
          width: 1.w,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: color, size: 20.r),
          ),
          SizedBox(height: 16.h),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.secondary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24.sp,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
