// lib/features/onboarding/presentation/screens/business_config_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/auth/app_auth_provider.dart';
import '../../../../core/auth/bootstrap_provider.dart';
import '../../data/repositories/onboarding_repository.dart'
    as onboarding_repo;

const List<String> _commonCurrencies = [
  'USD',
  'EUR',
  'GBP',
  'CAD',
  'AUD',
  'JPY',
  'INR',
  'AED',
];

const List<String> _businessTypes = [
  'Fine Dining',
  'Casual Dining',
  'Quick Service (QSR)',
  'Cafe / Bakery',
  'Food Truck',
  'Bar / Pub',
  'Other',
];

class BusinessConfigScreen extends ConsumerStatefulWidget {
  const BusinessConfigScreen({super.key});

  @override
  ConsumerState<BusinessConfigScreen> createState() => _BusinessConfigScreenState();
}

class _BusinessConfigScreenState extends ConsumerState<BusinessConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String? _selectedCurrency = 'USD';
  String? _selectedBusinessType;
  late TextEditingController _taxIdController;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _taxIdController = TextEditingController();
  }

  @override
  void dispose() {
    _taxIdController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCurrency == null) {
      setState(() {
        _errorMessage = 'Currency is required.';
      });
      return;
    }
    if (_selectedBusinessType == null) {
      setState(() {
        _errorMessage = 'Business Type is required.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(onboarding_repo.onboardingRepositoryProvider);
      
      await repo.updateBusinessConfig(
        currencyCode: _selectedCurrency!,
        businessType: _selectedBusinessType,
        taxRegistrationNumber: _taxIdController.text.trim().isEmpty ? null : _taxIdController.text.trim(),
      );

      // Force bootstrap reload to get new onboarding_step and context
      final appContext = ref.read(appContextProvider);
      if (appContext != null) {
        await ref.read(bootstrapProvider.notifier).silentResolve(appContext.user.id);
      }

      if (mounted) {
        context.go('/onboarding');
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
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Step 2: Business Config',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: -0.5),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              color: AppTheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Operational Settings',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Define your core business settings. Your currency will apply to all pricing, menus, and reporting.',
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
                            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),

                      DropdownButtonFormField<String>(
                        value: _selectedBusinessType,
                        dropdownColor: AppTheme.surface,
                        style: const TextStyle(color: Colors.black),
                        decoration: _inputDecoration('Business Type *'),
                        items: _businessTypes.map((bt) {
                          return DropdownMenuItem(
                            value: bt,
                            child: Text(bt),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedBusinessType = val;
                          });
                        },
                        validator: (value) => value == null || value.isEmpty ? 'Business Type is required' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedCurrency,
                        dropdownColor: AppTheme.surface,
                        style: const TextStyle(color: Colors.black),
                        decoration: _inputDecoration('Currency *'),
                        items: _commonCurrencies.map((c) {
                          return DropdownMenuItem(
                            value: c,
                            child: Text(c),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedCurrency = val;
                          });
                        },
                        validator: (value) => value == null || value.isEmpty ? 'Currency is required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _taxIdController,
                        style: const TextStyle(color: Colors.black),
                        decoration: _inputDecoration('Tax Registration Number (Optional)'),
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
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
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
