import 'package:flutter/material.dart';
import '../../../../core/enums/activity_type.dart';
import '../../../../core/models/activity_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/compass_bottom_sheet.dart';

/// Read-only sheet showing every call the RM has logged for this lead.
/// Entries are sorted newest-first; each row shows date · time · outcome
/// chip · duration · notes (if any) · logged-by.
class CallLogsViewerSheet {
  static Future<void> show(
    BuildContext context, {
    required String leadName,
    required List<ActivityModel> activities,
  }) {
    final calls = activities
        .where((a) => a.type == ActivityType.call)
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return showCompassSheet<void>(
      context,
      title: 'Call logs · $leadName',
      child: _Body(calls: calls),
    );
  }
}

class _Body extends StatelessWidget {
  final List<ActivityModel> calls;
  const _Body({required this.calls});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          calls.isEmpty
              ? 'No calls logged'
              : '${calls.length} call${calls.length == 1 ? '' : 's'} logged',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (calls.isEmpty)
          _emptyState()
        else
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: calls.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _CallRow(call: calls[i]),
            ),
          ),
      ],
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceTertiary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.phone_disabled_outlined,
              size: 20, color: AppColors.textHint),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "No calls have been logged for this lead.",
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CallRow extends StatelessWidget {
  final ActivityModel call;
  const _CallRow({required this.call});

  Color _outcomeColor() {
    final o = call.outcome;
    if (o == null) return AppColors.textHint;
    return o.isPositive ? AppColors.successGreen : AppColors.errorRed;
  }

  @override
  Widget build(BuildContext context) {
    final outcomeColor = _outcomeColor();
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.navyPrimary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.phone_outlined,
                    size: 16, color: AppColors.navyPrimary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${call.dateDisplay} · ${call.timeDisplay}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: const Color(0xFF0F172A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Logged by ${call.loggedByName}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              if (call.outcome != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: outcomeColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: outcomeColor.withValues(alpha: 0.30)),
                  ),
                  child: Text(
                    call.outcome!.label,
                    style: AppTextStyles.caption.copyWith(
                      color: outcomeColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 10.5,
                    ),
                  ),
                ),
            ],
          ),
          if (call.durationMinutes != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule,
                    size: 13, color: AppColors.textMuted),
                const SizedBox(width: 5),
                Text(
                  call.durationDisplay,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          if (call.notes != null && call.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceTertiary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                call.notes!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: const Color(0xFF394150),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
