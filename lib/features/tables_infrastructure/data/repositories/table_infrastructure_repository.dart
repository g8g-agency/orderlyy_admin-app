import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orderlli_admin/features/tables_infrastructure/data/dtos/table_dto.dart';

import '../../../../core/network/network_providers.dart';
import '../../../../core/network/dio_client.dart';

final tableInfrastructureRepositoryProvider = Provider<TableInfrastructureRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return ApiTableInfrastructureRepository(dio);
});

abstract class TableInfrastructureRepository {
  Future<List<TableDto>> getTables(String tenantId, String branchId);
  Future<TableDto> createTable(TableDto table);
  Future<TableDto> updateTable(TableDto table);
  Future<void> deleteTable(String tableId);
  Future<String> rotateQrCode(String tableId);
}

class ApiTableInfrastructureRepository implements TableInfrastructureRepository {
  final DioClient _dio;

  ApiTableInfrastructureRepository(this._dio);

  @override
  Future<List<TableDto>> getTables(String tenantId, String branchId) async {
    final res = await _dio.get('/v1/admin/tables?branch_id=$branchId&limit=100');
    final data = res.data['data'] as List;
    return data.map((json) => TableDto.fromJson(json)).toList();
  }

  @override
  Future<TableDto> createTable(TableDto table) async {
    final res = await _dio.post('/v1/admin/tables', data: table.toJson());
    return TableDto.fromJson(res.data['data']);
  }

  @override
  Future<TableDto> updateTable(TableDto table) async {
    final res = await _dio.patch('/v1/admin/tables/${table.id}', data: table.toJson());
    return TableDto.fromJson(res.data['data']);
  }

  @override
  Future<void> deleteTable(String tableId) async {
    await _dio.delete('/v1/admin/tables/$tableId');
  }

  @override
  Future<String> rotateQrCode(String tableId) async {
    final res = await _dio.post('/v1/admin/tables/$tableId/qr/rotate');
    return res.data['token'] as String;
  }
}
