import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/auth/app_context_provider.dart';

class OrganizationDashboardScreen extends ConsumerWidget {
  const OrganizationDashboardScreen({super.key});

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

    final isDesktop = MediaQuery.of(context).size.width >= 900;

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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Organization Overview',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: isDesktop ? 36 : 28,
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
                    Row(
                      children: [
                        Expanded(
                          flex: isDesktop ? 0 : 1,
                          child: OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              foregroundColor: textColor,
                              side: BorderSide(color: borderColor),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Manage Regions'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: isDesktop ? 0 : 1,
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add New Branch'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Bento Grid (Stats + Map)
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 8,
                        child: _buildStatsGrid(
                          isDesktop,
                          surfaceColor,
                          borderColor,
                          textColor,
                          subTextColor,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 4,
                        child: _LiveHeatmapWidget(
                          surfaceColor: surfaceColor,
                          borderColor: borderColor,
                          textColor: textColor,
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildStatsGrid(
                        isDesktop,
                        surfaceColor,
                        borderColor,
                        textColor,
                        subTextColor,
                      ),
                      const SizedBox(height: 24),
                      _LiveHeatmapWidget(
                        surfaceColor: surfaceColor,
                        borderColor: borderColor,
                        textColor: textColor,
                      ),
                    ],
                  ),

                const SizedBox(height: 24),
                // Branch Directory
                _BranchDirectoryTable(
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

  Widget _buildStatsGrid(
    bool isDesktop,
    Color surfaceColor,
    Color borderColor,
    Color textColor,
    Color subTextColor,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final crossAxisCount = isMobile ? 1 : 3;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: isMobile ? 2.5 : 0.85,
          children: [
            _StatCard(
              title: 'Total Branches',
              value: '142',
              icon: Icons.storefront_outlined,
              iconColor: subTextColor,
              badgeText: '+3 This Month',
              badgeColor: AppColors.primary.withValues(alpha: 0.1),
              badgeTextColor: AppColors.primary,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
              textColor: textColor,
              subTextColor: subTextColor,
            ),
            _StatCard(
              title: 'Today\'s Global Sales',
              value: '\$124.5K',
              icon: Icons.payments_outlined,
              iconColor: AppColors.primary,
              isHighlighted: true,
              trendIcon: Icons.trending_up,
              trendText: '12% vs Yesterday',
              surfaceColor: surfaceColor,
              borderColor: borderColor,
              textColor: textColor,
              subTextColor: subTextColor,
            ),
            _StatCard(
              title: 'Active Orders',
              value: '843',
              icon: Icons.receipt_long_outlined,
              iconColor: subTextColor,
              badgeText: '12 Critical',
              badgeColor: AppColors.error.withValues(alpha: 0.15),
              badgeTextColor: AppColors.error,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
              textColor: textColor,
              subTextColor: subTextColor,
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final String? badgeText;
  final Color? badgeColor;
  final Color? badgeTextColor;
  final IconData? trendIcon;
  final String? trendText;
  final bool isHighlighted;
  final Color surfaceColor;
  final Color borderColor;
  final Color textColor;
  final Color subTextColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.badgeText,
    this.badgeColor,
    this.badgeTextColor,
    this.trendIcon,
    this.trendText,
    this.isHighlighted = false,
    required this.surfaceColor,
    required this.borderColor,
    required this.textColor,
    required this.subTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted ? AppColors.primary : borderColor,
          width: isHighlighted ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isHighlighted ? AppColors.primary : subTextColor,
                  ),
                ),
              ),
              Icon(icon, color: iconColor, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 16),
          if (badgeText != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                badgeText!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: badgeTextColor,
                ),
              ),
            )
          else if (trendText != null)
            Row(
              children: [
                Icon(trendIcon, color: AppColors.success, size: 16),
                const SizedBox(width: 4),
                Text(
                  trendText!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: subTextColor,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _LiveHeatmapWidget extends StatefulWidget {
  final Color surfaceColor;
  final Color borderColor;
  final Color textColor;

  const _LiveHeatmapWidget({
    required this.surfaceColor,
    required this.borderColor,
    required this.textColor,
  });

  @override
  State<_LiveHeatmapWidget> createState() => _LiveHeatmapWidgetState();
}

class _LiveHeatmapWidgetState extends State<_LiveHeatmapWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Live Heatmap',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: widget.textColor,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.fullscreen),
                  onPressed: () {},
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: widget.borderColor),
          AspectRatio(
            aspectRatio: 16 / 10,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.8,
                    child: Image.network(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuCdrKhsI7BflcKD0as8RskRtir45Qslz8RwL--Ku2RzDf5nH2bl7v9obWuKUE1glsqdsPaGRf_Ha1wNg3oOzWWH_aeF-p0dX0Q-0VM1ztxzOZh2-HOi8oClonkkx2IuaBibjC12KnHqHacMm-bw3SAzDwlHvJwi_nEZxqcigXZb0JizEn76WAynnWcF8IKLxsGQIjJA7ziWxSR7H4WGio821lANiu2HXGmwWrn4aCBRNiUnxwIyQQ4TQzNmOO7ClTH_fxRMqlp4sNVR',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: widget.borderColor.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 50,
                  left: 80,
                  child: _buildPin(size: 12, color: AppColors.primary),
                ),
                Positioned(
                  top: 120,
                  left: 150,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(
                                alpha: 0.8 * _pulseController.value,
                              ),
                              blurRadius: 15 * _pulseController.value,
                              spreadRadius: 5 * _pulseController.value,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 180,
                  left: 90,
                  child: _buildPin(size: 8, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPin({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
    );
  }
}

class _BranchDirectoryTable extends StatelessWidget {
  final Color surfaceColor;
  final Color borderColor;
  final Color textColor;
  final Color subTextColor;

  const _BranchDirectoryTable({
    required this.surfaceColor,
    required this.borderColor,
    required this.textColor,
    required this.subTextColor,
  });

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: [
                Text(
                  'Branch Directory',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 250,
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
                            vertical: 0,
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                borderColor.withValues(alpha: 0.2),
              ),
              dataRowMaxHeight: 70,
              dataRowMinHeight: 70,
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
                    'Region',
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
                    'Active Orders',
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
              rows: [
                _buildRow(
                  'Downtown Core (Store #042)',
                  '124 Main St, Metropolis',
                  'Northeast',
                  true,
                  '\$8,450',
                  '42',
                ),
                _buildRow(
                  'Uptown Plaza (Store #018)',
                  '890 High St, Metropolis',
                  'Northeast',
                  true,
                  '\$6,120',
                  '28',
                ),
                _buildRow(
                  'Westside Mall (Store #105)',
                  '400 Commerce Way, Suburbia',
                  'Midwest',
                  false,
                  '\$0',
                  '0',
                ),
              ],
            ),
          ),
          Divider(height: 1, color: borderColor),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: TextButton(
                onPressed: () {},
                child: const Text(
                  'View All 142 Branches',
                  style: TextStyle(
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
    String name,
    String address,
    String region,
    bool isOpen,
    String sales,
    String orders,
  ) {
    return DataRow(
      cells: [
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                address,
                style: TextStyle(fontSize: 12, color: subTextColor),
              ),
            ],
          ),
        ),
        DataCell(Text(region, style: TextStyle(color: textColor))),
        DataCell(
          Container(
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
            icon: Icon(Icons.chevron_right, color: subTextColor),
            onPressed: () {},
          ),
        ),
      ],
    );
  }
}
