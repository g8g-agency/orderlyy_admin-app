import '../../domain/models/order.dart' as domain;
import '../../domain/models/order_item.dart' as domain_item;
import '../../domain/models/order_status.dart' as domain_status;
import '../../domain/models/money.dart';
import '../../../../core/data/dtos/order_dto.dart' as dto;

class OrderMapper {
  const OrderMapper._();

  static domain.Order toDomain(dto.OrderDto d, {String? tableLabel, String? staffName}) => domain.Order(
    id: d.id,
    tenantId: d.tenantId,
    tableId: d.tableId,
    tableLabel: tableLabel ?? d.tableLabel,
    status: _mapStatus(d.status),
    items: d.items.map(_mapItem).toList(),
    totalAmount: Money(amountInCents: d.totalAmount),
    createdAt: d.createdAt,
    updatedAt: d.updatedAt,
    staffId: d.staffId,
    staffName: staffName ?? d.staffName,
    notes: d.notes,
  );

  static domain_status.OrderStatus _mapStatus(dto.OrderStatus s) =>
    domain_status.OrderStatus.values.firstWhere(
      (e) => e.name == s.name,
      orElse: () => domain_status.OrderStatus.pending,
    );

  static domain_item.OrderItem _mapItem(dto.OrderItemDto i) =>
    domain_item.OrderItem(
      id: i.id,
      menuItemId: i.menuItemId,
      menuItemName: i.menuItemName,
      quantity: i.quantity,
      unitPrice: Money(amountInCents: i.unitPriceAmount),
      notes: i.notes,
    );
}
