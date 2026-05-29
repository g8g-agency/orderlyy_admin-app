import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/runtime_health_provider.dart';
import 'dart:math' as math;

class ProjectionDriftHeatmap extends ConsumerWidget {
  const ProjectionDriftHeatmap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthState = ref.watch(runtimeHealthProvider);

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
          const Row(
            children: [
              Icon(Icons.grid_on, color: Color(0xFF8B949E), size: 16),
              SizedBox(width: 8),
              Text(
                'PROJECTION DRIFT HEATMAP',
                style: TextStyle(
                  color: Color(0xFFE6EDF3),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          healthState.when(
            data: (snapshot) {
              if (snapshot.domains.isEmpty) return const SizedBox.shrink();
              
              // We extract data for the heatmap
              final domains = snapshot.domains.keys.toList();
              final lags = domains.map((d) {
                // Mock calculation of drift lag based on stale count and avg duration
                final domain = snapshot.domains[d]!;
                return math.min(100.0, (domain.staleCount * 10 + domain.avgDurationMs / 10).toDouble());
              }).toList();

              return SizedBox(
                height: 120,
                child: CustomPaint(
                  painter: _HeatmapPainter(
                    domains: domains,
                    lags: lags,
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => const Text('Error loading drift data'),
          ),
        ],
      ),
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  final List<String> domains;
  final List<double> lags; // 0 to 100

  _HeatmapPainter({required this.domains, required this.lags});

  @override
  void paint(Canvas canvas, Size size) {
    if (domains.isEmpty) return;

    final double cellWidth = size.width / domains.length;
    final double cellHeight = size.height - 20;

    for (int i = 0; i < domains.length; i++) {
      final lag = lags[i];
      Color cellColor;

      if (lag > 80) {
        cellColor = const Color(0xFFF85149);
      } else if (lag > 50) {
        cellColor = const Color(0xFFFFA657);
      } else if (lag > 20) {
        cellColor = const Color(0xFFD29922);
      } else {
        cellColor = const Color(0xFF238636);
      }

      final rect = Rect.fromLTWH(i * cellWidth + 4, 0, cellWidth - 8, cellHeight);
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        Paint()..color = cellColor,
      );

      // Draw text
      final textPainter = TextPainter(
        text: TextSpan(
          text: domains[i].toUpperCase(),
          style: const TextStyle(
            color: Color(0xFFE6EDF3),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          rect.left + (rect.width - textPainter.width) / 2,
          rect.bottom + 4,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter oldDelegate) {
    return true; // Simplified
  }
}
