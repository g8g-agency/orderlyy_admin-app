import '../dtos/pricing_dto.dart';
import '../../network/api_exception.dart';

abstract class PricingRepository {
  /// Fetches the pricing history for a specific entity (e.g. Menu Item).
  /// This history is immutable and append-only on the backend.
  Future<Result<List<PricingRecordDto>>> getPricingHistory(String entityId);

  /// Fetches the resolved active price projection for a list of entities.
  /// Backend strictly computes time windows, precedence, and fallback.
  Future<Result<List<ResolvedPriceProjectionDto>>> getResolvedPrices(List<String> entityIds);

  /// Adds a new pricing record. The backend enforces append-only logic.
  /// Replaces the active window or queues future windows depending on dates.
  Future<Result<PricingRecordDto>> addPricingRecord(PricingRecordDto record);
}
