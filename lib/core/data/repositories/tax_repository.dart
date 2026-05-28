import '../dtos/tax_dto.dart';
import '../../network/api_exception.dart';

abstract class TaxRepository {
  /// Fetches a paginated/filtered list of tax profiles from the backend.
  Future<Result<List<TaxProfileDto>>> getTaxProfiles({
    int page = 1,
    int limit = 100,
    bool includeDeleted = false,
  });

  /// Fetches the resolved tax projection for a given entity.
  Future<Result<ResolvedTaxProjectionDto>> getResolvedTax(String entityId);

  /// Creates a new tax profile. The backend handles `id`, `version_num`, `deleted_at`.
  Future<Result<TaxProfileDto>> createTaxProfile(TaxProfileDto profile);

  /// Updates a tax profile. Mandatory OCC checking using `version_num`.
  Future<Result<TaxProfileDto>> updateTaxProfile(TaxProfileDto profile);

  /// Soft-deletes a tax profile. Backend updates `deleted_at`.
  Future<Result<void>> deleteTaxProfile(String profileId, int currentVersion);
}
