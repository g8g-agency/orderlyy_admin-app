// ── Admin App Router ──────────────────────────────────────────────────────────
// Implements a deterministic, layered routing state machine:
//
//   LAYER 1: Auth loading          → /splash
//   LAYER 2: Unauthenticated       → /admin/login
//   LAYER 3: Bootstrap gate        → /admin/loading | /admin/bootstrap-error
//   LAYER 4: Bootstrap resolved    → /onboarding | /admin/dashboard
//   LAYER 5: Context flag gates    → /change-password | /subscription-expired | /account-suspended
//
// INVARIANT:
//   The dashboard (and ALL operational routes behind ShellRoute) MUST NOT render
//   until BootstrapStatus.tenantReady. This is enforced by the redirect logic
//   and by RuntimeReadyGate wrapping all ShellRoute children.
//
// IMPORTANT: ref.read() is used (not ref.watch()) inside the redirect callback
// to avoid GoRouter recreating itself on every provider change. The RouterNotifier
// triggers refreshListenable instead.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/mock_auth_provider.dart';
import '../../core/auth/bootstrap_provider.dart';
import '../../core/auth/bootstrap_state.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/auth/admin_login_screen.dart';
import '../../features/auth/change_password_screen.dart';
import '../../features/auth/subscription_expired_screen.dart';
import '../../features/auth/account_suspended_screen.dart';
import '../../features/auth/bootstrap_loading_screen.dart';
import '../../features/auth/bootstrap_error_screen.dart';
import '../../features/onboarding/presentation/screens/setup_dashboard_screen.dart';
import '../../features/dashboard/admin_dashboard_screen.dart';
import '../../features/profile/admin_profile_screen.dart';
import '../../features/inventory/inventory_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/orders/admin_orders_screen.dart';
import '../../features/analytics/analytics_screen.dart';
import '../../features/menu/menu_management_screen.dart';
import '../../features/staff/staff_management_screen.dart';
import '../../features/debug/debug_screen.dart';
import '../../features/pricing/pricing_management_screen.dart';
import '../../features/tables_infrastructure/presentation/screens/table_infrastructure_screen.dart';
import '../../features/tables_infrastructure/presentation/screens/live_floorplan_screen.dart';
import '../../features/organization/presentation/screens/organization_dashboard_screen.dart';
import '../../features/runtime_monitoring/presentation/screens/guest_sessions_screen.dart';
import '../../features/runtime_monitoring/presentation/screens/device_management_screen.dart';
import '../../features/taxes/tax_management_screen.dart';
import '../../features/branch_overrides/branch_override_screen.dart';
import '../../features/tables_infrastructure/presentation/screens/table_management_screen.dart';
import '../../features/kds/presentation/screens/kds_management_screen.dart';
import '../../features/audit/audit_logs_screen.dart';
import '../../features/menu/presentation/screens/occ_conflict_screen.dart';
import '../../features/runtime_monitoring/presentation/screens/runtime_observability_screen.dart';
import '../../features/runtime_monitoring/presentation/screens/historical_replay_explorer.dart';
import '../../features/runtime_monitoring/presentation/screens/correlation_tree_explorer_screen.dart';
import '../runtime/runtime_ready_gate.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  // RouterNotifier fires notifyListeners on auth + bootstrap changes.
  // Using ref.read (not ref.watch) prevents GoRouter recreation on each notify.
  final notifier = ref.read(routerNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final bootstrapState = ref.read(bootstrapProvider);
      final appCtx = ref.read(appContextProvider);
      final loc = state.matchedLocation;

      debugPrint(
        '[ROUTER] loc=$loc '
        'auth=${authState.status} '
        'bootstrap=${bootstrapState.status}',
      );

      // ── Debug always accessible ─────────────────────────────────────────────
      if (loc == '/debug') return null;

      // ── LAYER 1: Auth loading ───────────────────────────────────────────────
      if (authState.status == AuthStatus.loading) {
        debugPrint('[ROUTER] ⏳ Auth loading → /splash');
        return loc == '/splash' ? null : '/splash';
      }

      // ── LAYER 2: Unauthenticated ────────────────────────────────────────────
      if (authState.status == AuthStatus.unauthenticated) {
        const publicRoutes = {'/splash', '/admin/login'};
        if (!publicRoutes.contains(loc)) {
          debugPrint('[ROUTER] 🔒 Unauthenticated → /admin/login');
          return '/admin/login';
        }
        if (loc == '/splash') {
          debugPrint('[ROUTER] ℹ️ Unauthenticated on splash → /admin/login');
          return '/admin/login';
        }
        return null;
      }

      // ── From here: authState.status == AuthStatus.authenticated ────────────

      // ── LAYER 3: Bootstrap gate (HARD INVARIANT) ────────────────────────────
      // The dashboard and ALL operational routes are completely unreachable
      // until BootstrapStatus.tenantReady. This is non-negotiable.

      // Bootstrap not yet started or in-flight
      if (bootstrapState.status == BootstrapStatus.idle ||
          bootstrapState.status == BootstrapStatus.loading) {
        if (loc != '/admin/loading') {
          debugPrint('[ROUTER] ⏳ Bootstrap in flight → /admin/loading');
          return '/admin/loading';
        }
        return null;
      }

      // Bootstrap failed (network or server error) — hard block
      if (bootstrapState.isFailure) {
        if (loc != '/admin/bootstrap-error') {
          debugPrint('[ROUTER] ❌ Bootstrap failed → /admin/bootstrap-error');
          return '/admin/bootstrap-error';
        }
        return null;
      }

      // ── LAYER 4: Bootstrap resolved ─────────────────────────────────────────
      // Either BootstrapStatus.onboardingRequired or BootstrapStatus.tenantReady

      // Redirect away from bootstrap transient screens now that it's resolved
      if (loc == '/admin/loading' || loc == '/admin/bootstrap-error') {
        if (bootstrapState.requiresOnboarding) {
          debugPrint('[ROUTER] 📋 Bootstrap resolved → /onboarding');
          return '/onboarding';
        }
        debugPrint('[ROUTER] ✅ Bootstrap resolved → /admin/dashboard');
        return '/admin/dashboard';
      }

      // Authenticated on public routes — route to workspace destination
      const publicRoutes = {'/splash', '/admin/login'};
      if (publicRoutes.contains(loc)) {
        if (bootstrapState.requiresOnboarding) {
          debugPrint('[ROUTER] 📋 Authenticated on public → /onboarding');
          return '/onboarding';
        }
        debugPrint('[ROUTER] ✅ Authenticated on public → /admin/dashboard');
        return '/admin/dashboard';
      }

      // Onboarding required — hard block on all operational routes
      if (bootstrapState.requiresOnboarding) {
        const onboardingAllowed = {
          '/onboarding',
          '/admin/menu',
          '/admin/categories',
          '/admin/tables',
          '/admin/taxes',
          '/admin/staff',
          '/admin/kds',
        };
        if (loc.startsWith('/admin') && !onboardingAllowed.contains(loc)) {
          debugPrint('[ROUTER] 📋 Onboarding required, blocking "$loc" → /onboarding');
          return '/onboarding';
        }
        return null;
      }

      // ── LAYER 5: tenantReady — context flag gates ───────────────────────────
      // Only reached when bootstrapState.status == BootstrapStatus.tenantReady.
      if (appCtx != null) {
        final flags = appCtx.flags;

        if (flags.accountSuspended && loc != '/account-suspended') {
          debugPrint('[ROUTER] 🚫 Account suspended → /account-suspended');
          return '/account-suspended';
        }
        if (flags.subscriptionExpired && loc != '/subscription-expired') {
          debugPrint('[ROUTER] 💳 Subscription expired → /subscription-expired');
          return '/subscription-expired';
        }
        if (flags.mustChangePassword && loc != '/change-password') {
          debugPrint('[ROUTER] 🔑 Must change password → /change-password');
          return '/change-password';
        }

        // Onboarding complete — lock out the setup screen
        if (loc == '/onboarding') {
          debugPrint('[ROUTER] ✅ Onboarding done → /admin/dashboard');
          return '/admin/dashboard';
        }
      }

      debugPrint('[ROUTER] ✅ No redirect for $loc');
      return null;
    },

    routes: [
      // ── Debug ─────────────────────────────────────────────────────────────
      GoRoute(
        path: '/debug',
        name: 'debug',
        builder: (context, state) => const DebugScreen(),
      ),

      // ── Splash ────────────────────────────────────────────────────────────
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // ── Admin Auth ────────────────────────────────────────────────────────
      GoRoute(
        path: '/admin/login',
        name: 'admin-login',
        builder: (context, state) => const AdminLoginScreen(),
      ),

      // ── Bootstrap States (hard gate screens) ──────────────────────────────
      GoRoute(
        path: '/admin/loading',
        name: 'admin-loading',
        builder: (context, state) => const BootstrapLoadingScreen(),
      ),
      GoRoute(
        path: '/admin/bootstrap-error',
        name: 'admin-bootstrap-error',
        builder: (context, state) => const BootstrapErrorScreen(),
      ),

      // ── Post-Login Gated Routes ───────────────────────────────────────────
      GoRoute(
        path: '/change-password',
        name: 'change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/subscription-expired',
        name: 'subscription-expired',
        builder: (context, state) => const SubscriptionExpiredScreen(),
      ),
      GoRoute(
        path: '/account-suspended',
        name: 'account-suspended',
        builder: (context, state) => const AccountSuspendedScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const SetupDashboardScreen(),
      ),

      // ── Admin Operational App ─────────────────────────────────────────────
      // ALL routes here are wrapped in RuntimeReadyGate as a secondary invariant
      // enforcer — it renders a loading screen if bootstrap is not tenantReady.
      ShellRoute(
        builder: (context, state, child) => RuntimeReadyGate(child: child),
        routes: [
          GoRoute(
            path: '/admin/dashboard',
            name: 'admin-dashboard',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/orders',
            name: 'admin-orders',
            builder: (context, state) => const AdminOrdersScreen(),
          ),
          GoRoute(
            path: '/admin/organization',
            name: 'admin-organization',
            builder: (context, state) => const OrganizationDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/guest-sessions',
            name: 'admin-guest-sessions',
            builder: (context, state) => const GuestSessionsScreen(),
          ),
          GoRoute(
            path: '/admin/devices',
            name: 'admin-devices',
            builder: (context, state) => const DeviceManagementScreen(),
          ),
          GoRoute(
            path: '/admin/tables',
            name: 'admin-tables',
            builder: (context, state) => const TableInfrastructureScreen(),
          ),
          GoRoute(
            path: '/admin/live-floorplan',
            name: 'admin-live-floorplan',
            builder: (context, state) => const LiveFloorplanScreen(),
          ),
          GoRoute(
            path: '/admin/analytics',
            name: 'admin-analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: '/admin/settings',
            name: 'admin-settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/admin/profile',
            name: 'admin-profile',
            builder: (context, state) => const AdminProfileScreen(),
          ),
          GoRoute(
            path: '/admin/inventory',
            name: 'admin-inventory',
            builder: (context, state) => const InventoryScreen(),
          ),
          GoRoute(
            path: '/admin/menu',
            name: 'admin-menu',
            builder: (context, state) => const MenuManagementScreen(),
          ),
          GoRoute(
            path: '/admin/staff',
            name: 'admin-staff',
            builder: (context, state) => const StaffManagementScreen(),
          ),
          GoRoute(
            path: '/admin/pricing',
            name: 'admin-pricing',
            builder: (context, state) => const PricingManagementScreen(),
          ),
          GoRoute(
            path: '/admin/taxes',
            name: 'admin-taxes',
            builder: (context, state) => const TaxManagementScreen(),
          ),
          GoRoute(
            path: '/admin/table-management',
            name: 'admin-table-management',
            builder: (context, state) => const TableManagementScreen(),
          ),
          GoRoute(
            path: '/admin/kds',
            name: 'admin-kds',
            builder: (context, state) => const KdsManagementScreen(),
          ),
          GoRoute(
            path: '/admin/overrides',
            name: 'admin-overrides',
            builder: (context, state) => const BranchOverrideScreen(),
          ),
          GoRoute(
            path: '/admin/audit',
            name: 'admin-audit',
            builder: (context, state) => const AuditLogsScreen(),
          ),
          GoRoute(
            path: '/admin/occ-conflict',
            name: 'admin-occ-conflict',
            builder: (context, state) => const OccConflictScreen(),
          ),
          GoRoute(
            path: '/admin/runtime-observability',
            name: 'admin-runtime-observability',
            builder: (context, state) => const RuntimeObservabilityScreen(),
          ),
          GoRoute(
            path: '/admin/runtime-observability/replay/:runId',
            name: 'admin-runtime-replay',
            builder: (context, state) => HistoricalReplayExplorerScreen(
              runId: state.pathParameters['runId']!,
            ),
          ),
          GoRoute(
            path: '/admin/runtime-observability/replay/:runId/tree/:correlationId',
            name: 'admin-runtime-replay-tree',
            builder: (context, state) => CorrelationTreeExplorerScreen(
              runId: state.pathParameters['runId']!,
              correlationId: state.pathParameters['correlationId']!,
            ),
          ),
        ],
      ),
    ],
  );
});
