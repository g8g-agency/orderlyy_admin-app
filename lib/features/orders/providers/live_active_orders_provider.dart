import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/providers/branch_context_service.dart';
import '../../../core/providers/tables_provider.dart';
import '../../../core/providers/staff_providers.dart';
import '../data/mappers/order_mapper.dart';
import '../domain/models/order.dart';

/// Realtime stream of active (non-terminal) orders for the selected branch.
/// Backed by Supabase postgres_changes — same pattern as KDS.
final liveActiveOrdersProvider = StreamProvider.autoDispose<List<Order>>((ref) {
  final activeBranch = ref.watch(currentBranchProvider).value;
  if (activeBranch == null) return const Stream.empty();

  final tablesState = ref.watch(tablesProvider);
  final staffList = ref.watch(staffStreamProvider).value ?? [];

  return ref
    .watch(ordersRepositoryProvider)
    .watchOrders(activeBranch.id)
    .map((dtos) => dtos
      .map((d) {
        final matches = staffList.where((s) => s.id == d.staffId);
        final staffName = matches.isNotEmpty ? matches.first.name : null;
        return OrderMapper.toDomain(d, 
          tableLabel: tablesState.tablesById[d.tableId]?.label,
          staffName: staffName,
        );
      })
      .where((o) => o.isActive)       // mirrors existing watchActiveOrders filter
      .toList()
    );
});
