import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/instability_score_provider.dart';

class InstabilityScoreGauge extends ConsumerWidget {
  const InstabilityScoreGauge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = ref.watch(instabilityScoreProvider);

    if (score == null) {
      return const SizedBox.shrink();
    }

    Color overallColor;
    switch (score.overallHealth) {
      case 'CRITICAL':
        overallColor = const Color(0xFFF85149);
        break;
      case 'UNSTABLE':
        overallColor = const Color(0xFFFFA657);
        break;
      case 'DEGRADED':
        overallColor = const Color(0xFFD29922);
        break;
      default:
        overallColor = const Color(0xFF3FB950);
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.speed, color: Color(0xFF8B949E), size: 16),
              const SizedBox(width: 8),
              const Text(
                'RUNTIME INSTABILITY',
                style: TextStyle(
                  color: Color(0xFFE6EDF3),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: overallColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: overallColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  score.overallHealth,
                  style: TextStyle(
                    color: overallColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ScoreRow(label: 'Reconnects', score: score.reconnectScore),
          const SizedBox(height: 8),
          _ScoreRow(label: 'Mutations', score: score.mutationScore),
          const SizedBox(height: 8),
          _ScoreRow(label: 'Projections', score: score.projectionScore),
          const SizedBox(height: 8),
          _ScoreRow(label: 'Transport', score: score.transportScore),
          const SizedBox(height: 8),
          _ScoreRow(label: 'Duplicates', score: score.duplicateScore),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final int score; // 0 - 100

  const _ScoreRow({required this.label, required this.score});

  @override
  Widget build(BuildContext context) {
    Color barColor;
    if (score > 80) {
      barColor = const Color(0xFFF85149);
    } else if (score > 50) {
      barColor = const Color(0xFFFFA657);
    } else if (score > 20) {
      barColor = const Color(0xFFD29922);
    } else {
      barColor = const Color(0xFF3FB950);
    }

    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8B949E),
              fontSize: 11,
              fontFamily: 'RobotoMono',
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFF21262D),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (score / 100).clamp(0.0, 1.0),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 30,
          child: Text(
            '$score',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: barColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              fontFamily: 'RobotoMono',
            ),
          ),
        ),
      ],
    );
  }
}
