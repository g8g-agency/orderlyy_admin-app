import 'package:flutter/material.dart';
import '../../data/dtos/runtime_event_dto.dart';

class ReplayTraceExplorer extends StatelessWidget {
  final List<RuntimeEventDto> events;
  final bool isLoading;
  final VoidCallback onLoadMore;

  const ReplayTraceExplorer({
    super.key,
    required this.events,
    required this.isLoading,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty && isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (events.isEmpty) {
      return const Center(
        child: Text('No trace events found.', style: TextStyle(color: Color(0xFF8B949E))),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index == events.length) {
                return _buildLoadMoreButton();
              }
              final event = events[index];
              return _TraceEventItem(event: event);
            },
            childCount: events.length + 1,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : TextButton(
                onPressed: onLoadMore,
                child: const Text('Load More', style: TextStyle(color: Color(0xFF58A6FF))),
              ),
      ),
    );
  }
}

class _TraceEventItem extends StatelessWidget {
  final RuntimeEventDto event;

  const _TraceEventItem({required this.event});

  Color _getSeverityColor() {
    switch (event.severity) {
      case 'CRITICAL':
        return const Color(0xFFF85149);
      case 'ERROR':
        return const Color(0xFFFFA657);
      case 'WARNING':
        return const Color(0xFFD29922);
      case 'INFO':
        return const Color(0xFF58A6FF);
      default:
        return const Color(0xFF8B949E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getSeverityColor();

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF30363D))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      event.eventType,
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'RobotoMono',
                      ),
                    ),
                    const Spacer(),
                    Text(
                      event.timestamp,
                      style: const TextStyle(
                        color: Color(0xFF8B949E),
                        fontSize: 11,
                        fontFamily: 'RobotoMono',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (event.incidentId != null)
                  Text(
                    'Incident ID: ${event.incidentId}',
                    style: const TextStyle(color: Color(0xFFFFA657), fontSize: 11, fontFamily: 'RobotoMono'),
                  ),
                if (event.replayChainId != null)
                  Text(
                    'Replay Chain ID: ${event.replayChainId}',
                    style: const TextStyle(color: Color(0xFF8B949E), fontSize: 11, fontFamily: 'RobotoMono'),
                  ),
                Text(
                  'Domain: ${event.domain ?? 'N/A'} | Surface: ${event.surface ?? 'N/A'}',
                  style: const TextStyle(color: Color(0xFF8B949E), fontSize: 11, fontFamily: 'RobotoMono'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
