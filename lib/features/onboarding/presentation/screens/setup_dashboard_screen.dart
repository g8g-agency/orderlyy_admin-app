// lib/features/onboarding/presentation/screens/setup_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../state/onboarding_notifier.dart';
import '../../../../core/auth/app_auth_provider.dart';
import '../../data/repositories/onboarding_repository.dart'
    as tableos_admin_onboarding_repository_provider;
import '../../../../core/auth/bootstrap_provider.dart';
import '../../../../core/runtime/runtime_reset_service.dart';

class SetupDashboardScreen extends ConsumerStatefulWidget {
  const SetupDashboardScreen({super.key});

  @override
  ConsumerState<SetupDashboardScreen> createState() => _SetupDashboardScreenState();
}

class _SetupDashboardScreenState extends ConsumerState<SetupDashboardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isSavingProfile = false;
  bool _isLaunching = false;

  @override
  void initState() {
    super.initState();
    // Force refresh onboarding status from backend on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(onboardingNotifierProvider);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _showProfileDialog(String tenantId, String initialName) async {
    _nameController.text = initialName;

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: !_isSavingProfile,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Configure Restaurant Profile',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.black),
              ),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.black),
                        decoration: const InputDecoration(
                          labelText: 'Restaurant Name *',
                          labelStyle: TextStyle(color: Colors.grey),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryContainer)),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isSavingProfile ? null : () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: _isSavingProfile
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          setDialogState(() => _isSavingProfile = true);

                          try {
                            final client = Supabase.instance.client;
                            // Update tenant name (branches table has no address/phone columns)
                            await client
                                .from('tenants')
                                .update({'name': _nameController.text.trim()})
                                .eq('id', tenantId);

                            // Complete step in the database onboarding state
                            await ref.read(appContextProvider.notifier).completeOnboardingStep(
                                  tenantId,
                                  'profile',
                                  false,
                                );

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Profile updated successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              // Refresh onboarding metrics
                              ref.invalidate(onboardingNotifierProvider);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error saving profile: $e')),
                              );
                            }
                          } finally {
                            setDialogState(() => _isSavingProfile = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryContainer,
                    foregroundColor: Colors.white,
                  ),
                  child: _isSavingProfile
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save Profile'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _launchReadyScreen(String tenantId) async {
    showDialog(
      context: context,
      barrierDismissible: !_isLaunching,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              contentPadding: const EdgeInsets.all(32),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.celebration_rounded,
                    color: Colors.green,
                    size: 64,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "You're Ready to Roll!",
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Your restaurant profile, taxes, and floor infrastructure are fully configured. Tapping Launch will complete your setup and open your main operational dashboard.",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLaunching
                          ? null
                          : () async {
                              setDialogState(() => _isLaunching = true);
                              try {
                                // Mark the ready step as complete and set is_complete = true in database
                                await ref.read(appContextProvider.notifier).completeOnboardingStep(
                                      tenantId,
                                      'ready',
                                      true, // isLastStep!
                                    );

                                await RuntimeResetService.clearRuntimeViews();

                                // Force reload context via bootstrap
                                final appCtx = ref.read(appContextProvider);
                                final userId = appCtx?.user.id ?? '';
                                await ref.read(bootstrapProvider.notifier).resolve(userId);

                                if (context.mounted) {
                                  Navigator.pop(context);
                                  context.go('/admin/dashboard');
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error launching restaurant: $e')),
                                  );
                                }
                              } finally {
                                setDialogState(() => _isLaunching = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isLaunching
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            )
                          : Text(
                              'Launch Orderlli',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingNotifierProvider);
    final appContext = ref.watch(appContextProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Restaurant Setup',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: -0.5),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () {
              ref.read(authServiceProvider).signOut();
            },
          ),
        ],
      ),
      body: onboardingState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
              const SizedBox(height: 16),
              Text('Failed to load setup status: $err', style: const TextStyle(color: Colors.black)),
              TextButton(
                onPressed: () => ref.invalidate(onboardingNotifierProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (status) {
          // If unauthenticated (e.g., from "New Member"), we provide a fallback UI
          // so the user can see the setup page as requested.
          final isGuest = status == null || appContext == null;

          final hasProfile = isGuest ? false : (appContext.onboarding.stepsCompleted.contains('restaurant_info'));
          final hasTax = isGuest ? false : status.hasTaxProfiles;
          final hasTables = isGuest ? false : status.hasTables;
          final isReady = hasProfile && hasTax && hasTables;
          
          final tenantName = isGuest ? 'New Restaurant' : appContext.tenant.name;

          int completedSteps = 0;
          if (hasProfile) completedSteps++;
          if (hasTax) completedSteps++;
          if (hasTables) completedSteps++;
          if (!isGuest && appContext.onboarding.isComplete) completedSteps++;

          final progress = completedSteps / 4.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to Orderlli, $tenantName',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Let's complete your premium setup wizard to prepare your floor and operations for seamless real-time ordering.",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.secondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Progress Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.primaryContainer.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Setup Wizard Progress',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                '${(progress * 100).toInt()}%',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  color: AppTheme.primaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: AppTheme.background,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryContainer,
                            ),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Completed: $completedSteps / 4 steps",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    Text(
                      'Required Configurations',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Step 1: Restaurant Profile
                    _ChecklistCard(
                      title: 'Step 1: Restaurant Profile',
                      description: 'Configure restaurant identity, primary location address, and phone.',
                      isCompleted: hasProfile,
                      icon: Icons.storefront_rounded,
                      onTap: () {
                        if (isGuest) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in or sign up to configure this.')));
                          return;
                        }
                        if (!hasProfile) {
                          _showProfileDialog(appContext.tenant.id, appContext.tenant.name);
                        } else {
                          context.go('/onboarding/restaurant-info');
                        }
                      },
                    ),

                    // Step 2: GST and Legal Compliance
                    _ChecklistCard(
                      title: 'Step 2: GST & Taxes',
                      description: 'Configure legal compliance and default GST percentage.',
                      isCompleted: hasTax,
                      icon: Icons.gavel_rounded,
                      onTap: () {
                        if (isGuest) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in or sign up to configure this.')));
                          return;
                        }
                        context.push('/onboarding/gst-legal');
                      },
                    ),

                    // Step 3: Floor Setup
                    _ChecklistCard(
                      title: 'Step 3: Tables & Floor Setup',
                      description: 'Create floor physical tables and map real-time digital ordering codes.',
                      isCompleted: hasTables,
                      icon: Icons.table_bar_rounded,
                      onTap: () {
                        if (isGuest) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in or sign up to configure this.')));
                          return;
                        }
                        context.push('/onboarding/tables-hours');
                      },
                    ),

                    // Step 4: Ready
                    _ChecklistCard(
                      title: 'Step 4: Launch Center',
                      description: 'All steps verified. Complete the wizard and go live.',
                      isCompleted: !isGuest && appContext.onboarding.isComplete,
                      icon: Icons.rocket_launch_rounded,
                      isEnabled: isReady,
                      onTap: () {
                        if (isGuest) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in or sign up to launch.')));
                          return;
                        }
                        if (isReady) {
                          _launchReadyScreen(appContext.tenant.id);
                        }
                      },
                    ),

                    // Skip CTA
                    Padding(
                      padding: const EdgeInsets.only(top: 36),
                      child: InkWell(
                        onTap: () async {
                          if (isGuest) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in or sign up to configure this.')));
                            return;
                          }
                          try {
                            final repo = ref.read(
                              tableos_admin_onboarding_repository_provider.onboardingRepositoryProvider,
                            );
                            await repo.skipOnboarding();
                            await RuntimeResetService.clearRuntimeViews();

                            // Reload Context
                            final userId = appContext.user.id;
                            await ref.read(bootstrapProvider.notifier).resolve(userId);

                            if (context.mounted) {
                              context.go('/admin/dashboard');
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to skip: $e')),
                              );
                            }
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.2),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Skip Onboarding for Now',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'You can access and update all parameters from settings dashboard anytime.',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppTheme.secondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ChecklistCard extends StatelessWidget {
  final String title;
  final String description;
  final bool isCompleted;
  final IconData icon;
  final VoidCallback onTap;
  final bool isEnabled;

  const _ChecklistCard({
    required this.title,
    required this.description,
    required this.isCompleted,
    required this.icon,
    required this.onTap,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final finalEnabled = isEnabled && !isCompleted;
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: finalEnabled ? AppTheme.surface : AppTheme.surface.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isCompleted
              ? Colors.green.withValues(alpha: 0.4)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: isCompleted
              ? Colors.green.withValues(alpha: 0.15)
              : (finalEnabled ? AppTheme.background : AppTheme.background.withValues(alpha: 0.5)),
          child: Icon(
            isCompleted ? Icons.check_circle_rounded : icon,
            color: isCompleted
                ? Colors.green
                : (finalEnabled ? AppTheme.primaryContainer : Colors.grey),
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            color: isCompleted ? Colors.grey : (finalEnabled ? Colors.black : Colors.grey),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isCompleted ? Colors.grey : (finalEnabled ? AppTheme.secondary : Colors.grey[600]),
            ),
          ),
        ),
        trailing: Icon(
          isCompleted ? Icons.verified : Icons.arrow_forward_ios_rounded,
          size: 16,
          color: isCompleted ? Colors.green : (finalEnabled ? Colors.black54 : Colors.grey),
        ),
        onTap: finalEnabled ? onTap : null,
      ),
    );
  }
}
