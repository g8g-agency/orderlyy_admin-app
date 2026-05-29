import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/dtos/runtime_snapshot_dto.dart';
import 'runtime_health_provider.dart';

final divergenceAlertsProvider = Provider<List<DivergenceAlertDto>>((ref) {
  final health = ref.watch(runtimeHealthProvider);
  return health.valueOrNull?.activeAlerts ?? [];
});
