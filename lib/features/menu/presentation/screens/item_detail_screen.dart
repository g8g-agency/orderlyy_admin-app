import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/data/dtos/menu_dto.dart';
import '../../../../core/providers/categories_provider.dart';
import '../../../../core/providers/menu_items_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/auth/app_auth_provider.dart';
import '../../../../core/network/api_exception.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

class ItemDetailScreen extends ConsumerStatefulWidget {
  final MenuItemDto? item;
  final String? defaultCategoryId;

  const ItemDetailScreen({super.key, this.item, this.defaultCategoryId});

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _priceCtrl;
  late String _categoryId;

  bool _available = true;
  bool _isSaving = false;
  XFile? _pickedImage;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    final item = widget.item;

    _nameCtrl = TextEditingController(text: item?.name ?? '');
    _descCtrl = TextEditingController(text: item?.description ?? '');
    _priceCtrl = TextEditingController(
      text: item != null ? (item.basePriceAmount / 100).toStringAsFixed(2) : '',
    );
    _categoryId = item?.categoryId ?? widget.defaultCategoryId ?? '';
    _available = item?.isAvailable ?? true;
    _currentImageUrl = item?.imageUrl ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
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

    if (_categoryId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final Result<MenuItemDto> result;
      if (widget.item != null) {
        final updated = MenuItemDto(
          id: widget.item!.id,
          tenantId: widget.item!.tenantId,
          categoryId: _categoryId,
          name: name,
          description: _descCtrl.text.trim(),
          basePriceAmount: ((double.tryParse(_priceCtrl.text) ?? (widget.item!.basePriceAmount / 100)) * 100).round(),
          imageUrl: _pickedImage != null
              ? _pickedImage!.path
              : _currentImageUrl,
          isAvailable: _available,
          isVegetarian: widget.item!.isVegetarian,
          prepTimeMinutes: widget.item!.prepTimeMinutes,
          tags: widget.item!.tags,
          versionNum: widget.item!.versionNum,
        );
        result = await ref.read(menuItemsProvider.notifier).updateMenuItem(updated);
      } else {
        final tenantId = ref.read(appContextProvider)?.tenant.id ?? '';
        final newItem = MenuItemDto(
          id: uuid.v4(),
          tenantId: tenantId,
          categoryId: _categoryId,
          name: name,
          description: _descCtrl.text.trim(),
          basePriceAmount: ((double.tryParse(_priceCtrl.text) ?? 0.0) * 100).round(),
          imageUrl: _pickedImage != null
              ? _pickedImage!.path
              : _currentImageUrl,
          isAvailable: _available,
          isVegetarian: false,
          prepTimeMinutes: 15,
          tags: [],
          versionNum: 1,
        );
        result = await ref.read(menuItemsProvider.notifier).createMenuItem(newItem);
      }

      if (!mounted) return;

      if (result is Failure<MenuItemDto>) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: ${result.error.message}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.error,
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Item "$name" saved successfully.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(categoriesProvider);
    final categories = categoriesState.byId.values.toList();

    if (categories.isNotEmpty && !categories.any((c) => c.id == _categoryId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _categoryId = categories.first.id;
          });
        }
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          widget.item == null ? 'Add Menu Item' : 'Edit Item',
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
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: 600.w),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header Area (Item Name + Availability)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          _nameCtrl.text.isEmpty ? 'New Item' : _nameCtrl.text,
                          style: AppTheme.displayLg.copyWith(fontSize: 32.sp),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: _available
                              ? const Color(0xFF10B981).withValues(alpha: 0.1)
                              : AppTheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: _available
                                ? const Color(0xFF10B981)
                                : AppTheme.error,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _available
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded,
                              size: 14.r,
                              color: _available
                                  ? const Color(0xFF10B981)
                                  : AppTheme.error,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              _available ? 'Active' : 'Hidden',
                              style: AppTheme.labelSm.copyWith(
                                color: _available
                                    ? const Color(0xFF10B981)
                                    : AppTheme.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),

                  // Actions (Discard / Save)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppTheme.surfaceContainerHigh,
                            ),
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          child: Text(
                            'Discard Changes',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveItem,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            elevation: 0,
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
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.save_rounded, size: 18.r),
                                    SizedBox(width: 8.w),
                                    Text(
                                      'Save Item',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 32.h),

                  // 2. Item Media
                  _buildSectionTitle(Icons.image_outlined, 'Item Media'),
                  SizedBox(height: 12.h),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: double.infinity,
                      height: 240.h,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppTheme.surfaceContainerHigh,
                          style: BorderStyle.solid,
                          width: 2,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _pickedImage != null
                          ? Image.file(
                              File(_pickedImage!.path),
                              fit: BoxFit.cover,
                            )
                          : _currentImageUrl != null &&
                                _currentImageUrl!.isNotEmpty
                          ? (_currentImageUrl!.startsWith('/') ||
                                    _currentImageUrl!.contains('cache')
                                ? Image.file(
                                    File(_currentImageUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : Image.network(
                                    _currentImageUrl!,
                                    fit: BoxFit.cover,
                                  ))
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo_outlined,
                                  size: 48.r,
                                  color: AppTheme.secondary,
                                ),
                                SizedBox(height: 12.h),
                                Text(
                                  'Tap to upload item photo',
                                  style: AppTheme.bodyMd.copyWith(
                                    color: AppTheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  SizedBox(height: 32.h),

                  // 3. Basic Info
                  _buildSectionTitle(
                    Icons.info_outline_rounded,
                    'Basic Details',
                  ),
                  SizedBox(height: 12.h),
                  _buildInputField(
                    'Item Name',
                    _nameCtrl,
                    'e.g. Signature Truffle Burger',
                    onChanged: (v) => setState(() {}),
                  ),
                  SizedBox(height: 16.h),

                  // Category Dropdown
                  Text(
                    'Category',
                    style: AppTheme.labelSm.copyWith(color: AppTheme.secondary),
                  ),
                  SizedBox(height: 6.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: AppTheme.surfaceContainerHigh),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: categories.any((c) => c.id == _categoryId)
                            ? _categoryId
                            : null,
                        isExpanded: true,
                        hint: Text(
                          'Select Category',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.secondary,
                          ),
                        ),
                        items: categories.isEmpty
                            ? []
                            : categories.map((c) {
                                return DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.name),
                                );
                              }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _categoryId = val);
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Price
                  _buildInputField(
                    'Base Price (₹)',
                    _priceCtrl,
                    'e.g. 24.50',
                    type: TextInputType.number,
                  ),
                  SizedBox(height: 32.h),

                  // 4. Description
                  _buildSectionTitle(Icons.subject_rounded, 'Description'),
                  SizedBox(height: 12.h),
                  _buildInputField(
                    'Customer Facing Description',
                    _descCtrl,
                    'A decadent blend of dry-aged beef, melted gruyere...',
                    maxLines: 4,
                  ),
                  SizedBox(height: 32.h),

                  // 5. Visibility
                  _buildSectionTitle(Icons.visibility_outlined, 'Visibility'),
                  SizedBox(height: 12.h),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppTheme.surfaceContainerHigh),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Material(
                      color: AppTheme.surfaceContainerLowest,
                      child: SwitchListTile(
                      title: Text(
                        'Available on Menu',
                        style: AppTheme.bodyMd.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        'Toggle to instantly hide this item from diners',
                        style: AppTheme.bodySm,
                      ),
                      value: _available,
                      activeThumbColor: AppTheme.primary,
                      onChanged: (val) => setState(() => _available = val),
                    ),
                    ),
                  ),

                  // Bottom padding
                  SizedBox(height: 60.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20.r, color: AppTheme.onSurface),
        SizedBox(width: 8.w),
        Text(
          title,
          style: AppTheme.titleMd.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController ctrl,
    String hint, {
    TextInputType type = TextInputType.text,
    int maxLines = 1,
    Function(String)? onChanged,
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
          onChanged: onChanged,
          style: GoogleFonts.plusJakartaSans(fontSize: 14.sp),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
              color: AppTheme.secondary,
              fontSize: 14.sp,
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
              horizontal: 16.w,
              vertical: 14.h,
            ),
          ),
        ),
      ],
    );
  }
}

