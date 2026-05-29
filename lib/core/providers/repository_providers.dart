// ── Repository Providers ──────────────────────────────────────────────────────
// Single source of truth for which implementation is wired.
//
// MOCK MODE (current): All repositories use Mock* implementations.
// No Supabase calls are made anywhere in the app.
//
// PRODUCTION MIGRATION CHECKLIST:
//   1. Set kUseMockRepositories = false
//   2. Implement SupabaseAuthRepository, SupabaseMenuRepository, etc.
//   3. Wire them in the `else` branch below.
//   4. Remove the mock imports.
//   Zero UI code changes needed.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/repositories/auth_repository.dart';
import '../data/repositories/menu_repository.dart';
import '../data/repositories/orders_repository.dart';
import '../data/repositories/staff_repository.dart';
import '../data/repositories/tables_repository.dart';
import '../data/repositories/settings_repository.dart';

import '../data/mock/mock_auth_repository.dart';
import '../data/mock/mock_menu_repository.dart';
import '../data/mock/mock_staff_repository.dart';

import '../data/api/api_staff_repository.dart';


import '../data/api/api_auth_repository.dart';
import '../data/api/api_categories_repository.dart';
import '../data/repositories/categories_repository.dart';
import '../data/api/api_menu_items_repository.dart';
import '../data/repositories/menu_items_repository.dart';
import '../data/api/api_pricing_repository.dart';
import '../data/repositories/pricing_repository.dart';
import '../data/api/api_tax_repository.dart';
import '../data/repositories/tax_repository.dart';
import '../data/api/api_modifier_repository.dart';
import '../data/repositories/modifier_repository.dart';
import '../data/api/api_tables_repository.dart';
import '../data/api/api_availability_repository.dart';
import '../data/repositories/availability_repository.dart';
import '../data/api/api_orders_repository.dart';
import '../data/api/api_settings_repository.dart';
import '../data/api/api_analytics_repository.dart';
import '../data/repositories/analytics_repository.dart';
import '../../features/runtime_monitoring/data/repositories/runtime_observability_repository.dart';
import '../../features/runtime_monitoring/data/api/api_runtime_observability_repository.dart';

import '../data/local/offline_sync_queue.dart';
import '../network/network_providers.dart';

// ── Feature flag ──────────────────────────────────────────────────────────────
// Toggle this to switch between mock and live repositories.
const bool kUseMockRepositories = false;

// ── SharedPreferences Provider ────────────────────────────────────────────────
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main.dart',
  );
});

// ── Offline Sync Queue Provider ───────────────────────────────────────────────
final offlineSyncQueueProvider = Provider<OfflineSyncQueue>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return OfflineSyncQueue(prefs);
});

// ── Supabase Client Provider ──────────────────────────────────────────────────
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// ── Auth Repository Provider ──────────────────────────────────────────────────
// NOTE: In mock mode this is overridden in main.dart with a pre-seeded
// MockAuthRepository instance (session already restored from SharedPreferences).
final Provider<AuthRepository> authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (kUseMockRepositories) return MockAuthRepository();
  final dioClient = ref.watch(dioClientProvider);
  final supabaseClient = ref.watch(supabaseClientProvider);
  return ApiAuthRepository(dioClient, supabaseClient);
});

// ── Menu Repository Provider ──────────────────────────────────────────────────
final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  return MockMenuRepository();
});

// ── Categories Repository Provider ────────────────────────────────────────────
final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ApiCategoriesRepository(dioClient);
});

// ── Menu Items Repository Provider ────────────────────────────────────────────
final menuItemsRepositoryProvider = Provider<MenuItemsRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ApiMenuItemsRepository(dioClient);
});

// ── Pricing Repository Provider ───────────────────────────────────────────────
final pricingRepositoryProvider = Provider<PricingRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ApiPricingRepository(dioClient);
});

// ── Tax Repository Provider ───────────────────────────────────────────────────
final taxRepositoryProvider = Provider<TaxRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ApiTaxRepository(dioClient);
});

// ── Modifier Repository Provider ──────────────────────────────────────────────
final modifierRepositoryProvider = Provider<ModifierRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ApiModifierRepository(dioClient);
});

// ── Tables Repository Provider (Phase 9) ────────────────────────────────────
final tablesRepositoryProvider = Provider<TablesRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ApiTablesRepository(dioClient);
});

// ── Availability Repository Provider (Phase 9) ──────────────────────────────
final availabilityRepositoryProvider = Provider<AvailabilityRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ApiAvailabilityRepository(dioClient);
});

// ── Orders Repository Provider (Phase 10) ───────────────────────────────────
final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ApiOrdersRepository(dioClient);
});

// ── Settings Repository Provider (Phase 11) ─────────────────────────────────
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ApiSettingsRepository(dioClient);
});

// ── Analytics Repository Provider (Phase 11) ────────────────────────────────
// ── Analytics Repository Provider (Phase 11) ────────────────────────────────
final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ApiAnalyticsRepository(dioClient);
});

// ── Runtime Observability Repository Provider ───────────────────────────────
final runtimeObservabilityRepositoryProvider = Provider<RuntimeObservabilityRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final supabaseClient = ref.watch(supabaseClientProvider);
  return ApiRuntimeObservabilityRepository(dioClient, supabaseClient);
});

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  if (kUseMockRepositories) return MockStaffRepository();
  final dioClient = ref.watch(dioClientProvider);
  final supabaseClient = ref.watch(supabaseClientProvider);
  return ApiStaffRepository(dioClient, supabaseClient);
});
