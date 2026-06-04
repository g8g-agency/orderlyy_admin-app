import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/categories_provider.dart';
import '../../../../core/providers/menu_items_provider.dart';
import '../../../../core/data/dtos/menu_dto.dart';

class ModifierMatrixScreen extends ConsumerStatefulWidget {
  const ModifierMatrixScreen({super.key});

  @override
  ConsumerState<ModifierMatrixScreen> createState() =>
      _ModifierMatrixScreenState();
}

class _ModifierMatrixScreenState extends ConsumerState<ModifierMatrixScreen> {
  // Details Inputs
  final _internalNameCtrl = TextEditingController(text: 'Steak Temperatures');
  final _customerNameCtrl = TextEditingController(
    text: 'How would you like that cooked?',
  );

  // Rules States
  String _requirement = 'Required';
  int _minSelections = 1;
  int _maxSelections = 1;

  // Modifiers Options States
  late List<Map<String, dynamic>> _options;
  int? _defaultOptionIndex = 1; // "Medium Rare" is checked by default

  // Mapper search state
  String _mapperSearchQuery = '';

  // Multi-Item checkboxes states (mapped by item UUID)
  final Map<String, bool> _mappedItemIds = {};

  @override
  void initState() {
    super.initState();
    _options = [
      {'name': 'Rare', 'price': 0.00},
      {'name': 'Medium Rare', 'price': 0.00},
      {'name': 'Medium', 'price': 0.00},
    ];
  }

  @override
  void dispose() {
    _internalNameCtrl.dispose();
    _customerNameCtrl.dispose();
    super.dispose();
  }

  void _addOption() {
    setState(() {
      _options.add({'name': 'New Option', 'price': 0.00});
    });
  }

  void _removeOption(int index) {
    setState(() {
      _options.removeAt(index);
      if (_defaultOptionIndex == index) {
        _defaultOptionIndex = null;
      } else if (_defaultOptionIndex != null && _defaultOptionIndex! > index) {
        _defaultOptionIndex = _defaultOptionIndex! - 1;
      }
    });
  }

  void _saveModifierGroup() {
    final name = _internalNameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an internal name.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final selectedItemsCount = _mappedItemIds.values.where((v) => v).length;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                'Modifier Group "$name" saved & linked to $selectedItemsCount menu items.',
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.success,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.of(context).size.width >= 960;
    final selectedCount = _mappedItemIds.values.where((v) => v).length;

    final itemsState = ref.watch(menuItemsProvider);
    final categoriesState = ref.watch(categoriesProvider);

    final items = itemsState.byId.values.toList();
    final categories = categoriesState.byId.values.toList();

    final Map<String, String> categoryNames = {
      for (var cat in categories) cat.id: cat.name,
    };

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Modifier Studio',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18.sp,
          ),
        ),
        backgroundColor: AppTheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            size: 22.r,
            color: AppTheme.secondary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 16.r,
              color: AppTheme.primary,
            ),
            label: Text(
              'Discard Draft',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 11.sp,
                color: AppTheme.primary,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.primary),
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              minimumSize: Size(110.w, 36.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6.r),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          ElevatedButton.icon(
            onPressed: _saveModifierGroup,
            icon: Icon(Icons.save_rounded, size: 16.r, color: Colors.white),
            label: Text(
              'Save Modifier Group',
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
              minimumSize: Size(150.w, 36.h),
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
              child: desktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column (Details, Rules, Options - 8 cols)
                        Expanded(
                          flex: 8,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _buildLeftStudioColumn(context),
                          ),
                        ),
                        SizedBox(width: 24.w),

                        // Right Column (Multi-Item Mapper - 4 cols)
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildItemMapperCard(
                                context,
                                selectedCount,
                                items,
                                categoryNames,
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      // Mobile stacked
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ..._buildLeftStudioColumn(context),
                        SizedBox(height: 16.h),
                        _buildItemMapperCard(
                          context,
                          selectedCount,
                          items,
                          categoryNames,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Left Studio Column Widget Builder ───────────────────────────────────────
  List<Widget> _buildLeftStudioColumn(BuildContext context) {
    return [
      // 1. Basic Info Card
      Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12.r),
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
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18.r,
                  color: AppTheme.primary,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Group Details',
                  style: AppTheme.titleMd.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Divider(color: AppTheme.surfaceContainerHigh),
            SizedBox(height: 16.h),

            Row(
              children: [
                Expanded(
                  child: _buildStudioField(
                    'Internal Name',
                    _internalNameCtrl,
                    'e.g. Steak Temps',
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildStudioField(
                    'Customer Facing Name',
                    _customerNameCtrl,
                    'e.g. Choose Temperature',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      SizedBox(height: 16.h),

      // 2. Validation Rules Card
      Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12.r),
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
                      Icons.rule_rounded,
                      size: 18.r,
                      color: AppTheme.primary,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Selection Rules',
                      style: AppTheme.titleMd.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
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
                        'REQUIRED RULE ACTIVE',
                        style: AppTheme.labelSm.copyWith(
                          fontSize: 8.sp,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w800,
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

            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: AppTheme.surfaceContainerHigh),
              ),
              child: Row(
                children: [
                  // Requirement dropdown
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Requirement',
                          style: AppTheme.labelSm.copyWith(
                            color: AppTheme.secondary,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: AppTheme.surfaceContainerHigh,
                            ),
                          ),
                          child: DropdownButton<String>(
                            value: _requirement,
                            isExpanded: true,
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(
                                value: 'Required',
                                child: Text('Required'),
                              ),
                              DropdownMenuItem(
                                value: 'Optional',
                                child: Text('Optional'),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _requirement = val;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12.w),

                  // Min selections
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Min Selections',
                          style: AppTheme.labelSm.copyWith(
                            color: AppTheme.secondary,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        _buildSelectionsCounter(
                          value: _minSelections,
                          onChanged: (val) {
                            setState(() {
                              _minSelections = val.clamp(0, _maxSelections);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12.w),

                  // Max selections
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Max Selections',
                          style: AppTheme.labelSm.copyWith(
                            color: AppTheme.secondary,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        _buildSelectionsCounter(
                          value: _maxSelections,
                          onChanged: (val) {
                            setState(() {
                              _maxSelections = val.clamp(_minSelections, 10);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      SizedBox(height: 16.h),

      // 3. Modifier Options Card
      Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12.r),
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
                      Icons.list_alt_rounded,
                      size: 18.r,
                      color: AppTheme.primary,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Modifier Options',
                      style: AppTheme.titleMd.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: _addOption,
                  child: Row(
                    children: [
                      Icon(
                        Icons.add_circle_outline_rounded,
                        size: 16.r,
                        color: AppTheme.primary,
                      ),
                      SizedBox(width: 3.w),
                      Text(
                        'Add Option',
                        style: AppTheme.labelSm.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w800,
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

            // Options list grid layout header
            Row(
              children: [
                SizedBox(width: 24.w), // Drag handle placeholder
                Expanded(
                  flex: 5,
                  child: Text(
                    'Name',
                    style: AppTheme.labelSm.copyWith(
                      fontSize: 9.sp,
                      color: AppTheme.secondary,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Extra Cost',
                    style: AppTheme.labelSm.copyWith(
                      fontSize: 9.sp,
                      color: AppTheme.secondary,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Container(
                  width: 50.w,
                  alignment: Alignment.center,
                  child: Text(
                    'Default',
                    style: AppTheme.labelSm.copyWith(
                      fontSize: 9.sp,
                      color: AppTheme.secondary,
                    ),
                  ),
                ),
                SizedBox(width: 32.w), // Delete button placeholder
              ],
            ),
            SizedBox(height: 8.h),

            // Draggable options rows list
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _options.length,
              separatorBuilder: (_, _) => SizedBox(height: 8.h),
              itemBuilder: (context, i) {
                final option = _options[i];
                final nameCtrl = TextEditingController(
                  text: option['name'] as String,
                );
                final priceCtrl = TextEditingController(
                  text: (option['price'] as double).toStringAsFixed(2),
                );

                return Container(
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: AppTheme.surfaceContainerHigh.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Drag handle
                      Icon(
                        Icons.drag_indicator_rounded,
                        color: AppTheme.surfaceContainerHighest,
                        size: 18.r,
                      ),
                      SizedBox(width: 6.w),

                      // Name Textfield
                      Expanded(
                        flex: 5,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(
                              color: AppTheme.surfaceContainerHigh,
                            ),
                          ),
                          child: TextField(
                            controller: nameCtrl,
                            onChanged: (val) {
                              option['name'] = val;
                            },
                            style: GoogleFonts.plusJakartaSans(fontSize: 12.sp),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),

                      // Cost Textfield
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(
                              color: AppTheme.surfaceContainerHigh,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '₹',
                                style: AppTheme.bodySm.copyWith(
                                  color: AppTheme.secondary,
                                  fontSize: 10.sp,
                                ),
                              ),
                              SizedBox(width: 4.w),
                              Expanded(
                                child: TextField(
                                  controller: priceCtrl,
                                  keyboardType: TextInputType.number,
                                  onChanged: (val) {
                                    option['price'] =
                                        double.tryParse(val) ?? option['price'];
                                  },
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.sp,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),

                      Container(
                        width: 50.w,
                        alignment: Alignment.center,
                        // ignore: deprecated_member_use
                        child: Radio<int>(
                          value: i,
                          // ignore: deprecated_member_use
                          groupValue: _defaultOptionIndex,
                          activeColor: AppTheme.primary,
                          // ignore: deprecated_member_use
                          onChanged: (val) {
                            setState(() {
                              _defaultOptionIndex = val;
                            });
                          },
                        ),
                      ),

                      // Delete action
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          size: 16.r,
                          color: AppTheme.secondary,
                        ),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        onPressed: () => _removeOption(i),
                      ),
                      SizedBox(width: 8.w),
                    ],
                  ),
                ).animate().fadeIn(duration: 200.ms);
              },
            ),
          ],
        ),
      ),
    ];
  }

  // ── Multi Item Mapper Card Widget ──────────────────────────────────────────
  Widget _buildItemMapperCard(
    BuildContext context,
    int selectedCount,
    List<MenuItemDto> items,
    Map<String, String> categoryNames,
  ) {
    // Filter checklist elements by mapper search query
    final filteredItems = items.where((item) {
      if (_mapperSearchQuery.isEmpty) return true;
      return item.name.toLowerCase().contains(_mapperSearchQuery.toLowerCase());
    }).toList();

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppTheme.primaryContainer.withValues(alpha: 0.1),
          width: 1.w,
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
          Row(
            children: [
              Icon(Icons.link_rounded, size: 24.r, color: AppTheme.primary),
              SizedBox(width: 8.w),
              Text(
                'Item Mapper',
                style: AppTheme.titleLg.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'Select menu items to apply this modifier group to.',
            style: AppTheme.bodySm.copyWith(
              fontSize: 11.sp,
              color: AppTheme.secondary,
            ),
          ),
          SizedBox(height: 12.h),

          // Search mapper
          Container(
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
                        _mapperSearchQuery = val;
                      });
                    },
                    style: GoogleFonts.plusJakartaSans(fontSize: 12.sp),
                    decoration: InputDecoration(
                      hintText: 'Search menu items...',
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
          SizedBox(height: 12.h),

          // Counters and toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$selectedCount Items Selected',
                style: AppTheme.labelSm.copyWith(
                  color: AppTheme.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    final allSelected = filteredItems.every(
                      (item) => _mappedItemIds[item.id] == true,
                    );
                    for (var item in filteredItems) {
                      _mappedItemIds[item.id] = !allSelected;
                    }
                  });
                },
                child: Text(
                  'Select All Items',
                  style: AppTheme.labelSm.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 10.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),

          // Categorized Checklist Area
          SizedBox(
            height: 260.h,
            child: filteredItems.isEmpty
                ? Center(
                    child: Text(
                      'No matching menu items.',
                      style: AppTheme.bodySm.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredItems.length,
                    itemBuilder: (context, idx) {
                      final item = filteredItems[idx];
                      final isChecked = _mappedItemIds[item.id] ?? false;
                      final category =
                          categoryNames[item.categoryId] ?? 'Other';
                      final menu =
                          'Standard Menu'; // Placeholder for menu categorization if needed

                      // Render category headers when category transitions
                      bool showHeader =
                          idx == 0 ||
                          filteredItems[idx - 1].categoryId != item.categoryId;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showHeader) ...[
                            if (idx > 0) SizedBox(height: 8.h),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                category.toUpperCase(),
                                style: AppTheme.labelSm.copyWith(
                                  fontSize: 8.sp,
                                  color: AppTheme.tertiary,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            SizedBox(height: 4.h),
                          ],
                          Material(
                            color: Colors.transparent,
                            child: CheckboxListTile(
                              title: Text(
                                item.name,
                                style: AppTheme.bodyMd.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.sp,
                                ),
                              ),
                              subtitle: Text(
                                menu,
                                style: AppTheme.bodySm.copyWith(fontSize: 10.sp),
                              ),
                              value: isChecked,
                              activeColor: AppTheme.primary,
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              dense: true,
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _mappedItemIds[item.id] = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          SizedBox(height: 16.h),

          // Summary mapper graphic footer
          Container(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sync_rounded, size: 16.r, color: AppTheme.primary),
                SizedBox(width: 6.w),
                Text(
                  'Ready to map $selectedCount items',
                  style: AppTheme.labelSm.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionsCounter({
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppTheme.surfaceContainerHigh),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.remove, size: 14.r, color: AppTheme.secondary),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
            onPressed: () => onChanged(value - 1),
          ),
          Text(
            value.toString(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              color: AppTheme.onSurface,
            ),
          ),
          IconButton(
            icon: Icon(Icons.add, size: 14.r, color: AppTheme.secondary),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
            onPressed: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }

  Widget _buildStudioField(
    String label,
    TextEditingController ctrl,
    String hint,
  ) {
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
          style: GoogleFonts.plusJakartaSans(fontSize: 12.sp),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
              color: AppTheme.secondary,
              fontSize: 12.sp,
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
    );
  }
}
