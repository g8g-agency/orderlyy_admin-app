import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import 'data/dtos/tax_dto.dart';
import 'data/repositories/tax_provider.dart';
import 'data/repositories/tax_repository.dart';

class TaxManagementScreen extends ConsumerStatefulWidget {
  const TaxManagementScreen({super.key});

  @override
  ConsumerState<TaxManagementScreen> createState() =>
      _TaxManagementScreenState();
}

class _TaxManagementScreenState extends ConsumerState<TaxManagementScreen> {
  void _showTaxForm({TaxProfileDto? existingProfile}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TaxFormSheet(existingProfile: existingProfile),
    ).then((_) {
      // Refresh the list when sheet is closed
      ref.invalidate(taxProfilesProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncProfiles = ref.watch(taxProfilesProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLowest,
        title: Text(
          'Taxes',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: asyncProfiles.when(
        data: (profiles) {
          if (profiles.isEmpty) {
            return _buildEmptyState();
          }
          return _buildList(profiles);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(
          child: Text(
            'Error loading taxes: $err',
            style: GoogleFonts.inter(color: Colors.red),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTaxForm(),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'New Tax',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: AppTheme.secondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Tax Profiles',
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a tax profile to apply taxes to your menu items.',
            style: GoogleFonts.inter(color: AppTheme.secondary),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<TaxProfileDto> profiles) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: profiles.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 12),
      itemBuilder: (ctx, index) {
        final profile = profiles[index];
        final ratePercent = profile.effectiveBasisPoints / 100.0;

        return InkWell(
          onTap: () => _showTaxForm(existingProfile: profile),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.surfaceContainerHigh),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            profile.name,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!profile.isActive)
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Inactive',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (profile.description != null &&
                          profile.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            profile.description!,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppTheme.secondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${ratePercent.toStringAsFixed(2)}%',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.calculationMode.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Switch(
                  value: profile.isActive,
                  onChanged: (val) async {
                    await ref
                        .read(taxRepositoryProvider)
                        .toggleTaxProfile(profile.id, val);
                    ref.invalidate(taxProfilesProvider);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TaxFormSheet extends ConsumerStatefulWidget {
  final TaxProfileDto? existingProfile;

  const _TaxFormSheet({this.existingProfile});

  @override
  ConsumerState<_TaxFormSheet> createState() => _TaxFormSheetState();
}

class _TaxFormSheetState extends ConsumerState<_TaxFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _rateCtrl;
  String _calcMode = 'exclusive';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existingProfile?.name ?? '');
    _descCtrl = TextEditingController(
      text: widget.existingProfile?.description ?? '',
    );

    final currentBp = widget.existingProfile?.effectiveBasisPoints ?? 0;
    _rateCtrl = TextEditingController(
      text: currentBp > 0 ? (currentBp / 100.0).toStringAsFixed(2) : '',
    );

    if (widget.existingProfile != null) {
      _calcMode = widget.existingProfile!.calculationMode;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(taxRepositoryProvider);

      final rateDouble = double.tryParse(_rateCtrl.text) ?? 0.0;
      final rateBasisPoints = (rateDouble * 100).round();

      if (widget.existingProfile == null) {
        await repo.createTaxProfile(
          name: _nameCtrl.text,
          description: _descCtrl.text,
          calculationMode: _calcMode,
          rateBasisPoints: rateBasisPoints,
        );
      } else {
        await repo.updateTaxProfile(
          id: widget.existingProfile!.id,
          name: _nameCtrl.text,
          description: _descCtrl.text,
          calculationMode: _calcMode,
          newRateBasisPoints: rateBasisPoints,
          currentRateBasisPoints: widget.existingProfile!.effectiveBasisPoints,
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving tax: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: bottomInset > 0 ? bottomInset + 20 : 32,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existingProfile == null
                  ? 'Create Tax Profile'
                  : 'Edit Tax Profile',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Tax Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _rateCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Rate Percentage',
                suffixText: '%',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (double.tryParse(v) == null) return 'Invalid number';
                return null;
              },
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _calcMode,
              decoration: InputDecoration(
                labelText: 'Calculation Mode',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'exclusive',
                  child: Text('Exclusive (Added to price)'),
                ),
                DropdownMenuItem(
                  value: 'inclusive',
                  child: Text('Inclusive (Included in price)'),
                ),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _calcMode = val);
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _descCtrl,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            FilledButton(
              onPressed: _isLoading ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Save Tax',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
