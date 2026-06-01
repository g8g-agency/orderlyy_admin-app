import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/branch_context_service.dart';
import '../../features/organization/presentation/screens/organization_dashboard_screen.dart';

class RequireBranchGuard extends ConsumerWidget {
  final Widget child;
  final Widget? fallback;

  const RequireBranchGuard({
    super.key,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TEMPORARY SIMPLIFICATION: Disable branch guards
    return child;
  }

  Widget _buildSelectBranchPrompt(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.storefront, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('No Branch Selected', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('Please select or create a branch to manage its operations.', textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const OrganizationDashboardScreen()),
              );
            },
            child: const Text('Go to Organization Dashboard'),
          ),
        ],
      ),
    );
  }
}

class RequireOperationalBranchGuard extends ConsumerWidget {
  final Widget child;

  const RequireOperationalBranchGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TEMPORARY SIMPLIFICATION: Disable branch guards
    return child;
  }
}
