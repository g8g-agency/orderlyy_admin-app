import '../dtos/settings_dto.dart';
import '../../network/api_exception.dart';

abstract class SettingsRepository {
  /// Fetches settings configuration. Backend determines if this is tenant-wide or branch-specific.
  Future<Result<TenantSettingsDto>> getSettings({String? branchId});

  /// Updates settings configuration. Strictly protected by OCC (versionNum).
  Future<Result<TenantSettingsDto>> updateSettings(TenantSettingsDto settings);
}
