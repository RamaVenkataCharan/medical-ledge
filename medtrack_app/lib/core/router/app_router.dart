import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'routes.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/otp_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/customers/presentation/customer_list_screen.dart';
import '../../features/customers/presentation/customer_profile_screen.dart';
import '../../features/customers/presentation/add_customer_screen.dart';
import '../../features/purchases/presentation/billing_screen.dart';
import '../../features/purchases/presentation/purchase_details_screen.dart';
import '../../features/purchases/presentation/purchase_success_screen.dart';
import '../../features/payments/presentation/collect_payment_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/profile/presentation/settings_screen.dart';
import '../../features/profile/presentation/shop_info_screen.dart';
import '../../features/profile/presentation/pharmacist_screen.dart';
import '../../features/reminders/presentation/reminders_screen.dart';
import '../../features/data_management/presentation/data_management_screen.dart';
import '../../features/recycle_bin/presentation/recycle_bin_screen.dart';
import '../../features/recycle_bin/presentation/deleted_customer_screen.dart';
import '../../features/medicines/presentation/medicine_search_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../widgets/main_shell.dart';

part 'app_router.g.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final _ = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      final isOnAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.otp ||
          state.matchedLocation == AppRoutes.onboarding ||
          state.matchedLocation == AppRoutes.splash;

      if (state.matchedLocation == AppRoutes.splash) return null;

      if (!isLoggedIn && !isOnAuthRoute) return AppRoutes.login;
      if (isLoggedIn && isOnAuthRoute &&
          state.matchedLocation != AppRoutes.splash) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      // Splash
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: SplashScreen(),
        ),
      ),

      // Onboarding
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (context, state) => const MaterialPage(
          child: OnboardingScreen(),
        ),
      ),

      // Login
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => const MaterialPage(
          child: LoginScreen(),
        ),
      ),

      // OTP
      GoRoute(
        path: AppRoutes.otp,
        pageBuilder: (context, state) {
          final email = state.extra as String? ?? '';
          return MaterialPage(child: OtpScreen(email: email));
        },
      ),

      // Main shell with bottom nav
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          // Home / Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: DashboardScreen(),
                ),
              ),
            ],
          ),

          // Customers
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.customers,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: CustomerListScreen(),
                ),
                routes: [
                  GoRoute(
                    path: 'new',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) => const MaterialPage(
                      child: AddCustomerScreen(),
                    ),
                  ),
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return MaterialPage(
                        child: CustomerProfileScreen(customerId: id),
                      );
                    },
                    routes: [
                      GoRoute(
                        path: 'edit',
                        parentNavigatorKey: _rootNavigatorKey,
                        pageBuilder: (context, state) {
                          final id = state.pathParameters['id']!;
                          return MaterialPage(
                            child: AddCustomerScreen(customerId: id),
                          );
                        },
                      ),
                      GoRoute(
                        path: 'purchases/new',
                        parentNavigatorKey: _rootNavigatorKey,
                        pageBuilder: (context, state) {
                          final id = state.pathParameters['id']!;
                          return MaterialPage(
                            child: BillingScreen(customerId: id),
                          );
                        },
                      ),
                      GoRoute(
                        path: 'payment',
                        parentNavigatorKey: _rootNavigatorKey,
                        pageBuilder: (context, state) {
                          final id = state.pathParameters['id']!;
                          return MaterialPage(
                            child: CollectPaymentScreen(customerId: id),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // Reports
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.reports,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ReportsScreen(),
                ),
              ),
            ],
          ),

          // More / Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.more,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: SettingsScreen(),
                ),
              ),
            ],
          ),
        ],
      ),

      // Purchases (global)
      GoRoute(
        path: '/purchases/:id',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return MaterialPage(child: PurchaseDetailsScreen(purchaseId: id));
        },
      ),

      GoRoute(
        path: AppRoutes.purchaseSuccess,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return MaterialPage(child: PurchaseSuccessScreen(data: extra));
        },
      ),

      // Medicines search
      GoRoute(
        path: AppRoutes.medicineSearch,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => const MaterialPage(
          child: MedicineSearchScreen(),
        ),
      ),

      // Notifications
      GoRoute(
        path: AppRoutes.notifications,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => const MaterialPage(
          child: NotificationsScreen(),
        ),
      ),

      // Settings sub-screens
      GoRoute(
        path: AppRoutes.shopInfo,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => const MaterialPage(
          child: ShopInfoScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.pharmacist,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => const MaterialPage(
          child: PharmacistScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.reminders,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => const MaterialPage(
          child: RemindersScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.dataManagement,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => const MaterialPage(
          child: DataManagementScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.recycleBin,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => const MaterialPage(
          child: RecycleBinScreen(),
        ),
      ),
      GoRoute(
        path: '${AppRoutes.recycleBin}/:id',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return MaterialPage(child: DeletedCustomerScreen(customerId: id));
        },
      ),
    ],
  );
}

@riverpod
Stream<AuthState> authState(AuthStateRef ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
}
