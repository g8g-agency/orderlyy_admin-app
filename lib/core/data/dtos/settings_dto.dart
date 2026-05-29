// ── Tenant Settings DTO ────────────────────────────────────────────────────────
// Strictly configuration state. Protected by OCC.

class TenantSettingsDto {
  final String tenantId;
  final String?
  branchId; // Composable hierarchy: null means tenant-level default

  // Operational Config
  final bool notifyNewOrder;
  final bool notifyOrderReady;
  final bool notifyLowStock;
  final bool notifyRevenue;
  final bool printReceipt;
  final bool autoAccept;
  final String confirmationSound;
  final bool qrAutoAssign;

  // Financial Defaults
  final String gstNumber;
  final int defaultTaxBasisPoints; // STRICTLY integer minor units (500 = 5%)

  // OCC & Audit
  final DateTime updatedAt;
  final int versionNum;

  const TenantSettingsDto({
    required this.tenantId,
    this.branchId,
    required this.notifyNewOrder,
    required this.notifyOrderReady,
    required this.notifyLowStock,
    required this.notifyRevenue,
    required this.printReceipt,
    required this.autoAccept,
    required this.confirmationSound,
    required this.qrAutoAssign,
    required this.gstNumber,
    required this.defaultTaxBasisPoints,
    required this.updatedAt,
    required this.versionNum,
  });

  factory TenantSettingsDto.fromJson(Map<String, dynamic> json) =>
      TenantSettingsDto(
        tenantId: json['tenant_id'] as String,
        branchId: json['branch_id'] as String?,
        notifyNewOrder: json['notify_new_order'] as bool? ?? true,
        notifyOrderReady: json['notify_order_ready'] as bool? ?? true,
        notifyLowStock: json['notify_low_stock'] as bool? ?? false,
        notifyRevenue: json['notify_revenue'] as bool? ?? false,
        printReceipt: json['print_receipt'] as bool? ?? true,
        autoAccept: json['auto_accept'] as bool? ?? false,
        confirmationSound: json['confirmation_sound'] as String? ?? 'BEEP_01',
        qrAutoAssign: json['qr_auto_assign'] as bool? ?? true,
        gstNumber: json['gst_number'] as String? ?? '',
        defaultTaxBasisPoints:
            (json['default_tax_basis_points'] as num?)?.toInt() ?? 500,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : DateTime.now().toUtc(),
        versionNum: json['version_num'] as int? ?? 1,
      );

  Map<String, dynamic> toJson() => {
    'tenant_id': tenantId,
    'branch_id': branchId,
    'notify_new_order': notifyNewOrder,
    'notify_order_ready': notifyOrderReady,
    'notify_low_stock': notifyLowStock,
    'notify_revenue': notifyRevenue,
    'print_receipt': printReceipt,
    'auto_accept': autoAccept,
    'confirmation_sound': confirmationSound,
    'qr_auto_assign': qrAutoAssign,
    'gst_number': gstNumber,
    'default_tax_basis_points': defaultTaxBasisPoints,
    'version_num': versionNum, // Critical for OCC updates
  };

  TenantSettingsDto copyWith({
    String? tenantId,
    String? branchId,
    bool? notifyNewOrder,
    bool? notifyOrderReady,
    bool? notifyLowStock,
    bool? notifyRevenue,
    bool? printReceipt,
    bool? autoAccept,
    String? confirmationSound,
    bool? qrAutoAssign,
    String? gstNumber,
    int? defaultTaxBasisPoints,
    DateTime? updatedAt,
    int? versionNum,
  }) {
    return TenantSettingsDto(
      tenantId: tenantId ?? this.tenantId,
      branchId: branchId ?? this.branchId,
      notifyNewOrder: notifyNewOrder ?? this.notifyNewOrder,
      notifyOrderReady: notifyOrderReady ?? this.notifyOrderReady,
      notifyLowStock: notifyLowStock ?? this.notifyLowStock,
      notifyRevenue: notifyRevenue ?? this.notifyRevenue,
      printReceipt: printReceipt ?? this.printReceipt,
      autoAccept: autoAccept ?? this.autoAccept,
      confirmationSound: confirmationSound ?? this.confirmationSound,
      qrAutoAssign: qrAutoAssign ?? this.qrAutoAssign,
      gstNumber: gstNumber ?? this.gstNumber,
      defaultTaxBasisPoints:
          defaultTaxBasisPoints ?? this.defaultTaxBasisPoints,
      updatedAt: updatedAt ?? this.updatedAt,
      versionNum: versionNum ?? this.versionNum,
    );
  }
}
