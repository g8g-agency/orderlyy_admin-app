class RuntimeDomainHealth {
  final int watermark;
  final int rebuildCount;
  final int cancelledCount;
  final int staleCount;
  final int gapCount;
  final double avgDurationMs;

  RuntimeDomainHealth({
    required this.watermark,
    required this.rebuildCount,
    required this.cancelledCount,
    required this.staleCount,
    required this.gapCount,
    required this.avgDurationMs,
  });

  factory RuntimeDomainHealth.fromJson(Map<String, dynamic> json) {
    return RuntimeDomainHealth(
      watermark: json['watermark'] as int? ?? 0,
      rebuildCount: json['rebuildCount'] as int? ?? 0,
      cancelledCount: json['cancelledCount'] as int? ?? 0,
      staleCount: json['staleCount'] as int? ?? 0,
      gapCount: json['gapCount'] as int? ?? 0,
      avgDurationMs: (json['avgDurationMs'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
