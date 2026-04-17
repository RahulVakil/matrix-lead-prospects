import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../cubit/shell_cubit.dart';
import '../widgets/bottom_nav_bar.dart';
import '../../../clients/presentation/pages/client_list_screen.dart';
import '../../../dashboard_tl/presentation/pages/tl_dashboard_screen.dart';
import '../../../ib_lead/presentation/pages/ib_dashboard_screen.dart';
import '../../../leads_dashboard/presentation/pages/leads_dashboard_screen.dart';
import 'more_screen.dart';

/// AppShell: bottom nav. Tab 0 varies by role:
/// RM → Leads Dashboard
/// TL → Team Dashboard
/// Checker/Admin → More (grid menu)
/// IB → IB Dashboard
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.currentUser;
    if (user == null) return const SizedBox.shrink();

    return BlocProvider(
      create: (_) => ShellCubit(),
      child: BlocBuilder<ShellCubit, int>(
        builder: (context, currentIndex) {
          final tabs = _tabsForRole(user.role);
          final clampedIndex = currentIndex.clamp(0, tabs.length - 1);

          return Scaffold(
            backgroundColor: AppColors.heroBackdrop,
            body: IndexedStack(
              index: clampedIndex,
              children: tabs,
            ),
            bottomNavigationBar: BottomNavBar(
              currentIndex: clampedIndex,
              onTap: (i) => context.read<ShellCubit>().updateIndex(i),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _tabsForRole(UserRole role) {
    switch (role) {
      case UserRole.rm:
        return const [
          LeadsDashboardScreen(),
          ClientListScreen(),
          _PlaceholderTab(title: 'Analytics', icon: Icons.analytics_outlined),
          MoreScreen(),
        ];
      case UserRole.teamLead:
        return const [
          TlDashboardScreen(),
          ClientListScreen(showAll: true),
          _PlaceholderTab(title: 'Analytics', icon: Icons.analytics_outlined),
          MoreScreen(),
        ];
      case UserRole.ib:
        return const [
          IbDashboardScreen(),
          _PlaceholderTab(title: 'Clients', icon: Icons.people_outline),
          _PlaceholderTab(title: 'Analytics', icon: Icons.analytics_outlined),
          MoreScreen(),
        ];
      case UserRole.admin:
        return const [
          LeadsDashboardScreen(),
          ClientListScreen(),
          _PlaceholderTab(title: 'Analytics', icon: Icons.analytics_outlined),
          MoreScreen(),
        ];
      default:
        return const [
          LeadsDashboardScreen(),
          ClientListScreen(),
          _PlaceholderTab(title: 'Analytics', icon: Icons.analytics_outlined),
          MoreScreen(),
        ];
    }
  }
}

class _PlaceholderTab extends StatelessWidget {
  final String title;
  final IconData icon;
  const _PlaceholderTab({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceContent,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.navyPrimary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 30, color: AppColors.navyPrimary),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Coming soon',
                style: TextStyle(fontSize: 12, color: AppColors.textHint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
