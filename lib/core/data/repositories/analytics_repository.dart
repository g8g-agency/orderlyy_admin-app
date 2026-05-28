import '../dtos/analytics_dto.dart';
import '../../network/api_exception.dart';

abstract class AnalyticsRepository {
  /// Fetches the backend-resolved daily summary projection.
  /// The frontend NEVER computes these values locally.
  Future<Result<DailySummaryProjectionDto>> getDailySummary({
    required DateTime date,
    String? branchId,
  });

  /// Fetches a time-bounded analytics projection for a given range.
  Future<Result<List<DailySummaryProjectionDto>>> getAnalyticsRange({
    required DateTime startDate,
    required DateTime endDate,
    String? branchId,
  });
}
