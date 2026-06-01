import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/branch_entity.dart';

part 'branch_dto.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class BranchDto {
  final String id;
  final String tenantId;
  final String name;
  final String timezone;
  final String status;
  final String? address;
  final String? phone;
  final String? email;
  final String? region;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const BranchDto({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.timezone,
    required this.status,
    this.address,
    this.phone,
    this.email,
    this.region,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory BranchDto.fromJson(Map<String, dynamic> json) => _$BranchDtoFromJson(json);
  Map<String, dynamic> toJson() => _$BranchDtoToJson(this);

  BranchEntity toEntity() {
    return BranchEntity(
      id: id,
      tenantId: tenantId,
      name: name,
      timezone: timezone,
      status: BranchStatus.values.firstWhere(
        (e) => e.toString().split('.').last == status,
        orElse: () => BranchStatus.inactive,
      ),
      address: address,
      phone: phone,
      email: email,
      region: region,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }

  static BranchDto fromEntity(BranchEntity entity) {
    return BranchDto(
      id: entity.id,
      tenantId: entity.tenantId,
      name: entity.name,
      timezone: entity.timezone,
      status: entity.status.toString().split('.').last,
      address: entity.address,
      phone: entity.phone,
      email: entity.email,
      region: entity.region,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
    );
  }
}
