import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/network_providers.dart';
import '../../domain/entities/branch_entity.dart';
import '../../domain/repositories/branch_repository.dart';
import '../../data/repositories/branch_repository_impl.dart';
import '../../../../core/auth/app_auth_provider.dart';

final branchRepositoryProvider = Provider<BranchRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return BranchRepositoryImpl(dio);
});

final branchesProvider = FutureProvider<List<BranchEntity>>((ref) async {
  final repo = ref.watch(branchRepositoryProvider);
  final ctx = ref.watch(appContextProvider);
  if (ctx == null) throw Exception('No app context found');
  return repo.getBranches(ctx.tenant.id);
});
