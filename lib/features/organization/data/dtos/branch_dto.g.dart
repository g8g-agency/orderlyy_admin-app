// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'branch_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BranchDto _$BranchDtoFromJson(Map<String, dynamic> json) => BranchDto(
  id: json['id'] as String,
  tenantId: json['tenant_id'] as String,
  name: json['name'] as String,
  timezone: json['timezone'] as String,
  status: json['status'] as String,
  address: json['address'] as String?,
  phone: json['phone'] as String?,
  email: json['email'] as String?,
  region: json['region'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  deletedAt: json['deleted_at'] == null
      ? null
      : DateTime.parse(json['deleted_at'] as String),
);

Map<String, dynamic> _$BranchDtoToJson(BranchDto instance) => <String, dynamic>{
  'id': instance.id,
  'tenant_id': instance.tenantId,
  'name': instance.name,
  'timezone': instance.timezone,
  'status': instance.status,
  'address': instance.address,
  'phone': instance.phone,
  'email': instance.email,
  'region': instance.region,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
  'deleted_at': instance.deletedAt?.toIso8601String(),
};
