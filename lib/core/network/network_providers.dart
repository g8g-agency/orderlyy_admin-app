import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';
import 'dio_client.dart';
import 'network_info.dart';
import 'offline_queue.dart';
import '../device/device_fingerprint_provider.dart';

final apiCacheBoxProvider = Provider<Box<String>>((ref) {
  throw UnimplementedError('apiCacheBoxProvider has not been overridden');
});

final offlineQueueBoxProvider = Provider<Box<String>>((ref) {
  throw UnimplementedError('offlineQueueBoxProvider has not been overridden');
});

final offlineQueueManagerProvider = Provider<OfflineQueueManager>((ref) {
  final queueBox = ref.watch(offlineQueueBoxProvider);
  final networkInfo = ref.watch(networkInfoProvider);
  final talker = ref.watch(talkerProvider);
  return OfflineQueueManager(queueBox, networkInfo, talker);
});

final Provider<DioClient> dioClientProvider = Provider<DioClient>((ref) {
  final talker = ref.watch(talkerProvider);
  final fingerprint = ref.watch(deviceFingerprintProvider);

  return DioClient(
    talker: talker,
    deviceFingerprint: fingerprint,
    onUnauthorized: (message) {
      logWarning(
        '[DioClient] 🚨 Unauthorized request (401) detected: $message',
      );

      final lowerMsg = message.toLowerCase();
      // DO NOT logout if missing fingerprint
      if (lowerMsg.contains('fingerprint')) return;

      if (lowerMsg.contains('session expired')) {
        logWarning('[DioClient] 🚨 Session refresh failed — signing out.');
        Supabase.instance.client.auth.signOut();
      }
    },
  );
});
