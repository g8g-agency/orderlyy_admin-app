// ── RuntimeReadyProvider ──────────────────────────────────────────────────────
// Secondary invariant enforcer — used by RuntimeReadyGate as a widget-level gate.
//
// INVARIANT:
//   Returns true ONLY when BootstrapStatus.tenantReady.
//   All runtime providers (realtime, projections, telemetry, observability)
//   must remain dormant until this returns true.
//
// The primary gate is the router redirect logic in app_router.dart.
// This gate is a secondary defense that protects ShellRoute child widgets
// from attempting to initialise with a null/stale context.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/bootstrap_provider.dart';
import '../auth/bootstrap_state.dart';

final runtimeReadyProvider = Provider<bool>((ref) {
  final bootstrapState = ref.watch(bootstrapProvider);
  return bootstrapState.status == BootstrapStatus.tenantReady;
});
