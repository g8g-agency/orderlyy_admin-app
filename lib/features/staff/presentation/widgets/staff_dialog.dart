import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/data/dtos/staff_dto.dart';
import '../providers/staff_provider.dart';
import '../../../organization/presentation/state/branch_providers.dart';

class StaffDialog extends ConsumerStatefulWidget {
  final StaffDto? staff;

  const StaffDialog({super.key, this.staff});

  @override
  ConsumerState<StaffDialog> createState() => _StaffDialogState();
}

class _StaffDialogState extends ConsumerState<StaffDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _pinController;
  late TextEditingController _employeeIdController;
  late TextEditingController _emailController;
  late StaffRole _selectedRole;
  late bool _isActive;
  String? _selectedBranchId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.staff?.name ?? '');
    _pinController = TextEditingController(text: widget.staff?.pin ?? '');
    _employeeIdController = TextEditingController(
      text: widget.staff?.employeeId ?? '',
    );
    _emailController = TextEditingController(text: widget.staff?.email ?? '');
    _selectedRole = widget.staff?.role ?? StaffRole.waiter;
    _isActive = widget.staff?.isActive ?? true;
    _selectedBranchId = widget.staff?.branchId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    _employeeIdController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final staff = StaffDto(
      id: widget.staff?.id ?? const Uuid().v4(),
      tenantId: widget.staff?.tenantId ?? '', // Set correctly by Notifier
      name: _nameController.text.trim(),
      role: _selectedRole,
      pin: _pinController.text.trim(),
      isActive: _isActive,
      employeeId: _employeeIdController.text.trim().isEmpty
          ? null
          : _employeeIdController.text.trim(),
      branchId: _selectedBranchId,
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
    );

    if (widget.staff == null) {
      ref.read(staffNotifierProvider.notifier).addStaff(staff);
    } else {
      ref.read(staffNotifierProvider.notifier).updateStaff(staff);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    final branchesAsync = ref.watch(branchesProvider);

    return AlertDialog(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkSurface
          : AppColors.lightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      title: Text(
        widget.staff == null ? 'Add Staff Member' : 'Edit Staff Member',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
      content: SizedBox(
        width: 400.w,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
                ),
                SizedBox(height: 16.h),
                DropdownButtonFormField<StaffRole>(
                  initialValue: _selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  items: StaffRole.values.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(role.displayLabel),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedRole = val);
                  },
                ),
                SizedBox(height: 16.h),
                branchesAsync.when(
                  data: (branches) => DropdownButtonFormField<String>(
                    initialValue: _selectedBranchId,
                    decoration: InputDecoration(
                      labelText: 'Branch (Optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Branches / None'),
                      ),
                      ...branches.map(
                        (b) =>
                            DropdownMenuItem(value: b.id, child: Text(b.name)),
                      ),
                    ],
                    onChanged: (val) => setState(() => _selectedBranchId = val),
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (e, s) => Text('Error loading branches: $e'),
                ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: _employeeIdController,
                  decoration: InputDecoration(
                    labelText: 'Employee ID (Optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: _pinController,
                  decoration: InputDecoration(
                    labelText: 'PIN Code (4-10 digits)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Required';
                    if (val.length < 4 || val.length > 10)
                      return 'Must be 4-10 characters';
                    return null;
                  },
                ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email (Optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 16.h),
                SwitchListTile(
                  title: Text(
                    'Active',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  value: _isActive,
                  onChanged: (val) => setState(() => _isActive = val),
                  activeThumbColor: AppTheme.primary,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
