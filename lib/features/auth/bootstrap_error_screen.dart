import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/auth/bootstrap_provider.dart';
import '../../core/auth/bootstrap_state.dart';
import '../../core/auth/mock_auth_provider.dart';
import '../../core/providers/repository_providers.dart';

/// Shown when bootstrap fails — either network unreachable or server error.
/// Provides retry and sign-out options.
/// The dashboard CANNOT be reached from this screen — only retry or logout.
class BootstrapErrorScreen extends ConsumerWidget {
  const BootstrapErrorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrapState = ref.watch(bootstrapProvider);
    final authState = ref.watch(authNotifierProvider);

    final isNetworkError =
        bootstrapState.status == BootstrapStatus.networkFailure;
    final errorMessage = bootstrapState.errorMessage ??
        'An unexpected error occurred while loading your workspace.';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Error icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    isNetworkError
                        ? Icons.wifi_off_rounded
                        : Icons.error_outline_rounded,
                    color: Colors.red.shade400,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  isNetworkError ? 'Connection Failed' : 'Workspace Error',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  errorMessage,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white60,
                        height: 1.5,
                      ),
                ),
                const SizedBox(height: 40),

                // Retry button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      final userId = authState.userId;
                      if (userId != null) {
                        ref
                            .read(bootstrapProvider.notifier)
                            .retry(userId);
                      }
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try Again'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryContainer,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Sign out button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final repo = ref.read(authRepositoryProvider);
                      await repo.signOut();
                    },
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Use a Different Account'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white60,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
