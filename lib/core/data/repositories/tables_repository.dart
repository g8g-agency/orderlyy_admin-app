// ── TablesRepository interface ─────────────────────────────────────────────────
// The UI layer ONLY depends on this contract.
// Implementations: MockTablesRepository (dev) | SupabaseTablesRepository (prod)

import '../dtos/table_dto.dart';
import '../../network/api_exception.dart';

abstract class TablesRepository {
  // ── Phase 9: New Backend-Authoritative Methods ──────────────────────────────
  
  /// Fetches a paginated/filtered list of tables from the backend.
  Future<Result<List<RestaurantTableDto>>> getTablesPaginated({
    String? sectionId,
    int page = 1,
    int limit = 200,
    bool includeDeleted = false,
  });

  /// Creates a new table. Backend manages `id`, `version_num`, `deleted_at`.
  Future<Result<RestaurantTableDto>> createTableEntity(RestaurantTableDto table);

  /// Updates a table. Mandatory OCC checking using `version_num`.
  Future<Result<RestaurantTableDto>> updateTableEntity(RestaurantTableDto table);

  /// Soft-deletes a table. Backend updates `deleted_at`.
  Future<Result<void>> deleteTableEntity(String tableId, int currentVersion);


  // ── Legacy Methods (Deprecated) ───────────────────────────────────────────
  
  @Deprecated('Use getTablesPaginated instead')
  Future<List<RestaurantTableDto>> getTables(String tenantId);

  @Deprecated('Use backend filtering via getTablesPaginated instead')
  Future<RestaurantTableDto?> getTableById(String tableId);

  @Deprecated('Use createTableEntity instead')
  Future<RestaurantTableDto> createTable(RestaurantTableDto table);

  @Deprecated('Use updateTableEntity instead')
  Future<RestaurantTableDto> updateTableStatus(
    String tableId,
    TableStatus newStatus, {
    String? activeOrderId,
  });

  @Deprecated('Use deleteTableEntity instead (requires version_num)')
  Future<void> deleteTable(String tableId);

  @Deprecated('Realtime is now managed via TablesNotifier reconciliation hook')
  Stream<List<RestaurantTableDto>> watchTables(String tenantId);
}
