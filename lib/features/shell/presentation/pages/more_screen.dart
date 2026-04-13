import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/widgets/hero_app_bar.dart';
import '../../../../core/widgets/hero_scaffold.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

/// More tab — deliberately minimal.
/// Single Leads entry → Leads landing hub. Switch role + logout.
/// All other lead-related screens are accessed FROM the Leads hub.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.currentUser;

    return HeroScaffold(
      header: HeroAppBar.simple(title: 'More', showBack: false),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 32),
        children: [
          if (user != null) _ProfileCard(name: user.name, role: user.role),
          const SizedBox(height: 22),

          _MoreCard(
            children: [
              _MoreRow(
                icon: Icons.people_alt_outlined,
                accent: AppColors.navyPrimary,
                title: 'Leads',
                trailing: 'Pipeline, capture',
                onTap: () => context.push('/leads-dashboard'),
              ),
              _MoreRow(
                icon: Icons.notifications_outlined,
                accent: AppColors.warmAmber,
                title: 'Notifications',
                onTap: () => context.push('/notifications'),
              ),
            ],
          ),
          const SizedBox(height: 22),

          _MoreCard(
            children: [
              _MoreRow(
                icon: Icons.swap_horiz,
                accent: AppColors.tealAccent,
                title: 'Switch role',
                trailing: 'Demo',
                onTap: () => _showRoleSwitcher(context),
              ),
              _MoreRow(
                icon: Icons.logout,
                accent: AppColors.errorRed,
                title: 'Sign out',
                onTap: () => context.read<AuthCubit>().logout(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRoleSwitcher(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surfacePrimary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(27)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderDefault,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Switch role',
                  style: AppTextStyles.heading3.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Demo only — see how the app changes per role.',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 16),
                ...[
                  UserRole.rm,
                  UserRole.teamLead,
                  UserRole.branchManager,
                  UserRole.checker,
                  UserRole.admin,
                ].map(
                  (role) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.navyPrimary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        switch (role) {
                          UserRole.rm => Icons.person_outline,
                          UserRole.teamLead => Icons.groups_outlined,
                          UserRole.branchManager => Icons.fact_check_outlined,
                          UserRole.checker => Icons.verified_user_outlined,
                          UserRole.admin => Icons.admin_panel_settings_outlined,
                          _ => Icons.person_outline,
                        },
                        color: AppColors.navyPrimary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      role.label,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      context.read<AuthCubit>().login(role);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String name;
  final UserRole role;
  const _ProfileCard({required this.name, required this.role});

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDefault.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFDBEAFE),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _initials,
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.navyPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: AppTextStyles.heading3.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  role.label,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreCard extends StatelessWidget {
  final List<Widget> children;
  const _MoreCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDefault.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: List.generate(children.length, (i) {
          final isLast = i == children.length - 1;
          return Column(
            children: [
              children[i],
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.only(left: 68),
                  child: Container(
                    height: 1,
                    color: AppColors.borderDefault.withValues(alpha: 0.4),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _MoreRow extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String? trailing;
  final VoidCallback onTap;

  const _MoreRow({
    required this.icon,
    required this.accent,
    required this.title,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailing != null) ...[
                Text(
                  trailing!,
                  style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
                ),
                const SizedBox(width: 6),
              ],
              const Icon(Icons.chevron_right, color: AppColors.textHint, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
