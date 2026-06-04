// lib/features/onboarding/data/repositories/onboarding_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/onboarding_status_model.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return OnboardingRepository(dio);
});

class OnboardingRepository {
  final DioClient _dio;

  OnboardingRepository(this._dio);

  Future<OnboardingStatusModel> getOnboardingStatus() async {
    try {
      final response = await _dio.get('/api/v1/admin/onboarding/status');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return OnboardingStatusModel.fromJson(response.data['data']);
      }

      throw Exception(
        'Failed to fetch onboarding status: ${response.data['error']}',
      );
    } catch (e) {
      throw Exception('Network error while fetching onboarding status: $e');
    }
  }

  Future<void> skipOnboarding() async {
    try {
      final response = await _dio.post('/api/v1/admin/onboarding/skip');
      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception('Failed to skip onboarding: ${response.data['error']}');
      }
    } catch (e) {
      throw Exception('Network error while skipping onboarding: $e');
    }
  }

  Future<void> updateRestaurantInfo({
    required String displayName,
    required String city,
    required String state,
    required String fullAddress,
    required String timezone,
  }) async {
    try {
      final response = await _dio.put(
        '/api/v1/admin/onboarding/restaurant-info',
        data: {
          'display_name': displayName,
          'city': city,
          'state': state,
          'full_address': fullAddress,
          'timezone': timezone,
        },
      );

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception(
          response.data['error'] ?? 'Failed to update restaurant info',
        );
      }
    } catch (e) {
      throw Exception('Network error while updating restaurant info: $e');
    }
  }

  Future<void> updateBusinessConfig({
    required String currencyCode,
    String? businessType,
    String? taxRegistrationNumber,
  }) async {
    try {
      final response = await _dio.put(
        '/api/v1/admin/onboarding/business-config',
        data: {
          'currency_code': currencyCode,
          'business_type': ?businessType,
          'tax_registration_number': ?taxRegistrationNumber,
        },
      );

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception(
          response.data['error'] ?? 'Failed to update business config',
        );
      }
    } catch (e) {
      throw Exception('Network error while updating business config: $e');
    }
  }

  Future<void> updateGstLegalConfig({
    String? gstin,
    required String fssaiLicenseNumber,
    required String gstType,
    required double defaultTaxRate,
    double cgstRate = 0,
    double sgstRate = 0,
    double igstRate = 0,
  }) async {
    try {
      final response = await _dio.put(
        '/api/v1/admin/onboarding/gst-legal',
        data: {
          if (gstin != null && gstin.isNotEmpty) 'gstin': gstin,
          'fssai_license_number': fssaiLicenseNumber,
          'gst_type': gstType,
          'default_tax_rate': defaultTaxRate,
          'cgst_rate': cgstRate,
          'sgst_rate': sgstRate,
          'igst_rate': igstRate,
        },
      );

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception(
          response.data['error'] ?? 'Failed to update GST config',
        );
      }
    } catch (e) {
      throw Exception('Network error while updating GST config: $e');
    }
  }

  Future<void> updateTablesAndHours({
    required int numberOfTables,
    required String tablePrefix,
    required String openingTime,
    required String closingTime,
  }) async {
    try {
      final response = await _dio.put(
        '/api/v1/admin/onboarding/tables-hours',
        data: {
          'number_of_tables': numberOfTables,
          'table_prefix': tablePrefix,
          'opening_time': openingTime,
          'closing_time': closingTime,
        },
      );

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception(
          response.data['error'] ?? 'Failed to update tables and hours',
        );
      }
    } catch (e) {
      throw Exception('Network error while updating tables and hours: $e');
    }
  }
}
