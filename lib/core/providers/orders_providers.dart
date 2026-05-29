import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/dtos/order_dto.dart';
import '../data/repositories/orders_repository.dart';
import '../network/api_exception.dart';
import 'repository_providers.dart';
import '../data/local/offline_sync_queue.dart';

// ── Orders State ──────────────────────────────────────────────────────────────
class OrdersState {
  final bool isLoading;
  final String? error;

  // Normalized map of active/historical orders by ID
  final Map<String, OrderDto> ordersById;

  const OrdersState({
    this.isLoading = false,
    this.error,
    this.ordersById = const {},
  });

  OrdersState copyWith({
    bool? isLoading,
    String? error,
    Map<String, OrderDto>? ordersById,
  }) {
    return OrdersState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      ordersById: ordersById ?? this.ordersById,
    );
  }
}

// ── Orders Notifier ───────────────────────────────────────────────────────────
class OrdersNotifier extends StateNotifier<OrdersState> {
  final OrdersRepository _repository;
  final _uuid = const Uuid();

  OrdersNotifier(this._repository) : super(const OrdersState());

  /// Fetches backend-resolved order projections.
  Future<void> loadOrders({
    OrderStatus? status,
    String? tableId,
    bool forceRefresh = false,
  }) async {
    if (state.isLoading) return;
    if (state.ordersById.isNotEmpty &&
        !forceRefresh &&
        status == null &&
        tableId == null) {
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getOrdersPaginated(
      status: status,
      tableId: tableId,
    );

    if (result is Success<List<OrderDto>>) {
      final newOrders = forceRefresh
          ? <String, OrderDto>{}
          : Map<String, OrderDto>.from(state.ordersById);
      for (final order in result.value) {
        newOrders[order.id] = order;
      }
      state = state.copyWith(isLoading: false, ordersById: newOrders);
    } else if (result is Failure<List<OrderDto>>) {
      state = state.copyWith(isLoading: false, error: result.error.message);
    }
  }

  /// Creates a new order using an idempotency key to prevent double-billing on reconnects.
  Future<Result<OrderDto>> createOrder(OrderDto order) async {
    final idempotencyKey = _uuid.v4(); // Generate unique key for this intent

    final result = await _repository.createOrderEntity(
      order,
      idempotencyKey: idempotencyKey,
    );

    if (result is Success<OrderDto>) {
      final newOrders = Map<String, OrderDto>.from(state.ordersById);
      newOrders[result.value.id] = result.value;
      state = state.copyWith(ordersById: newOrders);
    }

    return result;
  }

  /// Safely advances the order state machine.
  Future<Result<OrderDto>> transitionOrderStatus(
    String orderId,
    OrderStatus newStatus,
  ) async {
    final order = state.ordersById[orderId];
    if (order == null) return Failure(ApiFailure('Order not found locally'));

    final idempotencyKey = _uuid.v4();

    final result = await _repository.transitionOrderStatus(
      orderId,
      newStatus,
      order.versionNum,
      idempotencyKey: idempotencyKey,
    );

    if (result is Success<OrderDto>) {
      final newOrders = Map<String, OrderDto>.from(state.ordersById);
      newOrders[result.value.id] = result.value;
      state = state.copyWith(ordersById: newOrders);
    } else if (result is Failure<OrderDto>) {
      if (result.error.code == ApiErrorCode.conflict) {
        // Deterministic reload on OCC Conflict (another surface mutated it)
        await loadOrders(forceRefresh: true);
      }
    }

    return result;
  }

  /// Updates items, delegating all financial computation to the backend.
  Future<Result<OrderDto>> updateOrderItems(
    String orderId,
    List<OrderItemDto> items,
  ) async {
    final order = state.ordersById[orderId];
    if (order == null) return Failure(ApiFailure('Order not found locally'));

    final idempotencyKey = _uuid.v4();

    final result = await _repository.updateOrderLineItems(
      orderId,
      items,
      order.versionNum,
      idempotencyKey: idempotencyKey,
    );

    if (result is Success<OrderDto>) {
      final newOrders = Map<String, OrderDto>.from(state.ordersById);
      newOrders[result.value.id] = result.value;
      state = state.copyWith(ordersById: newOrders);
    } else if (result is Failure<OrderDto>) {
      if (result.error.code == ApiErrorCode.conflict) {
        await loadOrders(forceRefresh: true);
      }
    }

    return result;
  }

  /// Sequence-aware realtime hook.
  /// Overwrites local state ONLY if the remote version is strictly newer.
  void reconcileRemoteUpdate(OrderDto remoteOrder) {
    final current = state.ordersById[remoteOrder.id];

    // Sequence validation: Reject stale events
    if (current != null && remoteOrder.versionNum <= current.versionNum) {
      return;
    }

    final newOrders = Map<String, OrderDto>.from(state.ordersById);
    newOrders[remoteOrder.id] = remoteOrder;
    state = state.copyWith(ordersById: newOrders);
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────
final ordersProvider = StateNotifierProvider<OrdersNotifier, OrdersState>((
  ref,
) {
  final repo = ref.watch(ordersRepositoryProvider);
  return OrdersNotifier(repo);
});

final activeTableOrdersProvider = Provider.family<List<OrderDto>, String>((
  ref,
  tableId,
) {
  final state = ref.watch(ordersProvider);
  return state.ordersById.values
      .where(
        (o) =>
            o.tableId == tableId &&
            o.status != OrderStatus.cancelled &&
            o.status != OrderStatus.served,
      )
      .toList();
});

// ── Offline UI Compatibility (Deprecated for direct mutations, kept for dev toggle)
final isOnlineProvider = StateNotifierProvider<IsOnlineNotifier, bool>((ref) {
  final queue = ref.watch(offlineSyncQueueProvider);
  return IsOnlineNotifier(queue);
});

class IsOnlineNotifier extends StateNotifier<bool> {
  final OfflineSyncQueue _queue;

  IsOnlineNotifier(this._queue) : super(_queue.isOnline());

  Future<void> toggleOnline() async {
    final newStatus = !state;
    await _queue.setOnlineStatus(newStatus);
    state = newStatus;
  }
}

final pendingActionsCountProvider = StreamProvider<int>((ref) {
  final queue = ref.watch(offlineSyncQueueProvider);
  return queue.watchCount();
});
