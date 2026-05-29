import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/convergence_comparison_provider.dart';

class CrossSurfaceConvergencePanel extends ConsumerWidget {
  const CrossSurfaceConvergencePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final convergence = ref.watch(convergenceComparisonProvider);

    if (convergence == null || convergence.surfaces.isEmpty) {
      return const SizedBox.shrink();
    }

    final surfaces = convergence.surfaces.values.toList();
    // Sort so ADMIN is first, then POS, KDS, etc.
    surfaces.sort((a, b) => a.surface.compareTo(b.surface));

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
              const Icon(Icons.devices, color: Color(0xFF8B949E), size: 16),
              const SizedBox(width: 8),
              const Text(
                'CROSS-SURFACE CONVERGENCE',
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
                  color: const Color(0xFF3FB950).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${surfaces.length} SURFACES',
                  style: const TextStyle(
                    color: Color(0xFF3FB950),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 30,
              dataRowMinHeight: 40,
              dataRowMaxHeight: 40,
              columns: const [
                DataColumn(label: _HeaderCell('SURFACE')),
                DataColumn(label: _HeaderCell('WATERMARK')),
                DataColumn(label: _HeaderCell('SYNC')),
                DataColumn(label: _HeaderCell('LAG')),
                DataColumn(label: _HeaderCell('RECONNECTS')),
              ],
              rows: surfaces.map((s) {
                return DataRow(
                  cells: [
                    DataCell(Text(
                      s.surface,
                      style: const TextStyle(color: Color(0xFFE6EDF3), fontWeight: FontWeight.bold),
                    )),
                    DataCell(Text(
                      '${s.watermark}',
                      style: const TextStyle(color: Color(0xFF8B949E), fontFamily: 'RobotoMono'),
                    )),
                    DataCell(Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          s.isStale ? Icons.warning_amber_rounded : Icons.check_circle,
                          color: s.isStale ? const Color(0xFFFFA657) : const Color(0xFF3FB950),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          s.isStale ? 'STALE' : 'SYNCED',
                          style: TextStyle(
                            color: s.isStale ? const Color(0xFFFFA657) : const Color(0xFF3FB950),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    )),
                    DataCell(Text(
                      '${s.lag}ms',
                      style: TextStyle(
                        color: s.lag > 1000 ? const Color(0xFFF85149) : const Color(0xFF8B949E),
                        fontFamily: 'RobotoMono',
                      ),
                    )),
                    DataCell(Text(
                      '${s.reconnectAttempts}',
                      style: TextStyle(
                        color: s.reconnectAttempts > 0 ? const Color(0xFFFFA657) : const Color(0xFF8B949E),
                        fontFamily: 'RobotoMono',
                      ),
                    )),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF8B949E),
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
    );
  }
}
