import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/app_context_provider.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/network/dio_client.dart';
import '../dtos/tax_dto.dart';
import 'dart:developer' as dev;

final taxRepositoryProvider = Provider<TaxRepository>((ref) {
  final appCtx = ref.watch(appContextProvider);
  return TaxRepository(
    ref.watch(dioClientProvider),
    appCtx?.tenant.id,
  );
});

class TaxRepository {
  final DioClient _dio;
  final String? _tenantId;

  TaxRepository(this._dio, this._tenantId);

  Future<List<TaxProfileDto>> getTaxProfiles() async {
    if (_tenantId == null) return [];

    try {
      dev.log('[TaxRepo] Fetching tax profiles for tenant: $_tenantId');

      final response = await _dio.get('/api/v1/tenants/$_tenantId/tax/profiles');
      
      final data = response.data['data'] ?? response.data; // Handle unwrapped or wrapped format
      final List<dynamic> profilesList = data is List ? data : [];

      return profilesList.map((p) {
        final profile = TaxProfileDto.fromJson(p as Map<String, dynamic>);
        final rates = p['tax_rates'] as List<dynamic>? ?? [];
        final activeRates = rates.where((r) => r['is_active'] == true).toList();
        final effectiveBp = activeRates.fold<int>(
          0,
          (sum, r) => sum + (r['rate_basis_points'] as int),
        );
        return profile.copyWith(effectiveBasisPoints: effectiveBp);
      }).toList();
    } catch (e, st) {
      dev.log(
        '[TaxRepo] Error fetching tax profiles',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  Future<void> createTaxProfile({
    required String name,
    required String calculationMode,
    required int rateBasisPoints,
    String? description,
  }) async {
    if (_tenantId == null) throw Exception('No tenant context');

    try {
      dev.log('[TaxRepo] Creating tax profile: $name');

      // 1. Create Profile
      final profileRes = await _dio.post('/api/v1/tenants/$_tenantId/tax/profiles', data: {
        'name': name,
        'description': description,
        'calculation_mode': calculationMode,
        'is_active': true,
      });

      final newProfileId = profileRes.data['id'] ?? profileRes.data['data']?['id'];

      if (newProfileId == null) {
        throw Exception('Failed to get profile ID from response: ${profileRes.data}');
      }

      // 2. Create corresponding Rate
      await _dio.post('/api/v1/tenants/$_tenantId/tax/rates', data: {
        'tax_profile_id': newProfileId,
        'name': '$name Rate',
        'rate_basis_points': rateBasisPoints,
        'is_active': true,
      });
    } catch (e, st) {
      dev.log('[TaxRepo] Error creating tax profile', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> updateTaxProfile({
    required String id,
    required String name,
    required String calculationMode,
    required int newRateBasisPoints,
    required int currentRateBasisPoints,
    String? description,
  }) async {
    if (_tenantId == null) throw Exception('No tenant context');

    try {
      // 1. Fetch current profile to get version_num
      final getRes = await _dio.get('/api/v1/tenants/$_tenantId/tax/profiles/$id');
      final versionNum = getRes.data['version_num'] ?? getRes.data['data']?['version_num'];

      // 2. Update profile name/calc mode
      await _dio.put('/api/v1/tenants/$_tenantId/tax/profiles/$id', data: {
        'name': name,
        'description': description,
        'calculation_mode': calculationMode,
        'version_num': versionNum,
      });

      // 3. If rate changed, append new rate
      if (newRateBasisPoints != currentRateBasisPoints) {
        final listRes = await _dio.get('/api/v1/tenants/$_tenantId/tax/profiles');
        final data = listRes.data['data'] ?? listRes.data;
        final List<dynamic> profilesList = data is List ? data : [];
        final thisProfile = profilesList.firstWhere((p) => p['id'] == id, orElse: () => null);
        
        if (thisProfile != null) {
          final activeRates = (thisProfile['tax_rates'] as List<dynamic>? ?? [])
              .where((r) => r['is_active'] == true).toList();
          
          for (var rate in activeRates) {
            await _dio.delete('/api/v1/tenants/$_tenantId/tax/rates/${rate['id']}?version_num=${rate['version_num']}');
          }
        }

        // Append new rate
        await _dio.post('/api/v1/tenants/$_tenantId/tax/rates', data: {
          'tax_profile_id': id,
          'name': '$name Rate',
          'rate_basis_points': newRateBasisPoints,
          'is_active': true,
        });
      }
    } catch (e, st) {
      dev.log('[TaxRepo] Error updating tax profile', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> toggleTaxProfile(String id, bool isActive) async {
    if (_tenantId == null) throw Exception('No tenant context');

    try {
      final getRes = await _dio.get('/api/v1/tenants/$_tenantId/tax/profiles/$id');
      final versionNum = getRes.data['version_num'] ?? getRes.data['data']?['version_num'];

      await _dio.put('/api/v1/tenants/$_tenantId/tax/profiles/$id', data: {
        'is_active': isActive,
        'version_num': versionNum,
      });
    } catch (e, st) {
      dev.log('[TaxRepo] Error toggling tax profile', error: e, stackTrace: st);
      rethrow;
    }
  }
}
