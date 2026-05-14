import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../widgets/add_bottom_sheet.dart';
import '../widgets/home_calendar_strip.dart';
import '../widgets/leads_at_a_glance_card.dart';
import '../widgets/matrix_top_bar.dart';
import '../widgets/meetings_section.dart';
import '../widgets/tasks_section.dart';

/// MATRIX home screen.
/// Stack:
///   - Navy hero top bar (profile, JM logo, Welcome, bell)
///   - Calendar strip (drives the calendar-aware widgets below)
///   - Rounded white-grey content sheet:
///       1. Tasks rollup (today-anchored — Wealth-CRM module rows)
///       2. Meetings section (filtered to selected date)
///       3. Day Snapshot (calendar-aware — past/today/future modes)
///       4. Leads at a glance (compact, Open dashboard CTA → Leads tab)
///   - FAB → Add bottom sheet (Lead / Get Lead / IB Lead wired)
class MatrixHomeScreen extends StatelessWidget {
  const MatrixHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.currentUser;
    final fullName = user?.name ?? 'Vinit Mehta';

    return Scaffold(
      backgroundColor: AppColors.heroBackdrop,
      floatingActionButton: SizedBox(
        width: 56,
        height: 56,
        child: FloatingActionButton(
          shape: const CircleBorder(),
          backgroundColor: AppColors.navyPrimary,
          onPressed: () => AddBottomSheet.show(context),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MatrixTopBar(name: fullName),
            const HomeCalendarStrip(),
            Expanded(
              child: Container(
                color: AppColors.heroBackdrop,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContent,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28)),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 22, 16, 110),
                      children: const [
                        TasksSection(),
                        SizedBox(height: 22),
                        MeetingsSection(),
                        SizedBox(height: 22),
                        LeadsAtAGlanceCard(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
