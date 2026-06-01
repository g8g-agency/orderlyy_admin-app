import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/branch_entity.dart';
import '../state/branch_mutations.dart';
import '../../../../core/crud/form_error_mapper.dart';
import 'package:google_fonts/google_fonts.dart';

class BranchFormSheet extends ConsumerStatefulWidget {
  final BranchEntity? initialData;

  const BranchFormSheet({super.key, this.initialData});

  static Future<void> show(BuildContext context, {BranchEntity? initialData}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BranchFormSheet(initialData: initialData),
    );
  }

  @override
  ConsumerState<BranchFormSheet> createState() => _BranchFormSheetState();
}

class _BranchFormSheetState extends ConsumerState<BranchFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _timezoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _regionController;
  BranchStatus _status = BranchStatus.active;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialData?.name);
    _timezoneController = TextEditingController(text: widget.initialData?.timezone ?? 'UTC');
    _addressController = TextEditingController(text: widget.initialData?.address);
    _phoneController = TextEditingController(text: widget.initialData?.phone);
    _emailController = TextEditingController(text: widget.initialData?.email);
    _regionController = TextEditingController(text: widget.initialData?.region);
    _status = widget.initialData?.status ?? BranchStatus.active;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _timezoneController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final isUpdating = widget.initialData != null;
    try {
      if (isUpdating) {
        await ref.read(branchMutationProvider.notifier).updateBranch(
          widget.initialData!.id,
          _nameController.text.trim(),
          _timezoneController.text.trim(),
          _status,
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          region: _regionController.text.trim().isEmpty ? null : _regionController.text.trim(),
        );
      } else {
        await ref.read(branchMutationProvider.notifier).createBranch(
          _nameController.text.trim(),
          _timezoneController.text.trim(),
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          region: _regionController.text.trim().isEmpty ? null : _regionController.text.trim(),
        );
      }

      final errorState = ref.read(branchMutationProvider);
      if (errorState is AsyncError) {
        throw errorState.error;
      }
      
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(FormErrorMapper.mapError(e)),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mutationState = ref.watch(branchMutationProvider);
    final isLoading = mutationState.isLoading;

    final surfaceColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkSurface
        : AppColors.lightSurface;
    final textColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.initialData == null ? 'Add New Branch' : 'Edit Branch',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Branch Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _timezoneController,
                  decoration: const InputDecoration(
                    labelText: 'Timezone',
                    border: OutlineInputBorder(),
                    hintText: 'e.g. UTC, America/New_York',
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _regionController,
                  decoration: const InputDecoration(
                    labelText: 'Region',
                    border: OutlineInputBorder(),
                    hintText: 'e.g. North, West Coast, South Region',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                    hintText: 'Full physical address of the branch',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                          border: OutlineInputBorder(),
                          hintText: 'e.g. +1 555-0199',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          hintText: 'e.g. branch@orderlli.com',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (widget.initialData != null)
                  DropdownButtonFormField<BranchStatus>(
                    value: _status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: BranchStatus.values.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status.name.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _status = val);
                    },
                  ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(100, 44), // Ensure bounded size inside horizontal Row
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(widget.initialData == null ? 'Create' : 'Save'),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
