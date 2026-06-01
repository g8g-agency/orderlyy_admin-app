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

  /// Called by AuthNotifier after a successful sign-in or session restore.
  ///
  /// [authenticatedUserId] — the newly authenticated user's ID.
  /// This MUST be called before any runtime provider initialises.
  Future<void> resolve(String authenticatedUserId) async {
    debugPrint('[Bootstrap] 🔍 Resolving bootstrap for userId=$authenticatedUserId');
    state = const BootstrapState.loading();

    // ── Phase 5: User-consistency validation ──────────────────────────────
    await _validateUserConsistency(authenticatedUserId);

    // ── Call bootstrap endpoint ────────────────────────────────────────────
    try {
      final repo = _ref.read(authRepositoryProvider);
      final result = await repo.resolveContext();

      if (result is Success<AppContextDto?>) {
        final ctx = result.value;

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

        // Distinguish network from server errors
        if (failure.code == ApiErrorCode.networkError) {
          state = BootstrapState.networkFailure(failure.message);
        } else {
          state = BootstrapState.bootstrapFailure(failure.message);
        }
      }
    } catch (e) {
      debugPrint('[Bootstrap] 💥 Unexpected error: $e');
      state = BootstrapState.networkFailure(
        'Could not reach the server. Check your connection and try again.',
      );
    }
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

