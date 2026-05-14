import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// Production-grade navy header used by full-screen list views (matches
/// `compass_v2_mobile/lib/core/widgets/header_top_bar.dart` minus the
/// custom decorative painter).
///
/// Layout: navy bg (`#0F1E4A`), back arrow on the left, 23px white title.
/// Bleeds under the status bar via the parent's SafeArea(top: false) when
/// hosted inside [HeroScaffold]; otherwise pads top inset itself.
class HeaderTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final bool useTopInset;

  const HeaderTopBar({
    super.key,
    required this.title,
    this.onBack,
    this.actions,
    this.useTopInset = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(76);

  @override
  Widget build(BuildContext context) {
    final topInset = useTopInset ? MediaQuery.of(context).padding.top : 0.0;
    return Container(
      width: double.infinity,
      color: AppColors.heroBackdrop,
      padding: EdgeInsets.only(top: topInset),
      child: SizedBox(
        height: 76,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back,
                    color: Colors.white, size: 24),
                splashRadius: 22,
              ),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.46,
                  ),
                ),
              ),
              if (actions != null) ...actions!,
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
