import '../dtos/modifier_dto.dart';
import '../../network/api_exception.dart';

abstract class ModifierRepository {
  /// Fetches a paginated/filtered list of modifier groups.
  Future<Result<List<ModifierGroupDto>>> getModifierGroups({
    int page = 1,
    int limit = 100,
    bool includeDeleted = false,
  });

  /// Fetches a paginated/filtered list of modifier items for a specific group.
  Future<Result<List<ModifierItemDto>>> getModifierItems(String groupId, {
    int page = 1,
    int limit = 100,
    bool includeDeleted = false,
  });

  // Group CRUD
  Future<Result<ModifierGroupDto>> createModifierGroup(ModifierGroupDto group);
  Future<Result<ModifierGroupDto>> updateModifierGroup(ModifierGroupDto group);
  Future<Result<void>> deleteModifierGroup(String groupId, int currentVersion);

  // Item CRUD
  Future<Result<ModifierItemDto>> createModifierItem(ModifierItemDto item);
  Future<Result<ModifierItemDto>> updateModifierItem(ModifierItemDto item);
  Future<Result<void>> deleteModifierItem(String itemId, int currentVersion);
}
