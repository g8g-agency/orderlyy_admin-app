import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';

/// Shown while bootstrap is resolving after authentication.
/// Prevents any dashboard UI from rendering before workspace is confirmed.
class BootstrapLoadingScreen extends ConsumerWidget {
  const BootstrapLoadingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo / Brand mark
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primaryContainer.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.restaurant_menu_rounded,
                color: AppTheme.primaryContainer,
                size: 36,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              color: AppTheme.primaryContainer,
              strokeWidth: 2.5,
            ),
            const SizedBox(height: 24),
            Text(
              'Verifying your workspace…',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white54,
                    letterSpacing: 0.2,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
