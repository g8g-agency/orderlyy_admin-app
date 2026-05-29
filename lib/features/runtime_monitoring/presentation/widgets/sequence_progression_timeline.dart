import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/runtime_health_provider.dart';

class SequenceProgressionTimeline extends ConsumerWidget {
  const SequenceProgressionTimeline({super.key});

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
              Icon(Icons.timeline, color: Color(0xFF8B949E), size: 16),
              SizedBox(width: 8),
              Text(
                'SEQUENCE PROGRESSION TIMELINE',
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
              
              // We'll just take the 'orders' domain watermark for a demo progression
              final ordersDomain = snapshot.domains['orders'];
              final watermark = ordersDomain?.watermark ?? 0;
              final gaps = ordersDomain?.gapCount ?? 0;

              return SizedBox(
                height: 100,
                child: CustomPaint(
                  painter: _SequencePainter(
                    watermark: watermark,
                    gaps: gaps,
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => const Text('Error loading sequence data'),
          ),
        ],
      ),
    );
  }
}

class _SequencePainter extends CustomPainter {
  final int watermark;
  final int gaps;

  _SequencePainter({required this.watermark, required this.gaps});

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = const Color(0xFF58A6FF)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final paintGap = Paint()
      ..color = const Color(0xFFF85149)
      ..style = PaintingStyle.fill;

    // Draw baseline
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paintLine..color = const Color(0xFF30363D),
    );

    // Draw progression line (mocked based on watermark)
    // In a real implementation, this would iterate over actual sequence points
    double progressWidth = size.width * 0.8; 
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(progressWidth, size.height / 2),
      paintLine..color = const Color(0xFF58A6FF),
    );

    // Draw current watermark node
    canvas.drawCircle(
      Offset(progressWidth, size.height / 2),
      6,
      Paint()..color = const Color(0xFF58A6FF),
    );

    // Draw gap anomalies if any
    for (int i = 0; i < gaps; i++) {
      double gapX = progressWidth - (i * 20 + 20);
      if (gapX > 0) {
        canvas.drawCircle(
          Offset(gapX, size.height / 2),
          4,
          paintGap,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SequencePainter oldDelegate) {
    return oldDelegate.watermark != watermark || oldDelegate.gaps != gaps;
  }
}
