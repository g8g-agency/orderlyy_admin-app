
class RestaurantContextDto {
  final TenantDto activeTenant;
  final BranchDto activeBranch;
  final List<RoleDto> roles;
  final List<CapabilityDto> capabilities;
  final List<FeatureAccessDto> featureAccess;

  const RestaurantContextDto({
    required this.activeTenant,
    required this.activeBranch,
    required this.roles,
    required this.capabilities,
    required this.featureAccess,
  });

  factory RestaurantContextDto.fromJson(Map<String, dynamic> json) {
    if (json['activeTenant'] == null) {
      throw const FormatException('Missing activeTenant');
    }
    if (json['activeBranch'] == null) {
      throw const FormatException('Missing activeBranch');
    }

    return RestaurantContextDto(
      activeTenant: TenantDto.fromJson(
        json['activeTenant'] as Map<String, dynamic>,
      ),
      activeBranch: BranchDto.fromJson(
        json['activeBranch'] as Map<String, dynamic>,
      ),
      roles:
          (json['roles'] as List<dynamic>?)
              ?.map((e) => RoleDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      capabilities:
          (json['capabilities'] as List<dynamic>?)
              ?.map((e) => CapabilityDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      featureAccess:
          (json['featureAccess'] as List<dynamic>?)
              ?.map((e) => FeatureAccessDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class TenantDto {
  final String id;
  final String name;
  final String slug;
  final String status;
  final bool isActive;

  const TenantDto({
    required this.id,
    required this.name,
    required this.slug,
    required this.status,
    required this.isActive,
  });

  factory TenantDto.fromJson(Map<String, dynamic> json) {
    if (json['id'] == null) throw const FormatException('Missing tenant id');
    if (json['name'] == null) {
      throw const FormatException('Missing tenant name');
    }
    if (json['slug'] == null) {
      throw const FormatException('Missing tenant slug');
    }

    return TenantDto(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      status: json['status'] as String? ?? 'active',
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class BranchDto {
  final String id;
  final String name;
  final String code;
  final String timezone;
  final bool isActive;

  const BranchDto({
    required this.id,
    required this.name,
    required this.code,
    required this.timezone,
    required this.isActive,
  });

  factory BranchDto.fromJson(Map<String, dynamic> json) {
    if (json['id'] == null) throw const FormatException('Missing branch id');
    if (json['name'] == null) {
      throw const FormatException('Missing branch name');
    }

    return BranchDto(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String? ?? '',
      timezone: json['timezone'] as String? ?? 'UTC',
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class RoleDto {
  final String id;
  final String name;

  const RoleDto({required this.id, required this.name});

  factory RoleDto.fromJson(Map<String, dynamic> json) {
    if (json['id'] == null) throw const FormatException('Missing role id');
    if (json['name'] == null) throw const FormatException('Missing role name');

    return RoleDto(id: json['id'] as String, name: json['name'] as String);
  }
}

class CapabilityDto {
  final String code; // e.g., 'menu.write', 'orders.refund'

  const CapabilityDto({required this.code});

  factory CapabilityDto.fromJson(Map<String, dynamic> json) {
    if (json['code'] == null) {
      throw const FormatException('Missing capability code');
    }

    return CapabilityDto(code: json['code'] as String);
  }
}

class FeatureAccessDto {
  final String featureKey;
  final bool isEnabled;

  const FeatureAccessDto({required this.featureKey, required this.isEnabled});

  factory FeatureAccessDto.fromJson(Map<String, dynamic> json) {
    if (json['featureKey'] == null) {
      throw const FormatException('Missing featureKey');
    }

    return FeatureAccessDto(
      featureKey: json['featureKey'] as String,
      isEnabled: json['isEnabled'] as bool? ?? false,
    );
  }
}
