import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Compass-aligned bottom sheet helper. 27px top radius, white bg, drag handle,
/// SafeArea bottom, scroll-friendly.
Future<T?> showCompassSheet<T>(
  BuildContext context, {
  required Widget child,
  String? title,
  bool isDismissible = true,
  bool isScrollControlled = true,
  EdgeInsets padding = const EdgeInsets.fromLTRB(20, 12, 20, 24),
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    backgroundColor: Colors.transparent,
    builder: (_) => CompassBottomSheet(
      title: title,
      padding: padding,
      child: child,
    ),
  );
}

class CompassBottomSheet extends StatelessWidget {
  final Widget child;
  final String? title;
  final EdgeInsets padding;

  const CompassBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 24),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(27)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: padding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderDefault,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (title != null) ...[
                  const SizedBox(height: 16),
                  Text(title!, style: AppTextStyles.heading3),
                ],
                const SizedBox(height: 16),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
