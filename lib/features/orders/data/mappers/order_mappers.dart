// ── Order Mappers ────────────────────────────────────────────────────────────
// Maps between DTOs (API contracts) and Domain Models (business logic).
// Keeps API changes isolated from domain logic.

import '../../../../core/data/dtos/order_dto.dart' as dto;
import '../../domain/models/order.dart';
import '../../domain/models/order_item.dart';
import '../../domain/models/order_status.dart' as domain;
import '../../domain/models/money.dart';

// ── DTO to Domain ────────────────────────────────────────────────────────────

extension OrderDtoMapper on dto.OrderDto {
  Order toDomain() {
    return Order(
      id: id,
      tenantId: tenantId,
      tableId: tableId,
      tableLabel: tableLabel,
      status: domain.OrderStatus.fromString(status.name),
      items: items.map((dtoItem) => dtoItem.toDomain()).toList(),
      totalAmount: Money(amountInCents: totalAmount),
      createdAt: createdAt,
      updatedAt: updatedAt,
      staffId: staffId,
      staffName: staffName,
      notes: notes,
    );
  }
}

extension OrderItemDtoMapper on dto.OrderItemDto {
  OrderItem toDomain() {
    return OrderItem(
      id: id,
      menuItemId: menuItemId,
      menuItemName: menuItemName,
      quantity: quantity,
      unitPrice: Money(amountInCents: unitPriceAmount),
      notes: notes,
    );
  }
}

// ── Domain to DTO ────────────────────────────────────────────────────────────

extension OrderMapper on Order {
  dto.OrderDto toDto() {
    return dto.OrderDto(
      id: id,
      tenantId: tenantId,
      tableId: tableId,
      tableLabel: tableLabel,
      status: dto.OrderStatus.fromString(status.name),
      items: items.map((item) => item.toDto()).toList(),
      totalAmount: totalAmount.amountInCents,
      createdAt: createdAt,
      updatedAt: updatedAt,
      staffId: staffId,
      staffName: staffName,
      notes: notes,
      versionNum: 1,
    );
  }
}

extension OrderItemMapper on OrderItem {
  dto.OrderItemDto toDto() {
    return dto.OrderItemDto(
      id: id,
      menuItemId: menuItemId,
      menuItemName: menuItemName,
      quantity: quantity,
      unitPriceAmount: unitPrice.amountInCents,
      lineTotalAmount: unitPrice.amountInCents * quantity,
      notes: notes,
    );
  }
}
