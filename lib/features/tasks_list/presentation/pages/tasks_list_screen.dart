import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/enums/ib_deal_type.dart' show IbLeadStatus;
import '../../../../core/enums/user_role.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/header_top_bar.dart';
import '../../../../routing/route_names.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

/// Show-All Tasks list — mirrors compass_v2_mobile/TaskListScreen.
///
/// Scope: this prototype renders ONLY the Wealth CRM module's tasks
/// (EWG / PWG RMs). In the live app this screen would also include
/// production-module tasks (Liquidation, Shortfall, MTF, Nudges,
/// Birthdays) merged in.
class TasksListScreen extends StatelessWidget {
  const TasksListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.currentUser;
    if (user == null) return const SizedBox.shrink();

    final tasks = _buildTasks(context, user);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const HeaderTopBar(title: 'Task List'),
            Expanded(
              child: tasks.isEmpty
                  ? Center(
                      child: Text(
                        'No tasks available',
                        style: GoogleFonts.roboto(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        child: ListView.separated(
                          itemCount: tasks.length,
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, color: Colors.grey.shade300),
                          itemBuilder: (_, i) => _TaskRow(entry: tasks[i]),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<_TaskEntry> _buildTasks(BuildContext context, UserModel user) {
    final isWealthRm = user.role == UserRole.rm &&
        (user.vertical == null ||
            user.vertical == 'EWG' ||
            user.vertical == 'PWG');
    if (!isWealthRm) return const [];

    final list = <_TaskEntry>[];
    void add(String title, int count, _Tier tier, VoidCallback onTap) {
      if (count > 0) list.add(_TaskEntry(title, count, tier, onTap));
    }

    add('Follow-ups overdue', 3, _Tier.actionNow,
        () => context.push(RouteNames.followUpsOverdue));
    add('IB leads sent back', 1, _Tier.actionNow,
        () => context.push(RouteNames.ibLeads,
            extra: {'status': IbLeadStatus.sentBack}));
    add('Follow-ups due today', 4, _Tier.today,
        () => context.push(RouteNames.followUpsToday));

    return list;
  }
}

enum _Tier {
  actionNow,
  today;

  Color get color =>
      this == _Tier.actionNow ? AppColors.errorRed : AppColors.warmAmber;

  IconData get icon => this == _Tier.actionNow
      ? Icons.arrow_upward_rounded
      : Icons.remove_rounded;
}

class _TaskEntry {
  final String title;
  final int count;
  final _Tier tier;
  final VoidCallback onTap;
  _TaskEntry(this.title, this.count, this.tier, this.onTap);
}

class _TaskRow extends StatelessWidget {
  final _TaskEntry entry;
  const _TaskRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: entry.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                entry.title,
                style: GoogleFonts.roboto(
                  color: const Color(0xFF0F172A),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              constraints: const BoxConstraints(minWidth: 28),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFD2D9E5)),
              ),
              child: Text(
                entry.count.toString().padLeft(2, '0'),
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  color: const Color(0xFF394150),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: entry.tier.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(entry.tier.icon, size: 14, color: entry.tier.color),
            ),
          ],
        ),
      ),
    );
  }
}
