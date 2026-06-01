import 'package:equatable/equatable.dart';

enum BranchStatus { active, inactive, deleted }

class BranchEntity extends Equatable {
  final String id;
  final String tenantId;
  final String name;
  final String timezone;
  final BranchStatus status;
  final String? address;
  final String? phone;
  final String? email;
  final String? region;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const BranchEntity({
    required this.id,
    required this.tenantId,
    required this.name,
    this.timezone = 'UTC',
    this.status = BranchStatus.active,
    this.address,
    this.phone,
    this.email,
    this.region,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  BranchEntity copyWith({
    String? id,
    String? tenantId,
    String? name,
    String? timezone,
    BranchStatus? status,
    String? address,
    String? phone,
    String? email,
    String? region,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return BranchEntity(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      timezone: timezone ?? this.timezone,
      status: status ?? this.status,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      region: region ?? this.region,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        tenantId,
        name,
        timezone,
        status,
        address,
        phone,
        email,
        region,
        createdAt,
        updatedAt,
        deletedAt,
      ];
}
