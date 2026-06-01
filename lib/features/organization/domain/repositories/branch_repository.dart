import '../entities/branch_entity.dart';

abstract class BranchRepository {
  Future<List<BranchEntity>> getBranches(String tenantId);
  
  Future<BranchEntity> createBranch({
    required String tenantId,
    required String name,
    required String timezone,
    String? address,
    String? phone,
    String? email,
    String? region,
  });

  Future<BranchEntity> updateBranch({
    required String tenantId,
    required String branchId,
    required String name,
    required String timezone,
    required BranchStatus status,
    String? address,
    String? phone,
    String? email,
    String? region,
  });

  Future<void> deleteBranch(String tenantId, String branchId);
}
