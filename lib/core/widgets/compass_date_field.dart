import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'compass_text_field.dart';

class CompassDateField extends StatelessWidget {
  final String? label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? hint;
  final String? errorText;
  final bool isRequired;
  final bool showTime;

  const CompassDateField({
    super.key,
    this.label,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    this.hint,
    this.errorText,
    this.isRequired = false,
    this.showTime = false,
  });

  String _format(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    if (!showTime) return '$d/$m/$y';
    final hh = dt.hour;
    final mm = dt.minute.toString().padLeft(2, '0');
    final period = hh >= 12 ? 'PM' : 'AM';
    final h12 = hh > 12 ? hh - 12 : (hh == 0 ? 12 : hh);
    return '$d/$m/$y · $h12:$mm $period';
  }

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: firstDate ?? DateTime(now.year - 5),
      lastDate: lastDate ?? DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.navyPrimary,
              onPrimary: AppColors.textOnDark,
              surface: AppColors.surfacePrimary,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;

    if (showTime && context.mounted) {
      final t = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(value ?? now),
      );
      if (t == null) return;
      onChanged(DateTime(
        picked.year,
        picked.month,
        picked.day,
        t.hour,
        t.minute,
      ));
    } else {
      onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          RichText(
            text: TextSpan(
              text: label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              children: [
                if (isRequired)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: AppColors.errorRedAlt),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
        ],
        InkWell(
          onTap: () => _pick(context),
          borderRadius: BorderRadius.circular(10),
          child: IgnorePointer(
            child: CompassTextField(
              hint: hint ?? (showTime ? 'Pick date & time' : 'Pick a date'),
              controller: TextEditingController(text: value != null ? _format(value!) : ''),
              prefixIcon: Icons.calendar_today_outlined,
              errorText: errorText,
              readOnly: true,
            ),
          ),
        ),
      ],
    );
  }
}
