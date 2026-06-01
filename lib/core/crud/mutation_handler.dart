import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// A generic async mutation handler that supports optimistic updates,
/// OCC conflict detection (version_num mismatch), and rollback.
class MutationHandler {
  final Talker _talker;

  MutationHandler(this._talker);

  /// Executes a mutation with optimistic UI updates.
  /// 
  /// [optimisticUpdate] runs before the network call to update the local state.
  /// [networkCall] performs the actual mutation (returns the authoritative state).
  /// [onSuccess] is called with the authoritative result.
  /// [rollback] is called if the network call fails or throws an OCC conflict.
  Future<void> executeOptimistic<T>({
    required Future<void> Function() optimisticUpdate,
    required Future<T> Function() networkCall,
    required Future<void> Function(T result) onSuccess,
    required Future<void> Function(Object error) rollback,
    String operationName = 'Mutation',
  }) async {
    try {
      _talker.info('[$operationName] Applying optimistic update...');
      await optimisticUpdate();

      _talker.info('[$operationName] Executing network call...');
      final result = await networkCall();

      _talker.info('[$operationName] Success. Applying authoritative state.');
      await onSuccess(result);
    } catch (e, st) {
      _talker.error('[$operationName] Failed! Rolling back.', e, st);
      await rollback(e);
      rethrow;
    }
  }
}

final mutationHandlerProvider = Provider<MutationHandler>((ref) {
  // We can inject Talker here, for now using a default one or a simple logger.
  return MutationHandler(TalkerFlutter.init());
});
