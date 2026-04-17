import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/compass_bottom_sheet.dart';
import '../../../../core/widgets/hero_scaffold.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

/// More tab — 4x4 icon grid with role-specific tiles.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.currentUser;
    if (user == null) return const SizedBox.shrink();

    return HeroScaffold(
      header: _MoreHeader(name: user.name, role: user.role),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width < 370 ? 3 : 4,
          childAspectRatio: MediaQuery.of(context).size.width < 370 ? 0.6 : 0.7,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: _tilesForRole(context, user.role),
        ),
      ),
    );
  }

  List<Widget> _tilesForRole(BuildContext context, UserRole role) {
    switch (role) {
      case UserRole.rm:
        return [
          _GridTile(icon: Icons.people_alt_outlined, label: 'All leads', onTap: () => context.push('/leads')),
          _GridTile(icon: Icons.person_add_alt_1, label: 'New lead', onTap: () => context.push('/leads/new')),
          _GridTile(icon: Icons.business_center_outlined, label: 'IB leads', onTap: () => context.push('/ib-leads')),
          _GridTile(icon: Icons.move_to_inbox_outlined, label: 'Get lead', onTap: () => context.push('/get-lead')),
          _GridTile(icon: Icons.notifications_outlined, label: 'Notifications', onTap: () => context.push('/notifications')),
          _GridTile(icon: Icons.swap_horiz, label: 'Switch role', onTap: () => _showRoleSwitcher(context)),
        ];
      case UserRole.teamLead:
        return [
          _GridTile(icon: Icons.people_alt_outlined, label: 'All leads', onTap: () => context.push('/leads')),
          _GridTile(icon: Icons.person_add_alt_1, label: 'New lead', onTap: () => context.push('/leads/new')),
          _GridTile(icon: Icons.business_center_outlined, label: 'IB leads', onTap: () => context.push('/ib-leads')),
          _GridTile(icon: Icons.fact_check_outlined, label: 'IB status', onTap: () => context.push('/ib-leads')),
          _GridTile(icon: Icons.swap_horiz, label: 'Switch role', onTap: () => _showRoleSwitcher(context)),
        ];
      case UserRole.admin:
        return [
          _GridTile(icon: Icons.people_alt_outlined, label: 'All leads', onTap: () => context.push('/leads')),
          _GridTile(icon: Icons.inventory_outlined, label: 'Manage pool', onTap: () => context.push('/admin/manage-pool')),
          _GridTile(icon: Icons.dashboard_outlined, label: 'Lead dashboard', onTap: () => context.push('/tl/dashboard')),
          _GridTile(icon: Icons.fact_check_outlined, label: 'IB approvals', onTap: () => context.push('/ib-leads')),
          _GridTile(icon: Icons.swap_horiz, label: 'Switch role', onTap: () => _showRoleSwitcher(context)),
        ];
      case UserRole.ib:
        // IB-1: IB Approval module hidden for IB role. They only see their leads.
        return [
          _GridTile(icon: Icons.business_center_outlined, label: 'IB leads', onTap: () => context.push('/ib-leads')),
          _GridTile(icon: Icons.notifications_outlined, label: 'Notifications', onTap: () => context.push('/notifications')),
          _GridTile(icon: Icons.swap_horiz, label: 'Switch role', onTap: () => _showRoleSwitcher(context)),
        ];
      default:
        return [
          _GridTile(icon: Icons.people_alt_outlined, label: 'All leads', onTap: () => context.push('/leads')),
          _GridTile(icon: Icons.swap_horiz, label: 'Switch role', onTap: () => _showRoleSwitcher(context)),
        ];
    }
  }

  void _showRoleSwitcher(BuildContext context) {
    showCompassSheet(
      context,
      title: 'Switch role',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Demo — see how the app changes per role.', style: AppTextStyles.bodySmall),
          const SizedBox(height: 14),
          ...[UserRole.rm, UserRole.teamLead, UserRole.admin, UserRole.ib]
              .map((role) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.navyPrimary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8.67),
                      ),
                      child: Icon(_iconForRole(role), color: AppColors.navyPrimary, size: 20),
                    ),
                    title: Text(role.label, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                    onTap: () { Navigator.pop(context); context.read<AuthCubit>().login(role); },
                  )),
        ],
      ),
    );
  }

  IconData _iconForRole(UserRole role) => switch (role) {
        UserRole.rm => Icons.person_outline,
        UserRole.teamLead => Icons.groups_outlined,
        UserRole.admin => Icons.admin_panel_settings_outlined,
        UserRole.ib => Icons.business_center_outlined,
        _ => Icons.person_outline,
      };
}

class _GridTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _GridTile({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 73, height: 73,
            decoration: ShapeDecoration(
              color: const Color(0xFFF7F8FF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.67)),
            ),
            child: Icon(icon, size: 28, color: color ?? AppColors.navyPrimary),
          ),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF41414E))),
        ],
      ),
    );
  }
}

class _MoreHeader extends StatelessWidget {
  final String name;
  final UserRole role;
  const _MoreHeader({required this.name, required this.role});

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      color: AppColors.heroBackdrop,
      padding: EdgeInsets.fromLTRB(20, topInset + 14, 20, 20),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: const BoxDecoration(color: Color(0xFFDBEAFE), shape: BoxShape.circle),
            child: Center(child: Text(_initials, style: AppTextStyles.heading3.copyWith(color: AppColors.navyPrimary, fontWeight: FontWeight.w700))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name, style: AppTextStyles.heading3.copyWith(color: Colors.white, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(role.label, style: AppTextStyles.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.65))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
