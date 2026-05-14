import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/bottom_nav_bar.dart';

/// AppShellScaffold — the persistent shell wrapped around all main app
/// routes via StatefulShellRoute.indexedStack. Bottom nav stays visible
/// through every push within a branch (e.g. Home → Leads list → Lead
/// detail) so users always have a way back to other tabs.
///
/// Per-tab navigation state is preserved by the StatefulNavigationShell
/// (each branch keeps its own back stack across tab switches).
class AppShellScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShellScaffold({super.key, required this.navigationShell});

  void _onTap(int index) {
    // Tap on the active tab → reset that branch's stack to its initial route
    // (matches the default mobile-app expectation: re-tapping Home goes back
    // to the Home root rather than no-op).
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.heroBackdrop,
      body: navigationShell,
      bottomNavigationBar: BottomNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
      ),
    );
  }
}
