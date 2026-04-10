import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/enums/user_role.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.currentUser;

    return ListView(
      children: [
        const SizedBox(height: 8),

        // Lead management section
        _sectionHeader('LEAD MANAGEMENT'),
        _menuItem(
          context,
          icon: Icons.people_outline,
          title: 'Leads & Prospects',
          subtitle: 'View and manage your lead pipeline',
          onTap: () => context.push('/leads'),
        ),
        _menuItem(
          context,
          icon: Icons.shield_outlined,
          title: 'Coverage Check',
          subtitle: 'Check if a person/company is already covered',
          onTap: () => context.push('/coverage'),
        ),
        _menuItem(
          context,
          icon: Icons.business_center,
          title: 'Capture IB Lead',
          subtitle: 'Log an Investment Banking opportunity',
          onTap: () => context.push('/ib-leads/new'),
        ),
        if (user?.role == UserRole.branchManager || user?.role == UserRole.admin)
          _menuItem(
            context,
            icon: Icons.fact_check_outlined,
            title: 'IB Lead Approvals',
            subtitle: 'Review IB leads pending Branch Head approval',
            onTap: () => context.push('/ib-leads'),
          ),
        _menuItem(
          context,
          icon: Icons.notifications_none,
          title: 'Notifications',
          subtitle: 'Inbox of recent updates',
          onTap: () => context.push('/notifications'),
        ),
        _menuItem(
          context,
          icon: Icons.search,
          title: 'Search Leads',
          subtitle: 'Find leads by name, phone, or company',
          onTap: () => context.push('/leads/search'),
        ),

        // Profiling section (visible to RM + Checker)
        if (user?.role == UserRole.rm || user?.role == UserRole.checker || user?.role == UserRole.admin) ...[
          _sectionHeader('PROFILING'),
          if (user?.role == UserRole.checker || user?.role == UserRole.admin)
            _menuItem(
              context,
              icon: Icons.verified_user,
              title: 'Checker Queue',
              subtitle: 'Review pending profiling submissions',
              badge: '8',
              onTap: () => context.push('/profiling/queue'),
            ),
        ],

        // Admin section
        if (user?.role == UserRole.admin || user?.role == UserRole.teamLead) ...[
          _sectionHeader('ADMINISTRATION'),
          if (user?.role == UserRole.admin)
            _menuItem(
              context,
              icon: Icons.assignment_ind,
              title: 'Lead Assignment',
              subtitle: 'Assign unassigned leads to RMs',
              onTap: () => context.push('/admin/leads'),
            ),
          _menuItem(
            context,
            icon: Icons.pool,
            title: 'Lead Pool',
            subtitle: 'Manage on-demand lead pool',
            onTap: () => context.push('/admin/pool'),
          ),
          if (user?.role == UserRole.teamLead || user?.role == UserRole.admin)
            _menuItem(
              context,
              icon: Icons.dashboard,
              title: 'TL Lead Dashboard',
              subtitle: 'Team lead pipeline overview',
              onTap: () => context.push('/tl/dashboard'),
            ),
          _menuItem(
            context,
            icon: Icons.history,
            title: 'Lead Request Log',
            subtitle: 'View lead request history',
            onTap: () => context.push('/tl/requests'),
          ),
        ],

        // RM section — request leads
        if (user?.role == UserRole.rm) ...[
          _sectionHeader('REQUESTS'),
          _menuItem(
            context,
            icon: Icons.add_circle_outline,
            title: 'Request Leads',
            subtitle: 'Request additional leads from pool',
            onTap: () => context.push('/leads/request'),
          ),
        ],

        _sectionHeader('ACCOUNT'),
        _menuItem(
          context,
          icon: Icons.swap_horiz,
          title: 'Switch Role',
          subtitle: 'Demo: switch between RM, TL, Checker, Admin',
          onTap: () => _showRoleSwitcher(context),
        ),
        _menuItem(
          context,
          icon: Icons.logout,
          title: 'Logout',
          subtitle: 'Sign out of Matrix',
          iconColor: AppColors.errorRed,
          onTap: () => context.read<AuthCubit>().logout(),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(title, style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1, color: AppColors.textSecondary)),
    );
  }

  Widget _menuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    String? badge,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.navyPrimary, size: 24),
      title: Text(title, style: AppTextStyles.labelLarge),
      subtitle: Text(subtitle, style: AppTextStyles.caption),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.hotRed,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(badge, style: AppTextStyles.caption.copyWith(color: AppColors.textOnDark, fontWeight: FontWeight.w600)),
            ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
        ],
      ),
      onTap: onTap,
    );
  }

  void _showRoleSwitcher(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Switch Role', style: AppTextStyles.heading3),
            const SizedBox(height: 16),
            ...UserRole.values.where((r) => [UserRole.rm, UserRole.teamLead, UserRole.branchManager, UserRole.checker, UserRole.admin].contains(r)).map(
              (role) => ListTile(
                leading: Icon(
                  role == UserRole.rm ? Icons.person :
                  role == UserRole.teamLead ? Icons.group :
                  role == UserRole.branchManager ? Icons.fact_check :
                  role == UserRole.checker ? Icons.verified_user : Icons.admin_panel_settings,
                  color: AppColors.navyPrimary,
                ),
                title: Text(role.label),
                onTap: () {
                  Navigator.pop(context);
                  context.read<AuthCubit>().login(role);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
