import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/pages/login_screen.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../features/shell/presentation/pages/app_shell.dart';
import '../features/lead_inbox/presentation/pages/lead_inbox_screen.dart';
import '../features/lead_detail/presentation/pages/lead_detail_screen.dart';
import '../features/create_lead/presentation/pages/create_lead_screen.dart';
import '../features/get_lead/presentation/pages/get_lead_screen.dart';
import '../features/profiling/presentation/pages/profiling_start_screen.dart';
import '../features/profiling/presentation/pages/checker_queue_screen.dart';
import '../features/admin/presentation/pages/assignment_screen.dart';
import '../features/admin/presentation/pages/pool_management_screen.dart';
import '../features/admin/presentation/pages/request_log_screen.dart';
import '../features/clients/presentation/pages/client_detail_screen.dart';
import '../features/coverage/presentation/pages/coverage_check_screen.dart';
import '../features/dashboard_tl/presentation/pages/tl_dashboard_screen.dart';
import '../features/ib_lead/presentation/pages/ib_checker_queue_screen.dart';
import '../features/ib_lead/presentation/pages/ib_lead_capture_screen.dart';
import '../features/ib_lead/presentation/pages/ib_lead_detail_screen.dart';
import '../features/leads_dashboard/presentation/pages/leads_dashboard_screen.dart';
import '../features/notifications/presentation/pages/notifications_screen.dart';

GoRouter createRouter(AuthCubit authCubit) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: _GoRouterRefreshStream(authCubit.stream),
    redirect: (context, state) {
      final isLoggedIn = authCubit.state.isLoggedIn;
      final isLoginRoute = state.uri.path == '/login';
      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => _fadePage(const AppShell()),
      ),

      // Leads Dashboard — module landing page
      GoRoute(
        path: '/leads-dashboard',
        pageBuilder: (context, state) => _fadePage(const LeadsDashboardScreen()),
      ),

      // Lead module routes
      GoRoute(
        path: '/leads',
        pageBuilder: (context, state) => _fadePage(const LeadInboxScreen()),
      ),
      GoRoute(
        path: '/leads/new',
        pageBuilder: (context, state) => _fadePage(const CreateLeadScreen()),
      ),
      GoRoute(
        path: '/get-lead',
        pageBuilder: (context, state) => _fadePage(const GetLeadScreen()),
      ),
      GoRoute(
        path: '/leads/:leadId',
        pageBuilder: (context, state) => _fadePage(
          LeadDetailScreen(leadId: state.pathParameters['leadId']!),
        ),
      ),

      // Profiling routes
      GoRoute(
        path: '/profiling/:leadId/start',
        pageBuilder: (context, state) => _fadePage(
          ProfilingStartScreen(leadId: state.pathParameters['leadId']!),
        ),
      ),
      GoRoute(
        path: '/profiling/queue',
        pageBuilder: (context, state) => _fadePage(const CheckerQueueScreen()),
      ),

      // Admin routes
      GoRoute(
        path: '/admin/leads',
        pageBuilder: (context, state) => _fadePage(const AssignmentScreen()),
      ),
      GoRoute(
        path: '/admin/pool',
        pageBuilder: (context, state) => _fadePage(const PoolManagementScreen()),
      ),

      // TL routes
      GoRoute(
        path: '/tl/dashboard',
        pageBuilder: (context, state) => _fadePage(const TlDashboardScreen()),
      ),
      GoRoute(
        path: '/tl/requests',
        pageBuilder: (context, state) => _fadePage(const RequestLogScreen()),
      ),

      // Phase 1 — Coverage, Clients, Notifications, IB Lead
      GoRoute(
        path: '/coverage',
        pageBuilder: (context, state) => _fadePage(const CoverageCheckScreen()),
      ),
      GoRoute(
        path: '/clients/:clientId',
        pageBuilder: (context, state) => _fadePage(
          ClientDetailScreen(clientId: state.pathParameters['clientId']!),
        ),
      ),
      GoRoute(
        path: '/notifications',
        pageBuilder: (context, state) => _fadePage(const NotificationsScreen()),
      ),
      GoRoute(
        path: '/ib-leads',
        pageBuilder: (context, state) => _fadePage(const IbCheckerQueueScreen()),
      ),
      GoRoute(
        path: '/ib-leads/new',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return _fadePage(
            IbLeadCaptureScreen(
              clientName: extra?['clientName'] as String?,
              clientCode: extra?['clientCode'] as String?,
              companyName: extra?['companyName'] as String?,
            ),
          );
        },
      ),
      GoRoute(
        path: '/ib-leads/:ibLeadId',
        pageBuilder: (context, state) => _fadePage(
          IbLeadDetailScreen(ibLeadId: state.pathParameters['ibLeadId']!),
        ),
      ),
    ],
  );
}

CustomTransitionPage _fadePage(Widget child) {
  return CustomTransitionPage(
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
    transitionDuration: const Duration(milliseconds: 200),
  );
}

class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    stream.listen((_) => notifyListeners());
  }
}
