import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orderlli_admin/core/auth/app_context_provider.dart';
import 'package:orderlli_admin/features/tables_infrastructure/data/dtos/table_dto.dart';
import 'package:orderlli_admin/features/tables_infrastructure/data/repositories/table_infrastructure_repository.dart';

final tablesFutureProvider = AsyncNotifierProvider<TablesNotifier, List<TableDto>>(() {
  return TablesNotifier();
});

class TablesNotifier extends AsyncNotifier<List<TableDto>> {
  @override
  Future<List<TableDto>> build() async {
    final ctx = ref.watch(appContextProvider);
    if (ctx == null) return [];
    
    // For now we assume a default branch from the first branch linked, but let's hardcode 'branch_1' fallback if context doesn't have it.
    // Assuming context has a branch or we just fetch from API.
    // The backend uses JWT to scope tenant.
    final repo = ref.watch(tableInfrastructureRepositoryProvider);
    // Actually the UI currently hardcodes branch_1
    return repo.getTables(ctx.tenant.id, 'branch_1');
  }

  Future<void> addTable(String tableNumber, int capacity) async {
    final ctx = ref.read(appContextProvider);
    if (ctx == null) return;
    final repo = ref.read(tableInfrastructureRepositoryProvider);

    final dto = TableDto(
      id: '', // Empty, backend generates it
      tenantId: ctx.tenant.id,
      branchId: 'branch_1',
      tableNumber: tableNumber,
      capacity: capacity,
      isActive: true,
    );

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repo.createTable(dto);
      return repo.getTables(ctx.tenant.id, 'branch_1');
    });
  }

  Future<void> deleteTable(String tableId) async {
    final ctx = ref.read(appContextProvider);
    if (ctx == null) return;
    final repo = ref.read(tableInfrastructureRepositoryProvider);

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repo.deleteTable(tableId);
      return repo.getTables(ctx.tenant.id, 'branch_1');
    });
  }
}
