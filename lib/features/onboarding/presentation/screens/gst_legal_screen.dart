// lib/features/onboarding/presentation/screens/gst_legal_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/auth/app_auth_provider.dart';
import '../../data/repositories/onboarding_repository.dart' as onboarding_repo;

class GstLegalScreen extends ConsumerStatefulWidget {
  const GstLegalScreen({super.key});

  @override
  ConsumerState<GstLegalScreen> createState() => _GstLegalScreenState();
}

class _GstLegalScreenState extends ConsumerState<GstLegalScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _gstinController;
  late TextEditingController _fssaiController;

  String _selectedGstType = 'Intra-state';
  double _selectedTaxRate = 5.0;

  bool _isSaving = false;
  String? _errorMessage;

  final List<String> _gstTypes = [
    'Intra-state',
    'Inter-state',
    'Composition Scheme',
    'Non-GST Registered',
  ];

  final List<double> _taxRates = [0.0, 5.0, 12.0, 18.0, 28.0];

  @override
  void initState() {
    super.initState();
    _gstinController = TextEditingController();
    _fssaiController = TextEditingController();
  }

  @override
  void dispose() {
    _gstinController.dispose();
    _fssaiController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(onboarding_repo.onboardingRepositoryProvider);

      double cgst = 0;
      double sgst = 0;
      double igst = 0;

      if (_selectedGstType == 'Intra-state') {
        cgst = _selectedTaxRate / 2;
        sgst = _selectedTaxRate / 2;
      } else if (_selectedGstType == 'Inter-state') {
        igst = _selectedTaxRate;
      }

      await repo.updateGstLegalConfig(
        gstin: _gstinController.text.trim(),
        fssaiLicenseNumber: _fssaiController.text.trim(),
        gstType: _selectedGstType,
        defaultTaxRate: _selectedTaxRate,
        cgstRate: cgst,
        sgstRate: sgst,
        igstRate: igst,
      );

      // Force bootstrap reload to get new onboarding_step (which will be 4) and context
      ref
          .read(appContextProvider.notifier)
          .applyOnboardingProgress(completedStep: 'gst_legal', nextStep: 4);

      if (mounted) {
        context.go('/onboarding/tables-hours');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final showGstinWarning =
        _gstinController.text.trim().isEmpty &&
        _selectedGstType != 'Non-GST Registered';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Step 3: GST & Legal',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Card(
              color: AppTheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tax & compliance details',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'These details appear on printed receipts and tax documents. Some fields are required by law for GST-compliant invoicing.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.secondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),

                      if (_errorMessage != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.redAccent.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      DropdownButtonFormField<String>(
                        initialValue: _selectedGstType,
                        dropdownColor: AppTheme.surface,
                        style: const TextStyle(color: AppTheme.onSurface),
                        decoration: _inputDecoration('GST Type *'),
                        items: _gstTypes.map((t) {
                          return DropdownMenuItem(value: t, child: Text(t));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedGstType = val;
                              if (val == 'Non-GST Registered') {
                                _selectedTaxRate = 0.0;
                                _gstinController.clear();
                              }
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 20),

                      if (_selectedGstType != 'Non-GST Registered') ...[
                        TextFormField(
                          controller: _gstinController,
                          style: const TextStyle(color: AppTheme.onSurface),
                          textCapitalization: TextCapitalization.characters,
                          onChanged: (_) => setState(() {}),
                          decoration: _inputDecoration(
                            'GSTIN (15-digit) *Optional*',
                          ),
                          validator: (value) {
                            if (value != null && value.trim().isNotEmpty) {
                              final regex = RegExp(
                                r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[A-Z0-9]{1}Z[A-Z0-9]{1}$',
                              );
                              if (!regex.hasMatch(value)) {
                                return 'Invalid GSTIN format (e.g. 27AAPFU0939F1ZV)';
                              }
                            }
                            return null;
                          },
                        ),
                        if (showGstinWarning)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                            child: Text(
                              'GST-compliant invoices and receipts cannot be generated without a valid GSTIN.',
                              style: TextStyle(
                                color: Colors.orange[300],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<double>(
                          initialValue: _selectedTaxRate,
                          dropdownColor: AppTheme.surface,
                          style: const TextStyle(color: AppTheme.onSurface),
                          decoration: _inputDecoration(
                            'Default Tax Rate (%) *',
                          ),
                          items: _taxRates.map((rate) {
                            return DropdownMenuItem(
                              value: rate,
                              child: Text('${rate.toStringAsFixed(0)}%'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedTaxRate = val;
                              });
                            }
                          },
                        ),
                        if (_selectedGstType == 'Intra-state' &&
                            _selectedTaxRate > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                            child: Text(
                              'Splits into ${(_selectedTaxRate / 2).toStringAsFixed(1)}% CGST and ${(_selectedTaxRate / 2).toStringAsFixed(1)}% SGST',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        if (_selectedGstType == 'Inter-state' &&
                            _selectedTaxRate > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                            child: Text(
                              'Applies as ${_selectedTaxRate.toStringAsFixed(1)}% IGST',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                      ],

                      TextFormField(
                        controller: _fssaiController,
                        style: const TextStyle(color: AppTheme.onSurface),
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration(
                          'FSSAI License Number (14 digits) *',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'FSSAI License Number is required';
                          }
                          if (!RegExp(r'^[0-9]{14}$').hasMatch(value)) {
                            return 'Must be exactly 14 digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 40),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryContainer,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Save & Continue',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey, width: 0.5),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: AppTheme.primaryContainer, width: 1.5),
      ),
      errorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.redAccent, width: 0.5),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}
