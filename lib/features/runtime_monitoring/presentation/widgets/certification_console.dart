import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/runtime_certification_provider.dart';
import '../screens/historical_replay_explorer.dart' as import_screen;

class CertificationConsole extends ConsumerWidget {
  const CertificationConsole({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(runtimeCertificationProvider);
    final notifier = ref.read(runtimeCertificationProvider.notifier);

    return Card(
      color: const Color(0xFF161B22),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFF30363D)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CONVERGENCE CERTIFICATION',
              style: TextStyle(
                color: Color(0xFF8B949E),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            if (state.lastResult != null)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 8),
                color: const Color(0x203FB950),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF3FB950),
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.lastResult!,
                        style: const TextStyle(
                          color: Color(0xFF3FB950),
                          fontSize: 11,
                          fontFamily: 'RobotoMono',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (state.error != null)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 8),
                color: const Color(0x20F85149),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Color(0xFFF85149), size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.error!,
                        style: const TextStyle(
                          color: Color(0xFFF85149),
                          fontSize: 11,
                          fontFamily: 'RobotoMono',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSimulateButton(
                  'Scenario A',
                  state.isSimulating,
                  () => notifier.executeScenario('scenario_a'),
                ),
                _buildSimulateButton(
                  'Scenario B',
                  state.isSimulating,
                  () => notifier.executeScenario('scenario_b'),
                ),
                _buildSimulateButton(
                  'Scenario C',
                  state.isSimulating,
                  () => notifier.executeScenario('scenario_c'),
                ),
                _buildSimulateButton(
                  'Scenario D',
                  state.isSimulating,
                  () => notifier.executeScenario('scenario_d'),
                ),
                _buildSimulateButton(
                  'Scenario E',
                  state.isSimulating,
                  () => notifier.executeScenario('scenario_e'),
                ),
                _buildSimulateButton(
                  'Scenario F',
                  state.isSimulating,
                  () => notifier.executeScenario('scenario_f'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (state.lastRunId != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            import_screen.HistoricalReplayExplorerScreen(runId: state.lastRunId!),
                      ),
                    );
                  },
                  icon: const Icon(Icons.history, size: 16),
                  label: const Text('View Historical Replay Trace'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF238636),
                    foregroundColor: const Color(0xFFFFFFFF),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimulateButton(
    String label,
    bool isSimulating,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: isSimulating ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0x2058A6FF),
        foregroundColor: const Color(0xFF58A6FF),
        side: const BorderSide(color: Color(0x4058A6FF)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(
          fontFamily: 'RobotoMono',
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        elevation: 0,
      ),
      child: Text(label),
    );
  }
}
