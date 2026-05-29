import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/runtime_event_stream_provider.dart';

class EventStreamInspector extends ConsumerStatefulWidget {
  const EventStreamInspector({super.key});

  @override
  ConsumerState<EventStreamInspector> createState() =>
      _EventStreamInspectorState();
}

class _EventStreamInspectorState extends ConsumerState<EventStreamInspector> {
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;
  String _domainFilter = 'ALL';
  String _typeFilter = 'ALL';

  static const _domainFilters = [
    'ALL',
    'orders',
    'tables',
    'kds',
    'analytics',
    'system',
  ];
  static const _typeFilters = [
    'ALL',
    'TRANSPORT',
    'PROJECTION',
    'MUTATION',
    'REPLAY',
    'REALTIME',
    'BUFFER',
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_autoScroll && _scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final streamState = ref.watch(runtimeEventStreamProvider);

    // Auto-scroll logic when new events arrive
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    final filteredEvents = streamState.events.where((e) {
      if (_domainFilter != 'ALL' && e.domain != _domainFilter) return false;
      if (_typeFilter != 'ALL' && !e.eventType.startsWith(_typeFilter)) {
        return false;
      }
      return true;
    }).toList();

    return Card(
      color: const Color(0xFF161B22),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFF30363D)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header & Filters
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF30363D))),
            ),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                const Text(
                  'RUNTIME TIMELINE',
                  style: TextStyle(
                    color: Color(0xFF8B949E),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                Container(width: 1, height: 12, color: const Color(0xFF30363D)),
                // Domain Filters
                ..._domainFilters.map(
                  (d) => _buildFilterChip(
                    d,
                    _domainFilter == d,
                    (v) => setState(() => _domainFilter = d),
                  ),
                ),
                Container(width: 1, height: 12, color: const Color(0xFF30363D)),
                // Type Filters
                ..._typeFilters.map(
                  (t) => _buildFilterChip(
                    t,
                    _typeFilter == t,
                    (v) => setState(() => _typeFilter = t),
                    isType: true,
                  ),
                ),

                const Spacer(),
                Text(
                  '${streamState.events.length} events in buffer',
                  style: const TextStyle(
                    color: Color(0xFF484F58),
                    fontFamily: 'RobotoMono',
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),

          // List
          SizedBox(
            height: 320,
            child: NotificationListener<ScrollNotification>(
              onNotification: (scrollInfo) {
                if (scrollInfo is ScrollEndNotification) {
                  final metrics = scrollInfo.metrics;
                  setState(() {
                    _autoScroll =
                        metrics.pixels >= metrics.maxScrollExtent - 40;
                  });
                }
                return false;
              },
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8),
                itemCount: filteredEvents.length,
                itemBuilder: (context, index) {
                  final event = filteredEvents[index];
                  final color = _getTypeColor(event.eventType);

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 4,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0x4030363D)),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(
                            event.timestamp.substring(11, 23),
                            style: const TextStyle(
                              color: Color(0xFF484F58),
                              fontFamily: 'RobotoMono',
                              fontSize: 10,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 200,
                          child: Text(
                            event.eventType,
                            style: TextStyle(
                              color: color,
                              fontFamily: 'RobotoMono',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            event.metadata.toString(),
                            style: const TextStyle(
                              color: Color(0xFF8B949E),
                              fontFamily: 'RobotoMono',
                              fontSize: 10,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // Footer / Autoscroll
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF30363D))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'showing ${filteredEvents.length} of ${streamState.events.length} events',
                  style: const TextStyle(
                    color: Color(0xFF484F58),
                    fontFamily: 'RobotoMono',
                    fontSize: 9,
                  ),
                ),
                Row(
                  children: [
                    Checkbox(
                      value: _autoScroll,
                      onChanged: (v) => setState(() => _autoScroll = v ?? true),
                      fillColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected)
                            ? const Color(0xFF3FB950)
                            : null,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    const Text(
                      'auto-scroll',
                      style: TextStyle(color: Color(0xFF8B949E), fontSize: 9),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    bool isSelected,
    Function(bool) onSelected, {
    bool isType = false,
  }) {
    Color selectedColor = const Color(0xFF3FB950);
    if (isType && isSelected) {
      selectedColor = _getTypeColor(label);
    }

    return InkWell(
      onTap: () => onSelected(true),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected
              ? selectedColor.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? selectedColor : const Color(0xFF484F58),
            fontSize: 9,
            fontWeight: FontWeight.bold,
            fontFamily: 'RobotoMono',
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    if (type.startsWith('TRANSPORT')) return const Color(0xFF58A6FF);
    if (type.startsWith('PROJECTION')) return const Color(0xFFD2A8FF);
    if (type.startsWith('MUTATION')) return const Color(0xFFE3B341);
    if (type.startsWith('REPLAY')) return const Color(0xFFF85149);
    if (type.startsWith('REALTIME')) return const Color(0xFF3FB950);
    if (type.startsWith('BUFFER')) return const Color(0xFF484F58);
    return const Color(0xFF8B949E);
  }
}
