import '../dtos/settings_dto.dart';
import '../repositories/settings_repository.dart';
import '../../network/dio_client.dart';
import '../../network/api_exception.dart';
import '../../constants/api_constants.dart';

class ApiSettingsRepository implements SettingsRepository {
  final DioClient _dioClient;

  ApiSettingsRepository(this._dioClient);

  @override
  Future<Result<TenantSettingsDto>> getSettings({String? branchId}) async {
    try {
      final queryParams = <String, dynamic>{
        if (branchId != null) 'branch_id': branchId,
      };

      final response = await _dioClient.get(
        ApiConstants.settings,
        queryParameters: queryParams,
      );

      if (response.data['success'] == true) {
        return Success(TenantSettingsDto.fromJson(response.data['data']));
      } else {
        final errorMessage =
            response.data['error']?['message'] ?? 'Failed to fetch settings';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Result<TenantSettingsDto>> updateSettings(
    TenantSettingsDto settings,
  ) async {
    try {
      final response = await _dioClient.patch(
        ApiConstants.settings,
        data: settings.toJson(), // version_num sent for OCC
      );

      if (response.data['success'] == true) {
        return Success(TenantSettingsDto.fromJson(response.data['data']));
      } else {
        final errorMessage =
            response.data['error']?['message'] ?? 'Failed to update settings';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }
}
