import 'package:flutter/material.dart';
import '../../../../core/enums/activity_type.dart';
import '../../../../core/models/activity_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/compass_bottom_sheet.dart';

/// Read-only sheet showing every note the RM has written for this lead.
/// TL has no "add note" path — notes are inherently log entries and the
/// activity log belongs to the RM.
class NoteLogsViewerSheet {
  static Future<void> show(
    BuildContext context, {
    required String leadName,
    required List<ActivityModel> activities,
  }) {
    final notes = activities
        .where((a) => a.type == ActivityType.note)
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return showCompassSheet<void>(
      context,
      title: 'Notes · $leadName',
      child: _Body(notes: notes),
    );
  }
}

class _Body extends StatelessWidget {
  final List<ActivityModel> notes;
  const _Body({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.warmAmber.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: AppColors.warmAmber.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              const Icon(Icons.visibility_outlined,
                  size: 14, color: AppColors.warmAmber),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Read-only · Notes belong to the RM.",
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFF8A4F00),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (notes.isEmpty)
          _emptyState()
        else
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: notes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _NoteRow(note: notes[i]),
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
          const Icon(Icons.note_alt_outlined,
              size: 20, color: AppColors.textHint),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'No notes have been written for this lead.',
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

class _NoteRow extends StatelessWidget {
  final ActivityModel note;
  const _NoteRow({required this.note});

  @override
  Widget build(BuildContext context) {
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
                child: const Icon(Icons.note_alt_outlined,
                    size: 16, color: AppColors.navyPrimary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${note.dateDisplay} · ${note.timeDisplay}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: const Color(0xFF0F172A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Written by ${note.loggedByName}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (note.notes != null && note.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceTertiary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                note.notes!,
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
