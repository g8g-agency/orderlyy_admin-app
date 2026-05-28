import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/data/dtos/menu_dto.dart';
import '../../../../core/providers/menu_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class ItemDetailScreen extends ConsumerStatefulWidget {
  final MenuItemDto? item;
  final String? defaultCategoryId;

  const ItemDetailScreen({super.key, this.item, this.defaultCategoryId});

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  // Input Controllers
  late TextEditingController _nameCtrl;
  late TextEditingController _skuCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _priceCtrl;
  late String _categoryId;

  // Local States
  bool _available = true;
  bool _isSaving = false;
  XFile? _pickedImage;
  String? _currentImageUrl;

  // Stock tracking states
  int _stockCount = 5;
  double _stockProgress = 0.15; // Low Stock

  // Tags and Allergens states
  late List<Map<String, dynamic>> _tags;

  // Variants/Addons list
  late List<Map<String, dynamic>> _addons;

  @override
  void initState() {
    super.initState();
    final item = widget.item;

    _nameCtrl = TextEditingController(text: item?.name ?? 'Wagyu Burger');
    _skuCtrl = TextEditingController(
      text: item != null
          ? 'MNU-MB-${item.id.hashCode.toString().padLeft(3, '0')}'
          : 'MNU-MB-042',
    );
    _descCtrl = TextEditingController(
      text:
          item?.description ??
          'Premium 8oz Wagyu beef patty, aged cheddar, caramelized onions, house truffle aioli, on a toasted brioche bun. Served medium unless otherwise specified.',
    );
    _priceCtrl = TextEditingController(
      text: item != null ? item.price.toStringAsFixed(2) : '24.00',
    );
    _categoryId = item?.categoryId ?? widget.defaultCategoryId ?? 'cat-002';
    _available = item?.isAvailable ?? true;
    _currentImageUrl =
        item?.imageUrl ??
        'https://lh3.googleusercontent.com/aida-public/AB6AXuAVdq5VDic-tPPqrG4IZ9NrYtibwKWsDJYr33ioz3VLtH2BH62EOB9Kx2hb8UUoaQAIz8qQJZvtkc5m_jvMgSSkHIJ96gkJCC6D6cBRRwSSPZdSdlDVVfYvrsiilFgtvlllbC8iHBGQyWXySdmNgDSFH_WN7GNZFe83y_J8eCGFG3UXQCj88E7yO4sCfv6plTD_J2dCYQZ9u9rDH-D18wrTWIyXkwUA8ngHIkst7exLCKxwo6fw2YvAl61P75EnskscupoGigXag0PV';

    // Mock initial tags
    _tags = [
      {'label': 'Signature', 'isAllergen': false},
      {'label': 'Beef', 'isAllergen': false},
      {'label': 'Contains Dairy', 'isAllergen': true},
      {'label': 'Gluten', 'isAllergen': true},
    ];

    // Mock initial addons
    _addons = [
      {'name': 'Add Bacon', 'price': 3.50},
      {'name': 'Gluten-Free Bun', 'price': 2.00},
      {'name': 'Extra Patty', 'price': 8.00},
    ];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _skuCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image != null) {
      setState(() {
        _pickedImage = image;
      });
    }
  }

  void _addTag() {
    final controller = TextEditingController();
    bool isAllergen = false;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceContainerLowest,
              title: Text(
                'Add Dietary/Tag Label',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    style: GoogleFonts.plusJakartaSans(),
                    decoration: InputDecoration(
                      hintText: 'e.g. Nut Free',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        color: AppTheme.secondary,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  CheckboxListTile(
                    title: Text(
                      'Allergen Warning',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13.sp),
                    ),
                    subtitle: Text(
                      'Highlights the chip in warning red style',
                      style: GoogleFonts.plusJakartaSans(fontSize: 10.sp),
                    ),
                    value: isAllergen,
                    activeColor: AppTheme.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          isAllergen = val;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.secondary,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final label = controller.text.trim();
                    if (label.isNotEmpty) {
                      setState(() {
                        _tags.add({'label': label, 'isAllergen': isAllergen});
                      });
                      Navigator.pop(ctx);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryContainer,
                  ),
                  child: Text(
                    'Add Tag',
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
      },
    );
  }

  void _addAddon() {
    setState(() {
      _addons.add({'name': 'New Upgrade', 'price': 1.00});
    });
  }

  void _adjustStock() {
    final controller = TextEditingController(text: _stockCount.toString());
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceContainerLowest,
          title: Text(
            'Adjust Daily Stock',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            style: GoogleFonts.plusJakartaSans(),
            decoration: InputDecoration(
              hintText: 'e.g. 20',
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
                final count = int.tryParse(controller.text) ?? _stockCount;
                setState(() {
                  _stockCount = count;
                  if (_stockCount == 0) {
                    _stockProgress = 0.0;
                  } else if (_stockCount <= 5) {
                    _stockProgress = 0.15; // Low Stock status
                  } else {
                    _stockProgress = 0.8;
                  }
                });
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryContainer,
              ),
              child: Text(
                'Adjust',
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

  Future<void> _saveItem() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an item name'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (widget.item != null) {
        // Save using current Riverpod update menu item provider
        final updated = MenuItemDto(
          id: widget.item!.id,
          tenantId: widget.item!.tenantId,
          categoryId: _categoryId,
          name: name,
          description: _descCtrl.text.trim(),
          price: double.tryParse(_priceCtrl.text) ?? widget.item!.price,
          imageUrl: _pickedImage != null
              ? _pickedImage!.path
              : _currentImageUrl,
          isAvailable: _available,
          isVegetarian: widget.item!.isVegetarian,
          prepTimeMinutes: widget.item!.prepTimeMinutes,
          tags: _tags.map((t) => t['label'] as String).toList(),
        );
        await ref.read(updateMenuItemProvider)(updated);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item "$name" saved successfully.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.of(context).size.width >= 960;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          _nameCtrl.text,
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
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.surfaceContainerHigh),
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              minimumSize: Size(80.w, 36.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6.r),
              ),
            ),
            child: Text(
              'Discard',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 11.sp,
                color: AppTheme.onSurface,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          ElevatedButton(
            onPressed: _isSaving ? null : _saveItem,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryContainer,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              minimumSize: Size(90.w, 36.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6.r),
              ),
              elevation: 0,
            ),
            child: _isSaving
                ? SizedBox(
                    width: 16.r,
                    height: 16.r,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Save Item',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 11.sp,
                      color: Colors.white,
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(desktop ? 24.r : 16.r),
          child: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: 1100.w),
              child: desktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column (Visuals & Status - 5/12 width)
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _buildLeftVisualsColumn(context),
                          ),
                        ),
                        SizedBox(width: 24.w),

                        // Right Column (Details inputs - 7/12 width)
                        Expanded(
                          flex: 7,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _buildRightDetailsColumn(context),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      // Mobile stacked
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ..._buildLeftVisualsColumn(context),
                        SizedBox(height: 16.h),
                        ..._buildRightDetailsColumn(context),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Left Column Elements ────────────────────────────────────────────────────
  List<Widget> _buildLeftVisualsColumn(BuildContext context) {
    return [
      // 1. Photo Hero Card
      Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Image viewport
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Container(
                color: AppTheme.surfaceContainerLow,
                child: _pickedImage != null
                    ? Image.file(File(_pickedImage!.path), fit: BoxFit.cover)
                    : _currentImageUrl != null && _currentImageUrl!.isNotEmpty
                    ? _currentImageUrl!.startsWith('/') ||
                              _currentImageUrl!.contains('cache')
                          ? Image.file(
                              File(_currentImageUrl!),
                              fit: BoxFit.cover,
                            )
                          : Image.network(_currentImageUrl!, fit: BoxFit.cover)
                    : Icon(
                        Icons.restaurant_rounded,
                        size: 48.r,
                        color: AppTheme.surfaceContainerHigh,
                      ),
              ),
            ),

            // Image hover replacement overlay trigger
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.25),
                child: Center(
                  child: InkWell(
                    onTap: _pickImage,
                    borderRadius: BorderRadius.circular(8.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.r),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 8),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            size: 16.r,
                            color: AppTheme.primary,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            'Replace Image',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 11.sp,
                              color: AppTheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Availability overlay badge
            Positioned(
              top: 12.h,
              left: 12.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: AppTheme.surfaceContainerHigh,
                    width: 1.w,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7.r,
                      height: 7.r,
                      decoration: BoxDecoration(
                        color: _available
                            ? const Color(0xFF10B981)
                            : AppTheme.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      _available ? 'Active on Menu' : 'Inactive / Hidden',
                      style: AppTheme.labelSm.copyWith(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.onSurface,
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

      // 2. Stock Tracker Bento Card
      Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12.r),
          border: Border(
            left: BorderSide(
              color: _stockCount <= 5 ? AppTheme.primary : AppTheme.secondary,
              width: 4.w,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stock Count',
                      style: AppTheme.titleMd.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Real-time inventory tracking',
                      style: AppTheme.bodySm.copyWith(fontSize: 11.sp),
                    ),
                  ],
                ),
                Icon(
                  Icons.inventory_2_outlined,
                  size: 26.r,
                  color: _stockCount <= 5
                      ? AppTheme.primary
                      : AppTheme.secondary,
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Number indicators
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _stockCount.toString().padLeft(2, '0'),
                  style: AppTheme.displayLg.copyWith(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                SizedBox(width: 8.w),
                Padding(
                  padding: EdgeInsets.only(bottom: 2.h),
                  child: Text(
                    'remaining today',
                    style: AppTheme.bodySm.copyWith(fontSize: 12.sp),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Progress bar
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 6.h,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(3.r),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _stockProgress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _stockCount <= 5
                              ? AppTheme.primary
                              : const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(3.r),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_stockCount <= 5) ...[
                  SizedBox(width: 10.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 5.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      _stockCount == 0 ? 'SOLD OUT' : 'LOW STOCK',
                      style: AppTheme.labelSm.copyWith(
                        fontSize: 8.sp,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: 16.h),

            // Action triggers
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _adjustStock,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppTheme.surfaceContainerHigh,
                      ),
                      minimumSize: Size(double.infinity, 36.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      'Adjust Stock',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 11.sp,
                        color: AppTheme.onSurface,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _stockCount = 0;
                        _stockProgress = 0.0;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppTheme.surfaceContainerHigh,
                      ),
                      minimumSize: Size(double.infinity, 36.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      'Mark Sold Out',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 11.sp,
                        color: AppTheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      SizedBox(height: 16.h),

      // 3. Tags & Allergens Bento Card
      Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
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
                  Icons.label_outline_rounded,
                  size: 18.r,
                  color: AppTheme.secondary,
                ),
                SizedBox(width: 6.w),
                Text(
                  'Tags & Dietary',
                  style: AppTheme.titleMd.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            SizedBox(height: 14.h),

            // Chips wrapped list
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ..._tags.map((tag) {
                  final label = tag['label'] as String;
                  final isAllergen = tag['isAllergen'] as bool;

                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: isAllergen
                          ? const Color(0xFFFEF2F2)
                          : AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: isAllergen
                            ? const Color(0xFFFCA5A5)
                            : AppTheme.surfaceContainerHigh,
                        width: 1.w,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: AppTheme.labelSm.copyWith(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                            color: isAllergen
                                ? const Color(0xFF991B1B)
                                : AppTheme.onSurface,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _tags.remove(tag);
                            });
                          },
                          child: Icon(
                            Icons.close_rounded,
                            size: 12.r,
                            color: isAllergen
                                ? const Color(0xFF991B1B)
                                : AppTheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                // Add button trigger
                GestureDetector(
                  onTap: _addTag,
                  child: Container(
                    width: 26.r,
                    height: 26.r,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppTheme.secondary,
                        style: BorderStyle.solid,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      size: 14.r,
                      color: AppTheme.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  // ── Right Column Details Form ───────────────────────────────────────────────
  List<Widget> _buildRightDetailsColumn(BuildContext context) {
    return [
      // 1. Core Details Card
      Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Item Details',
              style: AppTheme.titleMd.copyWith(fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 6.h),
            Divider(color: AppTheme.surfaceContainerHigh),
            SizedBox(height: 16.h),

            // Name
            _buildInputField(
              'Item Name',
              _nameCtrl,
              'e.g. Classic Cheeseburger',
            ),
            SizedBox(height: 12.h),

            // Category + SKU
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Category',
                        style: AppTheme.labelSm.copyWith(
                          color: AppTheme.secondary,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: DropdownButton<String>(
                          value: _categoryId,
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(
                              value: 'cat-001',
                              child: Text('Starters'),
                            ),
                            DropdownMenuItem(
                              value: 'cat-002',
                              child: Text('Mains'),
                            ),
                            DropdownMenuItem(
                              value: 'cat-003',
                              child: Text('Sides'),
                            ),
                            DropdownMenuItem(
                              value: 'cat-004',
                              child: Text('Drinks'),
                            ),
                            DropdownMenuItem(
                              value: 'cat-005',
                              child: Text('Desserts'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _categoryId = val;
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
                  child: _buildInputField(
                    'SKU/ID',
                    _skuCtrl,
                    'e.g. MNU-MB-042',
                    editable: false,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Description
            _buildInputField(
              'Description',
              _descCtrl,
              'Detailed food ingredients, serving specs...',
              maxLines: 3,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_descCtrl.text.length}/200 chars',
                style: AppTheme.bodySm.copyWith(fontSize: 9.sp),
              ),
            ),
          ],
        ),
      ),
      SizedBox(height: 16.h),

      // 2. Pricing & Variations Card
      Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
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
                Text(
                  'Pricing & Variations',
                  style: AppTheme.titleMd.copyWith(fontWeight: FontWeight.w800),
                ),
                GestureDetector(
                  onTap: _addAddon,
                  child: Row(
                    children: [
                      Icon(
                        Icons.add_rounded,
                        size: 14.r,
                        color: AppTheme.primary,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        'Add Variant',
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

            // Base Price
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: AppTheme.surfaceContainerHigh,
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Base Price',
                          style: AppTheme.bodyMd.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Default price without add-ons',
                          style: AppTheme.bodySm.copyWith(fontSize: 10.sp),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Container(
                    width: 110.w,
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: AppTheme.surfaceContainerHigh),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '₹',
                          style: AppTheme.bodyMd.copyWith(
                            color: AppTheme.secondary,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: TextField(
                            controller: _priceCtrl,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.right,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 13.sp,
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
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Variations List
            Text(
              'Add-ons & Upgrades',
              style: AppTheme.labelSm.copyWith(
                color: AppTheme.secondary,
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(height: 10.h),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _addons.length,
              separatorBuilder: (_, _) => SizedBox(height: 8.h),
              itemBuilder: (context, i) {
                final addon = _addons[i];
                final addonNameCtrl = TextEditingController(
                  text: addon['name'] as String,
                );
                final addonPriceCtrl = TextEditingController(
                  text: (addon['price'] as double).toStringAsFixed(2),
                );

                return Row(
                  children: [
                    // Drag indicator
                    Icon(
                      Icons.drag_indicator_rounded,
                      color: AppTheme.surfaceContainerHighest,
                      size: 18.r,
                    ),
                    SizedBox(width: 6.w),

                    // Editable addon name
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: addonNameCtrl,
                        onChanged: (val) {
                          addon['name'] = val;
                        },
                        style: GoogleFonts.plusJakartaSans(fontSize: 12.sp),
                        decoration: InputDecoration(
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: AppTheme.surfaceContainerHigh,
                            ),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: AppTheme.surfaceContainerHigh,
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppTheme.primary),
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 4.h),
                          isDense: true,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),

                    // Editable addon price
                    Expanded(
                      flex: 1,
                      child: Row(
                        children: [
                          Text(
                            '+₹',
                            style: AppTheme.bodySm.copyWith(
                              fontSize: 10.sp,
                              color: AppTheme.secondary,
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: TextField(
                              controller: addonPriceCtrl,
                              keyboardType: TextInputType.number,
                              onChanged: (val) {
                                addon['price'] =
                                    double.tryParse(val) ?? addon['price'];
                              },
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.sp,
                              ),
                              decoration: InputDecoration(
                                border: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppTheme.surfaceContainerHigh,
                                  ),
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppTheme.surfaceContainerHigh,
                                  ),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppTheme.primary,
                                  ),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 4.h,
                                ),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),

                    // Remove button
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        size: 16.r,
                        color: AppTheme.secondary,
                      ),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        setState(() {
                          _addons.removeAt(i);
                        });
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      SizedBox(height: 16.h),

      // 3. Danger Zone Card
      Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5F5),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xFFFECACA), width: 1.w),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Danger Zone',
              style: AppTheme.titleMd.copyWith(
                color: const Color(0xFF991B1B),
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Actions here can affect live orders and menu visibility.',
              style: AppTheme.bodySm.copyWith(
                color: const Color(0xFF7F1D1D),
                fontSize: 11.sp,
              ),
            ),
            SizedBox(height: 16.h),

            // Archive and Delete buttons
            Row(
              children: [
                OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Item has been archived.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFDC2626),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text(
                    'Archive Item',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 11.sp,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Item deleted permanently.'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppTheme.error,
                      ),
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Delete Permanently',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 11.sp,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildInputField(
    String label,
    TextEditingController ctrl,
    String hint, {
    TextInputType type = TextInputType.text,
    int maxLines = 1,
    bool editable = true,
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
          maxLines: maxLines,
          enabled: editable,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.sp,
            color: editable ? AppTheme.onSurface : AppTheme.secondary,
          ),
          decoration: InputDecoration(
            hintText: hint,
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
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: AppTheme.surfaceContainerLow),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: maxLines > 1 ? 12.h : 8.h,
            ),
            isDense: true,
          ),
        ),
      ],
    );
  }
}
