import '../dtos/tax_dto.dart';
import '../repositories/tax_repository.dart';
import '../../network/dio_client.dart';
import '../../network/api_exception.dart';
import '../../constants/api_constants.dart';

class ApiTaxRepository implements TaxRepository {
  final DioClient _dioClient;

  ApiTaxRepository(this._dioClient);

  @override
  Future<Result<List<TaxProfileDto>>> getTaxProfiles({
    int page = 1,
    int limit = 100,
    bool includeDeleted = false,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (includeDeleted) 'include_deleted': 'true',
      };

      final response = await _dioClient.get(
        ApiConstants.taxes,
        queryParameters: queryParams,
      );

      if (response.data['success'] == true) {
        final data = response.data['data'] as List<dynamic>? ?? [];
        final profiles = data
            .map((json) => TaxProfileDto.fromJson(json as Map<String, dynamic>))
            .toList();
        return Success(profiles);
      } else {
        final errorMessage =
            response.data['error']?['message'] ??
            'Failed to fetch tax profiles';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Result<ResolvedTaxProjectionDto>> getResolvedTax(
    String entityId,
  ) async {
    try {
      final response = await _dioClient.get(
        '${ApiConstants.taxes}/resolved/$entityId',
      );

      if (response.data['success'] == true) {
        return Success(
          ResolvedTaxProjectionDto.fromJson(response.data['data']),
        );
      } else {
        final errorMessage =
            response.data['error']?['message'] ??
            'Failed to fetch resolved tax';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Result<TaxProfileDto>> createTaxProfile(TaxProfileDto profile) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.taxes,
        data: profile.toJson(),
      );

      if (response.data['success'] == true) {
        return Success(TaxProfileDto.fromJson(response.data['data']));
      } else {
        final errorMessage =
            response.data['error']?['message'] ??
            'Failed to create tax profile';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Result<TaxProfileDto>> updateTaxProfile(TaxProfileDto profile) async {
    try {
      final response = await _dioClient.patch(
        '${ApiConstants.taxes}/${profile.id}',
        data: profile.toJson(), // version_num sent for OCC
      );

      if (response.data['success'] == true) {
        return Success(TaxProfileDto.fromJson(response.data['data']));
      } else {
        final errorMessage =
            response.data['error']?['message'] ??
            'Failed to update tax profile';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteTaxProfile(
    String profileId,
    int currentVersion,
  ) async {
    try {
      final response = await _dioClient.delete(
        '${ApiConstants.taxes}/$profileId',
        data: {
          'version_num':
              currentVersion, // Explicit OCC boundary for safe deletion
        },
      );

      if (response.data['success'] == true) {
        return const Success(null);
      } else {
        final errorMessage =
            response.data['error']?['message'] ??
            'Failed to delete tax profile';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }
}
