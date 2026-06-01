import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_colors.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final subtitleColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;


    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 40.h),
            child: Container(
              constraints: BoxConstraints(maxWidth: 500.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(24.r),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryContainer.withValues(alpha: 0.15),
                        width: 2.w,
                      ),
                    ),
                    child: Icon(
                      Icons.settings_suggest_rounded,
                      size: 64.r,
                      color: AppTheme.primary,
                    ),
                  ).animate().scale(delay: 100.ms, duration: 400.ms, curve: Curves.easeOutBack),
                  SizedBox(height: 32.h),
                  Text(
                    'System Settings',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 200.ms),
                  SizedBox(height: 12.h),
                  Text(
                    'System configuration & parameters are currently under development.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 300.ms),
                  SizedBox(height: 16.h),
                  Text(
                    'Customize your tax profiles, pricing templates, layout configurations, localized currency options, and physical receipt printer configurations.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.sp,
                      height: 1.5,
                      color: subtitleColor,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 400.ms),
                  SizedBox(height: 40.h),
                  Container(
                    padding: EdgeInsets.all(20.r),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkSurface
                          : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: AppTheme.surfaceContainerHigh,
                        width: 1.w,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFeatureBullet(context, 'Receipt Printer Management', 'Auto-print receipts with custom thermal configuration parameters.'),
                        SizedBox(height: 16.h),
                        _buildFeatureBullet(context, 'Tax & Compliance Profiles', 'Set default CGST, SGST, VAT, and custom dynamic service charges.'),
                        SizedBox(height: 16.h),
                        _buildFeatureBullet(context, 'Operational Configurations', 'Toggle auto-order acceptance, select sound alarms, and map branch preferences.'),
                      ],
                    ),
                  ).animate().slideY(begin: 0.1, delay: 500.ms).fadeIn(delay: 500.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureBullet(BuildContext context, String title, String description) {
    final textColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final subtitleColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(top: 2.h),
          padding: EdgeInsets.all(4.r),
          decoration: const BoxDecoration(
            color: Color(0xFF10B981),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.done_rounded,
            size: 12.r,
            color: Colors.white,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.sp,
                  color: textColor,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                description,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.sp,
                  color: subtitleColor,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
