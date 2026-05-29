import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/auth/app_auth_provider.dart';
import '../dtos/tax_dto.dart';
import 'dart:developer' as dev;

final taxRepositoryProvider = Provider<TaxRepository>((ref) {
  return TaxRepository(
    Supabase.instance.client,
    ref
        .read(authNotifierProvider)
        .userId, // Using userId as tenantId for single-tenant mode
  );
});

class TaxRepository {
  final SupabaseClient _supabase;
  final String? _tenantId;

  TaxRepository(this._supabase, this._tenantId);

  Future<List<TaxProfileDto>> getTaxProfiles() async {
    if (_tenantId == null) return [];

    try {
      dev.log('[TaxRepo] Fetching tax profiles for tenant: $_tenantId');

      // Fetch profiles
      final profileRes = await _supabase
          .from('tax_profiles')
          .select()
          .eq('tenant_id', _tenantId)
          .isFilter('deleted_at', null)
          .order('priority', ascending: false);

      List<TaxProfileDto> profiles = profileRes
          .map((p) => TaxProfileDto.fromJson(p))
          .toList();

      if (profiles.isEmpty) return [];

      // Fetch active rates for these profiles
      final profileIds = profiles.map((p) => p.id).toList();
      final ratesRes = await _supabase
          .from('tax_rates')
          .select()
          .eq('tenant_id', _tenantId)
          .inFilter('tax_profile_id', profileIds)
          .eq('is_active', true)
          .isFilter('deleted_at', null);

      final rates = ratesRes.map((r) => TaxRateDto.fromJson(r)).toList();

      // Merge active rate into profile dto for UI display
      return profiles.map((p) {
        final activeRates = rates.where((r) => r.taxProfileId == p.id).toList();
        final effectiveBp = activeRates.fold<int>(
          0,
          (sum, rate) => sum + rate.rateBasisPoints,
        );
        return p.copyWith(effectiveBasisPoints: effectiveBp);
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
      final profileData = {
        'tenant_id': _tenantId,
        'name': name,
        'description': description,
        'calculation_mode': calculationMode,
        'is_active': true,
      };

      final insertedProfile = await _supabase
          .from('tax_profiles')
          .insert(profileData)
          .select()
          .single();

      final newProfileId = insertedProfile['id'] as String;

      // 2. Create corresponding Rate
      final rateData = {
        'tenant_id': _tenantId,
        'tax_profile_id': newProfileId,
        'name': '$name Rate',
        'rate_basis_points': rateBasisPoints,
        'is_active': true,
      };

      await _supabase.from('tax_rates').insert(rateData);
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
      // 1. Update profile name/calc mode
      await _supabase
          .from('tax_profiles')
          .update({
            'name': name,
            'description': description,
            'calculation_mode': calculationMode,
          })
          .eq('id', id)
          .eq('tenant_id', _tenantId);

      // 2. If rate changed, deactivate old rate and append new rate
      if (newRateBasisPoints != currentRateBasisPoints) {
        // Deactivate existing
        await _supabase
            .from('tax_rates')
            .update({'is_active': false})
            .eq('tax_profile_id', id)
            .eq('tenant_id', _tenantId)
            .eq('is_active', true);

        // Append new
        await _supabase.from('tax_rates').insert({
          'tenant_id': _tenantId,
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

    await _supabase
        .from('tax_profiles')
        .update({'is_active': isActive})
        .eq('id', id)
        .eq('tenant_id', _tenantId);
  }
}

