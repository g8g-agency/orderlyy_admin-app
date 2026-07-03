import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/table_model.dart';

class TableRepository {
  final SupabaseClient _supabase;
  final String? _branchId;

  TableRepository(this._supabase, this._branchId);

  Future<List<RestaurantTable>> fetchTables() async {
    if (_branchId == null) return [];
    
    final response = await _supabase
        .from('tables')
        .select('*')
        .eq('branch_id', _branchId)
        .isFilter('deleted_at', null)
        .order('table_number', ascending: true);

    return (response as List).map((json) => RestaurantTable.fromJson(json)).toList();
  }

  Future<RestaurantTable> addTable(String number, String? name) async {
    if (_branchId == null) throw Exception('No active branch');

    final branchResponse = await _supabase
        .from('branches')
        .select('tenant_id')
        .eq('id', _branchId)
        .single();
    
    final tenantId = branchResponse['tenant_id'];

    final response = await _supabase
        .from('tables')
        .insert({
          'tenant_id': tenantId,
          'branch_id': _branchId,
          'table_number': number,
          'display_name': name,
          'is_active': true,
        })
        .select()
        .single();

    return RestaurantTable.fromJson(response);
  }

  Future<void> removeTable(String tableId) async {
    await _supabase
        .from('tables')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', tableId);
  }
}
