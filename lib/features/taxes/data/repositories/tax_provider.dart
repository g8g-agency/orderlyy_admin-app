import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../dtos/tax_dto.dart';
import 'tax_repository.dart';

final taxProfilesProvider = FutureProvider.autoDispose<List<TaxProfileDto>>((ref) async {
  final repo = ref.watch(taxRepositoryProvider);
  return repo.getTaxProfiles();
});
