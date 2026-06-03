import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_colors.dart';
import 'presentation/providers/staff_provider.dart';
import 'presentation/widgets/staff_dialog.dart';
import '../../core/data/dtos/staff_dto.dart';

class StaffManagementScreen extends ConsumerWidget {
  const StaffManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffState = ref.watch(staffNotifierProvider);
    final textColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Staff Directory',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(staffNotifierProvider.notifier).refresh(),
          ),
          SizedBox(width: 16.w),
        ],
      ),
      body: staffState.when(
        data: (staffList) {
          if (staffList.isEmpty) {
            return const Center(child: Text('No staff found. Add one!'));
          }

          return ListView.builder(
            padding: EdgeInsets.all(16.r),
            itemCount: staffList.length,
            itemBuilder: (context, index) {
              final staff = staffList[index];
              return Card(
                elevation: 0,
                margin: EdgeInsets.only(bottom: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  side: BorderSide(
                    color: AppTheme.surfaceContainerHigh,
                    width: 1,
                  ),
                ),
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkSurface
                    : AppColors.lightSurface,
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryContainer.withValues(alpha: 0.2),
                    child: Icon(Icons.person_rounded, color: AppTheme.primary),
                  ),
                  title: Text(
                    staff.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  subtitle: Text(
                    '${staff.role.displayLabel} • PIN: ${staff.pin}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.sp,
                      color: staff.isActive ? Colors.green : Colors.redAccent,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_rounded),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => StaffDialog(staff: staff),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                        onPressed: () => _confirmDelete(context, ref, staff),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => const StaffDialog(),
          );
        },
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Add Staff', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, StaffDto staff) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Staff'),
        content: Text('Are you sure you want to delete ${staff.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () {
              ref.read(staffNotifierProvider.notifier).deleteStaff(staff.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
