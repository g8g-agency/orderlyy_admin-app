// ── Bootstrap Provider ────────────────────────────────────────────────────────
// Orchestrates tenant/workspace resolution after authentication.
//
// RESPONSIBILITIES:
//   • Call /api/v1/context/bootstrap after every successful auth.
//   • Parse the single deterministic payload into BootstrapState.
//   • Set AppContextDto state on success.
//   • Distinguish network failures from bootstrap failures.
//   • Reset ALL state on logout or user change.
//   • Validate user consistency before hydrating any cached state.
//
// WHAT IT DOES NOT DO:
//   • Does not authenticate users — that is AuthNotifier's job.
//   • Does not hydrate runtime projections — those await tenantReady.
//   • Does not fall back to demo/mock tenant data.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_exception.dart';
import '../providers/repository_providers.dart';
import '../data/dtos/auth_dto.dart';
import 'bootstrap_state.dart';
import 'app_auth_provider.dart';
import '../runtime/runtime_reset_service.dart';

// ── Persisted user-consistency key ────────────────────────────────────────────
const _kLastAuthUserId = 'bootstrap_last_user_id';
const _kBootstrapVersion = 'bootstrap_version';
const _kCurrentBootstrapVersion = 1;

// ── BootstrapNotifier ─────────────────────────────────────────────────────────

class BootstrapNotifier extends StateNotifier<BootstrapState> {
  BootstrapNotifier(this._ref) : super(const BootstrapState.idle());

  final Ref _ref;

  /// Coalesces duplicate resolve() calls (e.g. signIn + Supabase onAuthStateChange).
  Future<void>? _activeResolve;
  int _resolveGeneration = 0;

  Future<void> resolve(String userId, {bool force = false}) async {
    if (!force &&
        (state.status == BootstrapStatus.tenantReady ||
            state.status == BootstrapStatus.onboardingRequired)) {
      debugPrint('[Bootstrap] ⏭️ Already resolved (${state.status}) — skipping');
      return;
    }

    if (_activeResolve != null) {
      debugPrint('[Bootstrap] ⏭️ resolveContext already in flight.');
      return _activeResolve!;
    }

    _activeResolve = _doResolve(userId, emitLoading: true);
    try {
      await _activeResolve;
    } finally {
      _activeResolve = null;
    }
  }

  Future<void> silentResolve(String userId) async {
    if (_activeResolve != null) {
      debugPrint('[Bootstrap] ⏭️ resolveContext already in flight (silent).');
      return _activeResolve!;
    }

    _activeResolve = _doResolve(userId, emitLoading: false);
    try {
      await _activeResolve;
    } finally {
      _activeResolve = null;
    }
  }

  Future<void> _doResolve(String authenticatedUserId, {required bool emitLoading}) async {
    final generation = ++_resolveGeneration;
    debugPrint('[Bootstrap] 🔍 Resolving bootstrap for userId=$authenticatedUserId (gen=$generation)');
    
    if (emitLoading) {
      state = const BootstrapState.loading();
    }

    // ── Phase 5: User-consistency validation ──────────────────────────────
    await _validateUserConsistency(authenticatedUserId);
    if (generation != _resolveGeneration) {
      debugPrint('[Bootstrap] ⏭️ Stale resolve after validation (gen=$generation)');
      return;
    }

    // ── Call bootstrap endpoint ────────────────────────────────────────────
    try {
      debugPrint('[Bootstrap] 📡 Calling resolveContext API...');
      final repo = _ref.read(authRepositoryProvider);
      final result = await repo.resolveContext().timeout(
        const Duration(seconds: 25),
        onTimeout: () => Failure<AppContextDto?>(
          ApiFailure(
            'Workspace verification timed out. Check your connection and try again.',
            ApiErrorCode.networkError,
          ),
        ),
      );
      if (generation != _resolveGeneration) {
        debugPrint('[Bootstrap] ⏭️ Stale resolve after API (gen=$generation)');
        return;
      }
      debugPrint('[Bootstrap] 📡 API call completed. Result type: ${result.runtimeType}');

      if (result is Success<AppContextDto?>) {
        final ctx = result.value;
        debugPrint('[Bootstrap] ✅ Success result received. Context is null: ${ctx == null}');

        if (ctx == null) {
          // Backend returned success=true but no data — treat as bootstrap failure
          debugPrint('[Bootstrap] ⚠️ resolveContext returned null context');
          state = const BootstrapState.bootstrapFailure(
            'Workspace data could not be loaded. Please try again.',
          );
          return;
        }

        // Set app context
        _ref.read(appContextProvider.notifier).setContext(ctx);

        // Persist userId, tenantId, and bootstrap version for next-session consistency check
        await _persistBootstrapMeta(authenticatedUserId, ctx);

        // Determine routing outcome from context flags
        final requiresOnboarding = ctx.flags.onboardingRequired;

        if (requiresOnboarding) {
          debugPrint('[Bootstrap] 📋 Onboarding required');
          state = const BootstrapState.onboardingRequired();
        } else {
          debugPrint('[Bootstrap] ✅ Bootstrap complete — tenant ready');
          state = const BootstrapState.tenantReady();
        }
      } else if (result is Failure<AppContextDto?>) {
        final failure = result.error;
        debugPrint('[Bootstrap] ❌ resolveContext failed: ${failure.message}');
        debugPrint('[Bootstrap] ❌ Error code: ${failure.code}');

        // Distinguish network from server errors
        if (failure.code == ApiErrorCode.networkError) {
          state = BootstrapState.networkFailure(failure.message);
        } else {
          state = BootstrapState.bootstrapFailure(failure.message);
        }
      } else {
        debugPrint('[Bootstrap] ⚠️ Unexpected result type: ${result.runtimeType}');
        state = const BootstrapState.bootstrapFailure(
          'Workspace data could not be loaded. Please try again.',
        );
      }
    } catch (e, stackTrace) {
      if (generation != _resolveGeneration) {
        debugPrint('[Bootstrap] ⏭️ Stale resolve after error (gen=$generation)');
        return;
      }
      debugPrint('[Bootstrap] 💥 Unexpected error: $e');
      debugPrint('[Bootstrap] 💥 Stack trace: $stackTrace');
      state = BootstrapState.networkFailure(
        'Could not reach the server. Check your connection and try again.',
      );
    }
  }

  /// After the final onboarding step, transition bootstrap without re-fetching.
  void markTenantReady() {
    if (state.status == BootstrapStatus.tenantReady) return;
    debugPrint('[Bootstrap] ✅ Marking tenant ready after onboarding');
    state = const BootstrapState.tenantReady();
  }

  /// Retry bootstrap after a failure. Only valid when in a failure state.
  Future<void> retry(String authenticatedUserId) async {
    if (!state.isFailure) return;
    await resolve(authenticatedUserId);
  }

  /// Reset all bootstrap state. Must be called on logout or user change.
  /// Also clears AppContextDto from the provider.
  void reset() {
    debugPrint('[Bootstrap] 🗑️ Resetting bootstrap state');
    _resolveGeneration++;
    _activeResolve = null;
    _ref.read(appContextProvider.notifier).clearContext();
    state = const BootstrapState.idle();
  }

  // ── User Consistency Validation ───────────────────────────────────────────

  Future<void> _validateUserConsistency(String authenticatedUserId) async {
    try {
      final prefs = _ref.read(sharedPreferencesProvider);
      final lastUserId = prefs.getString(_kLastAuthUserId);
      final lastBootstrapVersion = prefs.getInt(_kBootstrapVersion) ?? 0;

      final userChanged = lastUserId != null && lastUserId != authenticatedUserId;
      final versionChanged = lastBootstrapVersion != _kCurrentBootstrapVersion;

      if (userChanged || versionChanged) {
        debugPrint(
          '[Bootstrap] ⚠️ User/version mismatch detected. '
          'lastUser=$lastUserId currentUser=$authenticatedUserId '
          'lastVersion=$lastBootstrapVersion currentVersion=$_kCurrentBootstrapVersion. '
          'Destroying all persisted runtime state.',
        );
        await _destroyAllPersistedState(prefs);
      } else {
        debugPrint('[Bootstrap] ✅ User consistency check passed');
      }
    } catch (e) {
      debugPrint('[Bootstrap] ⚠️ User consistency check failed: $e — proceeding with caution');
    }
  }

  Future<void> _destroyAllPersistedState(SharedPreferences prefs) async {
    debugPrint('[Bootstrap] 🔥 Destroying all persisted runtime state...');
    try {
      // Clear all SharedPreferences runtime keys (preserve only system keys)
      final keysToRemove = prefs.getKeys().where(
        (k) => !k.startsWith('flutter.') && k != _kLastAuthUserId,
      ).toList();

      for (final key in keysToRemove) {
        await prefs.remove(key);
      }

      // Clear all Hive boxes via repository layer
      // Individual feature providers will re-initialise when tenantReady
      await RuntimeResetService.fullReset();
      debugPrint('[Bootstrap] ✅ Persisted state destroyed (${keysToRemove.length} keys cleared)');
    } catch (e) {
      debugPrint('[Bootstrap] ⚠️ Failed to fully destroy persisted state: $e');
    }
  }

  Future<void> _persistBootstrapMeta(String userId, AppContextDto ctx) async {
    try {
      final prefs = _ref.read(sharedPreferencesProvider);
      await prefs.setString(_kLastAuthUserId, userId);
      await prefs.setString('last_tenant_id', ctx.tenant.id);
      await prefs.setInt(_kBootstrapVersion, _kCurrentBootstrapVersion);
      await prefs.setInt('runtime_schema_version', 1);
    } catch (e) {
      debugPrint('[Bootstrap] ⚠️ Failed to persist bootstrap meta: $e');
    }
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final bootstrapProvider =
    StateNotifierProvider<BootstrapNotifier, BootstrapState>((ref) {
  return BootstrapNotifier(ref);
});

