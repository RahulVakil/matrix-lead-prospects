import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../core/enums/ib_deal_type.dart' show IbLeadStatus;
import '../core/enums/lead_source.dart';
import '../core/enums/lead_stage.dart';
import '../core/enums/lead_temperature.dart';
import '../core/enums/user_role.dart';
import '../features/admin/presentation/pages/manage_pool_screen.dart';
import '../features/auth/presentation/pages/login_screen.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../features/client_onboarding/presentation/pages/rm_assisted_onboarding_screen.dart';
import '../features/clients/presentation/pages/client_detail_screen.dart';
import '../features/clients/presentation/pages/client_list_screen.dart';
import '../features/coverage/presentation/pages/coverage_check_screen.dart';
import '../features/create_lead/presentation/pages/create_lead_screen.dart';
import '../features/dashboard_leadership/presentation/pages/leadership_dashboard_screen.dart';
import '../features/day_activity/presentation/pages/day_activity_screen.dart';
import '../features/follow_ups/presentation/pages/follow_ups_screen.dart';
import '../features/get_lead/presentation/pages/get_lead_screen.dart';
import '../features/ib_lead/presentation/pages/ib_dashboard_screen.dart';
import '../features/ib_lead/presentation/pages/ib_lead_capture_screen.dart';
import '../features/ib_lead/presentation/pages/ib_lead_detail_screen.dart';
import '../features/ib_lead/presentation/pages/my_ib_leads_screen.dart';
import '../features/lead_detail/presentation/pages/lead_detail_screen.dart';
import '../features/lead_inbox/presentation/pages/lead_inbox_screen.dart';
import '../features/matrix_home/presentation/pages/matrix_home_screen.dart';
import '../features/meetings/presentation/pages/meeting_detail_screen.dart';
import '../features/my_team/presentation/pages/my_team_screen.dart';
import '../features/meetings/presentation/pages/meetings_list_screen.dart';
import '../features/tasks_list/presentation/pages/tasks_list_screen.dart';
import '../features/notifications/presentation/pages/notifications_screen.dart';
import '../features/profiling/presentation/pages/checker_queue_screen.dart';
import '../features/profiling_wizard/presentation/pages/profiling_wizard_screen.dart';
import '../features/shell/presentation/pages/app_shell.dart';
import '../features/shell/presentation/pages/more_screen.dart';

GoRouter createRouter(AuthCubit authCubit) {
  // Branch keys give each tab its own Navigator instance (so each tab keeps
  // its own back stack independent of the others, like a native iOS app).
  final homeKey = GlobalKey<NavigatorState>(debugLabel: 'home');
  final clientsKey = GlobalKey<NavigatorState>(debugLabel: 'clients');
  final analyticsKey = GlobalKey<NavigatorState>(debugLabel: 'analytics');
  final moreKey = GlobalKey<NavigatorState>(debugLabel: 'more');

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

      // ── Persistent shell — bottom nav stays visible across all routes
      // inside this StatefulShellRoute. Each branch is a tab with its own
      // Navigator stack. Tabs preserve their stacks when you switch between
      // them. Tapping the same tab twice resets that branch to its root.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShellScaffold(navigationShell: navigationShell),
        branches: [
          // ─── Branch 0: Home ───────────────────────────────────────────
          // Includes everything reachable from the home tab — leads,
          // dashboards, IB leads, profiling, notifications, admin, etc.
          // The /home route dispatches to the right landing page per role.
          StatefulShellBranch(
            navigatorKey: homeKey,
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (context, state) =>
                    _fadePage(_homeForRole(context)),
                routes: [
                  // Notifications — pushed from top-bar bell.
                  GoRoute(
                    path: 'notifications',
                    pageBuilder: (context, state) =>
                        _fadePage(const NotificationsScreen()),
                  ),
                ],
              ),

              // All Leads list — the "Show all" target from the home preview.
              GoRoute(
                path: '/leads',
                pageBuilder: (context, state) {
                  final extra = (state.extra is Map) ? state.extra as Map : const {};
                  return _fadePage(LeadInboxScreen(
                    initialStatus: _statusFromString(extra['status'] as String?),
                    initialSource: _sourceFromString(extra['source'] as String?),
                    initialActiveOnly: extra['activeOnly'] == true,
                    titleOverride: extra['title'] as String?,
                    initialLifecycle: _stageFromString(extra['lifecycle'] as String?),
                    initialReassignment: extra['reassignment'] as String?,
                  ));
                },
              ),
              GoRoute(
                path: '/leads/new',
                pageBuilder: (context, state) =>
                    _fadePage(const CreateLeadScreen()),
              ),
              GoRoute(
                path: '/get-lead',
                pageBuilder: (context, state) =>
                    _fadePage(const GetLeadScreen()),
              ),
              GoRoute(
                path: '/leads/:leadId',
                pageBuilder: (context, state) => _fadePage(
                  LeadDetailScreen(leadId: state.pathParameters['leadId']!),
                ),
              ),
              GoRoute(
                path: '/leads/:leadId/onboard',
                pageBuilder: (context, state) => _fadePage(
                  RmAssistedOnboardingScreen(
                      leadId: state.pathParameters['leadId']!),
                ),
              ),

              // Profiling
              GoRoute(
                path: '/profiling-wizard/:leadId',
                pageBuilder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  return _fadePage(
                    ProfilingWizardScreen(
                      leadId: state.pathParameters['leadId']!,
                      leadName: extra?['leadName'] as String? ?? 'Lead',
                    ),
                  );
                },
              ),
              GoRoute(
                path: '/profiling/queue',
                pageBuilder: (context, state) =>
                    _fadePage(const CheckerQueueScreen()),
              ),

              // Admin
              GoRoute(
                path: '/admin/manage-pool',
                pageBuilder: (context, state) =>
                    _fadePage(const ManagePoolScreen()),
              ),

              // Leadership dashboard (TL / Regional / Zonal / CEO / Admin)
              GoRoute(
                path: '/tl/dashboard',
                pageBuilder: (context, state) =>
                    _fadePage(const LeadershipDashboardScreen()),
              ),

              // Coverage check
              GoRoute(
                path: '/coverage',
                pageBuilder: (context, state) =>
                    _fadePage(const CoverageCheckScreen()),
              ),

              // Follow-up tasks. /follow-ups is the combined view (Overdue
              // + Today as sequential sections). /follow-ups/overdue and
              // /follow-ups/today are single-bucket variants kept for
              // back-compat / direct deep links.
              GoRoute(
                path: '/follow-ups',
                pageBuilder: (context, state) =>
                    _fadePage(const FollowUpsScreen()),
              ),
              GoRoute(
                path: '/follow-ups/overdue',
                pageBuilder: (context, state) => _fadePage(
                  const FollowUpsScreen(filter: FollowUpFilter.overdue),
                ),
              ),
              GoRoute(
                path: '/follow-ups/today',
                pageBuilder: (context, state) => _fadePage(
                  const FollowUpsScreen(filter: FollowUpFilter.today),
                ),
              ),

              // Meetings list (Show-All) — Upcoming/Past tabs + top actions
              // mirroring compass_v2_mobile/MeetingsDetailsView.
              GoRoute(
                path: '/meetings',
                pageBuilder: (context, state) =>
                    _fadePage(const MeetingsListScreen()),
              ),
              // Meeting detail — opens the full meeting flow (summary,
              // agenda, Join/Start action, Log meeting with draft support).
              GoRoute(
                path: '/meetings/:meetingId',
                pageBuilder: (context, state) => _fadePage(
                  MeetingDetailScreen(
                    meetingId: state.pathParameters['meetingId']!,
                  ),
                ),
              ),

              // Tasks list (Show-All) — mirrors compass_v2_mobile/TaskListScreen.
              GoRoute(
                path: '/tasks',
                pageBuilder: (context, state) =>
                    _fadePage(const TasksListScreen()),
              ),

              // Day activity drill-down — opened from the Day Snapshot CTA.
              GoRoute(
                path: '/day/:date',
                pageBuilder: (context, state) => _fadePage(
                  DayActivityScreen(
                      dateString: state.pathParameters['date']!),
                ),
              ),

              // Leads Dashboard — opens directly into All Leads list with
              // the KPI hero card on top.
              // Optional `rmId` + `rmName` extras for the TL-view (when a
              // TL drills from My Team into a reportee's pipeline).
              GoRoute(
                path: '/leads-dashboard',
                pageBuilder: (context, state) {
                  final extra = (state.extra is Map)
                      ? state.extra as Map
                      : const {};
                  return _fadePage(LeadInboxScreen(
                    showHero: true,
                    rmIdOverride: extra['rmId'] as String?,
                    rmNameOverride: extra['rmName'] as String?,
                  ));
                },
              ),

              // Team Lead — team aggregate dashboard.
              GoRoute(
                path: '/my-team',
                pageBuilder: (context, state) =>
                    _fadePage(const MyTeamScreen()),
              ),

              // IB Leads — accepts `initialStatus` extra so contextual home
              // taps (e.g. "IB leads sent back") land on the pre-filtered list.
              GoRoute(
                path: '/ib-leads',
                pageBuilder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  return _fadePage(MyIbLeadsScreen(
                    initialStatus: extra?['status'] as IbLeadStatus?,
                  ));
                },
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
                      parentLeadId: extra?['parentLeadId'] as String?,
                      seedNotes: extra?['notes'] as String?,
                    ),
                  );
                },
              ),
              GoRoute(
                path: '/ib-leads/my',
                pageBuilder: (context, state) =>
                    _fadePage(const MyIbLeadsScreen()),
              ),
              GoRoute(
                path: '/ib-leads/:ibLeadId',
                pageBuilder: (context, state) => _fadePage(
                  IbLeadDetailScreen(
                      ibLeadId: state.pathParameters['ibLeadId']!),
                ),
              ),
            ],
          ),

          // ─── Branch 1: Clients ────────────────────────────────────────
          StatefulShellBranch(
            navigatorKey: clientsKey,
            routes: [
              GoRoute(
                path: '/clients',
                pageBuilder: (context, state) =>
                    _fadePage(const ClientListScreen()),
                routes: [
                  GoRoute(
                    path: ':clientId',
                    pageBuilder: (context, state) => _fadePage(
                      ClientDetailScreen(
                          clientId: state.pathParameters['clientId']!),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ─── Branch 2: Analytics (placeholder) ────────────────────────
          StatefulShellBranch(
            navigatorKey: analyticsKey,
            routes: [
              GoRoute(
                path: '/analytics',
                pageBuilder: (context, state) =>
                    _fadePage(const _AnalyticsPlaceholder()),
              ),
            ],
          ),

          // ─── Branch 3: More ──────────────────────────────────────────
          StatefulShellBranch(
            navigatorKey: moreKey,
            routes: [
              GoRoute(
                path: '/more',
                pageBuilder: (context, state) =>
                    _fadePage(const MoreScreen()),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class _AnalyticsPlaceholder extends StatelessWidget {
  const _AnalyticsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Analytics — coming soon',
              style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}

/// Pick the right landing screen for the user's role on the Home tab.
/// RM   → MatrixHomeScreen (their own pipeline; daily commander view)
/// TL   → MatrixHomeScreen (TL also works their own pool — same flow as RM;
///        team oversight lives behind More → My Team)
/// IB   → IbDashboardScreen (IB checker queue / approvals)
/// Higher leadership → LeadershipDashboardScreen (scope filtered by role)
Widget _homeForRole(BuildContext context) {
  final user = context.read<AuthCubit>().state.currentUser;
  if (user == null) return const SizedBox.shrink();
  switch (user.role) {
    case UserRole.rm:
    case UserRole.teamLead:
      return const MatrixHomeScreen();
    case UserRole.ib:
      return const IbDashboardScreen();
    case UserRole.regional:
    case UserRole.zonal:
    case UserRole.ceo:
    case UserRole.admin:
    case UserRole.compliance:
    case UserRole.management:
      return const LeadershipDashboardScreen();
  }
}

// Helpers for parsing route extras passed to /leads from the
// Leadership Dashboard's clickable KPI tiles.
LeadTemperature? _statusFromString(String? s) {
  if (s == null) return null;
  switch (s.toLowerCase()) {
    case 'hot':
      return LeadTemperature.hot;
    case 'warm':
      return LeadTemperature.warm;
    case 'cold':
      return LeadTemperature.cold;
    case 'onboarded':
      return LeadTemperature.onboarded;
    default:
      return null;
  }
}

LeadSource? _sourceFromString(String? s) {
  if (s == null) return null;
  for (final v in LeadSource.values) {
    if (v.name == s) return v;
  }
  return null;
}

/// Parses the home Leads pipeline filter key into the prototype's
/// [LeadStage] enum. Maps the agreed Wealth-CRM lifecycle to the existing
/// stage values so the cubit can filter without a schema change.
LeadStage? _stageFromString(String? s) {
  if (s == null) return null;
  switch (s) {
    case 'lead':
      return LeadStage.lead;
    case 'contacted':
      return LeadStage.engage;
    case 'ib_pending':
      return LeadStage.profiling;
    // 'ib_approved' has no direct prototype enum value — leaves the filter
    // unmatched (empty list) until the prototype model adds the stage.
    case 'onboarded':
      return LeadStage.onboard;
    case 'dropped':
      return LeadStage.dropped;
    default:
      return null;
  }
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
