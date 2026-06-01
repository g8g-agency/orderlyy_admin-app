import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/branch_context_service.dart';
import '../runtime/branch_runtime_coordinator.dart';

class BranchStateDebugger extends ConsumerWidget {
  const BranchStateDebugger({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final epoch = ref.watch(branchEpochProvider);
    final switchState = ref.watch(runtimeSwitchStateProvider);
    final currentBranch = ref.watch(currentBranchProvider).value;

    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.black87,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Branch Debug Tool', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 4),
          Text('Epoch: $epoch', style: const TextStyle(color: Colors.greenAccent, fontSize: 10)),
          Text('State: ${switchState.name}', style: const TextStyle(color: Colors.greenAccent, fontSize: 10)),
          Text('Active: ${currentBranch?.name ?? "None"}', style: const TextStyle(color: Colors.greenAccent, fontSize: 10)),
        ],
      ),
    );
  }
}
