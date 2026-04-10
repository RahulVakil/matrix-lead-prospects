import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class CompassChoiceChip<T> extends StatelessWidget {
  final T value;
  final T? groupValue;
  final String label;
  final ValueChanged<T> onSelected;
  final IconData? icon;
  final Color? color;

  const CompassChoiceChip({
    super.key,
    required this.value,
    required this.groupValue,
    required this.label,
    required this.onSelected,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    final chipColor = color ?? AppColors.navyPrimary;
    return ChoiceChip(
      selected: selected,
      showCheckmark: false,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: selected ? chipColor : AppColors.textSecondary),
            const SizedBox(width: 4),
          ],
          Text(label),
        ],
      ),
      onSelected: (_) => onSelected(value),
      selectedColor: chipColor.withValues(alpha: 0.12),
      backgroundColor: AppColors.surfaceTertiary,
      labelStyle: AppTextStyles.bodySmall.copyWith(
        color: selected ? chipColor : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      ),
      shape: const StadiumBorder(),
      side: BorderSide(
        color: selected ? chipColor.withValues(alpha: 0.4) : AppColors.borderDefault,
      ),
    );
  }
}

class CompassFilterChip extends StatelessWidget {
  final bool selected;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final int? count;

  const CompassFilterChip({
    super.key,
    required this.selected,
    required this.label,
    required this.onTap,
    this.color,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.navyPrimary;
    return FilterChip(
      selected: selected,
      showCheckmark: false,
      label: Text(count != null ? '$label  $count' : label),
      onSelected: (_) => onTap(),
      selectedColor: chipColor.withValues(alpha: 0.15),
      backgroundColor: AppColors.surfaceTertiary,
      labelStyle: AppTextStyles.bodySmall.copyWith(
        color: selected ? chipColor : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      ),
      shape: const StadiumBorder(),
      side: BorderSide(
        color: selected ? chipColor.withValues(alpha: 0.4) : AppColors.borderDefault,
      ),
    );
  }
}
