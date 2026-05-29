import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/api/api_runtime_observability_repository.dart';
import '../../data/dtos/runtime_event_dto.dart';
import '../../data/repositories/runtime_observability_repository.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers/repository_providers.dart';

// Provides a list of flattened nodes with depth level
class FlatGraphNode {
  final RuntimeEventDto event;
  final int depth;
  bool isExpanded;
  bool hasChildrenLoaded;
  
  FlatGraphNode({
    required this.event,
    required this.depth,
    this.isExpanded = false,
    this.hasChildrenLoaded = false,
  });
}

final correlationGraphProvider = StateNotifierProvider.family<CorrelationGraphNotifier, AsyncValue<List<FlatGraphNode>>, String>((ref, correlationId) {
  return CorrelationGraphNotifier(ref.read(runtimeObservabilityRepositoryProvider), correlationId);
});

class CorrelationGraphNotifier extends StateNotifier<AsyncValue<List<FlatGraphNode>>> {
  final RuntimeObservabilityRepository _repository;
  final String _rootCorrelationId;

  CorrelationGraphNotifier(this._repository, this._rootCorrelationId) : super(const AsyncValue.loading()) {
    _loadRoot();
  }

  Future<void> _loadRoot() async {
    try {
      final result = await _repository.getGraphNode(_rootCorrelationId);
      if (result is Success<RuntimeEventDto>) {
        state = AsyncValue.data([FlatGraphNode(event: result.value, depth: 0)]);
      } else if (result is Failure<RuntimeEventDto>) {
        state = AsyncValue.error(result.error.message, StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleNode(String correlationId) async {
    final currentList = state.valueOrNull;
    if (currentList == null) return;

    final index = currentList.indexWhere((n) => n.event.correlationId == correlationId);
    if (index == -1) return;

    final node = currentList[index];

    if (node.isExpanded) {
      // Collapse: remove all descendants
      _collapseNode(index, node.depth, currentList);
    } else {
      // Expand: fetch and insert children
      await _expandNode(index, node, currentList);
    }
  }

  void _collapseNode(int index, int parentDepth, List<FlatGraphNode> currentList) {
    int removeCount = 0;
    for (int i = index + 1; i < currentList.length; i++) {
      if (currentList[i].depth > parentDepth) {
        removeCount++;
      } else {
        break;
      }
    }
    
    final newList = List<FlatGraphNode>.from(currentList);
    newList.removeRange(index + 1, index + 1 + removeCount);
    newList[index].isExpanded = false;
    state = AsyncValue.data(newList);
  }

  Future<void> _expandNode(int index, FlatGraphNode node, List<FlatGraphNode> currentList) async {
    try {
      final result = await _repository.getGraphChildren(node.event.correlationId, limit: 50, cursor: 0);
      if (result is Success<GraphCursorResponse>) {
        final childrenNodes = result.value.nodes
            .map((e) => FlatGraphNode(event: e, depth: node.depth + 1))
            .toList();

        final newList = List<FlatGraphNode>.from(currentList);
        newList[index].isExpanded = true;
        newList[index].hasChildrenLoaded = true;
        newList.insertAll(index + 1, childrenNodes);

        state = AsyncValue.data(newList);
      } else {
        debugPrint('Failed to load graph children');
      }
    } catch (e) {
      debugPrint('Failed to expand node: $e');
    }
  }
}

class CorrelationTreeExplorerScreen extends ConsumerWidget {
  final String runId;
  final String correlationId;

  const CorrelationTreeExplorerScreen({
    super.key,
    required this.runId,
    required this.correlationId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final graphState = ref.watch(correlationGraphProvider(correlationId));

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: Text('Correlation Tree: $correlationId'),
        backgroundColor: const Color(0xFF161B22),
      ),
      body: graphState.when(
        data: (nodes) {
          return ListView.builder(
            itemCount: nodes.length,
            itemBuilder: (context, index) {
              final node = nodes[index];
              return _buildNodeRow(ref, node);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Widget _buildNodeRow(WidgetRef ref, FlatGraphNode node) {
    return InkWell(
      onTap: () {
        ref.read(correlationGraphProvider(correlationId).notifier).toggleNode(node.event.correlationId);
      },
      child: Container(
        padding: EdgeInsets.only(
          left: 16.0 + (node.depth * 24.0),
          right: 16.0,
          top: 12.0,
          bottom: 12.0,
        ),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFF30363D))),
        ),
        child: Row(
          children: [
            Icon(
              node.isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
              color: Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getColorForEventType(node.event.eventType).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                node.event.eventType,
                style: TextStyle(
                  color: _getColorForEventType(node.event.eventType),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    node.event.correlationId,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  if (node.event.incidentId != null)
                    Text(
                      'Incident: ${node.event.incidentId}',
                      style: const TextStyle(color: Color(0xFFF85149), fontSize: 12),
                    ),
                ],
              ),
            ),
            Text(
              node.event.timestamp,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForEventType(String type) {
    if (type.contains('FAILED') || type.contains('REJECTED') || type.contains('DIVERGENCE')) return const Color(0xFFF85149);
    if (type.contains('COMPLETED') || type.contains('ACKNOWLEDGED')) return const Color(0xFF3FB950);
    if (type.contains('STARTED') || type.contains('QUEUED')) return const Color(0xFF58A6FF);
    return Colors.grey;
  }
}
