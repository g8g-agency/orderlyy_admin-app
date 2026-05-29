import 'package:flutter/foundation.dart';

/// Represents an immutable pricing entry.
/// Time windows, active status, and effective dates are backend-resolved.
/// We use strict INT minor units (e.g. ₹199.99 -> 19999).
/// NO FLOATING POINT MATH ALLOWED.
class PricingRecordDto {
  final String id;
  final String tenantId;
  final String entityId; // e.g. MenuItem ID, Modifier ID
  final String entityType; // 'menu_item', 'modifier'
  final int priceAmount; // MINOR UNITS ONLY. Never double/float.
  final String currencyCode;

  // Time windows are purely informational for the frontend.
  // Backend dictates overlap and activation logic.
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;

  final bool isActive;
  final int versionNum;
  final DateTime createdAt;

  const PricingRecordDto({
    required this.id,
    required this.tenantId,
    required this.entityId,
    required this.entityType,
    required this.priceAmount,
    this.currencyCode = 'INR',
    this.effectiveFrom,
    this.effectiveTo,
    required this.isActive,
    required this.versionNum,
    required this.createdAt,
  });

  factory PricingRecordDto.fromJson(Map<String, dynamic> json) {
    if (json['price_amount'] is double) {
      debugPrint(
        'WARNING: Received float/double for price_amount. Backend should send minor unit INTs.',
      );
    }

    return PricingRecordDto(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      entityId: json['entity_id'] as String,
      entityType: json['entity_type'] as String,
      priceAmount: (json['price_amount'] as num).toInt(),
      currencyCode: json['currency_code'] as String? ?? 'INR',
      effectiveFrom: json['effective_from'] != null
          ? DateTime.parse(json['effective_from'] as String)
          : null,
      effectiveTo: json['effective_to'] != null
          ? DateTime.parse(json['effective_to'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? false,
      versionNum: json['version_num'] as int? ?? 1,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    // We only send the parameters needed for creating a new append-only pricing record
    'tenant_id': tenantId,
    'entity_id': entityId,
    'entity_type': entityType,
    'price_amount': priceAmount,
    'currency_code': currencyCode,
    'effective_from': effectiveFrom?.toIso8601String(),
    'effective_to': effectiveTo?.toIso8601String(),
  };
}

/// A projection representing the currently active resolved price for an entity.
/// Computed exclusively by the backend.
class ResolvedPriceProjectionDto {
  final String entityId;
  final int activePriceAmount; // MINOR UNITS ONLY.
  final String currencyCode;
  final String pricingRecordId;

  const ResolvedPriceProjectionDto({
    required this.entityId,
    required this.activePriceAmount,
    required this.currencyCode,
    required this.pricingRecordId,
  });

  factory ResolvedPriceProjectionDto.fromJson(Map<String, dynamic> json) {
    return ResolvedPriceProjectionDto(
      entityId: json['entity_id'] as String,
      activePriceAmount: (json['active_price_amount'] as num).toInt(),
      currencyCode: json['currency_code'] as String? ?? 'INR',
      pricingRecordId: json['pricing_record_id'] as String,
    );
  }
}
