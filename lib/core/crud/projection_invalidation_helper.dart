import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProjectionInvalidationHelper {
  /// Invalidates a specific provider and ensures that components depending on it
  /// will trigger a rebuild and refetch the data from the backend.
  static void invalidateList<T>(WidgetRef ref, ProviderBase<T> provider) {
    ref.invalidate(provider);
  }

  /// Refreshes a provider and waits for the new data to be fetched.
  static Future<void> refreshList<T>(WidgetRef ref, Refreshable<Future<T>> provider) async {
    return await ref.refresh(provider);
  }
}
