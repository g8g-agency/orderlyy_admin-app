import 'package:flutter/material.dart';
import '../../data/dtos/runtime_snapshot_dto.dart';

class RuntimeHealthDashboard extends StatelessWidget {
  final RuntimeSnapshotDto snapshot;

  const RuntimeHealthDashboard({super.key, required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF161B22), // GitHub dim dark surface
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFF30363D)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'RUNTIME HEALTH DASHBOARD',
              style: TextStyle(
                color: Color(0xFF8B949E), // Muted
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildMetric(
                  'TRANSPORT',
                  snapshot.transportState,
                  _getTransportColor(),
                ),
                _buildMetric(
                  'POLLING',
                  snapshot.degradedPollingActive ? 'ACTIVE' : 'off',
                  snapshot.degradedPollingActive
                      ? const Color(0xFFE3B341)
                      : const Color(0xFF484F58),
                ),
                _buildMetric(
                  'RECONNECTS',
                  '${snapshot.reconnectAttempts}',
                  snapshot.reconnectAttempts > 0
                      ? const Color(0xFFE3B341)
                      : const Color(0xFF484F58),
                ),
                _buildMetric(
                  'GAPS',
                  '${snapshot.sequenceGaps}',
                  snapshot.sequenceGaps > 0
                      ? const Color(0xFFF85149)
                      : const Color(0xFF484F58),
                ),
                _buildMetric(
                  'STALE',
                  '${snapshot.staleRejected}',
                  snapshot.staleRejected > 0
                      ? const Color(0xFFE3B341)
                      : const Color(0xFF484F58),
                ),
                _buildMetric(
                  'MUTATIONS',
                  snapshot.mutationStalled > 0
                      ? '⚠ ${snapshot.mutationStalled} stalled'
                      : 'ok',
                  snapshot.mutationStalled > 0
                      ? const Color(0xFFE3B341)
                      : const Color(0xFF484F58),
                ),
                _buildMetric(
                  'BUFFER',
                  '${snapshot.bufferSize}/500',
                  snapshot.bufferSize > 400
                      ? const Color(0xFFE3B341)
                      : const Color(0xFFE6EDF3),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getTransportColor() {
    switch (snapshot.transportState) {
      case 'LIVE':
      case 'CONNECTED':
        return const Color(0xFF3FB950); // Green
      case 'RECONNECTING':
      case 'RECOVERING':
        return const Color(0xFFE3B341); // Yellow
      case 'DEGRADED':
      case 'FAILED':
        return const Color(0xFFF85149); // Red
      default:
        return const Color(0xFF8B949E); // Muted
    }
  }

  Widget _buildMetric(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF484F58), // Dim
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontFamily: 'RobotoMono',
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
