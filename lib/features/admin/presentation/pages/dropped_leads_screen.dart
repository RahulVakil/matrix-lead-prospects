import 'package:flutter/material.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/lead_stage.dart';
import '../../../../core/models/lead_model.dart';
import '../../../../core/repositories/lead_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/compass_button.dart';
import '../../../../core/widgets/compass_empty_state.dart';
import '../../../../core/widgets/compass_loader.dart';
import '../../../../core/widgets/compass_snackbar.dart';
import '../../../../core/widgets/hero_app_bar.dart';
import '../../../../core/widgets/hero_scaffold.dart';

/// Admin/MIS review screen for dropped leads.
/// Can approve returning a dropped lead to the Get Lead pool.
class DroppedLeadsScreen extends StatefulWidget {
  const DroppedLeadsScreen({super.key});

  @override
  State<DroppedLeadsScreen> createState() => _DroppedLeadsScreenState();
}

class _DroppedLeadsScreenState extends State<DroppedLeadsScreen> {
  final _repo = getIt<LeadRepository>();
  List<LeadModel> _dropped = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _dropped = await _repo.getDroppedLeads();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _returnToPool(LeadModel lead) async {
    await _repo.returnDroppedToPool(lead.id);
    if (mounted) {
      showCompassSnack(
        context,
        message: '${lead.fullName} returned to pool',
        type: CompassSnackType.success,
      );
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return HeroScaffold(
      header: HeroAppBar.simple(
        title: 'Dropped leads',
        subtitle: '${_dropped.length} for review',
      ),
      body: _loading
          ? const Center(child: CompassLoader())
          : _dropped.isEmpty
              ? const CompassEmptyState(
                  icon: Icons.check_circle_outline,
                  title: 'No dropped leads',
                  subtitle: 'All leads are active in the pipeline',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: _dropped.length,
                  itemBuilder: (_, i) => _DroppedCard(
                    lead: _dropped[i],
                    onReturnToPool: () => _returnToPool(_dropped[i]),
                  ),
                ),
    );
  }
}

class _DroppedCard extends StatelessWidget {
  final LeadModel lead;
  final VoidCallback onReturnToPool;

  const _DroppedCard({required this.lead, required this.onReturnToPool});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  lead.fullName,
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (lead.droppedAt != null)
                Text(
                  '${lead.droppedAt!.day}/${lead.droppedAt!.month}/${lead.droppedAt!.year}',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.remove_circle_outline, size: 14, color: AppColors.errorRed),
              const SizedBox(width: 6),
              Text(
                'Reason: ${lead.dropReason?.label ?? 'Unknown'}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.errorRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (lead.dropNotes != null && lead.dropNotes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              lead.dropNotes!,
              style: AppTextStyles.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'RM: ${lead.assignedRmName}',
                style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
              ),
              if (lead.previousStage != null) ...[
                Text(
                  ' · Was at: ${lead.previousStage!.label}',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: CompassButton(
                  label: 'Return to pool',
                  icon: Icons.replay,
                  onPressed: onReturnToPool,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
