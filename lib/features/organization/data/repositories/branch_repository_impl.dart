import '../../../../core/network/dio_client.dart';
import '../../domain/entities/branch_entity.dart';
import '../../domain/repositories/branch_repository.dart';
import '../dtos/branch_dto.dart';

class BranchRepositoryImpl implements BranchRepository {
  final DioClient _dioClient;

  BranchRepositoryImpl(this._dioClient);

  @override
  Future<List<BranchEntity>> getBranches(String tenantId) async {
    final response = await _dioClient.get('/api/v1/tenants/$tenantId/branches');
    final data = response.data['data'] as List;
    return data.map((json) => BranchDto.fromJson(json).toEntity()).toList();
  }

  @override
  Future<BranchEntity> createBranch({
    required String tenantId,
    required String name,
    required String timezone,
    String? address,
    String? phone,
    String? email,
    String? region,
  }) async {
    final response = await _dioClient.post(
      '/api/v1/tenants/$tenantId/branches',
      data: {
        'name': name,
        'timezone': timezone,
        'address': address,
        'phone': phone,
        'email': email,
        'region': region,
      },
    );
    return BranchDto.fromJson(response.data['data']).toEntity();
  }

  @override
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
  }) async {
    final response = await _dioClient.patch(
      '/api/v1/tenants/$tenantId/branches/$branchId',
      data: {
        'name': name,
        'timezone': timezone,
        'status': status.name,
        'address': address,
        'phone': phone,
        'email': email,
        'region': region,
      },
    );
    return BranchDto.fromJson(response.data['data']).toEntity();
  }

  @override
  Future<void> deleteBranch(String tenantId, String branchId) async {
    await _dioClient.delete('/api/v1/tenants/$tenantId/branches/$branchId');
  }
}
