import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../cubit/shell_cubit.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/bottom_nav_bar.dart';
import '../../../clients/presentation/pages/client_list_screen.dart';
import '../../../home/presentation/pages/home_screen.dart';
import 'more_screen.dart';

/// App shell with 4 tabs: Home | Clients | Analytics | More
/// Leads accessible via More → Leads & Prospects
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
            extendBodyBehindAppBar: true,
            resizeToAvoidBottomInset: true,
            body: Stack(
              children: [
                Container(
                  color: AppColors.navyDark,
                  height: MediaQuery.of(context).padding.top + 80,
                ),
                SafeArea(
                  child: Column(
                    children: [
                      AppTopBar(user: user),
                      Expanded(
                        child: IndexedStack(
                          index: currentIndex,
                          children: const [
                            HomeScreen(),
                            ClientListScreen(),
                            _PlaceholderScreen(title: 'Analytics', icon: Icons.analytics),
                            MoreScreen(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: BottomNavBar(
              currentIndex: currentIndex,
              onTap: (index) => context.read<ShellCubit>().updateIndex(index),
            ),
          );
        },
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  const _PlaceholderScreen({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 18, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          const Text('Coming Soon', style: TextStyle(fontSize: 14, color: AppColors.textHint)),
        ],
      ),
    );
  }
}
