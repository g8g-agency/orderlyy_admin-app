import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/historical_replay_provider.dart';
import '../widgets/replay_trace_explorer.dart';

class HistoricalReplayExplorerScreen extends ConsumerStatefulWidget {
  final String runId;

  const HistoricalReplayExplorerScreen({super.key, required this.runId});

  @override
  ConsumerState<HistoricalReplayExplorerScreen> createState() => _HistoricalReplayExplorerScreenState();
}

class _HistoricalReplayExplorerScreenState extends ConsumerState<HistoricalReplayExplorerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(historicalReplayProvider.notifier).loadRun(widget.runId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historicalReplayProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'HISTORICAL REPLAY EXPLORER',
              style: TextStyle(
                color: Color(0xFF8B949E),
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
            Text(
              'Run: ${widget.runId}',
              style: const TextStyle(
                color: Color(0xFFE6EDF3),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
      body: state.error != null
          ? Center(
              child: Text(
                'Error loading trace: ${state.error}',
                style: const TextStyle(color: Color(0xFFF85149)),
              ),
            )
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: const Color(0xFF161B22),
                  child: Row(
                    children: [
                      const Icon(Icons.history, color: Color(0xFF8B949E), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Total Events: ${state.totalCount}',
                        style: const TextStyle(color: Color(0xFF8B949E), fontSize: 12),
                      ),
                      const Spacer(),
                      Text(
                        'Loaded: ${state.events.length}',
                        style: const TextStyle(color: Color(0xFF8B949E), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ReplayTraceExplorer(
                    events: state.events,
                    isLoading: state.isLoading,
                    onLoadMore: () {
                      ref.read(historicalReplayProvider.notifier).fetchNextPage();
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
