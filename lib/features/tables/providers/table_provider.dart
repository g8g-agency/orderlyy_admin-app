import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/restaurant_context_provider.dart';
import '../../../core/providers/repository_providers.dart';
import '../repositories/table_repository.dart';
import '../models/table_model.dart';

final tableRepoProvider = Provider((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final branchId = ref.watch(activeBranchProvider)?.id;
  return TableRepository(supabase, branchId);
});

final tablesProvider =
    AsyncNotifierProvider<TablesNotifier, List<RestaurantTable>>(
  TablesNotifier.new,
);

class TablesNotifier extends AsyncNotifier<List<RestaurantTable>> {
  late TableRepository _repo;

  @override
  Future<List<RestaurantTable>> build() async {
    _repo = ref.watch(tableRepoProvider);
    return _repo.fetchTables();
  }

  Future<RestaurantTable> addTable(String number, String? name) async {
    final created = await _repo.addTable(number, name);
    state = AsyncData([...state.value ?? [], created]);
    return created;
  }

  Future<void> removeTable(String tableId) async {
    await _repo.removeTable(tableId);
    state = AsyncData(
      (state.value ?? []).where((t) => t.id != tableId).toList(),
    );
  }
}
