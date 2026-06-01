import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../tables_infrastructure/presentation/state/table_infrastructure_providers.dart';

// ── Models & State ────────────────────────────────────────────────────────────
class WaiterCall {
  final String id;
  final String tableLabel;
  final String waitTime;
  final String requestType; // 'Assistance' or 'Bill Request'
  final bool isUrgent;

  WaiterCall({
    required this.id,
    required this.tableLabel,
    required this.waitTime,
    required this.requestType,
    this.isUrgent = false,
  });
}

class GuestSession {
  final String id;
  final String tableLabel;
  final String seatedTime;
  final String idleTime;
  final bool isIdle;
  final List<String> guestNames;
  final List<String> guestAvatars;
  final List<String> cartItems;
  final double cartTotal;
  final String status;

  GuestSession({
    required this.id,
    required this.tableLabel,
    required this.seatedTime,
    this.idleTime = '',
    required this.isIdle,
    required this.guestNames,
    required this.guestAvatars,
    required this.cartItems,
    required this.cartTotal,
    required this.status,
  });
}

// Waiter calls state provider
final waiterCallsProvider =
    StateNotifierProvider<WaiterCallsNotifier, List<WaiterCall>>((ref) {
      return WaiterCallsNotifier();
    });

class WaiterCallsNotifier extends StateNotifier<List<WaiterCall>> {
  WaiterCallsNotifier()
    : super([
        WaiterCall(
          id: 'call-1',
          tableLabel: 'Table 5',
          waitTime: '4m waiting',
          requestType: 'Assistance',
          isUrgent: true,
        ),
        WaiterCall(
          id: 'call-2',
          tableLabel: 'Table 12',
          waitTime: '2m waiting',
          requestType: 'Bill Request',
          isUrgent: true,
        ),
      ]);

  void removeCall(String id) {
    state = state.where((c) => c.id != id).toList();
  }
}

// Diner sessions state provider
final guestSessionsProvider =
    StateNotifierProvider<GuestSessionsNotifier, List<GuestSession>>((ref) {
      return GuestSessionsNotifier();
    });

class GuestSessionsNotifier extends StateNotifier<List<GuestSession>> {
  GuestSessionsNotifier()
    : super([
        GuestSession(
          id: 'session-1',
          tableLabel: 'Table 4',
          seatedTime: '25m seated',
          isIdle: false,
          guestNames: ['Sarah', 'Mike'],
          guestAvatars: ['S', 'M'],
          cartItems: ['2x Wagyu Burger', '1x Truffle Fries', '2x Craft Cola'],
          cartTotal: 68.00,
          status: 'Active',
        ),
        GuestSession(
          id: 'session-2',
          tableLabel: 'Table 8',
          seatedTime: '45m seated',
          idleTime: 'Idle 45m',
          isIdle: true,
          guestNames: ['James'],
          guestAvatars: ['J'],
          cartItems: ['1x Espresso'],
          cartTotal: 4.50,
          status: 'Idle Warning',
        ),
        GuestSession(
          id: 'session-3',
          tableLabel: 'Table 1',
          seatedTime: '10m seated',
          isIdle: false,
          guestNames: ['Party of 3'],
          guestAvatars: ['G1', 'G2', 'G3'],
          cartItems: ['Browsing menu...'],
          cartTotal: 0.00,
          status: 'Active',
        ),
      ]);
}

// ── Screen Class ──────────────────────────────────────────────────────────────
class GuestSessionsScreen extends ConsumerWidget {
  const GuestSessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calls = ref.watch(waiterCallsProvider);
    final sessions = ref.watch(guestSessionsProvider);

    final floorsAsync = ref.watch(floorsFutureProvider);
    final tablesAsync = ref.watch(tablesFutureProvider);
    final activeFloorId = ref.watch(activeFloorIdProvider);

    final desktop = MediaQuery.of(context).size.width >= 960;

    floorsAsync.whenData((floors) {
      if (activeFloorId == null && floors.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(activeFloorIdProvider.notifier).state = floors.first.id;
        });
      }
    });

    final tablesList = tablesAsync.value ?? [];
    final activeFloorTables = tablesList.where((t) => t.floorId == activeFloorId).toList();
    final activeTableNumbers = activeFloorTables.map((t) => t.tableNumber.toLowerCase()).toSet();

    // Filter sessions & calls by active floor tables
    final filteredSessions = sessions.where((s) {
      return activeTableNumbers.contains(s.tableLabel.toLowerCase());
    }).toList();

    final filteredCalls = calls.where((c) {
      return activeTableNumbers.contains(c.tableLabel.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Diner Activity Monitor',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18.sp,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline_rounded,
                color: AppTheme.primary, size: 24.r),
            onPressed: () {
              _showAddFloorDialog(context, ref);
            },
            tooltip: 'Add Floor',
          ),
          Container(
            margin: EdgeInsets.only(right: 16.w),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                      width: 6.r,
                      height: 6.r,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .fadeOut(duration: 500.ms),
                SizedBox(width: 6.w),
                Text(
                  'Live Sync',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
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
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Page Title Description Header
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 8.h),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Floor Engagement',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: desktop ? 24.sp : 20.sp,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Real-time view of active diner carts, elapsed seating times, and unresolved waiter calls.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.sp,
                        color: AppTheme.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Floor Selector Toggle Row
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              sliver: SliverToBoxAdapter(
                child: floorsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (floors) {
                    if (floors.isEmpty) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        child: Text(
                          'No floors created yet. Click the + button in the app bar to add a floor.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.sp,
                            color: AppTheme.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }
                    return SizedBox(
                      height: 48.h,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: EdgeInsets.all(4.r),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(30.r),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: floors.map((f) {
                                  return _buildSectionToggle(
                                    ref,
                                    f.id,
                                    f.name,
                                    activeFloorId == f.id,
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            if (tablesList.isEmpty || activeFloorTables.isEmpty) ...[
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 48.h),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(24.r),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLow,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          tablesList.isEmpty
                              ? Icons.table_restaurant_rounded
                              : Icons.layers_clear_rounded,
                          size: 64.r,
                          color: AppTheme.secondary.withValues(alpha: 0.5),
                        ),
                      ),
                      SizedBox(height: 24.h),
                      Text(
                        tablesList.isEmpty
                            ? 'No Tables Placed Yet'
                            : 'No Tables on this Floor',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        tablesList.isEmpty
                            ? 'To track diner activity and waiter calls, you first need to design your floorplan and place tables.'
                            : 'No tables are placed on the active floor. Go to the Floorplan Monitor to add tables.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.sp,
                          color: AppTheme.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Active Waiter Calls section
              SliverPadding(
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Icon(
                        Icons.campaign_rounded,
                        color: AppTheme.primary,
                        size: 20.r,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Active Waiter Calls',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      if (filteredCalls.isNotEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Text(
                            '${filteredCalls.length} URGENT',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Waiter Calls horizontal/grid view
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                sliver: SliverToBoxAdapter(
                  child: filteredCalls.isEmpty
                      ? Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 24.h),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: AppTheme.surfaceContainerHigh,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'No pending waiter calls ✅',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.sp,
                                color: AppTheme.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredCalls.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: desktop ? 3 : 1,
                            crossAxisSpacing: 12.w,
                            mainAxisSpacing: 12.h,
                            mainAxisExtent: 140.h,
                          ),
                          itemBuilder: (context, i) {
                            final call = filteredCalls[i];
                            return _WaiterCallCard(call: call);
                          },
                        ),
                ),
              ),

              // Active Sessions & Carts Section Header
              SliverPadding(
                padding: EdgeInsets.fromLTRB(20.w, 28.h, 20.w, 8.h),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.table_restaurant_rounded,
                            color: AppTheme.secondary,
                            size: 20.r,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Active Carts & Sessions',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      // Legends
                      Row(
                        children: [
                          _buildStatusLegend(Colors.green, 'Active'),
                          SizedBox(width: 12.w),
                          _buildStatusLegend(AppTheme.primary, 'Idle > 30m'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Active Sessions Grid / Empty State
              if (filteredSessions.isEmpty)
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 40.h),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: AppTheme.surfaceContainerHigh,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.no_accounts_rounded,
                            size: 40.r,
                            color: AppTheme.secondary.withValues(alpha: 0.5),
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            'No Active Diner Sessions',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.onSurface,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Scan the table QR code to start a session.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.sp,
                              color: AppTheme.secondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 40.h),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: desktop
                          ? 4
                          : (MediaQuery.of(context).size.width >= 600 ? 2 : 1),
                      crossAxisSpacing: 12.w,
                      mainAxisSpacing: 12.h,
                      childAspectRatio: desktop ? 1.05 : 1.25,
                    ),
                    delegate: SliverChildBuilderDelegate((context, i) {
                      final session = filteredSessions[i];
                      return _SessionGridCard(session: session);
                    }, childCount: filteredSessions.length),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionToggle(
    WidgetRef ref,
    String floorId,
    String label,
    bool active,
  ) {
    return GestureDetector(
      onTap: () {
        ref.read(activeFloorIdProvider.notifier).state = floorId;
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

  void _showAddFloorDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            'Create New Floor',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 16.sp,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Floor Name',
              hintText: 'e.g., Floor 2, Terrace, Rooftop',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
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
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  ref.read(floorsFutureProvider.notifier).addFloor(name);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Adding Floor "$name"...'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.teal,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                'Create',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusLegend(Color color, String text) {
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
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.secondary,
          ),
        ),
      ],
    );
  }
}

// ── Helper Widgets ───────────────────────────────────────────────────────────
class _WaiterCallCard extends ConsumerWidget {
  final WaiterCall call;
  const _WaiterCallCard({required this.call});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.r),
        border: Border(
          left: BorderSide(color: AppTheme.primary, width: 4.w),
          top: BorderSide(color: AppTheme.surfaceContainerHigh, width: 1.w),
          right: BorderSide(color: AppTheme.surfaceContainerHigh, width: 1.w),
          bottom: BorderSide(color: AppTheme.surfaceContainerHigh, width: 1.w),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x02000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    call.tableLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  Text(
                    call.waitTime,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.sp,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppTheme.errorContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  call.requestType,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.error,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Assign call
                    ref.read(waiterCallsProvider.notifier).removeCall(call.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Assigned ${call.tableLabel} to server.'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: Size(0, 32.h),
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text(
                    'Assign',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // Acknowledge call
                    ref.read(waiterCallsProvider.notifier).removeCall(call.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Acknowledged ${call.tableLabel} call.'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppTheme.primary,
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.onSurface,
                    side: const BorderSide(
                      color: AppTheme.surfaceContainerHigh,
                    ),
                    minimumSize: Size(0, 32.h),
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text(
                    'Acknowledge',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SessionGridCard extends StatelessWidget {
  final GuestSession session;
  const _SessionGridCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final statusColor = session.isIdle ? AppTheme.primary : Colors.green;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: session.isIdle
            ? AppTheme.errorContainer.withValues(alpha: 0.1)
            : AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: session.isIdle
              ? AppTheme.primary.withValues(alpha: 0.2)
              : AppTheme.surfaceContainerHigh,
          width: 1.w,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x02000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8.r,
                    height: 8.r,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    session.tableLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: session.isIdle
                      ? AppTheme.primaryContainer.withValues(alpha: 0.08)
                      : AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  session.isIdle ? session.idleTime : session.seatedTime,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w800,
                    color: session.isIdle
                        ? AppTheme.primary
                        : AppTheme.secondary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Guest Names / Party size
          Row(
            children: [
              // Circular avatar indicators
              Row(
                children: List.generate(session.guestAvatars.length, (i) {
                  return Container(
                    margin: EdgeInsets.only(
                      right: i == session.guestAvatars.length - 1 ? 0 : 4.w,
                    ),
                    child: CircleAvatar(
                      radius: 12.r,
                      backgroundColor: AppTheme.surfaceContainerLow,
                      child: Text(
                        session.guestAvatars[i],
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  session.guestNames.join(', '),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.secondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Cart items summary
          Expanded(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppTheme.surfaceContainerHigh),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: session.cartItems.length,
                      itemBuilder: (context, idx) {
                        final item = session.cartItems[idx];
                        final isItalic = item == 'Browsing menu...';
                        return Padding(
                          padding: EdgeInsets.only(bottom: 2.h),
                          child: Text(
                            item,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.sp,
                              color: isItalic
                                  ? AppTheme.secondary
                                  : AppTheme.onSurface,
                              fontStyle: isItalic
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ),
                  ),
                  if (session.isIdle)
                    Text(
                      'No additions in 40m',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.sp,
                        color: AppTheme.primary,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12.h),

          // Card Footer
          Divider(
            height: 1.h,
            thickness: 1.h,
            color: AppTheme.surfaceContainerHigh,
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cart Total',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.secondary,
                ),
              ),
              Text(
                '₹${session.cartTotal.toStringAsFixed(2)}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
