// lib/features/onboarding/presentation/state/onboarding_notifier.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/onboarding_status_model.dart';
import '../../data/repositories/onboarding_repository.dart';

part 'onboarding_notifier.g.dart';

@Riverpod(keepAlive: true)
class OnboardingNotifier extends _$OnboardingNotifier {
  @override
  FutureOr<OnboardingStatusModel?> build() async {
    return _fetchStatus();
  }

  Future<OnboardingStatusModel?> _fetchStatus() async {
    final repo = ref.read(onboardingRepositoryProvider);
    return await repo.getOnboardingStatus();
  }


  void reset() {
    state = const AsyncValue.data(null);
  }
}
