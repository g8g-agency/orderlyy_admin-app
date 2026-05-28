import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/mock_auth_provider.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/auth/admin_login_screen.dart';
import '../../features/auth/change_password_screen.dart';
import '../../features/auth/subscription_expired_screen.dart';
import '../../features/auth/account_suspended_screen.dart';
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
import '../runtime/runtime_ready_gate.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  // ── RouterNotifier drives GoRouter.refreshListenable ─────────────────────
  // Every time auth state changes (login/logout/restore), the notifier fires
  // notifyListeners() → GoRouter re-runs redirect → correct screen shown.
  // CRITICAL: We use ref.read here instead of ref.watch. Watching the notifier
  // would cause Riverpod to completely recreate the GoRouter instance on every
  // notifyListeners(), resetting navigation history and causing redirect loops.
  final notifier = ref.read(routerNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      // ── Read auth state directly from providers (reactive via notifier) ───
      final authState = ref.read(authNotifierProvider);
      final currentUserId = authState.userId;
      final resolvedCtx = ref.read(appContextProvider);
      final loc = state.matchedLocation;

      debugPrint(
        '[ROUTER] location=$loc authStatus=${authState.status} userId=$currentUserId',
      );

      if (authState.status == AuthStatus.loading) {
        debugPrint(
          '[ROUTER] ⏳ Auth status is loading. Redirecting to /splash',
        );
        return loc == '/splash' ? null : '/splash';
      }

      // Debug route always accessible
      if (loc == '/debug') {
        debugPrint('[ROUTER] 🛠️ Debug route allowed (redirectResult=null)');
        return null;
      }

      // ── 2. Determine Login / Role flags ────────────────────────────────────
      final isAdminLoggedIn =
          authState.status == AuthStatus.authenticated &&
          currentUserId != null &&
          !currentUserId.startsWith('staff-');

      const publicRoutes = {
        '/splash',
        '/admin/login',
      };

      final isPublicRoute = publicRoutes.contains(loc);

      // ── 3. Unauthenticated redirects ────────────────────────────────────────
      if (authState.status == AuthStatus.unauthenticated) {
        if (!isPublicRoute) {
          debugPrint(
            '[ROUTER] 🔒 Protected route "$loc" accessed without session → redirectResult=/admin/login',
          );
          return '/admin/login';
        }
        if (loc == '/splash') {
          debugPrint(
            '[ROUTER] ℹ️ Unauthenticated on splash → redirectResult=/admin/login',
          );
          return '/admin/login';
        }
        debugPrint(
          '[ROUTER] ✅ Public route "$loc" allowed for unauthenticated (redirectResult=null)',
        );
        return null;
      }

      // ── 4. Authenticated redirects ──────────────────────────────────────────
      if (authState.status == AuthStatus.authenticated) {
        // A. Resolve flags from context if admin is logged in
        if (isAdminLoggedIn && resolvedCtx != null) {
          final flags = resolvedCtx.flags;
          if (flags.mustChangePassword && loc != '/change-password') {
            debugPrint(
              '[ROUTER] 🔑 Admin password change required → redirectResult=/change-password',
            );
            return '/change-password';
          }
          if (flags.subscriptionExpired && loc != '/subscription-expired') {
            debugPrint(
              '[ROUTER] 💳 Subscription expired → redirectResult=/subscription-expired',
            );
            return '/subscription-expired';
          }
          if (flags.accountSuspended && loc != '/account-suspended') {
            debugPrint(
              '[ROUTER] 🚫 Account suspended → redirectResult=/account-suspended',
            );
            return '/account-suspended';
          }
          final isOnboardingIncomplete = !resolvedCtx.onboarding.isComplete || flags.onboardingRequired;

          const onboardingAllowedRoutes = {
            '/onboarding',
            '/admin/menu',
            '/admin/categories',
            '/admin/tables',
            '/admin/taxes',
            '/admin/staff',
            '/admin/kds',
          };

          const operationalRoutes = {
            '/admin/dashboard',
            '/admin/orders',
            '/admin/live-floorplan',
            '/admin/analytics',
            '/admin/inventory',
            '/admin/profile',
            '/admin/settings',
            '/admin/pricing',
            '/admin/overrides',
            '/admin/audit',
            '/admin/occ-conflict',
            '/admin/organization',
            '/admin/guest-sessions',
            '/admin/devices',
          };

          if (isOnboardingIncomplete) {
            // Block access to operational routes during setup
            if (operationalRoutes.contains(loc) || (!onboardingAllowedRoutes.contains(loc) && loc.startsWith('/admin'))) {
              debugPrint(
                '[ROUTER] 📋 Onboarding incomplete, blocking operational route "$loc" → redirectResult=/onboarding',
              );
              return '/onboarding';
            }
          } else {
            // Onboarding is complete, lock out the setup screen
            if (loc == '/onboarding') {
              debugPrint(
                '[ROUTER] ✅ Onboarding complete, redirecting away from setup → redirectResult=/admin/dashboard',
              );
              return '/admin/dashboard';
            }
          }
        }

        // B. If on splash or other public routes, route to dashboard (or onboarding)
        if (isPublicRoute) {
          if (isAdminLoggedIn) {
            final isOnboardingIncomplete = resolvedCtx != null && (!resolvedCtx.onboarding.isComplete || resolvedCtx.flags.onboardingRequired);
            final target = isOnboardingIncomplete ? '/onboarding' : '/admin/dashboard';
            debugPrint(
              '[ROUTER] ✅ Admin logged in on public route → redirectResult=$target',
            );
            return target;
          }
        }

        // C. Protect admin / staff routes
        final isProtectedAdmin = loc.startsWith('/admin') && loc != '/admin/login';

        if (isProtectedAdmin && !isAdminLoggedIn) {
          debugPrint(
            '[ROUTER] 🔒 Protected admin route accessed by non-admin → redirectResult=/admin/login',
          );
          return '/admin/login';
        }

        // STRICT RUNTIME GOVERNANCE GUARDS
        if (isProtectedAdmin) {
          if (resolvedCtx == null || resolvedCtx.tenant.id.isEmpty) {
            debugPrint('[ROUTER] 🚫 Missing Tenant scope. Redirecting to initialization.');
            // return '/initialization'; // Or handle appropriately
          }
          
          // Note: In a fully wired app, we would read ref.read(projectionReadinessProvider) here.
          // If projection is NOT ready, we should not allow entry to operational screens.
          // if (!isProjectionReady) {
          //    debugPrint('[ROUTER] ⏳ Projection rebuilding. Halting navigation.');
          //    return '/syncing';
          // }
        }
      }

      debugPrint(
        '[ROUTER] ✅ No redirect needed for $loc (redirectResult=null)',
      );
      return null;
    },
    routes: [
      // ── Debug ──────────────────────────────────────────────────────────────
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

      // ── Admin Auth ───────────────────────────────────────────────────────
      GoRoute(
        path: '/admin/login',
        name: 'admin-login',
        builder: (context, state) => const AdminLoginScreen(),
      ),

      // ── Post-Login Gated Routes ──────────────────────────────────────────
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

      // ── Admin App ───────────────────────────────────────────────────────
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
            path: '/admin/tables',
            name: 'admin-tabls',
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
        ],
      ),
    ],
  );
});
