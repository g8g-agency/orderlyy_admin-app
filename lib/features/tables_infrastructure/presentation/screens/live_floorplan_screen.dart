import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

// ── Models & State ────────────────────────────────────────────────────────────
enum TableDiningPhase {
  vacant, // Emerald green
  seated, // Amber yellow
  cooking, // Orange KDS preparing
  dining, // Blue served
  waitingForBill, // Purple checkout requested
}

class LiveTableNode {
  final String label;
  final TableDiningPhase phase;
  final int activeGuests;
  final int capacity;
  final double x; // Percent positioning
  final double y;
  final double width;
  final double height;
  final bool isRound;
  final String elapsedText;
  final String currentStatusText;

  LiveTableNode({
    required this.label,
    required this.phase,
    required this.activeGuests,
    required this.capacity,
    required this.x,
    required this.y,
    this.width = 96,
    this.height = 96,
    this.isRound = false,
    this.elapsedText = '',
    this.currentStatusText = '',
  });
}

// Active room/section provider (Main Dining vs Patio)
final activeSectionProvider = StateProvider<int>((ref) => 0);

final liveTablesProvider =
    StateNotifierProvider<LiveTablesNotifier, List<LiveTableNode>>((ref) {
      return LiveTablesNotifier();
    });

class LiveTablesNotifier extends StateNotifier<List<LiveTableNode>> {
  LiveTablesNotifier()
    : super([
        LiveTableNode(
          label: 'T-1',
          phase: TableDiningPhase.vacant,
          activeGuests: 0,
          capacity: 4,
          x: 0.1,
          y: 0.12,
          isRound: false,
        ),
        LiveTableNode(
          label: 'T-2',
          phase: TableDiningPhase.seated,
          activeGuests: 2,
          capacity: 2,
          x: 0.45,
          y: 0.12,
          isRound: true,
          elapsedText: '10m seated',
          currentStatusText: 'Browsing Menu',
        ),
        LiveTableNode(
          label: 'B-1',
          phase: TableDiningPhase.cooking,
          activeGuests: 4,
          capacity: 6,
          x: 0.18,
          y: 0.45,
          width: 120,
          height: 80,
          isRound: false,
          elapsedText: '22m elapsed',
          currentStatusText: 'Mains Fired',
        ),
        LiveTableNode(
          label: 'T-4',
          phase: TableDiningPhase.dining,
          activeGuests: 4,
          capacity: 4,
          x: 0.62,
          y: 0.42,
          isRound: false,
          elapsedText: '35m dining',
          currentStatusText: 'Served & Enjoying',
        ),
        LiveTableNode(
          label: 'P-1',
          phase: TableDiningPhase.waitingForBill,
          activeGuests: 2,
          capacity: 2,
          x: 0.52,
          y: 0.72,
          isRound: true,
          elapsedText: '48m elapsed',
          currentStatusText: 'Bill Requested',
        ),
      ]);

  void seatGuests(String label, int guests) {
    state = state.map((t) {
      if (t.label == label) {
        return LiveTableNode(
          label: t.label,
          phase: TableDiningPhase.seated,
          activeGuests: guests,
          capacity: t.capacity,
          x: t.x,
          y: t.y,
          width: t.width,
          height: t.height,
          isRound: t.isRound,
          elapsedText: 'Just seated',
          currentStatusText: 'Browsing Menu',
        );
      }
      return t;
    }).toList();
  }
}

// ── Screen Class ──────────────────────────────────────────────────────────────
class LiveFloorplanScreen extends ConsumerWidget {
  const LiveFloorplanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tables = ref.watch(liveTablesProvider);
    final activeSection = ref.watch(activeSectionProvider);
    final desktop = MediaQuery.of(context).size.width >= 960;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Live Floorplan Monitor',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18.sp,
          ),
        ),
        backgroundColor: AppTheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
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
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: desktop ? 32.w : 16.w,
            vertical: 20.h,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Section Switcher Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live Floorplan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: desktop ? 24.sp : 20.sp,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Operational dashboard tracking dining phases & service stages.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.sp,
                          color: AppTheme.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  // Room Selector Toggle
                  Container(
                    padding: EdgeInsets.all(4.r),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                    child: Row(
                      children: [
                        _buildSectionToggle(
                          ref,
                          0,
                          'Dining Room',
                          activeSection == 0,
                        ),
                        _buildSectionToggle(
                          ref,
                          1,
                          'Patio Deck',
                          activeSection == 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // Legend indicators
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppTheme.surfaceContainerHigh),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildLegendItem(Colors.green, 'Vacant'),
                    _buildLegendItem(Colors.amber.shade600, 'Seated'),
                    _buildLegendItem(Colors.orange, 'Cooking'),
                    _buildLegendItem(Colors.blue, 'Dining'),
                    _buildLegendItem(Colors.purple, 'Bill'),
                  ],
                ),
              ),
              SizedBox(height: 16.h),

              // Interactive Floor Canvas
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AppTheme.surfaceContainerHigh),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x02000000),
                        blurRadius: 16,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.r),
                    child: Stack(
                      children: [
                        // Blueprint grid paper background
                        Positioned.fill(
                          child: CustomPaint(painter: _FloorGridPainter()),
                        ),

                        // Draw tables relative positioning
                        Positioned.fill(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final w = constraints.maxWidth;
                              final h = constraints.maxHeight;

                              return Stack(
                                children: tables.map((table) {
                                  final leftPos = table.x * w;
                                  final topPos = table.y * h;

                                  return Positioned(
                                    left: leftPos,
                                    top: topPos,
                                    child: _buildTableWidget(
                                      context,
                                      ref,
                                      table,
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ),

                        // FAB to quickly add guests or seat manually at bottom right
                        Positioned(
                          right: 20.w,
                          bottom: 20.h,
                          child: FloatingActionButton(
                            onPressed: () {
                              _showQuickSeatDialog(context, ref, tables);
                            },
                            backgroundColor: AppTheme.primary,
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 24.r,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionToggle(
    WidgetRef ref,
    int index,
    String label,
    bool active,
  ) {
    return GestureDetector(
      onTap: () {
        ref.read(activeSectionProvider.notifier).state = index;
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: active ? AppTheme.surfaceContainerLowest : Colors.transparent,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: active
              ? const [
                  BoxShadow(
                    color: Color(0x04000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.sp,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            color: active ? AppTheme.primary : AppTheme.secondary,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8.r,
          height: 8.r,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 6.w),
        Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.secondary,
          ),
        ),
      ],
    );
  }

  // ── Table Element Builder ───────────────────────────────────────────────────
  Widget _buildTableWidget(
    BuildContext context,
    WidgetRef ref,
    LiveTableNode table,
  ) {
    final Color borderCol = switch (table.phase) {
      TableDiningPhase.vacant => Colors.green,
      TableDiningPhase.seated => Colors.amber.shade600,
      TableDiningPhase.cooking => Colors.orange,
      TableDiningPhase.dining => Colors.blue,
      TableDiningPhase.waitingForBill => Colors.purple,
    };

    final Color textCol = borderCol;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _showTableDetailDrawer(context, ref, table);
        },
        borderRadius: BorderRadius.circular(table.isRound ? 99.r : 12.r),
        child: Container(
          width: table.width,
          height: table.height,
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            shape: table.isRound ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: table.isRound ? null : BorderRadius.circular(12.r),
            border: Border.all(color: borderCol, width: 2.w),
            boxShadow: const [
              BoxShadow(
                color: Color(0x04000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                table.label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.onSurface,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chair_rounded,
                    color: textCol.withValues(alpha: 0.8),
                    size: 12.r,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    '${table.activeGuests}/${table.capacity}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: textCol,
                    ),
                  ),
                ],
              ),
              if (table.currentStatusText.isNotEmpty) ...[
                SizedBox(height: 2.h),
                Text(
                  table.currentStatusText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w800,
                    color: textCol,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Seating Trigger Drawer ──────────────────────────────────────────────────
  void _showTableDetailDrawer(
    BuildContext context,
    WidgetRef ref,
    LiveTableNode table,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 32.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Table Details — ${table.label}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      Text(
                        'Capacity: ${table.capacity} Seating Seats',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.sp,
                          color: AppTheme.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      table.phase.name.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Divider(
                height: 1.h,
                thickness: 1.h,
                color: AppTheme.surfaceContainerHigh,
              ),
              SizedBox(height: 16.h),

              if (table.phase == TableDiningPhase.vacant) ...[
                Text(
                  'Seat Guests (Manual Seating Trigger)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.onSurface,
                  ),
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    _buildSeatButton(context, ref, table.label, 2),
                    SizedBox(width: 8.w),
                    _buildSeatButton(context, ref, table.label, 4),
                    SizedBox(width: 8.w),
                    if (table.capacity >= 6) ...[
                      _buildSeatButton(context, ref, table.label, 6),
                    ],
                  ],
                ),
              ] else ...[
                _buildDetailRow(
                  Icons.timer_rounded,
                  'Session Duration',
                  table.elapsedText,
                ),
                _buildDetailRow(
                  Icons.room_service_rounded,
                  'Dining Status',
                  table.currentStatusText,
                ),
                _buildDetailRow(
                  Icons.people_rounded,
                  'Assigned Waiter',
                  'Maria (Server)',
                ),
                SizedBox(height: 12.h),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back to Floorplan'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSeatButton(
    BuildContext context,
    WidgetRef ref,
    String label,
    int count,
  ) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          ref.read(liveTablesProvider.notifier).seatGuests(label, count);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Seated party of $count at $label successfully!'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.teal,
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        child: Text('$count Guests'),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.secondary, size: 18.r),
          SizedBox(width: 12.w),
          Text(
            '$label: ',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.secondary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              color: AppTheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickSeatDialog(
    BuildContext context,
    WidgetRef ref,
    List<LiveTableNode> tables,
  ) {
    final vacant = tables
        .where((t) => t.phase == TableDiningPhase.vacant)
        .toList();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            'Quick Manual Seating',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
          ),
          content: vacant.isEmpty
              ? const Text('All tables are currently occupied!')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: vacant.map((t) {
                    return ListTile(
                      leading: Icon(
                        Icons.table_restaurant_rounded,
                        color: Colors.green,
                      ),
                      title: Text(t.label),
                      subtitle: Text('Capacity: ${t.capacity}'),
                      onTap: () {
                        Navigator.pop(context);
                        ref
                            .read(liveTablesProvider.notifier)
                            .seatGuests(t.label, t.capacity);
                      },
                    );
                  }).toList(),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}

// ── Blueprint Custom Painter ─────────────────────────────────────────────────
class _FloorGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final gridPaint = Paint()
      ..color = AppTheme.surfaceContainerHigh.withValues(alpha: 0.3)
      ..strokeWidth = 1.0;

    const step = 20.0;

    // Draw vertical lines
    for (double x = 0; x < w; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }

    // Draw horizontal lines
    for (double y = 0; y < h; y += step) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
