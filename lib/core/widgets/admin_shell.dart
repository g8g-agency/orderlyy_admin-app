import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/dtos/restaurant_context_dto.dart';
import '../runtime/runtime_switch_state.dart';
import 'branch_guards.dart';
import 'branch_state_debugger.dart';
import 'package:flutter/foundation.dart';
import '../auth/app_auth_provider.dart';
import '../theme/app_theme.dart';
import '../providers/branch_context_service.dart';
import '../../features/organization/presentation/state/branch_providers.dart';
import '../../features/organization/domain/entities/branch_entity.dart';

// ── AdminShell ─────────────────────────────────────────────────────────────────
// A unified layout wrapper for all /admin routes.
// Renders a persistent left sidebar on desktop, mobile drawer otherwise.
// Usage: wrap any admin screen body with AdminShell(title: '...', body: ...)
class AdminShell extends ConsumerWidget {
  final Widget body;
  final String title;
  final List<Widget>? actions;
  final bool disablePadding;

  const AdminShell({
    super.key,
    required this.body,
    required this.title,
    this.actions,
    this.disablePadding = false,
  });

  static const double _desktopBreak = 800;
  static const double _sidebarWidth = 240;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= _desktopBreak;

        return Stack(
          children: [
            Scaffold(
              backgroundColor: AppTheme.background,
              appBar: isDesktop
                  ? null
                  : AppBar(
                      backgroundColor: AppTheme.surfaceContainerLowest,
                      elevation: 0,
                      surfaceTintColor: Colors.transparent,
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: AppTheme.titleLg.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const BranchSwitcher(),
                        ],
                      ),
                      actions: actions,
                    ),
              drawer: isDesktop ? null : const _AdminSidebarWidget(),
              body: isDesktop
                  ? Row(
                      children: [
                        const SizedBox(
                          width: _sidebarWidth,
                          child: _AdminSidebarWidget(),
                        ),
                        Container(width: 1, color: AppTheme.surfaceContainerHigh),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Desktop top header bar
                              Container(
                                height: 72,
                                padding: const EdgeInsets.symmetric(horizontal: 32),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceContainerLowest,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: AppTheme.surfaceContainerHigh,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          title,
                                          style: AppTheme.headlineSm.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        const BranchSwitcher(),
                                      ],
                                    ),
                                    if (actions != null) Row(children: actions!),
                                  ],
                                ),
                              ),
                              // Main content area
                              Expanded(
                                child: Container(
                                  color: AppTheme.background,
                                  padding: disablePadding
                                      ? EdgeInsets.zero
                                      : const EdgeInsets.symmetric(
                                          horizontal: 32,
                                          vertical: 24,
                                        ),
                                  child: RequireBranchGuard(child: body),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Padding(
                      padding: disablePadding
                          ? EdgeInsets.zero
                          : const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                      child: RequireBranchGuard(child: body),
                    ),
            ),
            if (kDebugMode)
              Positioned(
                bottom: 16,
                right: 16,
                child: const BranchStateDebugger(),
              ),
          ],
        );
      },
    );
  }
}

// ── Branch Context Switcher ───────────────────────────────────────────────────
class BranchSwitcher extends ConsumerWidget {
  const BranchSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentBranchAsync = ref.watch(currentBranchProvider);
    final branchesAsync = ref.watch(branchesProvider);

    return currentBranchAsync.when(
      loading: () => Container(
        height: 32,
        width: 120,
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
        ),
      ),
      error: (err, stack) => const SizedBox.shrink(),
      data: (currentBranch) {
        if (currentBranch == null) return const SizedBox.shrink();

        return branchesAsync.when(
          loading: () => _buildPill(context, currentBranch.name, const []),
          error: (err, stack) => _buildPill(context, currentBranch.name, const []),
          data: (branches) {
            final activeBranches = branches.where((b) => b.status == BranchStatus.active).toList();
            return _buildPill(context, currentBranch.name, activeBranches, ref: ref);
          },
        );
      },
    );
  }

  Widget _buildPill(
    BuildContext context,
    String currentName,
    List<BranchEntity> branches, {
    WidgetRef? ref,
  }) {
    final hasMultiple = branches.length > 1;

    return Theme(
      data: Theme.of(context).copyWith(
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
      ),
      child: PopupMenuButton<String>(
        enabled: hasMultiple,
        tooltip: 'Switch Branch',
        offset: const Offset(0, 36),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppTheme.surfaceContainerHigh),
        ),
        color: AppTheme.surfaceContainerLowest,
        elevation: 4,
        onSelected: (branchId) {
          if (ref != null) {
            ref.read(currentBranchProvider.notifier).setBranch(branchId);
          }
        },
        itemBuilder: (context) {
          return branches.map((branch) {
            final isSelected = branch.name == currentName;
            return PopupMenuItem<String>(
              value: branch.id,
              child: Row(
                children: [
                  Icon(
                    Icons.store_rounded,
                    size: 16,
                    color: isSelected ? AppTheme.primary : AppTheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      branch.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AppTheme.primary : AppTheme.onSurface,
                      ),
                    ),
                  ),
                  if (branch.region != null && branch.region!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        branch.region!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ),
                  ],
                  if (isSelected) ...[
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: AppTheme.primary,
                    ),
                  ],
                ],
              ),
            );
          }).toList();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.store_rounded,
                size: 12,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  currentName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasMultiple) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 12,
                  color: AppTheme.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


// ── Shared Admin Sidebar Widget ────────────────────────────────────────────────
// Extracted from AdminDashboardScreen._DesktopSidebar.
// Shows branding, grouped nav items, and user profile row.
class _AdminSidebarWidget extends ConsumerWidget {
  const _AdminSidebarWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final email = user?.email ?? 'admin@orderlli.com';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : 'A';
    final name = email.split('@').first;
    final capitalizedName = name.isNotEmpty
        ? name[0].toUpperCase() + name.substring(1)
        : 'Admin';

    // Safely get current route
    String currentUri = '';
    try {
      currentUri = GoRouterState.of(context).uri.toString();
    } catch (_) {}

    return Container(
      color: AppTheme.surfaceContainerLowest,
      padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Branding
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Row(
              children: [
                Icon(Icons.store_rounded, color: AppTheme.primary, size: 26.r),
                SizedBox(width: 10.w),
                Text(
                  'Orderlli',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 28.h),

          // Navigation items list wrapped in scroll view to prevent layout overflows
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CORE OPERATIONS
                  _sectionHeader('CORE OPERATIONS'),
                  _NavItem(
                    icon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                    active: currentUri == '/admin/dashboard',
                    onTap: () => context.go('/admin/dashboard'),
                  ),
                  _NavItem(
                    icon: Icons.receipt_long_rounded,
                    label: 'Live Orders',
                    active: currentUri == '/admin/orders',
                    onTap: () => context.go('/admin/orders'),
                  ),
                  _NavItem(
                    icon: Icons.bar_chart_rounded,
                    label: 'Analytics',
                    active: currentUri == '/admin/analytics',
                    onTap: () => context.go('/admin/analytics'),
                  ),
                  SizedBox(height: 16.h),

                  // STUDIO CONFIG
                  _sectionHeader('STUDIO CONFIG'),
                  _NavItem(
                    icon: Icons.restaurant_menu_rounded,
                    label: 'Menu Manager',
                    active: currentUri == '/admin/menu',
                    onTap: () => context.go('/admin/menu'),
                  ),
                  _NavItem(
                    icon: Icons.table_restaurant_rounded,
                    label: 'Tables & QR',
                    active: currentUri == '/admin/tables',
                    onTap: () => context.go('/admin/tables'),
                  ),
                  _NavItem(
                    icon: Icons.grid_view_rounded,
                    label: 'Table & Floor Monitor',
                    active: currentUri == '/admin/live-floorplan',
                    onTap: () => context.go('/admin/live-floorplan'),
                  ),
                  _NavItem(
                    icon: Icons.group_rounded,
                    label: 'Staff & Team',
                    active: currentUri == '/admin/staff',
                    onTap: () => context.go('/admin/staff'),
                  ),
                  SizedBox(height: 16.h),

                  // FINANCIALS
                  _sectionHeader('FINANCIALS'),
                  _NavItem(
                    icon: Icons.percent_rounded,
                    label: 'Tax Matrix',
                    active: currentUri == '/admin/taxes',
                    onTap: () => context.go('/admin/taxes'),
                  ),
                  _NavItem(
                    icon: Icons.monetization_on_rounded,
                    label: 'Dynamic Pricing',
                    active: currentUri == '/admin/pricing',
                    onTap: () => context.go('/admin/pricing'),
                  ),
                  SizedBox(height: 16.h),

                  // SYSTEM
                  _sectionHeader('SYSTEM'),
                  _NavItem(
                    icon: Icons.business_rounded,
                    label: 'Organization',
                    active: currentUri == '/admin/organization',
                    onTap: () => context.go('/admin/organization'),
                  ),
                  _NavItem(
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    active: currentUri == '/admin/settings',
                    onTap: () => context.go('/admin/settings'),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16.h),

          // Profile row at bottom
          Container(
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18.r,
                  backgroundColor: AppTheme.primary,
                  child: Text(
                    initial,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        capitalizedName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        email,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.sp,
                          color: AppTheme.secondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    Icons.logout_rounded,
                    color: AppTheme.error,
                    size: 18.r,
                  ),
                  onPressed: () async {
                    final authService = ref.read(authServiceProvider);
                    await authService.signOut();
                    if (context.mounted) context.go('/admin/login');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 6, top: 4),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: AppTheme.secondary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

// ── Individual Nav Item ────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    this.active = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: active
                  ? AppTheme.primaryContainer.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: active ? AppTheme.primary : AppTheme.secondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active ? AppTheme.primary : AppTheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

