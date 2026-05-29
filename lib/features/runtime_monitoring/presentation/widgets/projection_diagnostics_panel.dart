import 'package:flutter/material.dart';
import '../../data/dtos/runtime_snapshot_dto.dart';

class ProjectionDiagnosticsPanel extends StatelessWidget {
  final RuntimeSnapshotDto snapshot;

  const ProjectionDiagnosticsPanel({super.key, required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final domains = ['orders', 'tables', 'kds', 'analytics', 'system'];

    return Card(
      color: const Color(0xFF161B22),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFF30363D)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text(
              'DOMAIN WATERMARKS & PROJECTION STATE',
              style: TextStyle(
                color: Color(0xFF8B949E),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFF30363D)),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingTextStyle: const TextStyle(
                color: Color(0xFF484F58),
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
              dataTextStyle: const TextStyle(
                color: Color(0xFFE6EDF3),
                fontFamily: 'RobotoMono',
                fontSize: 11,
              ),
              columns: const [
                DataColumn(label: Text('DOMAIN')),
                DataColumn(label: Text('WATERMARK')),
                DataColumn(label: Text('REBUILDS')),
                DataColumn(label: Text('CANCELLED')),
                DataColumn(label: Text('STALE')),
                DataColumn(label: Text('GAPS')),
                DataColumn(label: Text('AVG REBUILD')),
              ],
              rows: domains.map((domainName) {
                final d = snapshot.domains[domainName];
                final hasGap = (d?.gapCount ?? 0) > 0;

                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        domainName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${d?.watermark ?? 0}',
                        style: TextStyle(
                          color: (d?.watermark ?? 0) > 0
                              ? const Color(0xFF3FB950)
                              : const Color(0xFF484F58),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${d?.rebuildCount ?? 0}',
                        style: TextStyle(
                          color: (d?.rebuildCount ?? 0) > 0
                              ? const Color(0xFFE6EDF3)
                              : const Color(0xFF484F58),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${d?.cancelledCount ?? 0}',
                        style: TextStyle(
                          color: (d?.cancelledCount ?? 0) > 0
                              ? const Color(0xFFE3B341)
                              : const Color(0xFF484F58),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${d?.staleCount ?? 0}',
                        style: TextStyle(
                          color: (d?.staleCount ?? 0) > 0
                              ? const Color(0xFFE3B341)
                              : const Color(0xFF484F58),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${d?.gapCount ?? 0}',
                        style: TextStyle(
                          color: hasGap
                              ? const Color(0xFFF85149)
                              : const Color(0xFF484F58),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        (d?.avgDurationMs ?? 0) > 0
                            ? '${d!.avgDurationMs.toStringAsFixed(1)}ms'
                            : '—',
                        style: TextStyle(
                          color: (d?.avgDurationMs ?? 0) > 0
                              ? const Color(0xFF58A6FF)
                              : const Color(0xFF484F58),
                        ),
                      ),
                    ),
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
