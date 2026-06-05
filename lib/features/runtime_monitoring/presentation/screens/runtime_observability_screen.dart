import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart'; // For kReleaseMode

import '../providers/runtime_health_provider.dart';
import '../widgets/runtime_health_dashboard.dart';
import '../widgets/projection_diagnostics_panel.dart';
import '../widgets/replay_recovery_inspector.dart';
import '../widgets/mutation_pipeline_inspector.dart';
import '../widgets/event_stream_inspector.dart';
import '../widgets/certification_console.dart';
import '../widgets/divergence_alert_panel.dart';
import '../widgets/instability_score_gauge.dart';
import '../widgets/cross_surface_convergence_panel.dart';
import '../widgets/sequence_progression_timeline.dart';
import '../widgets/projection_drift_heatmap.dart';
import '../widgets/operational_safety_panel.dart';

class RuntimeObservabilityScreen extends ConsumerWidget {
  const RuntimeObservabilityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kReleaseMode) {
      return const Scaffold(
        body: Center(child: Text('Not available in production.')),
      );
    }

    final healthState = ref.watch(runtimeHealthProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117), // GitHub very dark background
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ORDERLYY · RUNTIME INFRASTRUCTURE',
              style: TextStyle(
                color: Color(0xFF8B949E),
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
            Text(
              'Observability Panel',
              style: TextStyle(
                color: Color(0xFFE6EDF3),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0x20E3B341),
              border: Border.all(color: const Color(0x40E3B341)),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Center(
              child: Text(
                'DEV ONLY',
                style: TextStyle(
                  color: Color(0xFFE3B341),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
      body: healthState.when(
        data: (snapshot) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RuntimeHealthDashboard(snapshot: snapshot),
                const SizedBox(height: 16),
                const DivergenceAlertPanel(),
                const SizedBox(height: 16),
                const CrossSurfaceConvergencePanel(),
                const SizedBox(height: 16),

                // Two Column Layout
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 800) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                const InstabilityScoreGauge(),
                                const SizedBox(height: 16),
                                const SequenceProgressionTimeline(),
                                const SizedBox(height: 16),
                                const OperationalSafetyPanel(),
                                const SizedBox(height: 16),
                                ProjectionDiagnosticsPanel(snapshot: snapshot),
                                const SizedBox(height: 16),
                                const CertificationConsole(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              children: [
                                ProjectionDriftHeatmap(),
                                SizedBox(height: 16),
                                MutationPipelineInspector(),
                                SizedBox(height: 16),
                                ReplayRecoveryInspector(),
                              ],
                            ),
                          ),
                        ],
                      );
                    }

                    // Single Column
                    return Column(
                      children: [
                        const InstabilityScoreGauge(),
                        const SizedBox(height: 16),
                        const SequenceProgressionTimeline(),
                        const SizedBox(height: 16),
                        const OperationalSafetyPanel(),
                        const SizedBox(height: 16),
                        const ProjectionDriftHeatmap(),
                        const SizedBox(height: 16),
                        ProjectionDiagnosticsPanel(snapshot: snapshot),
                        const SizedBox(height: 16),
                        const MutationPipelineInspector(),
                        const SizedBox(height: 16),
                        const ReplayRecoveryInspector(),
                        const SizedBox(height: 16),
                        const CertificationConsole(),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 16),
                const EventStreamInspector(),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF58A6FF)),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Color(0xFFF85149),
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load runtime telemetry:\n$err',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFF85149),
                  fontFamily: 'RobotoMono',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
