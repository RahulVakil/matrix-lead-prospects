import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/client_master_record.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/avatar_circle.dart';
import '../../../../core/widgets/compass_app_bar.dart';
import '../../../../core/widgets/compass_button.dart';
import '../../../../core/widgets/compass_card.dart';
import '../../../../core/widgets/compass_chip.dart';
import '../../../../core/widgets/compass_empty_state.dart';
import '../../../../core/widgets/compass_loader.dart';
import '../../../../core/widgets/compass_text_field.dart';
import '../cubit/coverage_cubit.dart';

class CoverageCheckScreen extends StatelessWidget {
  const CoverageCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CoverageCubit(),
      child: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CoverageCubit, CoverageState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.surfaceTertiary,
          appBar: const CompassAppBar(
            title: 'Coverage Check',
            subtitle: 'Search Client Master, Company Master, Lead List',
          ),
          body: Column(
            children: [
              Container(
                color: AppColors.surfacePrimary,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      children: [
                        CompassChoiceChip<CoverageSearchMode>(
                          value: CoverageSearchMode.name,
                          groupValue: state.mode,
                          label: 'Name search',
                          onSelected: context.read<CoverageCubit>().switchMode,
                        ),
                        CompassChoiceChip<CoverageSearchMode>(
                          value: CoverageSearchMode.group,
                          groupValue: state.mode,
                          label: 'Group / Company',
                          onSelected: context.read<CoverageCubit>().switchMode,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (state.mode == CoverageSearchMode.name) ...[
                      Row(
                        children: [
                          Expanded(
                            child: CompassTextField(
                              label: 'First name',
                              hint: 'e.g. Rajesh',
                              onChanged: context.read<CoverageCubit>().setFirstName,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: CompassTextField(
                              label: 'Last name (optional)',
                              hint: 'e.g. Mehta',
                              onChanged: context.read<CoverageCubit>().setLastName,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      CompassTextField(
                        label: 'Group / Company',
                        hint: 'e.g. Tata Consultancy',
                        onChanged: context.read<CoverageCubit>().setGroupQuery,
                      ),
                    ],
                    const SizedBox(height: 14),
                    CompassButton(
                      label: 'Search',
                      icon: Icons.search,
                      onPressed: () => context.read<CoverageCubit>().search(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: state.isSearching
                    ? const CompassLoader()
                    : !state.hasSearched
                        ? const CompassEmptyState(
                            icon: Icons.shield_outlined,
                            title: 'Check coverage before capture',
                            subtitle:
                                'Search by name or company to see if a prospect is already covered.',
                          )
                        : state.results.isEmpty
                            ? CompassEmptyState(
                                icon: Icons.check_circle_outline,
                                title: 'No coverage found',
                                subtitle: 'Safe to capture as a new lead.',
                                ctaLabel: 'Capture lead',
                                onCtaTap: () => context.push('/leads/new'),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
                                itemCount: state.results.length,
                                itemBuilder: (_, i) => _ResultCard(record: state.results[i]),
                              ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ResultCard extends StatelessWidget {
  final ClientMasterRecord record;
  const _ResultCard({required this.record});

  Color get _sourceColor => switch (record.source) {
        CoverageSource.clientMaster => AppColors.successGreen,
        CoverageSource.companyMaster => AppColors.navyPrimary,
        CoverageSource.leadList => AppColors.warmAmber,
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CompassCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AvatarCircle(name: record.clientName),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.clientName, style: AppTextStyles.labelLarge),
                  if (record.groupName != null) ...[
                    const SizedBox(height: 2),
                    Text(record.groupName!, style: AppTextStyles.bodySmall),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _sourceColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          record.source.label,
                          style: AppTextStyles.caption.copyWith(
                            color: _sourceColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (record.rmName != null)
                        Text(
                          'RM: ${record.rmName}',
                          style: AppTextStyles.caption,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
