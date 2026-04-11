import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../cubit/shell_cubit.dart';
import '../widgets/bottom_nav_bar.dart';
import '../../../clients/presentation/pages/client_list_screen.dart';
import '../../../home/presentation/pages/home_screen.dart';
import 'more_screen.dart';

/// AppShell: only owns the bottom nav. Each tab is a full-screen with its own
/// custom hero header. Mirrors compass_v2_mobile dashboard tab structure.
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
          return Scaffold(
            backgroundColor: AppColors.heroBackdrop,
            body: IndexedStack(
              index: currentIndex,
              children: const [
                HomeScreen(),
                ClientListScreen(),
                _PlaceholderTab(title: 'Analytics', icon: Icons.analytics_outlined),
                MoreScreen(),
              ],
            ),
            bottomNavigationBar: BottomNavBar(
              currentIndex: currentIndex,
              onTap: (i) => context.read<ShellCubit>().updateIndex(i),
            ),
          );
        },
      ),
    );
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
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Coming soon',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
