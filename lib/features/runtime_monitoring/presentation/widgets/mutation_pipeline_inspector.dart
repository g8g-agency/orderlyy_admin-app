import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/mutation_pipeline_provider.dart';

class MutationPipelineInspector extends ConsumerWidget {
  const MutationPipelineInspector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(mutationPipelineProvider);

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
              'MUTATION DIAGNOSTICS',
              style: TextStyle(
                color: Color(0xFF8B949E),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            if (metrics == null || metrics.submitted == 0)
              const Text(
                'no mutations in buffer',
                style: TextStyle(
                  color: Color(0xFF484F58),
                  fontFamily: 'RobotoMono',
                  fontSize: 11,
                ),
              )
            else
              Column(
                children: [
                  _buildBar(
                    'submitted',
                    metrics.submitted,
                    metrics.submitted,
                    const Color(0xFFE6EDF3),
                  ),
                  _buildBar(
                    'acknowledged',
                    metrics.acknowledged,
                    metrics.submitted,
                    const Color(0xFF58A6FF),
                  ),
                  _buildBar(
                    'confirmed',
                    metrics.confirmed,
                    metrics.submitted,
                    const Color(0xFF3FB950),
                  ),
                  _buildBar(
                    'stalled',
                    metrics.stalled,
                    metrics.submitted,
                    const Color(0xFFE3B341),
                  ),
                  _buildBar(
                    'failed',
                    metrics.failed,
                    metrics.submitted,
                    const Color(0xFFF85149),
                  ),
                  _buildBar(
                    'rejected',
                    metrics.rejected,
                    metrics.submitted,
                    const Color(0xFFF85149),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(String label, int value, int total, Color color) {
    final percentage = total > 0 ? (value / total).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF8B949E),
                fontFamily: 'RobotoMono',
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(3),
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: percentage,
                child: Container(
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 30,
            child: Text(
              '$value',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: color,
                fontFamily: 'RobotoMono',
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
