import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/auth/mock_auth_provider.dart';
import '../../core/data/dtos/staff_dto.dart';
import '../../core/providers/staff_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/uuid.dart';
import 'presentation/screens/rbac_matrix_screen.dart';

class StaffManagementScreen extends ConsumerStatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  ConsumerState<StaffManagementScreen> createState() =>
      _StaffManagementScreenState();
}

class _StaffManagementScreenState extends ConsumerState<StaffManagementScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffStreamProvider);
    final desktop = MediaQuery.of(context).size.width >= 960;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Staff Directory',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18.sp,
          ),
        ),
        backgroundColor: AppTheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RbacMatrixScreen()),
              );
            },
            icon: Icon(
              Icons.security_rounded,
              size: 16.r,
              color: AppTheme.primary,
            ),
            label: Text(
              'Permission Matrix',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 11.sp,
                color: AppTheme.primary,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: AppTheme.primaryContainer.withValues(alpha: 0.3),
              ),
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              minimumSize: Size(130.w, 36.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6.r),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          ElevatedButton.icon(
            onPressed: () => _showStaffSheet(context, ref, null),
            icon: Icon(Icons.add_rounded, size: 16.r, color: Colors.white),
            label: Text(
              'Add Staff',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 11.sp,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryContainer,
              foregroundColor: Colors.white,
              minimumSize: Size(110.w, 36.h),
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6.r),
              ),
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
              child: staffAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
                error: (err, stack) => Center(
                  child: Text(
                    'Failed to load staff: $err',
                    style: GoogleFonts.plusJakartaSans(color: AppTheme.error),
                  ),
                ),
                data: (allStaff) {
                  // Filter list based on search query
                  final filteredStaff = allStaff.where((member) {
                    if (_searchQuery.isEmpty) return true;
                    final query = _searchQuery.toLowerCase();
                    return member.name.toLowerCase().contains(query) ||
                        member.role.displayLabel.toLowerCase().contains(query);
                  }).toList();

                  final onlineCount = allStaff.where((s) => s.isActive).length;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Page intro
                      Text(
                        'Manage team members, roles, and current shifts.',
                        style: AppTheme.bodySm.copyWith(
                          fontSize: 12.sp,
                          color: AppTheme.secondary,
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // Top Bento grids (Shift monitor + KPI scorecard)
                      desktop
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Shift monitor (8/12 width)
                                Expanded(
                                  flex: 8,
                                  child: _buildActiveShiftMonitor(
                                    context,
                                    onlineCount,
                                  ),
                                ),
                                SizedBox(width: 24.w),

                                // KPIs scorecard (4/12 width)
                                Expanded(
                                  flex: 4,
                                  child: _buildPerformanceScorecard(context),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                _buildActiveShiftMonitor(context, onlineCount),
                                SizedBox(height: 16.h),
                                _buildPerformanceScorecard(context),
                              ],
                            ),
                      SizedBox(height: 24.h),

                      // Bottom directory ledger block
                      _buildDirectoryLedgerCard(context, filteredStaff),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Active Shift Monitor Card Widget ────────────────────────────────────────
  Widget _buildActiveShiftMonitor(BuildContext context, int onlineCount) {
    return Container(
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
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 20.r,
                    color: AppTheme.primary,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Active Shift Monitor',
                    style: AppTheme.titleLg.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6.r,
                      height: 6.r,
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      '$onlineCount Online',
                      style: AppTheme.labelSm.copyWith(
                        fontSize: 9.sp,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Stacked Shift Cards
          Row(
            children: [
              Expanded(
                child: _buildShiftCard(
                  name: 'Sarah J.',
                  role: 'Lead Server • Patio',
                  duration: '4h 20m',
                  imageUrl:
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuASDPloBfxf2IdaK6ctQvtktFUnoc5CmLYHJCbwnRprPqzd8te0Q1IwnKIxzW4KterBb0kvpYJxFrX-HdljAHln_FWxNu7ZLYxJa-TNazbpr0YXazlV-MlwJVPBBW0cxoGVze9FppWIin61QXCcHgC0cTDtrZaEHwfIqXJF3OvIxpJhj2LKopISwQX6jUV9DJgthgc3VUWd1lACYVlLoo_Q29ceRsMpDNjGigsWY5wiRPdHYCCnv2J_QqDnA8wzceKixYybfhfQofpZ',
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildShiftCard(
                  name: 'Mike T.',
                  role: 'Sous Chef • Kitchen',
                  duration: '6h 15m',
                  imageUrl:
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuATuJDLTMST4gVaJE9FRhevlVGJkrgaIW1N1wGNT-ahY30cBbECqdRjK3kkd25K9f46DFcwfrf1WPYy9VpGIyKsQ9UoxDisawP58CugTHGXpkUs6M-UNxH0ZX4VAQlnSeU_G8wmkqDfLKFo6kkOEZtZ3kIGiBP0sipaeYJLM6devNFi5mDAag7BehKPszf4tSxGdi1o63brSOrAi7VQd6HwY9eAkshSpk6XClEzy8KkX9qVxzoYE8X8mHA0PliYzBPTot5atWd-lMNU',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShiftCard({
    required String name,
    required String role,
    required String duration,
    required String imageUrl,
  }) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppTheme.surfaceContainerHigh),
      ),
      child: Row(
        children: [
          // Avatar image
          Stack(
            children: [
              Container(
                width: 38.r,
                height: 38.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  ),
                  border: Border.all(color: Colors.white, width: 2.w),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 9.r,
                  height: 9.r,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5.w),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: 10.w),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTheme.bodyMd.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.sp,
                  ),
                ),
                Text(role, style: AppTheme.bodySm.copyWith(fontSize: 10.sp)),
              ],
            ),
          ),

          // Duration
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Duration',
                style: AppTheme.labelSm.copyWith(
                  fontSize: 8.sp,
                  color: AppTheme.secondary,
                ),
              ),
              Text(
                duration,
                style: AppTheme.bodyMd.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── KPIs Scorecard Card Widget ──────────────────────────────────────────────
  Widget _buildPerformanceScorecard(BuildContext context) {
    return Container(
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
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bar_chart_rounded,
                size: 20.r,
                color: AppTheme.secondary,
              ),
              SizedBox(width: 8.w),
              Text(
                'Team Performance',
                style: AppTheme.titleMd.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Stacked score items
          _buildKpiScoreRow(
            label: 'Avg. Response Time',
            value: '2m 14s',
            icon: Icons.trending_down_rounded,
            success: true,
          ),
          SizedBox(height: 10.h),
          _buildKpiScoreRow(
            label: 'Table Turnover',
            value: '45m',
            icon: Icons.trending_up_rounded,
            success: false,
          ),
        ],
      ),
    );
  }

  Widget _buildKpiScoreRow({
    required String label,
    required String value,
    required IconData icon,
    required bool success,
  }) {
    return Container(
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppTheme.surfaceContainerHigh),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.labelSm.copyWith(
                  color: AppTheme.secondary,
                  fontSize: 9.sp,
                ),
              ),
              Text(
                value,
                style: AppTheme.headlineMd.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 18.sp,
                ),
              ),
            ],
          ),
          Icon(
            icon,
            color: success ? const Color(0xFF10B981) : AppTheme.primary,
            size: 22.r,
          ),
        ],
      ),
    );
  }

  // ── Directory Ledger Data Table Card Widget ─────────────────────────────────
  Widget _buildDirectoryLedgerCard(BuildContext context, List<StaffDto> staff) {
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
          ),
        ],
      ),
      child: Column(
        children: [
          // Filter/Search bar
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Directory Ledger',
                  style: AppTheme.titleMd.copyWith(fontWeight: FontWeight.w800),
                ),
                Container(
                  width: 220.w,
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: AppTheme.surfaceContainerHigh),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: AppTheme.secondary,
                        size: 18.r,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: TextField(
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                          style: GoogleFonts.plusJakartaSans(fontSize: 12.sp),
                          decoration: InputDecoration(
                            hintText: 'Search staff...',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 8.h),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1.h,
            thickness: 1.h,
            color: AppTheme.surfaceContainerHigh,
          ),

          // Custom Data Table view
          if (staff.isEmpty)
            Padding(
              padding: EdgeInsets.all(32.r),
              child: Text(
                'No employees found matching query.',
                style: AppTheme.bodySm.copyWith(fontStyle: FontStyle.italic),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: staff.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1.h, color: AppTheme.surfaceContainerHigh),
              itemBuilder: (context, idx) {
                final member = staff[idx];
                final roleColor = member.role == StaffRole.owner
                    ? AppTheme.primary
                    : member.role == StaffRole.manager
                    ? const Color(0xFF3B82F6)
                    : AppTheme.secondary;

                final initials = member.name.length >= 2
                    ? member.name.substring(0, 2).toUpperCase()
                    : member.name.toUpperCase();

                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  child: Row(
                    children: [
                      // Avatar block
                      Stack(
                        children: [
                          Container(
                            width: 36.r,
                            height: 36.r,
                            decoration: BoxDecoration(
                              color: roleColor.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                initials,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12.sp,
                                  color: roleColor,
                                ),
                              ),
                            ),
                          ),
                          if (member.isActive)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 10.r,
                                height: 10.r,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2.w,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(width: 12.w),

                      // Name and Employee ID
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member.name,
                              style: AppTheme.bodyMd.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.sp,
                              ),
                            ),
                            Text(
                              'ID: EMP-${member.id.hashCode.toString().padLeft(3, '0')}',
                              style: AppTheme.bodySm.copyWith(fontSize: 10.sp),
                            ),
                          ],
                        ),
                      ),

                      // Role text
                      Expanded(
                        flex: 2,
                        child: Text(
                          member.role.displayLabel,
                          style: AppTheme.bodyMd.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),

                      // Status Badge
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: member.isActive
                                  ? const Color(0xFFE6F4EA)
                                  : AppTheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Text(
                              member.isActive ? 'Clocked In' : 'Off Shift',
                              style: AppTheme.labelSm.copyWith(
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w800,
                                color: member.isActive
                                    ? const Color(0xFF0F9D58)
                                    : AppTheme.secondary,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Action buttons
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.edit_outlined,
                              size: 18.r,
                              color: AppTheme.secondary,
                            ),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            onPressed: () =>
                                _showStaffSheet(context, ref, member),
                          ),
                          SizedBox(width: 8.w),
                          IconButton(
                            icon: Icon(
                              Icons.archive_outlined,
                              size: 18.r,
                              color: AppTheme.secondary,
                            ),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Archived employee "${member.name}".',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          Divider(
            height: 1.h,
            thickness: 1.h,
            color: AppTheme.surfaceContainerHigh,
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Text(
              'View All Staff  →',
              style: AppTheme.labelSm.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStaffSheet(BuildContext context, WidgetRef ref, StaffDto? member) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StaffSheet(member: member),
    );
  }
}

// ── Add / Edit Staff Sheet ────────────────────────────────────────────────────
class _StaffSheet extends ConsumerStatefulWidget {
  final StaffDto? member;
  const _StaffSheet({this.member});

  @override
  ConsumerState<_StaffSheet> createState() => _StaffSheetState();
}

class _StaffSheetState extends ConsumerState<_StaffSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _pinCtrl;
  StaffRole _role = StaffRole.waiter;
  bool _active = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.member?.name ?? '');
    _pinCtrl = TextEditingController(text: widget.member?.pin ?? '');
    _role = widget.member?.role ?? StaffRole.waiter;
    _active = widget.member?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final pin = _pinCtrl.text.trim();
    if (name.isEmpty || pin.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final appContext = ref.read(appContextProvider);
      final tenantId = appContext?.tenant.id ?? 'tenant-mock';

      if (widget.member == null) {
        // Create
        final newStaff = StaffDto(
          id: UuidGenerator.generateRuntimeId(prefix: 'staff'),
          tenantId: tenantId,
          name: name,
          role: _role,
          pin: pin,
          isActive: _active,
        );
        await ref.read(createStaffProvider)(newStaff);
      } else {
        // Update
        final updated = widget.member!.copyWith(
          name: name,
          role: _role,
          pin: pin,
          isActive: _active,
        );
        await ref.read(updateStaffProvider)(updated);
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context);
    }
  }

  Future<void> _remove() async {
    if (widget.member == null) return;
    try {
      await ref.read(deleteStaffProvider)(widget.member!.id);
    } catch (_) {}
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 32.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pull Handle
              Center(
                child: Container(
                  margin: EdgeInsets.only(bottom: 16.h),
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.member == null ? 'Add Staff Member' : 'Edit Staff',
                    style: AppTheme.titleLg.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (widget.member != null)
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: AppTheme.error,
                        size: 22.r,
                      ),
                      onPressed: _remove,
                    ),
                ],
              ),
              SizedBox(height: 16.h),

              _buildField('Full Name', _nameCtrl, 'e.g. Rajesh Kumar'),
              SizedBox(height: 12.h),

              _buildField(
                'PIN (4 digits)',
                _pinCtrl,
                'e.g. 1234',
                type: TextInputType.number,
                maxLen: 4,
              ),
              SizedBox(height: 16.h),

              // Role selectors
              Text(
                'Role',
                style: AppTheme.labelSm.copyWith(color: AppTheme.secondary),
              ),
              SizedBox(height: 8.h),
              Row(
                children: StaffRole.values.map((r) {
                  final active = _role == r;
                  final color = switch (r) {
                    StaffRole.owner => AppTheme.primary,
                    StaffRole.manager => const Color(0xFF3B82F6),
                    StaffRole.waiter => AppTheme.secondary,
                  };
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _role = r),
                      child: AnimatedContainer(
                        duration: 200.ms,
                        margin: EdgeInsets.only(right: 8.w),
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        decoration: BoxDecoration(
                          color: active ? color : AppTheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(8.r),
                          border: active
                              ? null
                              : Border.all(
                                  color: AppTheme.surfaceContainerHigh,
                                ),
                        ),
                        child: Center(
                          child: Text(
                            r.displayLabel,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w800,
                              color: active ? Colors.white : AppTheme.secondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 16.h),

              // Active switch
              SwitchListTile(
                title: Text(
                  'Currently Active',
                  style: AppTheme.bodyMd.copyWith(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  'Toggles clocked in or off shift status',
                  style: AppTheme.bodySm,
                ),
                value: _active,
                activeThumbColor: AppTheme.primary,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) => setState(() => _active = val),
              ),
              SizedBox(height: 24.h),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppTheme.surfaceContainerHigh,
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.secondary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryContainer,
                      ),
                      child: _isSaving
                          ? SizedBox(
                              width: 20.r,
                              height: 20.r,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Save Staff',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl,
    String hint, {
    TextInputType? type,
    int? maxLen,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.labelSm.copyWith(color: AppTheme.secondary),
        ),
        SizedBox(height: 6.h),
        TextField(
          controller: ctrl,
          keyboardType: type,
          maxLength: maxLen,
          style: GoogleFonts.plusJakartaSans(fontSize: 13.sp),
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            hintStyle: GoogleFonts.plusJakartaSans(
              color: AppTheme.secondary,
              fontSize: 13.sp,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(
                color: AppTheme.surfaceContainerHigh,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(
                color: AppTheme.surfaceContainerHigh,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: AppTheme.primary),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 8.h,
            ),
            isDense: true,
          ),
        ),
      ],
    );
  }
}
