import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/divergence_alerts_provider.dart';
import '../../data/dtos/runtime_snapshot_dto.dart';

class DivergenceAlertPanel extends ConsumerWidget {
  const DivergenceAlertPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(divergenceAlertsProvider);

    if (alerts.isEmpty) {
      return const SizedBox.shrink(); // Hide if no alerts
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF85149).withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFF85149), size: 20),
              const SizedBox(width: 8),
              const Text(
                'DIVERGENCE ALERTS',
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
                  color: const Color(0xFFF85149).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${alerts.length} ACTIVE',
                  style: const TextStyle(
                    color: Color(0xFFF85149),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: alerts.length,
            separatorBuilder: (context, index) => const Divider(color: Color(0xFF30363D)),
            itemBuilder: (context, index) {
              final alert = alerts[index];
              return _AlertItem(alert: alert);
            },
          ),
        ],
      ),
    );
  }
}

class _AlertItem extends StatelessWidget {
  final DivergenceAlertDto alert;

  const _AlertItem({required this.alert});

  Color _getSeverityColor() {
    switch (alert.severity) {
      case 'CRITICAL':
        return const Color(0xFFF85149);
      case 'ERROR':
        return const Color(0xFFFFA657);
      case 'WARNING':
        return const Color(0xFFD29922);
      default:
        return const Color(0xFF58A6FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getSeverityColor();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                alert.eventType,
                style: const TextStyle(
                  color: Color(0xFFE6EDF3),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'RobotoMono',
                ),
              ),
              const Spacer(),
              Text(
                'Count: ${alert.count}',
                style: const TextStyle(
                  color: Color(0xFF8B949E),
                  fontSize: 11,
                  fontFamily: 'RobotoMono',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Text(
              'Domain: ${alert.domain ?? 'N/A'} | Incident ID: ${alert.incidentId}',
              style: const TextStyle(
                color: Color(0xFF8B949E),
                fontSize: 11,
                fontFamily: 'RobotoMono',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
