import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

/// Compass-aligned screen scaffold:
/// - Navy backdrop (#0F1E4A) bleeds behind status bar
/// - SafeArea(top: false) so the navy paints under the system bar
/// - Custom hero header is the FIRST child of a Column body (not Scaffold.appBar)
/// - The remaining body sits inside a soft-gray (#E8EDF3) sheet with 28px top
///   radius, giving the "content sheet on dark background" effect
///
/// Mirrors HomeDashboardContent in compass_v2_mobile lines 113-124.
class HeroScaffold extends StatelessWidget {
  final Widget header;        // hero header widget (HeroAppBar or custom)
  final Widget body;          // sheet content (will be wrapped in the soft-gray sheet)
  final Widget? bottomBar;    // optional bottom action bar
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool resizeToAvoidBottomInset;

  const HeroScaffold({
    super.key,
    required this.header,
    required this.body,
    this.bottomBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.heroBackdrop,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.heroBackdrop,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
        bottomNavigationBar: bottomBar,
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              header,
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
                      child: body,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
