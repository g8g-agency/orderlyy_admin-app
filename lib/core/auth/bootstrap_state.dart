// ── Bootstrap State Definitions ───────────────────────────────────────────────
// Separates tenant/workspace resolution from authentication.
//
// LIFECYCLE:
//   unauthenticated
//     → authenticated
//         → bootstrapLoading
//             → onboardingRequired   (new user, no tenant)
//             → networkFailure       (backend unreachable)
//             → bootstrapFailure     (backend error, invalid payload)
//             → tenantReady          (fully resolved, dashboard allowed)
//
// INVARIANT:
//   The dashboard MUST NEVER render until status == BootstrapStatus.tenantReady.
//   All runtime providers (realtime, projections, telemetry) must remain dormant
//   until tenantReady.

/// Discriminated bootstrap lifecycle status.
enum BootstrapStatus {
  /// No bootstrap has been attempted yet (e.g. before login).
  idle,

  /// Bootstrap call is in flight.
  loading,

  /// Backend was unreachable (XMLHttpRequest network error, timeout).
  networkFailure,

  /// Backend returned an error or the payload was malformed.
  bootstrapFailure,

  /// Authenticated but user has no tenant — must go through onboarding.
  onboardingRequired,

  /// Fully resolved. Tenant, branches, and flags are valid.
  tenantReady,
}

/// Immutable bootstrap state snapshot.
class BootstrapState {
  final BootstrapStatus status;
  final String? errorMessage;

  const BootstrapState({
    required this.status,
    this.errorMessage,
  });

  const BootstrapState.idle()
      : status = BootstrapStatus.idle,
        errorMessage = null;

  const BootstrapState.loading()
      : status = BootstrapStatus.loading,
        errorMessage = null;

  const BootstrapState.networkFailure(String message)
      : status = BootstrapStatus.networkFailure,
        errorMessage = message;

  const BootstrapState.bootstrapFailure(String message)
      : status = BootstrapStatus.bootstrapFailure,
        errorMessage = message;

  const BootstrapState.onboardingRequired()
      : status = BootstrapStatus.onboardingRequired,
        errorMessage = null;

  const BootstrapState.tenantReady()
      : status = BootstrapStatus.tenantReady,
        errorMessage = null;

  bool get isLoading => status == BootstrapStatus.loading;
  bool get isReady => status == BootstrapStatus.tenantReady;
  bool get isFailure =>
      status == BootstrapStatus.networkFailure ||
      status == BootstrapStatus.bootstrapFailure;
  bool get requiresOnboarding => status == BootstrapStatus.onboardingRequired;

  @override
  String toString() =>
      'BootstrapState(status: $status, error: $errorMessage)';
}
