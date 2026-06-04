import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/auth/app_auth_provider.dart';
import '../state/branch_providers.dart';
import '../widgets/branch_form_sheet.dart';
import '../../../../core/crud/crud_state_widgets.dart';
import '../../domain/entities/branch_entity.dart';

class OrganizationDashboardScreen extends ConsumerWidget {
  const OrganizationDashboardScreen({super.key});

  void _showRegionsOverview(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _RegionsOverviewSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctx = ref.watch(appContextProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark
        ? AppColors.darkBackground
        : AppColors.lightBackground;
    final surfaceColor = isDark
        ? AppColors.darkSurface
        : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final subTextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    if (ctx == null) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;
    final isCompact = !isDesktop;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 1,
        title: Row(
          children: [
            const Icon(Icons.restaurant, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Orderlyy',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: subTextColor),
            onPressed: () {},
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 40 : 16,
          vertical: 24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Flex(
                  direction: isDesktop ? Axis.horizontal : Axis.vertical,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: isDesktop
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.start,
                  children: [
                    if (isDesktop)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Organization Overview',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Manage and monitor franchise performance across all regions.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                color: subTextColor,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Organization Overview',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manage and monitor franchise performance across all regions.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              color: subTextColor,
                            ),
                          ),
                        ],
                      ),
                    if (!isDesktop) const SizedBox(height: 20),
                    _HeaderActions(
                      isDesktop: isDesktop,
                      isCompact: isCompact,
                      textColor: textColor,
                      borderColor: borderColor,
                      onManageRegions: () => _showRegionsOverview(context),
                      onAddBranch: () => BranchFormSheet.show(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Branch Directory
                _BranchDirectoryTable(
                  isCompact: isCompact,
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderActions extends StatelessWidget {
  final bool isDesktop;
  final bool isCompact;
  final Color textColor;
  final Color borderColor;
  final VoidCallback onManageRegions;
  final VoidCallback onAddBranch;

  const _HeaderActions({
    required this.isDesktop,
    required this.isCompact,
    required this.textColor,
    required this.borderColor,
    required this.onManageRegions,
    required this.onAddBranch,
  });

  @override
  Widget build(BuildContext context) {
    final manageRegionsButton = OutlinedButton(
      onPressed: onManageRegions,
      style: OutlinedButton.styleFrom(
        foregroundColor: textColor,
        side: BorderSide(color: borderColor),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: isDesktop
            ? const Size(0, 52)
            : const Size(double.infinity, 48),
      ),
      child: const Text('Manage Regions'),
    );

    final addBranchButton = ElevatedButton.icon(
      onPressed: onAddBranch,
      icon: const Icon(Icons.add, size: 18),
      label: const Text('Add New Branch'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
        minimumSize: isDesktop
            ? const Size(0, 52)
            : const Size(double.infinity, 48),
      ),
    );

    if (isDesktop) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          manageRegionsButton,
          const SizedBox(width: 12),
          addBranchButton,
        ],
      );
    }

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          manageRegionsButton,
          const SizedBox(height: 12),
          addBranchButton,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: manageRegionsButton),
        const SizedBox(width: 12),
        Expanded(child: addBranchButton),
      ],
    );
  }
}

class _BranchDirectoryTable extends ConsumerWidget {
  final bool isCompact;
  final Color surfaceColor;
  final Color borderColor;
  final Color textColor;
  final Color subTextColor;

  const _BranchDirectoryTable({
    required this.isCompact,
    required this.surfaceColor,
    required this.borderColor,
    required this.textColor,
    required this.subTextColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(branchesProvider);

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.all(isCompact ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Branch Directory',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search branches...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor:
                              Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkBackground
                              : AppColors.lightBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: borderColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.filter_list),
                        onPressed: () {},
                        color: subTextColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          branchesAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => CrudErrorState(
              message: error.toString(),
              onRetry: () => ref.invalidate(branchesProvider),
            ),
            data: (branches) {
              if (branches.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  child: Text(
                    'No branches found',
                    style: TextStyle(color: subTextColor),
                  ),
                );
              }

              if (isCompact) {
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: branches.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: borderColor),
                  itemBuilder: (context, index) {
                    final branch = branches[index];
                    return _BranchCard(
                      branch: branch,
                      textColor: textColor,
                      subTextColor: subTextColor,
                      borderColor: borderColor,
                      onEdit: () =>
                          BranchFormSheet.show(context, initialData: branch),
                    );
                  },
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  return Scrollbar(
                    thumbVisibility: constraints.maxWidth < 900,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                        ),
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[900]
                                : Colors.grey[50],
                          ),
                          columnSpacing: 24,
                          columns: [
                            DataColumn(
                              label: Text(
                                'Branch Name',
                                style: TextStyle(
                                  color: subTextColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Timezone',
                                style: TextStyle(
                                  color: subTextColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Status',
                                style: TextStyle(
                                  color: subTextColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Today\'s Sales',
                                style: TextStyle(
                                  color: subTextColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Orders',
                                style: TextStyle(
                                  color: subTextColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Actions',
                                style: TextStyle(
                                  color: subTextColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          rows: branches
                              .map(
                                (branch) => _buildRow(
                                  context,
                                  branch,
                                  branch.name,
                                  branch.timezone,
                                  branch.status == BranchStatus.active,
                                  '\$0',
                                  '0',
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          Divider(height: 1, color: borderColor),
          if (branchesAsync.hasValue && branchesAsync.value!.length > 5)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    'View All ${branchesAsync.value!.length} Branches',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  DataRow _buildRow(
    BuildContext context,
    dynamic branch,
    String name,
    String timezone,
    bool isOpen,
    String sales,
    String orders,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final subTextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return DataRow(
      cells: [
        DataCell(
          Text(
            name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
              fontSize: 15,
            ),
          ),
        ),
        DataCell(Text(timezone, style: TextStyle(color: textColor))),
        DataCell(
          _StatusChip(
            isOpen: isOpen,
            subTextColor: subTextColor,
            borderColor: borderColor,
          ),
        ),
        DataCell(
          Text(
            sales,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isOpen ? textColor : subTextColor,
            ),
          ),
        ),
        DataCell(
          Text(
            orders,
            style: TextStyle(color: isOpen ? textColor : subTextColor),
          ),
        ),
        DataCell(
          IconButton(
            icon: Icon(Icons.edit, color: subTextColor),
            onPressed: () => BranchFormSheet.show(context, initialData: branch),
          ),
        ),
      ],
    );
  }
}

class _BranchCard extends StatelessWidget {
  final BranchEntity branch;
  final Color textColor;
  final Color subTextColor;
  final Color borderColor;
  final VoidCallback onEdit;

  const _BranchCard({
    required this.branch,
    required this.textColor,
    required this.subTextColor,
    required this.borderColor,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isOpen = branch.status == BranchStatus.active;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  branch.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
              ),
              _StatusChip(
                isOpen: isOpen,
                subTextColor: subTextColor,
                borderColor: borderColor,
              ),
              IconButton(
                icon: Icon(Icons.edit_outlined, color: subTextColor, size: 20),
                onPressed: onEdit,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _Metric(
                label: 'Timezone',
                value: branch.timezone,
                subTextColor: subTextColor,
                textColor: textColor,
              ),
              _Metric(
                label: 'Today\'s Sales',
                value: '\$0',
                subTextColor: subTextColor,
                textColor: textColor,
              ),
              _Metric(
                label: 'Orders',
                value: '0',
                subTextColor: subTextColor,
                textColor: textColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final Color subTextColor;
  final Color textColor;

  const _Metric({
    required this.label,
    required this.value,
    required this.subTextColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: subTextColor),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isOpen;
  final Color subTextColor;
  final Color borderColor;

  const _StatusChip({
    required this.isOpen,
    required this.subTextColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen
            ? AppColors.primary.withValues(alpha: 0.1)
            : borderColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        isOpen ? 'Open' : 'Closed',
        style: TextStyle(
          color: isOpen ? AppColors.primary : subTextColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RegionsOverviewSheet extends ConsumerWidget {
  const _RegionsOverviewSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(branchesProvider);
    final surfaceColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkSurface
        : AppColors.lightSurface;
    final textColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final subTextColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final borderColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkBorder
        : AppColors.lightBorder;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Franchise Regions',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Franchise branches grouped by operational or geographic regions.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: subTextColor,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: branchesAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, _) => Center(
                  child: Text(
                    'Error loading regions: $error',
                    style: const TextStyle(color: AppColors.primary),
                  ),
                ),
                data: (branches) {
                  // Group branches by region
                  final Map<String, List<BranchEntity>> grouped = {};
                  for (final branch in branches) {
                    final reg = branch.region?.trim() ?? '';
                    final regionName = reg.isEmpty ? 'Unassigned Region' : reg;
                    grouped.putIfAbsent(regionName, () => []).add(branch);
                  }

                  if (grouped.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          'No regions defined. Edit or onboard branches to assign regions.',
                          style: GoogleFonts.plusJakartaSans(
                            color: subTextColor,
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView(
                    shrinkWrap: true,
                    children: grouped.entries.map((entry) {
                      final regionName = entry.key;
                      final regionBranches = entry.value;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[900]
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: ExpansionTile(
                          shape: const Border(),
                          title: Row(
                            children: [
                              Icon(
                                Icons.public_rounded,
                                color: regionName == 'Unassigned Region'
                                    ? subTextColor
                                    : AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  regionName,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: textColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                  '${regionBranches.length} ${regionBranches.length == 1 ? 'branch' : 'branches'}',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          children: regionBranches.map((branch) {
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 4,
                              ),
                              leading: const Icon(
                                Icons.storefront_rounded,
                                size: 20,
                              ),
                              title: Text(
                                branch.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              subtitle: Text(
                                branch.address ??
                                    'No physical address specified',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: subTextColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: branch.status == BranchStatus.active
                                      ? Colors.green.withValues(alpha: 0.1)
                                      : Colors.grey.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  branch.status.name.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: branch.status == BranchStatus.active
                                        ? Colors.green
                                        : subTextColor,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
