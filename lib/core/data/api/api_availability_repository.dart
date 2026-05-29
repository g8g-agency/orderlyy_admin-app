import '../dtos/availability_dto.dart';
import '../repositories/availability_repository.dart';
import '../../network/dio_client.dart';
import '../../network/api_exception.dart';
import '../../constants/api_constants.dart';

class ApiAvailabilityRepository implements AvailabilityRepository {
  final DioClient _dioClient;

  ApiAvailabilityRepository(this._dioClient);

  @override
  Future<Result<ResolvedAvailabilityProjectionDto>> getResolvedAvailability(
    String entityId,
    String entityType,
  ) async {
    try {
      final response = await _dioClient.get(
        '${ApiConstants.availability}/resolved',
        queryParameters: {'entity_id': entityId, 'entity_type': entityType},
      );

      if (response.data['success'] == true) {
        return Success(
          ResolvedAvailabilityProjectionDto.fromJson(response.data['data']),
        );
      } else {
        final errorMessage =
            response.data['error']?['message'] ??
            'Failed to fetch resolved availability';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<AvailabilityRuleDto>>> getAvailabilityRules(
    String entityId,
    String entityType,
  ) async {
    try {
      final response = await _dioClient.get(
        ApiConstants.availability,
        queryParameters: {'entity_id': entityId, 'entity_type': entityType},
      );

      if (response.data['success'] == true) {
        final data = response.data['data'] as List<dynamic>? ?? [];
        final rules = data
            .map(
              (json) =>
                  AvailabilityRuleDto.fromJson(json as Map<String, dynamic>),
            )
            .toList();
        return Success(rules);
      } else {
        final errorMessage =
            response.data['error']?['message'] ??
            'Failed to fetch availability rules';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Result<AvailabilityRuleDto>> addAvailabilityRule(
    AvailabilityRuleDto rule,
  ) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.availability,
        data: rule.toJson(),
      );

      if (response.data['success'] == true) {
        return Success(AvailabilityRuleDto.fromJson(response.data['data']));
      } else {
        final errorMessage =
            response.data['error']?['message'] ??
            'Failed to add availability rule';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Result<AvailabilityRuleDto>> updateAvailabilityRule(
    AvailabilityRuleDto rule,
  ) async {
    try {
      final response = await _dioClient.patch(
        '${ApiConstants.availability}/${rule.id}',
        data: rule.toJson(), // version_num sent for OCC
      );

      if (response.data['success'] == true) {
        return Success(AvailabilityRuleDto.fromJson(response.data['data']));
      } else {
        final errorMessage =
            response.data['error']?['message'] ??
            'Failed to update availability rule';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteAvailabilityRule(
    String ruleId,
    int currentVersion,
  ) async {
    try {
      final response = await _dioClient.delete(
        '${ApiConstants.availability}/$ruleId',
        data: {
          'version_num': currentVersion, // OCC explicit protection
        },
      );

      if (response.data['success'] == true) {
        return const Success(null);
      } else {
        final errorMessage =
            response.data['error']?['message'] ??
            'Failed to delete availability rule';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }
}
