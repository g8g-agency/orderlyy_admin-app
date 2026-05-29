import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/auth/mock_auth_provider.dart';
import '../dtos/kitchen_station_dto.dart';
import 'dart:developer' as dev;

final kdsRepositoryProvider = Provider<KdsRepository>((ref) {
  return KdsRepository(
    Supabase.instance.client,
    ref.read(authNotifierProvider).userId,
  );
});

final kitchenStationsProvider =
    FutureProvider.autoDispose<List<KitchenStationDto>>((ref) async {
      final repo = ref.watch(kdsRepositoryProvider);
      return repo.getStations();
    });

class KdsRepository {
  final SupabaseClient _supabase;
  final String? _tenantId;

  KdsRepository(this._supabase, this._tenantId);

  Future<List<KitchenStationDto>> getStations() async {
    if (_tenantId == null) return [];

    try {
      // Assuming single branch for now, or fetch all active for tenant
      final res = await _supabase
          .from('kitchen_stations')
          .select()
          .eq('tenant_id', _tenantId)
          .isFilter('deleted_at', null)
          .order('display_order', ascending: true);

      return res.map((json) => KitchenStationDto.fromJson(json)).toList();
    } catch (e, st) {
      dev.log('[KdsRepo] Error fetching stations', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> createStation({
    required String name,
    required String branchId,
    String? description,
    bool isDefault = false,
  }) async {
    if (_tenantId == null) throw Exception('No tenant context');

    try {
      await _supabase.from('kitchen_stations').insert({
        'tenant_id': _tenantId,
        'branch_id': branchId,
        'name': name,
        'description': description,
        'is_default': isDefault,
        'is_active': true,
      });
    } catch (e, st) {
      dev.log('[KdsRepo] Error creating station', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> updateStation(
    String id, {
    required String name,
    String? description,
    bool? isDefault,
  }) async {
    if (_tenantId == null) throw Exception('No tenant context');

    final data = <String, dynamic>{
      'name': name,
      'description': ?description,
      'is_default': ?isDefault,
    };

    await _supabase
        .from('kitchen_stations')
        .update(data)
        .eq('id', id)
        .eq('tenant_id', _tenantId);
  }

  Future<void> toggleStation(String id, bool isActive) async {
    if (_tenantId == null) throw Exception('No tenant context');

    await _supabase
        .from('kitchen_stations')
        .update({'is_active': isActive})
        .eq('id', id)
        .eq('tenant_id', _tenantId);
  }

  Future<void> deleteStation(String id) async {
    if (_tenantId == null) throw Exception('No tenant context');

    await _supabase
        .from('kitchen_stations')
        .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id)
        .eq('tenant_id', _tenantId);
  }
}
