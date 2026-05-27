import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class RbacMatrixScreen extends ConsumerStatefulWidget {
  const RbacMatrixScreen({super.key});

  @override
  ConsumerState<RbacMatrixScreen> createState() => _RbacMatrixScreenState();
}

class _RbacMatrixScreenState extends ConsumerState<RbacMatrixScreen> {
  // Active selected role: 'Manager', 'Chef', 'Server'
  String _selectedRole = 'Manager';

  // Credentials State
  String _pinComplexity = '6-Digit Numerical';
  bool _requireAccessCard = true;

  // Permissions matrices mapped by role -> category -> permission name -> enabled
  late Map<String, Map<String, Map<String, dynamic>>> _rolePermissions;

  @override
  void initState() {
    super.initState();
    // Pre-populate realistic matrix data
    _rolePermissions = {
      'Manager': {
        'Point of Sale Operations': {
          'Process Payments': {'desc': 'Settle checks, split bills, process credit cards', 'val': true},
          'Void Orders / Items': {'desc': 'Remove items after they have been sent to kitchen', 'val': true},
          'Apply Comps & Discounts': {'desc': 'Authorize percentage or dollar amount discounts', 'val': true},
        },
        'Menu & Pricing': {
          'Edit Pricing': {'desc': 'Change base prices of menu items', 'val': true},
          '86 Items (Mark Unavailable)': {'desc': 'Temporarily remove items from active menu', 'val': true},
        },
        'Administration': {
          'Manage Staff': {'desc': 'Add/remove employees, edit timesheets', 'val': true},
          'View Financial Reports': {'desc': 'Access end-of-day sales, labor costs, and tax reports', 'val': true},
        },
      },
      'Chef': {
        'Point of Sale Operations': {
          'Process Payments': {'desc': 'Settle checks, split bills, process credit cards', 'val': false},
          'Void Orders / Items': {'desc': 'Remove items after they have been sent to kitchen', 'val': false},
          'Apply Comps & Discounts': {'desc': 'Authorize percentage or dollar amount discounts', 'val': false},
        },
        'Menu & Pricing': {
          'Edit Pricing': {'desc': 'Change base prices of menu items', 'val': false},
          '86 Items (Mark Unavailable)': {'desc': 'Temporarily remove items from active menu', 'val': true},
        },
        'Administration': {
          'Manage Staff': {'desc': 'Add/remove employees, edit timesheets', 'val': false},
          'View Financial Reports': {'desc': 'Access end-of-day sales, labor costs, and tax reports', 'val': false},
        },
      },
      'Server': {
        'Point of Sale Operations': {
          'Process Payments': {'desc': 'Settle checks, split bills, process credit cards', 'val': true},
          'Void Orders / Items': {'desc': 'Remove items after they have been sent to kitchen', 'val': false},
          'Apply Comps & Discounts': {'desc': 'Authorize percentage or dollar amount discounts', 'val': true},
        },
        'Menu & Pricing': {
          'Edit Pricing': {'desc': 'Change base prices of menu items', 'val': false},
          '86 Items (Mark Unavailable)': {'desc': 'Temporarily remove items from active menu', 'val': false},
        },
        'Administration': {
          'Manage Staff': {'desc': 'Add/remove employees, edit timesheets', 'val': false},
          'View Financial Reports': {'desc': 'Access end-of-day sales, labor costs, and tax reports', 'val': false},
        },
      },
    };
  }

  void _saveMatrixChanges() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
            SizedBox(width: 8.w),
            const Text('RBAC Permission Matrix updated successfully.'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.success,
      ),
    );
    Navigator.pop(context);
  }

  void _createNewRole() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceContainerLowest,
          title: Text(
            'Create Custom Role',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: GoogleFonts.plusJakartaSans(),
            decoration: InputDecoration(
              hintText: 'e.g. Head Bartender',
              hintStyle: GoogleFonts.plusJakartaSans(color: AppTheme.secondary),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.plusJakartaSans(color: AppTheme.secondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final roleName = controller.text.trim();
                if (roleName.isNotEmpty) {
                  setState(() {
                    _rolePermissions[roleName] = {
                      'Point of Sale Operations': {
                        'Process Payments': {'desc': 'Settle checks, split bills, process credit cards', 'val': false},
                        'Void Orders / Items': {'desc': 'Remove items after they have been sent to kitchen', 'val': false},
                        'Apply Comps & Discounts': {'desc': 'Authorize percentage or dollar amount discounts', 'val': false},
                      },
                      'Menu & Pricing': {
                        'Edit Pricing': {'desc': 'Change base prices of menu items', 'val': false},
                        '86 Items (Mark Unavailable)': {'desc': 'Temporarily remove items from active menu', 'val': false},
                      },
                      'Administration': {
                        'Manage Staff': {'desc': 'Add/remove employees, edit timesheets', 'val': false},
                        'View Financial Reports': {'desc': 'Access end-of-day sales, labor costs, and tax reports', 'val': false},
                      },
                    };
                    _selectedRole = roleName;
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Custom role "$roleName" added to directory.'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryContainer,
              ),
              child: Text(
                'Create',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _toggleAllSelected(bool val) {
    setState(() {
      final roleMap = _rolePermissions[_selectedRole];
      if (roleMap != null) {
        for (var cat in roleMap.keys) {
          for (var perm in roleMap[cat]!.keys) {
            roleMap[cat]![perm]!['val'] = val;
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.of(context).size.width >= 960;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'RBAC Matrix Studio',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18.sp,
          ),
        ),
        backgroundColor: AppTheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, size: 22.r, color: AppTheme.secondary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () {},
            icon: Icon(Icons.history_rounded, size: 16.r, color: AppTheme.secondary),
            label: Text(
              'Audit Log',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 11.sp,
                color: AppTheme.onSurface,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.surfaceContainerHigh),
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.r)),
            ),
          ),
          SizedBox(width: 10.w),
          ElevatedButton.icon(
            onPressed: _saveMatrixChanges,
            icon: Icon(Icons.save_rounded, size: 16.r, color: Colors.white),
            label: Text(
              'Save Changes',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 11.sp,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryContainer,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.r)),
              elevation: 0,
            ),
          ),
          SizedBox(width: 16.w),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Divider(
            height: 1.h,
            thickness: 1.h,
            color: AppTheme.surfaceContainerHigh,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(desktop ? 24.r : 16.r),
          child: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: 1200.w),
              child: desktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column (Role selector + default credentials - 4/12 width)
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _buildLeftRbacColumn(context),
                          ),
                        ),
                        SizedBox(width: 24.w),

                        // Right Column (Matrix settings table - 8/12 width)
                        Expanded(
                          flex: 8,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [_buildPermissionsMatrixCard(context)],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      // Mobile stacked
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ..._buildLeftRbacColumn(context),
                        SizedBox(height: 16.h),
                        _buildPermissionsMatrixCard(context),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Left Column Builders ────────────────────────────────────────────────────
  List<Widget> _buildLeftRbacColumn(BuildContext context) {
    return [
      // 1. Role Architect Card
      Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppTheme.surfaceContainerHigh),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.group_rounded, size: 20.r, color: AppTheme.primary),
                SizedBox(width: 8.w),
                Text(
                  'Role Architect',
                  style: AppTheme.titleLg.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Divider(color: AppTheme.surfaceContainerHigh),
            SizedBox(height: 16.h),

            // Roles buttons stack
            Column(
              children: _rolePermissions.keys.map((role) {
                final isSelected = _selectedRole == role;
                IconData roleIcon = Icons.room_service_outlined;
                String desc = 'POS & Floorplan access';

                if (role == 'Manager') {
                  roleIcon = Icons.admin_panel_settings_rounded;
                  desc = 'Full system access';
                } else if (role == 'Chef') {
                  roleIcon = Icons.local_dining_rounded;
                  desc = 'Menu & KDS access';
                }

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedRole = role;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: 10.h),
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primary.withValues(alpha: 0.04) : AppTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: isSelected ? AppTheme.primary : AppTheme.surfaceContainerHigh,
                        width: isSelected ? 1.5.w : 1.w,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32.r,
                          height: 32.r,
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryContainer : AppTheme.surfaceContainerLow,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            roleIcon,
                            size: 16.r,
                            color: isSelected ? Colors.white : AppTheme.secondary,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                role,
                                style: AppTheme.bodyMd.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: isSelected ? AppTheme.primary : AppTheme.onSurface,
                                ),
                              ),
                              Text(
                                desc,
                                style: AppTheme.bodySm.copyWith(fontSize: 10.sp),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: isSelected ? AppTheme.primary : AppTheme.surfaceContainerHighest,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 10.h),

            // Dashed role creator button
            GestureDetector(
              onTap: _createNewRole,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 10.h),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded, size: 16.r, color: AppTheme.primary),
                    SizedBox(width: 4.w),
                    Text(
                      'Create New Role',
                      style: AppTheme.labelSm.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      SizedBox(height: 16.h),

      // 2. Default Credentials Card
      Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppTheme.surfaceContainerHigh),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.key_rounded, size: 20.r, color: AppTheme.primary),
                SizedBox(width: 8.w),
                Text(
                  'Default Credentials',
                  style: AppTheme.titleLg.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            Text(
              'Set credential requirements for the \'$_selectedRole\' role.',
              style: AppTheme.bodySm.copyWith(fontSize: 11.sp),
            ),
            SizedBox(height: 6.h),
            Divider(color: AppTheme.surfaceContainerHigh),
            SizedBox(height: 16.h),

            // Complexity Dropdown
            Text(
              'PIN Complexity',
              style: AppTheme.labelSm.copyWith(color: AppTheme.secondary),
            ),
            SizedBox(height: 6.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppTheme.surfaceContainerHigh),
              ),
              child: DropdownButton<String>(
                value: _pinComplexity,
                isExpanded: true,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: '4-Digit Numerical', child: Text('4-Digit Numerical')),
                  DropdownMenuItem(value: '6-Digit Numerical', child: Text('6-Digit Numerical')),
                  DropdownMenuItem(value: 'Alphanumeric Password', child: Text('Alphanumeric Password')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _pinComplexity = val;
                    });
                  }
                },
              ),
            ),
            SizedBox(height: 16.h),

            // Toggle Require swipe card
            SwitchListTile(
              title: Text('Require Access Card', style: AppTheme.bodyMd.copyWith(fontWeight: FontWeight.w700)),
              subtitle: Text('NFC/RFID authentication', style: AppTheme.bodySm),
              value: _requireAccessCard,
              activeColor: AppTheme.primary,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _requireAccessCard = val),
            ),
          ],
        ),
      ),
    ];
  }

  // ── Right Column Matrix Table Widget Card ───────────────────────────────────
  Widget _buildPermissionsMatrixCard(BuildContext context) {
    final roleMap = _rolePermissions[_selectedRole] ?? {};

    // Check if all permissions under this role are checked
    bool allChecked = true;
    for (var cat in roleMap.values) {
      for (var val in cat.values) {
        if (val['val'] == false) allChecked = false;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppTheme.surfaceContainerHigh),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          // Header Bar
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.checklist_rounded, size: 20.r, color: AppTheme.primary),
                        SizedBox(width: 8.w),
                        Text(
                          '$_selectedRole Permissions',
                          style: AppTheme.titleLg.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    Text(
                      'Configure access levels for the selected role.',
                      style: AppTheme.bodySm.copyWith(fontSize: 11.sp),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'Select All',
                      style: AppTheme.labelSm.copyWith(fontSize: 10.sp, color: AppTheme.secondary),
                    ),
                    SizedBox(width: 8.w),
                    Switch(
                      value: allChecked,
                      activeColor: AppTheme.primary,
                      onChanged: _toggleAllSelected,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1.h, thickness: 1.h, color: AppTheme.surfaceContainerHigh),

          // Scrollable categorized checkbox lists
          roleMap.isEmpty
              ? Padding(
                  padding: EdgeInsets.all(32.r),
                  child: Text(
                    'No permissions defined for this role.',
                    style: AppTheme.bodySm.copyWith(fontStyle: FontStyle.italic),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: roleMap.keys.length,
                  itemBuilder: (context, catIdx) {
                    final category = roleMap.keys.elementAt(catIdx);
                    final categoryItems = roleMap[category] ?? {};

                    IconData catIcon = Icons.point_of_sale_rounded;
                    if (category.contains('Menu')) catIcon = Icons.restaurant_menu_rounded;
                    if (category.contains('Admin')) catIcon = Icons.manage_accounts_rounded;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Header Line
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                          color: AppTheme.surfaceContainerLow,
                          child: Row(
                            children: [
                              Icon(catIcon, size: 16.r, color: AppTheme.secondary),
                              SizedBox(width: 8.w),
                              Text(
                                category.toUpperCase(),
                                style: AppTheme.labelSm.copyWith(
                                  fontSize: 9.sp,
                                  color: AppTheme.onSurface,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Checkbox lists
                        ...categoryItems.keys.map((permName) {
                          final perm = categoryItems[permName]!;
                          final isChecked = perm['val'] as bool;
                          final subtitle = perm['desc'] as String;

                          return Column(
                            children: [
                              CheckboxListTile(
                                title: Text(
                                  permName,
                                  style: AppTheme.bodyMd.copyWith(fontWeight: FontWeight.w700, fontSize: 13.sp),
                                ),
                                subtitle: Text(
                                  subtitle,
                                  style: AppTheme.bodySm.copyWith(fontSize: 10.sp),
                                ),
                                value: isChecked,
                                activeColor: AppTheme.primary,
                                controlAffinity: ListTileControlAffinity.trailing,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      perm['val'] = val;
                                    });
                                  }
                                },
                              ),
                              Divider(height: 1.h, color: AppTheme.surfaceContainerLow),
                            ],
                          );
                        }).toList(),
                      ],
                    );
                  },
                ),
        ],
      ),
    );
  }
}
