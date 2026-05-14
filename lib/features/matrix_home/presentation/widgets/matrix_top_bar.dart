import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../routing/route_names.dart';

/// MATRIX home top bar — mirrors compass_v2_mobile/home_top_bar.dart exactly.
/// Layout: [profile circle] [JM logo] [Welcome!] [spacer] [bell + red dot]
/// Sits on the navy backdrop (#0F1E4A) and bleeds under the status bar via
/// the parent HeroScaffold's SafeArea(top: false).
class MatrixTopBar extends StatelessWidget {
  final String name;
  const MatrixTopBar({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topInset = MediaQuery.of(context).padding.top;
    final height = size.height <= 667 ? size.height * 0.12 : size.height * 0.10;

    return Container(
      color: AppColors.heroBackdrop,
      padding: EdgeInsets.only(top: topInset),
      child: SizedBox(
        height: height - topInset,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              _profileCircle(name),
              const SizedBox(width: 12),
              SvgPicture.asset(
                'assets/images/jm-logo.svg',
                height: 20,
                colorFilter:
                    const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
              const SizedBox(width: 10),
              Text(
                'Welcome!',
                style: GoogleFonts.roboto(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: () => context.push(RouteNames.notifications),
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDA251D),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileCircle(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : (name.isNotEmpty ? name[0].toUpperCase() : '?');
    return CircleAvatar(
      radius: 20,
      backgroundColor: const Color(0xFFDBEAFE),
      child: Text(
        initials,
        style: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.navyPrimary,
          height: 1.3,
        ),
      ),
    );
  }
}
