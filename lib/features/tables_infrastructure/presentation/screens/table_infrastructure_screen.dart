import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/dtos/table_dto.dart';
import '../state/table_infrastructure_providers.dart';

// ── Local State & Interaction Providers ───────────────────────────────────────
enum EditorTool { select, drawZone, addLabel, multiSelect }

final selectedToolProvider = StateProvider<EditorTool>(
  (ref) => EditorTool.select,
);

// Table node layout positioning coordinates local state (mapped by table ID)
class NodePosition {
  final double x; // Percent (0.0 to 1.0)
  final double y; // Percent (0.0 to 1.0)
  final double angle; // Rotation in radians
  final bool isSelected;

  NodePosition({
    required this.x,
    required this.y,
    this.angle = 0.0,
    this.isSelected = false,
  });

  NodePosition copyWith({
    double? x,
    double? y,
    double? angle,
    bool? isSelected,
  }) {
    return NodePosition(
      x: x ?? this.x,
      y: y ?? this.y,
      angle: angle ?? this.angle,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

final tablePositionsProvider =
    StateNotifierProvider<TablePositionsNotifier, Map<String, NodePosition>>((
      ref,
    ) {
      return TablePositionsNotifier();
    });

class TablePositionsNotifier extends StateNotifier<Map<String, NodePosition>> {
  TablePositionsNotifier() : super({});

  void initialize(List<TableDto> tables) {
    if (state.isNotEmpty) return;
    final Map<String, NodePosition> initial = {};
    for (int i = 0; i < tables.length; i++) {
      final t = tables[i];
      // Default spacing logic
      final row = i ~/ 3;
      final col = i % 3;
      initial[t.id] = NodePosition(x: 0.15 + (col * 0.2), y: 0.2 + (row * 0.2));
    }
    state = initial;
  }

  void updatePosition(String id, double dx, double dy) {
    if (!state.containsKey(id)) return;
    state = {
      ...state,
      id: state[id]!.copyWith(
        x: (state[id]!.x + dx).clamp(0.02, 0.92),
        y: (state[id]!.y + dy).clamp(0.02, 0.88),
      ),
    };
  }

  void selectNode(String id) {
    state = state.map((key, val) {
      return MapEntry(key, val.copyWith(isSelected: key == id));
    });
  }

  void clearSelection() {
    state = state.map((key, val) {
      return MapEntry(key, val.copyWith(isSelected: false));
    });
  }

  void addPosition(String id, double x, double y) {
    state = {...state, id: NodePosition(x: x, y: y)};
  }
}

// Bulk QR PDF build checked set
final checkedQrTablesProvider = StateProvider<Set<String>>((ref) => {});

// ── Screen Class ──────────────────────────────────────────────────────────────
class TableInfrastructureScreen extends ConsumerWidget {
  const TableInfrastructureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesAsync = ref.watch(tablesFutureProvider);
    final selectedTool = ref.watch(selectedToolProvider);
    final tablePositions = ref.watch(tablePositionsProvider);
    final checkedTables = ref.watch(checkedQrTablesProvider);

    final desktop = MediaQuery.of(context).size.width >= 960;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Floorplan Editor & QR Builder',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18.sp,
          ),
        ),
        backgroundColor: AppTheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Mass Builder trigger
          ElevatedButton.icon(
            onPressed: () {
              _showMassQrPanel(context, ref);
            },
            icon: Icon(
              Icons.qr_code_scanner_rounded,
              size: 16.r,
              color: Colors.white,
            ),
            label: Text(
              'Mass QR Builder',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 11.sp,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryContainer,
              foregroundColor: Colors.white,
              minimumSize: Size(130.w, 36.h),
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
              ),
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
      body: tablesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Error loading tables: $err',
            style: GoogleFonts.plusJakartaSans(color: AppTheme.error),
          ),
        ),
        data: (tables) {
          // Initialize default nodes position if empty
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(tablePositionsProvider.notifier).initialize(tables);
            // Default select all tables for bulk builder
            if (checkedTables.isEmpty) {
              ref.read(checkedQrTablesProvider.notifier).state = tables
                  .map((t) => t.id)
                  .toSet();
            }
          });

          return SafeArea(
            child: Row(
              children: [
                // 1. Sidebar Tools (Round, Rectangle, Booth library - desktop only)
                if (desktop) _buildSidebarTools(context, ref, selectedTool),

                // 2. Gridded Vector Canvas
                Expanded(
                  child: Container(
                    color: AppTheme.surfaceContainerLow,
                    child: Column(
                      children: [
                        // Mobile Toolbar (Top scroll)
                        if (!desktop)
                          _buildMobileToolbar(context, ref, selectedTool),

                        Expanded(
                          child: Stack(
                            children: [
                              // Grid background Custom Painter
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _BlueprintGridPainter(),
                                ),
                              ),

                              // Zone boundary outline dividers
                              Positioned.fill(
                                child: _buildZoneOutlineBoundaries(desktop),
                              ),

                              // Render drag-and-drop table nodes
                              Positioned.fill(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final canvasWidth = constraints.maxWidth;
                                    final canvasHeight = constraints.maxHeight;

                                    return Stack(
                                      children: tables.map((table) {
                                        final pos =
                                            tablePositions[table.id] ??
                                            NodePosition(x: 0.3, y: 0.3);

                                        final pixelX = pos.x * canvasWidth;
                                        final pixelY = pos.y * canvasHeight;

                                        return Positioned(
                                          left: pixelX,
                                          top: pixelY,
                                          child: _buildDraggableTableNode(
                                            context,
                                            ref,
                                            table,
                                            pos,
                                            canvasWidth,
                                            canvasHeight,
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  },
                                ),
                              ),

                              // Zoom indicator controls overlay
                              Positioned(
                                right: 16.w,
                                bottom: 16.h,
                                child: _buildZoomControls(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Vector Tools Layouts ────────────────────────────────────────────────────
  Widget _buildSidebarTools(
    BuildContext context,
    WidgetRef ref,
    EditorTool tool,
  ) {
    return Container(
      width: 260.w,
      height: double.infinity,
      color: AppTheme.surfaceContainerLowest,
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Editor Tools',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: AppTheme.onSurface,
            ),
          ),
          SizedBox(height: 12.h),

          // Tools list
          _buildToolBtn(
            ref,
            EditorTool.select,
            'Select / Move',
            Icons.near_me_rounded,
            tool,
          ),
          _buildToolBtn(
            ref,
            EditorTool.drawZone,
            'Draw Zone Area',
            Icons.architecture,
            tool,
          ),
          _buildToolBtn(
            ref,
            EditorTool.addLabel,
            'Add Custom Label',
            Icons.label_outline_rounded,
            tool,
          ),
          _buildToolBtn(
            ref,
            EditorTool.multiSelect,
            'Multi-Select',
            Icons.check_box_outlined,
            tool,
          ),

          SizedBox(height: 24.h),
          Divider(height: 1.h, color: AppTheme.surfaceContainerHigh),
          SizedBox(height: 20.h),

          Text(
            'Shapes Library',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
              color: AppTheme.onSurface,
            ),
          ),
          SizedBox(height: 12.h),

          // Draggable library grid
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10.w,
              mainAxisSpacing: 10.h,
              childAspectRatio: 1.1,
              children: [
                _buildLibraryShapeCard(
                  context,
                  ref,
                  'Round',
                  Icons.circle_outlined,
                ),
                _buildLibraryShapeCard(
                  context,
                  ref,
                  'Rectangle',
                  Icons.crop_din_rounded,
                ),
                _buildLibraryShapeCard(
                  context,
                  ref,
                  'Booth Table',
                  Icons.table_rows_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileToolbar(
    BuildContext context,
    WidgetRef ref,
    EditorTool tool,
  ) {
    return Container(
      height: 48.h,
      color: AppTheme.surfaceContainerLowest,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        children: [
          _buildMobileToolIcon(
            ref,
            EditorTool.select,
            Icons.near_me_rounded,
            tool,
          ),
          _buildMobileToolIcon(
            ref,
            EditorTool.drawZone,
            Icons.architecture,
            tool,
          ),
          _buildMobileToolIcon(
            ref,
            EditorTool.multiSelect,
            Icons.check_box_outlined,
            tool,
          ),
          VerticalDivider(
            width: 16.w,
            thickness: 1.w,
            color: AppTheme.surfaceContainerHigh,
          ),
          _buildMobileShapeTextBtn(context, ref, 'Round'),
          SizedBox(width: 8.w),
          _buildMobileShapeTextBtn(context, ref, 'Rectangle'),
        ],
      ),
    );
  }

  Widget _buildToolBtn(
    WidgetRef ref,
    EditorTool current,
    String text,
    IconData icon,
    EditorTool active,
  ) {
    final isSel = current == active;
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: InkWell(
        onTap: () => ref.read(selectedToolProvider.notifier).state = current,
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: isSel
                ? AppTheme.primaryContainer.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: isSel
                  ? AppTheme.primaryContainer.withValues(alpha: 0.2)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSel ? AppTheme.primary : AppTheme.secondary,
                size: 18.r,
              ),
              SizedBox(width: 12.w),
              Text(
                text,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp,
                  fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                  color: isSel ? AppTheme.primary : AppTheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileToolIcon(
    WidgetRef ref,
    EditorTool current,
    IconData icon,
    EditorTool active,
  ) {
    final isSel = current == active;
    return Container(
      margin: EdgeInsets.only(right: 6.w),
      child: IconButton(
        icon: Icon(
          icon,
          color: isSel ? AppTheme.primary : AppTheme.secondary,
          size: 20.r,
        ),
        style: IconButton.styleFrom(
          backgroundColor: isSel
              ? AppTheme.primaryContainer.withValues(alpha: 0.1)
              : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        onPressed: () =>
            ref.read(selectedToolProvider.notifier).state = current,
      ),
    );
  }

  Widget _buildMobileShapeTextBtn(
    BuildContext context,
    WidgetRef ref,
    String text,
  ) {
    return ElevatedButton(
      onPressed: () => _addLibraryTable(context, ref, text),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.surfaceContainerLowest,
        foregroundColor: AppTheme.onSurface,
        elevation: 0,
        minimumSize: Size(80.w, 36.h),
        side: const BorderSide(color: AppTheme.surfaceContainerHigh),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        padding: EdgeInsets.symmetric(horizontal: 12.w),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildLibraryShapeCard(
    BuildContext context,
    WidgetRef ref,
    String label,
    IconData icon,
  ) {
    return InkWell(
      onTap: () {
        _addLibraryTable(context, ref, label);
      },
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppTheme.surfaceContainerHigh),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.secondary, size: 24.r),
            SizedBox(height: 6.h),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.sp,
                color: AppTheme.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addLibraryTable(BuildContext context, WidgetRef ref, String shapeType) {
    // Generate a quick mock table ID and position
    final id = 'table-mock-${DateTime.now().millisecond}';
    final label = 'T-${math.Random().nextInt(20) + 20}';
    ref.read(tablePositionsProvider.notifier).addPosition(id, 0.4, 0.4);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added new $shapeType Table ($label) to the canvas!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.teal,
      ),
    );
  }

  // ── Zones Boundaries Builder ───────────────────────────────────────────────
  Widget _buildZoneOutlineBoundaries(bool desktop) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return Stack(
          children: [
            // Zone 1: Main Dining Hall
            Positioned(
              left: w * 0.05,
              top: h * 0.05,
              width: w * 0.55,
              height: h * 0.85,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: AppTheme.secondary.withValues(alpha: 0.3),
                    width: 2.w,
                    style: BorderStyle
                        .none, // We will paint dashes or simple border
                  ),
                ),
                child: Center(
                  child: Opacity(
                    opacity: 0.15,
                    child: Text(
                      'MAIN HALL',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: desktop ? 40.sp : 24.sp,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.secondary,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Zone divider
            Positioned(
              left: w * 0.65,
              top: h * 0.05,
              bottom: h * 0.05,
              child: const VerticalDivider(
                color: AppTheme.surfaceContainerHigh,
                thickness: 2,
              ),
            ),

            // Zone 2: Lounge
            Positioned(
              left: w * 0.70,
              top: h * 0.05,
              width: w * 0.25,
              height: h * 0.4,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Center(
                  child: Opacity(
                    opacity: 0.15,
                    child: Text(
                      'LOUNGE',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: desktop ? 24.sp : 16.sp,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.secondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Zone 3: Outdoor Patio
            Positioned(
              left: w * 0.70,
              top: h * 0.50,
              width: w * 0.25,
              height: h * 0.4,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Center(
                  child: Opacity(
                    opacity: 0.15,
                    child: Text(
                      'PATIO DECK',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: desktop ? 24.sp : 16.sp,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.secondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Draggable Table Node Builder ────────────────────────────────────────────
  Widget _buildDraggableTableNode(
    BuildContext context,
    WidgetRef ref,
    TableDto table,
    NodePosition pos,
    double canvasWidth,
    double canvasHeight,
  ) {
    final isRound = table.label.contains('L') || table.capacity == 2;
    final size = pos.isSelected ? 100.r : 90.r;

    return GestureDetector(
      onPanUpdate: (details) {
        // Drag update relative to canvas size
        final dx = details.delta.dx / canvasWidth;
        final dy = details.delta.dy / canvasHeight;
        ref
            .read(tablePositionsProvider.notifier)
            .updatePosition(table.id, dx, dy);
      },
      onTap: () {
        ref.read(tablePositionsProvider.notifier).selectNode(table.id);
      },
      child: Transform.rotate(
        angle: pos.angle,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: pos.isSelected
                ? AppTheme.primaryContainer.withValues(alpha: 0.08)
                : AppTheme.surfaceContainerLowest,
            shape: isRound ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: isRound ? null : BorderRadius.circular(8.r),
            border: Border.all(
              color: pos.isSelected ? AppTheme.primary : AppTheme.secondary,
              width: pos.isSelected ? 2.5.w : 1.5.w,
            ),
            boxShadow: [
              BoxShadow(
                color: pos.isSelected
                    ? AppTheme.primary.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: pos.isSelected ? 16 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Table label DTO name
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    table.label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: pos.isSelected
                          ? AppTheme.primary
                          : AppTheme.onSurface,
                    ),
                  ),
                  Text(
                    'Cap: ${table.capacity}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.secondary,
                    ),
                  ),
                ],
              ),

              // Checked Badge (if selected for bulk QR builder)
              if (ref.watch(checkedQrTablesProvider).contains(table.id))
                Positioned(
                  top: -6.h,
                  left: -6.w,
                  child: Container(
                    width: 20.r,
                    height: 20.r,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check, color: Colors.white, size: 12.r),
                  ),
                ),

              // Selection border handles (only when selected)
              if (pos.isSelected) ...[
                Positioned(top: -4.h, left: -4.w, child: _buildHandleDot()),
                Positioned(top: -4.h, right: -4.w, child: _buildHandleDot()),
                Positioned(bottom: -4.h, left: -4.w, child: _buildHandleDot()),
                Positioned(bottom: -4.h, right: -4.w, child: _buildHandleDot()),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandleDot() {
    return Container(
      width: 8.r,
      height: 8.r,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.primary, width: 2.w),
      ),
    );
  }

  Widget _buildZoomControls() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppTheme.surfaceContainerHigh),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.remove, size: 16.r, color: AppTheme.secondary),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
            onPressed: () {},
          ),
          SizedBox(width: 8.w),
          Text(
            '100%',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurface,
            ),
          ),
          SizedBox(width: 8.w),
          IconButton(
            icon: Icon(Icons.add, size: 16.r, color: AppTheme.secondary),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  // ── Mass QR Builder Bottom Sheet ────────────────────────────────────────────
  void _showMassQrPanel(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return _MassQrBuilderPanel();
      },
    );
  }
}

// Separate StatefulWidget to handle internal checkbox state and generation progress
class _MassQrBuilderPanel extends ConsumerStatefulWidget {
  @override
  ConsumerState<_MassQrBuilderPanel> createState() =>
      _MassQrBuilderPanelState();
}

class _MassQrBuilderPanelState extends ConsumerState<_MassQrBuilderPanel> {
  bool _isBuilding = false;
  double _buildProgress = 0.0;

  void _startPdfBuildSequence(Set<String> selectedTableIds) async {
    setState(() {
      _isBuilding = true;
      _buildProgress = 0.0;
    });

    // Simulated progress build sequence
    for (int i = 0; i <= 10; i++) {
      await Future.delayed(200.ms);
      if (mounted) {
        setState(() {
          _buildProgress = i / 10.0;
        });
      }
    }

    if (mounted) {
      setState(() {
        _isBuilding = false;
      });
      Navigator.pop(context);
      _showBuildSuccessDialog(selectedTableIds.length);
    }
  }

  void _showBuildSuccessDialog(int count) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'QR Package Ready!',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.picture_as_pdf_rounded,
              color: AppTheme.primary,
              size: 48.r,
            ),
            SizedBox(height: 12.h),
            Text(
              'Successfully compiled $count high-resolution tables access cards.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                fontSize: 13.sp,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'File: orderlyy_qr_package.pdf (1.2 MB)',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10.sp,
                color: AppTheme.secondary,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            child: const Text('Download PDF'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tablesAsync = ref.watch(tablesFutureProvider);
    final checkedSet = ref.watch(checkedQrTablesProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 32.h),
      child: tablesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
        error: (err, _) => Text('Error loading: $err'),
        data: (tables) {
          return Column(
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
              SizedBox(height: 16.h),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.picture_as_pdf_rounded,
                        color: AppTheme.primary,
                        size: 20.r,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Mass QR Code PDF Builder',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 20.r,
                      color: AppTheme.secondary,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                'Generate styled PDF table packages automatically. Secure access URL is generated for each card.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp,
                  color: AppTheme.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 16.h),

              // Build sequence overlay or listing
              if (_isBuilding) ...[
                Container(
                  padding: EdgeInsets.symmetric(vertical: 24.h),
                  width: double.infinity,
                  child: Column(
                    children: [
                      const CircularProgressIndicator(color: AppTheme.primary),
                      SizedBox(height: 12.h),
                      Text(
                        'Compiling high-resolution PDF cards...',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      SizedBox(
                        width: 200.w,
                        child: LinearProgressIndicator(
                          value: _buildProgress,
                          color: AppTheme.primary,
                          backgroundColor: AppTheme.surfaceContainerLow,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Tables checklist
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 200.h),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: tables.length,
                    separatorBuilder: (context, idx) => SizedBox(height: 6.h),
                    itemBuilder: (context, idx) {
                      final t = tables[idx];
                      final isChecked = checkedSet.contains(t.id);

                      return GestureDetector(
                        onTap: () {
                          final next = Set<String>.from(checkedSet);
                          if (isChecked) {
                            next.remove(t.id);
                          } else {
                            next.add(t.id);
                          }
                          ref.read(checkedQrTablesProvider.notifier).state =
                              next;
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            color: isChecked
                                ? AppTheme.primaryContainer.withValues(
                                    alpha: 0.04,
                                  )
                                : AppTheme.background,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: isChecked
                                  ? AppTheme.primary
                                  : AppTheme.surfaceContainerHigh,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isChecked
                                    ? Icons.check_box_rounded
                                    : Icons.check_box_outline_blank_rounded,
                                color: isChecked
                                    ? AppTheme.primary
                                    : AppTheme.secondary,
                                size: 20.r,
                              ),
                              SizedBox(width: 10.w),
                              Text(
                                'Section: ${t.sectionId} • Table ${t.label}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                isChecked ? 'Included' : 'Excluded',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.sp,
                                  color: isChecked
                                      ? AppTheme.primary
                                      : AppTheme.secondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 20.h),

                // Trigger generation button
                ElevatedButton(
                  onPressed: checkedSet.isEmpty
                      ? null
                      : () => _startPdfBuildSequence(checkedSet),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    disabledBackgroundColor: AppTheme.surfaceContainerHigh,
                  ),
                  child: Text('Generate QR Packages (${checkedSet.length})'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ── Blueprint Custom Painter ─────────────────────────────────────────────────
class _BlueprintGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final gridPaint = Paint()
      ..color = AppTheme.secondaryContainer.withValues(alpha: 0.5)
      ..strokeWidth = 1.0;

    const step = 40.0;

    // Draw vertical grid lines
    for (double x = 0; x < w; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }

    // Draw horizontal grid lines
    for (double y = 0; y < h; y += step) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
