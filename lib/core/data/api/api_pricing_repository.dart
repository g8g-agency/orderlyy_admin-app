import '../dtos/pricing_dto.dart';
import '../repositories/pricing_repository.dart';
import '../../network/dio_client.dart';
import '../../network/api_exception.dart';
import '../../constants/api_constants.dart';

class ApiPricingRepository implements PricingRepository {
  final DioClient _dioClient;

  ApiPricingRepository(this._dioClient);

  @override
  Future<Result<List<PricingRecordDto>>> getPricingHistory(
    String entityId,
  ) async {
    try {
      final response = await _dioClient.get(
        '${ApiConstants.pricing}/history/$entityId',
      );

      if (response.data['success'] == true) {
        final data = response.data['data'] as List<dynamic>? ?? [];
        final history = data
            .map(
              (json) => PricingRecordDto.fromJson(json as Map<String, dynamic>),
            )
            .toList();
        return Success(history);
      } else {
        final errorMessage =
            response.data['error']?['message'] ??
            'Failed to fetch pricing history';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<ResolvedPriceProjectionDto>>> getResolvedPrices(
    List<String> entityIds,
  ) async {
    try {
      final response = await _dioClient.post(
        '${ApiConstants.pricing}/resolved',
        data: {'entity_ids': entityIds},
      );

      if (response.data['success'] == true) {
        final data = response.data['data'] as List<dynamic>? ?? [];
        final projections = data
            .map(
              (json) => ResolvedPriceProjectionDto.fromJson(
                json as Map<String, dynamic>,
              ),
            )
            .toList();
        return Success(projections);
      } else {
        final errorMessage =
            response.data['error']?['message'] ??
            'Failed to fetch resolved prices';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Result<PricingRecordDto>> addPricingRecord(
    PricingRecordDto record,
  ) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.pricing,
        data: record
            .toJson(), // Backend enforces append-only logic and version_num constraints
      );

      if (response.data['success'] == true) {
        return Success(PricingRecordDto.fromJson(response.data['data']));
      } else {
        final errorMessage =
            response.data['error']?['message'] ??
            'Failed to add pricing record';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }
}
