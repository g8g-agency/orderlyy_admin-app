import 'package:flutter/foundation.dart';

/// Represents an operational tax profile.
/// Tax percentages MUST be in basis points (e.g. 5% = 500, 18% = 1800).
/// NO FLOATING POINT OR DECIMAL MATH ALLOWED.
class TaxProfileDto {
  final String id;
  final String tenantId;
  final String name; // e.g. "GST 5%", "State Tax"
  final String? description;
  final int basisPoints; // e.g. 500 for 5.00%

  final bool isActive;
  final int versionNum;
  final DateTime? deletedAt; // Soft delete tracking

  const TaxProfileDto({
    required this.id,
    required this.tenantId,
    required this.name,
    this.description,
    required this.basisPoints,
    required this.isActive,
    required this.versionNum,
    this.deletedAt,
  });

  factory TaxProfileDto.fromJson(Map<String, dynamic> json) {
    if (json['basis_points'] is double || json['percentage'] is double) {
      debugPrint(
        'WARNING: Received float/double for tax percentage. Backend must send basis point INTs.',
      );
    }

    return TaxProfileDto(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      basisPoints: (json['basis_points'] as num).toInt(),
      isActive: json['is_active'] as bool? ?? false,
      versionNum: json['version_num'] as int? ?? 1,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'tenant_id': tenantId,
    'name': name,
    'description': description,
    'basis_points': basisPoints,
    'is_active': isActive,
    'version_num': versionNum, // sent for OCC
  };
}

/// A projection representing resolved taxes for an entity.
/// Computed exclusively by the backend tax engine.
class ResolvedTaxProjectionDto {
  final String entityId;
  final List<String> appliedTaxProfileIds;
  final int totalTaxBasisPoints;

  const ResolvedTaxProjectionDto({
    required this.entityId,
    required this.appliedTaxProfileIds,
    required this.totalTaxBasisPoints,
  });

  factory ResolvedTaxProjectionDto.fromJson(Map<String, dynamic> json) {
    return ResolvedTaxProjectionDto(
      entityId: json['entity_id'] as String,
      appliedTaxProfileIds: List<String>.from(
        json['applied_tax_profile_ids'] as List? ?? [],
      ),
      totalTaxBasisPoints:
          (json['total_tax_basis_points'] as num?)?.toInt() ?? 0,
    );
  }
}
