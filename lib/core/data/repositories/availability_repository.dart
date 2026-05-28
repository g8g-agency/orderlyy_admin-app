import '../dtos/availability_dto.dart';
import '../../network/api_exception.dart';

abstract class AvailabilityRepository {
  /// Fetches the backend-resolved availability projection for an entity.
  Future<Result<ResolvedAvailabilityProjectionDto>> getResolvedAvailability(String entityId, String entityType);

  /// Fetches configured availability rules for an entity (raw config, backend evaluates it).
  Future<Result<List<AvailabilityRuleDto>>> getAvailabilityRules(String entityId, String entityType);

  /// Adds a new availability rule. Backend ensures it aligns with existing precedence.
  Future<Result<AvailabilityRuleDto>> addAvailabilityRule(AvailabilityRuleDto rule);

  /// Updates an availability rule with strict OCC checking.
  Future<Result<AvailabilityRuleDto>> updateAvailabilityRule(AvailabilityRuleDto rule);

  /// Deletes a rule with OCC checking.
  Future<Result<void>> deleteAvailabilityRule(String ruleId, int currentVersion);
}
