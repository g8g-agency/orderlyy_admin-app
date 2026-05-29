// ── OrdersRepository interface ─────────────────────────────────────────────────
// The UI layer ONLY depends on this contract.
// Implementations: MockOrdersRepository (dev) | SupabaseOrdersRepository (prod)

import '../dtos/order_dto.dart';
import '../../network/api_exception.dart';

abstract class OrdersRepository {
  // ── Phase 10: Strict State Machine & Projection Retrieval ─────────────────

  /// Fetches paginated, backend-resolved order projections.
  Future<Result<List<OrderDto>>> getOrdersPaginated({
    OrderStatus? status,
    String? tableId,
    int page = 1,
    int limit = 100,
  });

  /// Creates a new order safely. Requires an idempotency key to survive offline retries.
  /// Backend calculates all totals, taxes, discounts.
  Future<Result<OrderDto>> createOrderEntity(
    OrderDto order, {
    required String idempotencyKey,
  });

  /// Safely transitions an order state. Backend validates the state machine transition.
  Future<Result<OrderDto>> transitionOrderStatus(
    String orderId,
    OrderStatus newStatus,
    int currentVersion, {
    required String idempotencyKey,
  });

  /// Safely updates line items. Backend recalculates all pricing and taxes on success.
  Future<Result<OrderDto>> updateOrderLineItems(
    String orderId,
    List<OrderItemDto> items,
    int currentVersion, {
    required String idempotencyKey,
  });

  // ── Legacy Methods (Deprecated) ───────────────────────────────────────────

  @Deprecated('Use getOrdersPaginated instead')
  Future<List<OrderDto>> getOrders(
    String tenantId, {
    OrderStatus? status,
    String? tableId,
    DateTime? from,
    DateTime? to,
  });

  @Deprecated('Fetch from normalized state instead')
  Future<OrderDto?> getOrderById(String orderId);

  @Deprecated('Use createOrderEntity with idempotencyKey instead')
  Future<OrderDto> createOrder(OrderDto order);

  @Deprecated('Use transitionOrderStatus with idempotencyKey instead')
  Future<OrderDto> updateOrderStatus(String orderId, OrderStatus newStatus);

  @Deprecated('Use updateOrderLineItems with idempotencyKey instead')
  Future<OrderDto> updateOrder(OrderDto order);

  @Deprecated('Use transitionOrderStatus to cancelled instead')
  Future<void> cancelOrder(String orderId);

  @Deprecated(
    'Realtime is now managed via OrdersNotifier sequence reconciliation',
  )
  Stream<List<OrderDto>> watchOrders(String tenantId);

  @Deprecated('Migrate to Phase 11 Analytics API')
  Future<Map<String, dynamic>> getDailySummary(String tenantId, DateTime date);
}
