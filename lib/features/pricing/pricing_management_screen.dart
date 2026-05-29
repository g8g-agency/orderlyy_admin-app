import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class PricingManagementScreen extends StatefulWidget {
  const PricingManagementScreen({super.key});

  @override
  State<PricingManagementScreen> createState() =>
      _PricingManagementScreenState();
}

class _PricingManagementScreenState extends State<PricingManagementScreen> {
  // Tabs and toggles
  bool _isWeekView = true;

  // Rule Builder Form States
  final _ruleNameCtrl = TextEditingController(text: 'Happy Hour - Drafts');
  String _ruleType = 'Discount (%)';
  final _ruleValueCtrl = TextEditingController(text: '20');
  final List<String> _targetCategories = ['Draft Beer'];

  // Promo Codes Mock Data list
  final List<Map<String, dynamic>> _promoCodes = [
    {
      'code': 'SUMMER24',
      'subtitle': '10% Off Entire Order',
      'usage': '45/100 Used',
      'expiry': 'Expires in 2 days',
      'isExpiringSoon': true,
    },
    {
      'code': 'LOCALVIP',
      'subtitle': 'Free Appetizer',
      'usage': '∞ Uses',
      'expiry': 'No Expiry',
      'isExpiringSoon': false,
    },
  ];

  @override
  void dispose() {
    _ruleNameCtrl.dispose();
    _ruleValueCtrl.dispose();
    super.dispose();
  }

  void _addTargetCategory() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceContainerLowest,
          title: Text(
            'Add Target Category',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: GoogleFonts.plusJakartaSans(),
            decoration: InputDecoration(
              hintText: 'e.g. Cocktails',
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
                final cat = controller.text.trim();
                if (cat.isNotEmpty) {
                  setState(() {
                    _targetCategories.add(cat);
                  });
                  Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryContainer,
              ),
              child: Text(
                'Add',
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

  void _generatePromoCode() {
    final codeCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceContainerLowest,
          title: Text(
            'Generate Promo Code',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeCtrl,
                textCapitalization: TextCapitalization.characters,
                style: GoogleFonts.plusJakartaSans(),
                decoration: InputDecoration(
                  labelText: 'Promo Code (UPPERCASE)',
                  hintText: 'e.g. FREECOFFEE',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    color: AppTheme.secondary,
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: descCtrl,
                style: GoogleFonts.plusJakartaSans(),
                decoration: InputDecoration(
                  labelText: 'Discount Description',
                  hintText: 'e.g. 15% off espresso drinks',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    color: AppTheme.secondary,
                  ),
                ),
              ),
            ],
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
                final code = codeCtrl.text.trim().toUpperCase();
                final desc = descCtrl.text.trim();
                if (code.isNotEmpty && desc.isNotEmpty) {
                  setState(() {
                    _promoCodes.add({
                      'code': code,
                      'subtitle': desc,
                      'usage': '0 Uses',
                      'expiry': 'No Expiry',
                      'isExpiringSoon': false,
                    });
                  });
                  Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryContainer,
              ),
              child: Text(
                'Generate',
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

  void _saveRule() {
    final name = _ruleNameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a rule name.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
            SizedBox(width: 8.w),
            Text('Dynamic pricing rule "$name" updated successfully.'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.of(context).size.width >= 960;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Pricing Engine',
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
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.surfaceContainerHigh),
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6.r),
              ),
            ),
            child: Text(
              'Export Rules',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 11.sp,
                color: AppTheme.onSurface,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          ElevatedButton.icon(
            onPressed: _saveRule,
            icon: Icon(Icons.add_rounded, size: 16.r, color: Colors.white),
            label: Text(
              'New Rule',
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
              constraints: BoxConstraints(maxWidth: 1300.w),
              child: desktop
                  ? Column(
                      children: [
                        // Weekly calendar view full width
                        _buildWeeklyCalendarSection(context),
                        SizedBox(height: 24.h),

                        // Form builder + Codes side-by-side
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildRuleBuilderCard(context)),
                            SizedBox(width: 24.w),
                            Expanded(child: _buildPromoCodesCard(context)),
                          ],
                        ),
                      ],
                    )
                  : Column(
                      // Mobile stacked
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWeeklyCalendarSection(context),
                        SizedBox(height: 16.h),
                        _buildRuleBuilderCard(context),
                        SizedBox(height: 16.h),
                        _buildPromoCodesCard(context),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Rule Schedule Calendar View Card ────────────────────────────────────────
  Widget _buildWeeklyCalendarSection(BuildContext context) {
    final desktop = MediaQuery.of(context).size.width >= 960;

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
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    size: 20.r,
                    color: AppTheme.primary,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Active Rule Schedule',
                    style: AppTheme.titleLg.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.all(3.r),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _isWeekView = true),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 5.h,
                        ),
                        decoration: BoxDecoration(
                          color: _isWeekView
                              ? AppTheme.surfaceContainerLowest
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6.r),
                          boxShadow: _isWeekView
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          'Week',
                          style: AppTheme.labelSm.copyWith(
                            fontWeight: FontWeight.w700,
                            color: _isWeekView
                                ? AppTheme.onSurface
                                : AppTheme.secondary,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _isWeekView = false),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 5.h,
                        ),
                        decoration: BoxDecoration(
                          color: !_isWeekView
                              ? AppTheme.surfaceContainerLowest
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6.r),
                          boxShadow: !_isWeekView
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          'Day',
                          style: AppTheme.labelSm.copyWith(
                            fontWeight: FontWeight.w700,
                            color: !_isWeekView
                                ? AppTheme.onSurface
                                : AppTheme.secondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Divider(color: AppTheme.surfaceContainerHigh),
          SizedBox(height: 16.h),

          // Calendar Week Layout Grid
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              constraints: BoxConstraints(minWidth: desktop ? 900.w : 650.w),
              child: Column(
                children: [
                  // Days Header
                  Row(
                    children: [
                      SizedBox(
                        width: 60.w,
                        child: Text(
                          'Time',
                          textAlign: TextAlign.right,
                          style: AppTheme.labelSm.copyWith(
                            fontSize: 9.sp,
                            color: AppTheme.secondary,
                          ),
                        ),
                      ),
                      ...[
                        'Mon',
                        'Tue',
                        'Wed',
                        'Thu (Today)',
                        'Fri',
                        'Sat',
                        'Sun',
                      ].map((day) {
                        final isToday = day.contains('Thu');
                        return Expanded(
                          child: Container(
                            alignment: Alignment.center,
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            margin: EdgeInsets.symmetric(horizontal: 2.w),
                            decoration: BoxDecoration(
                              color: isToday
                                  ? AppTheme.primaryContainer.withValues(
                                      alpha: 0.06,
                                    )
                                  : AppTheme.surfaceContainerLow,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(8.r),
                              ),
                              border: isToday
                                  ? Border.all(
                                      color: AppTheme.primaryContainer
                                          .withValues(alpha: 0.15),
                                    )
                                  : null,
                            ),
                            child: Text(
                              day,
                              style: AppTheme.labelSm.copyWith(
                                fontSize: 10.sp,
                                fontWeight: isToday
                                    ? FontWeight.w800
                                    : FontWeight.w700,
                                color: isToday
                                    ? AppTheme.primary
                                    : AppTheme.onSurface,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),

                  // Calendar Matrix Area
                  Container(
                    height: 200.h,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLowest,
                      border: Border.all(color: AppTheme.surfaceContainerHigh),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(8.r),
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Hourly Horizontal division lines
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(
                            4,
                            (index) => Divider(
                              height: 1.h,
                              thickness: 1.h,
                              color: AppTheme.surfaceContainerLow,
                            ),
                          ),
                        ),

                        // Columns layouts
                        Row(
                          children: [
                            // Times indicators
                            Container(
                              width: 60.w,
                              padding: EdgeInsets.only(right: 8.w),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: ['12 PM', '3 PM', '6 PM', '9 PM']
                                    .map(
                                      (t) => Text(
                                        t,
                                        style: AppTheme.bodySm.copyWith(
                                          fontSize: 9.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),

                            // Columns contents grids
                            ...List.generate(7, (colIdx) {
                              final isTodayColumn = colIdx == 3; // Thursday

                              return Expanded(
                                child: Container(
                                  margin: EdgeInsets.symmetric(horizontal: 2.w),
                                  height: double.infinity,
                                  decoration: BoxDecoration(
                                    color: isTodayColumn
                                        ? AppTheme.primaryContainer.withValues(
                                            alpha: 0.02,
                                          )
                                        : Colors.transparent,
                                    border: Border(
                                      right: BorderSide(
                                        color: AppTheme.surfaceContainerLow,
                                        width: 1.w,
                                      ),
                                    ),
                                  ),
                                  child: isTodayColumn
                                      ? Stack(
                                          children: [
                                            // Red line timeline indicator
                                            Positioned(
                                              top: 200.h * 0.4,
                                              left: 0,
                                              right: 0,
                                              child: Container(
                                                height: 1.5.h,
                                                color: AppTheme.primary,
                                              ),
                                            ),
                                            Positioned(
                                              top: 200.h * 0.4 - 3.r,
                                              left: 0,
                                              child: Container(
                                                width: 6.r,
                                                height: 6.r,
                                                decoration: const BoxDecoration(
                                                  color: AppTheme.primary,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      : null,
                                ),
                              );
                            }),
                          ],
                        ),

                        // Event Overlays (Simulating positioned event boxes)
                        // 1. Happy Hour (Mon-Fri 4 PM - 6 PM -> top 33% depth, span Mon-Fri 5 columns)
                        Positioned(
                          left: 60.w + ((colWidth(desktop) + 4.w) * 0) + 2.w,
                          width: (colWidth(desktop) + 4.w) * 5 - 4.w,
                          top: 200.h * 0.33,
                          height: 200.h * 0.22,
                          child: Container(
                            padding: EdgeInsets.all(6.r),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryFixed.withValues(
                                alpha: 0.7,
                              ),
                              borderRadius: BorderRadius.circular(6.r),
                              border: Border(
                                left: BorderSide(
                                  color: AppTheme.primary,
                                  width: 4.w,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Happy Hour: 20% Off Beer',
                                  style: AppTheme.labelSm.copyWith(
                                    color: AppTheme.onPrimaryFixedVariant,
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '4:00 PM - 6:00 PM',
                                  style: AppTheme.bodySm.copyWith(
                                    color: AppTheme.onPrimaryFixedVariant
                                        .withValues(alpha: 0.8),
                                    fontSize: 8.sp,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // 2. Weekend Surcharge (Sat-Sun 8 PM - Close -> top 66% depth, span Sat-Sun 2 columns)
                        Positioned(
                          left: 60.w + ((colWidth(desktop) + 4.w) * 5) + 2.w,
                          width: (colWidth(desktop) + 4.w) * 2 - 4.w,
                          top: 200.h * 0.65,
                          height: 200.h * 0.3,
                          child: Container(
                            padding: EdgeInsets.all(6.r),
                            decoration: BoxDecoration(
                              color: AppTheme.errorContainer.withValues(
                                alpha: 0.7,
                              ),
                              borderRadius: BorderRadius.circular(6.r),
                              border: Border(
                                left: BorderSide(
                                  color: AppTheme.error,
                                  width: 4.w,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Peak Surcharge +10%',
                                  style: AppTheme.labelSm.copyWith(
                                    fontSize: 9.sp,
                                    color: const Color(0xFF991B1B),
                                    fontWeight: FontWeight.w800,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '8:00 PM - Close',
                                  style: AppTheme.bodySm.copyWith(
                                    color: const Color(
                                      0xFF991B1B,
                                    ).withValues(alpha: 0.8),
                                    fontSize: 8.sp,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
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
  }

  double colWidth(bool desktop) {
    // Dynamic estimate helper for event positioning width calculations
    final gridWidth = desktop ? 900.w - 60.w : 650.w - 60.w;
    return gridWidth / 7 - 4.w;
  }

  // ── Quick Rule Builder Card Widget ──────────────────────────────────────────
  Widget _buildRuleBuilderCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12.r),
        border: Border(
          top: BorderSide(color: AppTheme.primary, width: 4.w),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Rule Builder',
            style: AppTheme.titleLg.copyWith(fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 12.h),

          // Rule Name
          _buildFieldLabel('Rule Name'),
          TextField(
            controller: _ruleNameCtrl,
            style: GoogleFonts.plusJakartaSans(fontSize: 13.sp),
            decoration: _buildInputDecor('e.g. Happy Hour - Beer'),
          ),
          SizedBox(height: 12.h),

          // Row: Type + Value
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Type'),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: AppTheme.surfaceContainerHigh,
                        ),
                      ),
                      child: DropdownButton<String>(
                        value: _ruleType,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(
                            value: 'Discount (%)',
                            child: Text('Discount (%)'),
                          ),
                          DropdownMenuItem(
                            value: 'Surcharge (%)',
                            child: Text('Surcharge (%)'),
                          ),
                          DropdownMenuItem(
                            value: 'Fixed Price',
                            child: Text('Fixed Price'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _ruleType = val;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Value'),
                    TextField(
                      controller: _ruleValueCtrl,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                      ),
                      decoration: InputDecoration(
                        prefixText: _ruleType.contains('%') ? '% ' : '₹ ',
                        prefixStyle: GoogleFonts.plusJakartaSans(
                          color: AppTheme.secondary,
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
                          horizontal: 10.w,
                          vertical: 8.h,
                        ),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Target Categories List
          _buildFieldLabel('Target Categories'),
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: [
              ..._targetCategories.map(
                (cat) => Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 5.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(color: AppTheme.surfaceContainerHighest),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        cat,
                        style: AppTheme.labelSm.copyWith(
                          fontSize: 10.sp,
                          color: AppTheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _targetCategories.remove(cat)),
                        child: Icon(
                          Icons.close_rounded,
                          size: 12.r,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Add Target button
              GestureDetector(
                onTap: _addTargetCategory,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 5.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(
                      color: AppTheme.secondary,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_rounded,
                        size: 12.r,
                        color: AppTheme.secondary,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        'Add Category',
                        style: AppTheme.labelSm.copyWith(
                          fontSize: 10.sp,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),

          // Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {},
                child: Text(
                  'Cancel',
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.secondary),
                ),
              ),
              SizedBox(width: 10.w),
              ElevatedButton(
                onPressed: _saveRule,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryContainer,
                  minimumSize: Size(100.w, 36.h),
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                ),
                child: Text(
                  'Save Rule',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Discount Coupon Promo Codes Card Widget ────────────────────────────────
  Widget _buildPromoCodesCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppTheme.surfaceContainerHigh),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.local_offer_outlined,
                    size: 18.r,
                    color: AppTheme.secondary,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Promo Codes',
                    style: AppTheme.titleLg.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  '${_promoCodes.length} Active',
                  style: AppTheme.labelSm.copyWith(
                    fontSize: 8.sp,
                    color: AppTheme.tertiary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Coupon lists
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _promoCodes.length,
            separatorBuilder: (_, _) => SizedBox(height: 8.h),
            itemBuilder: (context, idx) {
              final promo = _promoCodes[idx];
              final code = promo['code'] as String;
              final subtitle = promo['subtitle'] as String;
              final usage = promo['usage'] as String;
              final expiry = promo['expiry'] as String;
              final isExpiringSoon = promo['isExpiringSoon'] as bool;

              return Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLowest,
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
                          code,
                          style: AppTheme.bodyMd.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: AppTheme.bodySm.copyWith(fontSize: 10.sp),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            usage,
                            style: AppTheme.labelSm.copyWith(
                              fontSize: 8.sp,
                              color: AppTheme.onSurface,
                            ),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          expiry,
                          style: AppTheme.bodySm.copyWith(
                            fontSize: 9.sp,
                            fontWeight: isExpiringSoon
                                ? FontWeight.w700
                                : FontWeight.normal,
                            color: isExpiringSoon
                                ? AppTheme.primary
                                : AppTheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          SizedBox(height: 16.h),

          // Dashed code generator button
          GestureDetector(
            onTap: _generatePromoCode,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 10.h),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppTheme.secondary.withValues(alpha: 0.5),
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_circle_outline_rounded,
                    size: 16.r,
                    color: AppTheme.secondary,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    'Generate Codes',
                    style: AppTheme.labelSm.copyWith(
                      color: AppTheme.secondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Text(
        text,
        style: AppTheme.labelSm.copyWith(color: AppTheme.secondary),
      ),
    );
  }

  InputDecoration _buildInputDecor(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(
        color: AppTheme.secondary,
        fontSize: 13.sp,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: const BorderSide(color: AppTheme.surfaceContainerHigh),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: const BorderSide(color: AppTheme.surfaceContainerHigh),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: const BorderSide(color: AppTheme.primary),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      isDense: true,
    );
  }
}
