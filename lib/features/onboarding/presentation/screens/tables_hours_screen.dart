// lib/features/onboarding/presentation/screens/tables_hours_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/auth/app_auth_provider.dart';
import '../../../../core/auth/bootstrap_provider.dart';
import '../../data/repositories/onboarding_repository.dart'
    as onboarding_repo;

class TablesHoursScreen extends ConsumerStatefulWidget {
  const TablesHoursScreen({super.key});

  @override
  ConsumerState<TablesHoursScreen> createState() => _TablesHoursScreenState();
}

class _TablesHoursScreenState extends ConsumerState<TablesHoursScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _tablesController;
  late TextEditingController _prefixController;

  TimeOfDay? _openingTime;
  TimeOfDay? _closingTime;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tablesController = TextEditingController(text: '12');
    _prefixController = TextEditingController(text: 'T-');
    _openingTime = const TimeOfDay(hour: 11, minute: 0);
    _closingTime = const TimeOfDay(hour: 23, minute: 0); // 11:00 PM
  }

  @override
  void dispose() {
    _tablesController.dispose();
    _prefixController.dispose();
    super.dispose();
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final amPm = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $amPm';
  }

  Future<void> _pickTime(BuildContext context, bool isOpening) async {
    final initialTime = isOpening ? _openingTime! : _closingTime!;
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryContainer,
              onPrimary: Colors.white,
              surface: AppTheme.surface,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isOpening) {
          _openingTime = picked;
        } else {
          _closingTime = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_openingTime == null || _closingTime == null) {
      setState(() => _errorMessage = 'Please select both opening and closing times.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(onboarding_repo.onboardingRepositoryProvider);

      await repo.updateTablesAndHours(
        numberOfTables: int.parse(_tablesController.text.trim()),
        tablePrefix: _prefixController.text.trim().toUpperCase(),
        openingTime: _formatTimeOfDay(_openingTime!),
        closingTime: _formatTimeOfDay(_closingTime!),
      );

      // Force bootstrap reload to get new onboarding_step
      final appContext = ref.read(appContextProvider);
      if (appContext != null) {
        await ref.read(bootstrapProvider.notifier).silentResolve(appContext.user.id);
      }

      if (mounted) {
        // App router will redirect to Step 5 automatically
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
          'Step 4: Tables & Hours',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: -0.5),
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
                        'Set up your floor',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your initial restaurant tables and default operating hours.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.secondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.blueAccent, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Important Notice: You can add, rename, merge, split, or delete tables anytime later from Table Management.',
                                style: GoogleFonts.inter(color: Colors.blueAccent, fontSize: 13, height: 1.4),
                              ),
                            ),
                          ],
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

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _tablesController,
                              style: const TextStyle(color: Colors.black),
                              keyboardType: TextInputType.number,
                              decoration: _inputDecoration('Number of Tables *'),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return 'Required';
                                final num = int.tryParse(value.trim());
                                if (num == null) return 'Must be a number';
                                if (num < 1 || num > 500) return 'Must be between 1 and 500';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _prefixController,
                              style: const TextStyle(color: Colors.black),
                              textCapitalization: TextCapitalization.characters,
                              decoration: _inputDecoration('Table Prefix *'),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return 'Required';
                                if (value.trim().length > 10) return 'Max 10 characters';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Operating Hours (Default)',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _pickTime(context, true),
                              borderRadius: BorderRadius.circular(4),
                              child: InputDecorator(
                                decoration: _inputDecoration('Opening Time *'),
                                child: Text(
                                  _openingTime != null ? _formatTimeOfDay(_openingTime!) : 'Select Time',
                                  style: const TextStyle(color: Colors.black, fontSize: 16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () => _pickTime(context, false),
                              borderRadius: BorderRadius.circular(4),
                              child: InputDecorator(
                                decoration: _inputDecoration('Closing Time *'),
                                child: Text(
                                  _closingTime != null ? _formatTimeOfDay(_closingTime!) : 'Select Time',
                                  style: const TextStyle(color: Colors.black, fontSize: 16),
                                ),
                              ),
                            ),
                          ),
                        ],
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
