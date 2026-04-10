import 'package:flutter/material.dart';
import 'package:stylish_bottom_bar/stylish_bottom_bar.dart';
import '../../../../core/theme/app_colors.dart';

/// 4 tabs matching compass_v2_mobile: Home | Clients | Analytics | More
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return StylishBottomBar(
      currentIndex: currentIndex.clamp(0, 3),
      onTap: onTap,
      option: AnimatedBarOptions(
        iconStyle: IconStyle.animated,
      ),
      items: [
        BottomBarItem(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          title: const Text('Home'),
          selectedColor: AppColors.navyPrimary,
          unSelectedColor: const Color(0xFF5E5F60),
        ),
        BottomBarItem(
          icon: const Icon(Icons.people_outline),
          selectedIcon: const Icon(Icons.people),
          title: const Text('Clients'),
          selectedColor: AppColors.navyPrimary,
          unSelectedColor: const Color(0xFF5E5F60),
        ),
        BottomBarItem(
          icon: const Icon(Icons.analytics_outlined),
          selectedIcon: const Icon(Icons.analytics),
          title: const Text('Analytics'),
          selectedColor: AppColors.navyPrimary,
          unSelectedColor: const Color(0xFF5E5F60),
        ),
        BottomBarItem(
          icon: const Icon(Icons.more_horiz),
          selectedIcon: const Icon(Icons.more_horiz),
          title: const Text('More'),
          selectedColor: AppColors.navyPrimary,
          unSelectedColor: const Color(0xFF5E5F60),
        ),
      ],
    );
  }
}
