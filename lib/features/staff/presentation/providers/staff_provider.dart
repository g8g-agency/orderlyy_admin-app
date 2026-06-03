import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/app_auth_provider.dart';
import '../../../../core/data/dtos/staff_dto.dart';
import '../../../../core/providers/repository_providers.dart';

final staffNotifierProvider =
    AsyncNotifierProvider<StaffNotifier, List<StaffDto>>(StaffNotifier.new);

class StaffNotifier extends AsyncNotifier<List<StaffDto>> {
  String? get _tenantId => ref.read(appContextProvider)?.tenant.id;

  @override
  Future<List<StaffDto>> build() async {
    return _fetchStaff();
  }

  Future<List<StaffDto>> _fetchStaff() async {
    if (_tenantId == null) return [];
    final repo = ref.read(staffRepositoryProvider);
    return repo.getStaff(_tenantId!);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetchStaff);
  }

  Future<void> addStaff(StaffDto staff) async {
    final tenantId = _tenantId;
    if (tenantId == null) throw Exception('No tenant context');

    state = const AsyncValue.loading();
    try {
      final repo = ref.read(staffRepositoryProvider);
      final newStaff = staff.copyWith(tenantId: tenantId);
      await repo.createStaff(newStaff);
      await refresh();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateStaff(StaffDto staff) async {
    final tenantId = _tenantId;
    if (tenantId == null) throw Exception('No tenant context');

    state = const AsyncValue.loading();
    try {
      final repo = ref.read(staffRepositoryProvider);
      await repo.updateStaff(staff);
      await refresh();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteStaff(String staffId) async {
    final tenantId = _tenantId;
    if (tenantId == null) throw Exception('No tenant context');

    state = const AsyncValue.loading();
    try {
      final repo = ref.read(staffRepositoryProvider);
      await repo.deleteStaff(tenantId, staffId);
      await refresh();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
