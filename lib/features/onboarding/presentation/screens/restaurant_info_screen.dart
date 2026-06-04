// lib/features/onboarding/presentation/screens/restaurant_info_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/auth/app_auth_provider.dart';
import '../../data/repositories/onboarding_repository.dart'
    as onboarding_repo;

const List<String> _commonTimezones = [
  'America/New_York',
  'America/Chicago',
  'America/Denver',
  'America/Los_Angeles',
  'America/Toronto',
  'Europe/London',
  'Europe/Paris',
  'Europe/Berlin',
  'Asia/Kolkata',
  'Asia/Tokyo',
  'Asia/Singapore',
  'Asia/Dubai',
  'Australia/Sydney',
  'Australia/Melbourne',
  'Pacific/Auckland',
  'UTC',
];

class RestaurantInfoScreen extends ConsumerStatefulWidget {
  const RestaurantInfoScreen({super.key});

  @override
  ConsumerState<RestaurantInfoScreen> createState() => _RestaurantInfoScreenState();
}

class _RestaurantInfoScreenState extends ConsumerState<RestaurantInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _addressController;
  String? _selectedTimezone;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final appContext = ref.read(appContextProvider);
    _nameController = TextEditingController(text: appContext?.tenant.name ?? '');
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _addressController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTimezone == null) {
      setState(() {
        _errorMessage = 'Timezone is required.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(onboarding_repo.onboardingRepositoryProvider);
      
      await repo.updateRestaurantInfo(
        displayName: _nameController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        fullAddress: _addressController.text.trim(),
        timezone: _selectedTimezone!,
      );

      ref.read(appContextProvider.notifier).applyOnboardingProgress(
        completedStep: 'restaurant_info',
        nextStep: 2,
      );

      if (mounted) {
        context.go('/onboarding/business-config');
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
          'Step 1: Restaurant Info',
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
                        'Core Information',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Establish your digital presence. Your timezone dictates all operational hours and reporting.',
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

                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: AppTheme.onSurface),
                        decoration: _inputDecoration('Restaurant Display Name *'),
                        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cityController,
                              style: const TextStyle(color: AppTheme.onSurface),
                              decoration: _inputDecoration('City *'),
                              validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _stateController,
                              style: const TextStyle(color: AppTheme.onSurface),
                              decoration: _inputDecoration('State/Region *'),
                              validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        style: const TextStyle(color: AppTheme.onSurface),
                        decoration: _inputDecoration('Full Physical Address *'),
                        maxLines: 3,
                        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      
                      DropdownButtonFormField<String>(
                        initialValue: _selectedTimezone,
                        dropdownColor: AppTheme.surfaceContainerLowest,
                        style: const TextStyle(color: AppTheme.onSurface),
                        decoration: _inputDecoration('Timezone (IANA) *'),
                        items: _commonTimezones.map((tz) {
                          return DropdownMenuItem(
                            value: tz,
                            child: Text(
                              tz,
                              style: const TextStyle(color: AppTheme.onSurface),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedTimezone = val;
                          });
                        },
                        validator: (value) => value == null || value.isEmpty ? 'Timezone is required' : null,
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
      labelStyle: const TextStyle(color: AppTheme.secondary),
      fillColor: AppTheme.surfaceContainerLowest,
      filled: true,
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: AppTheme.surfaceContainerHigh, width: 1),
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
