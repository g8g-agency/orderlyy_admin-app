import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BranchCancellationService {
  CancelToken _cancelToken = CancelToken();

  CancelToken get token => _cancelToken;

  void cancelAndReset() {
    if (!_cancelToken.isCancelled) {
      _cancelToken.cancel('Branch switch initiated');
    }
    _cancelToken = CancelToken();
  }
}

final branchCancellationServiceProvider = Provider<BranchCancellationService>((ref) {
  return BranchCancellationService();
});
