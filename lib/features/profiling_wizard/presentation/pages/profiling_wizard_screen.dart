import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/compass_button.dart';
import '../../../../core/widgets/compass_chip.dart';
import '../../../../core/widgets/compass_loader.dart';
import '../../../../core/widgets/compass_section_header.dart';
import '../../../../core/widgets/compass_stepper.dart';
import '../../../../core/widgets/hero_app_bar.dart';
import '../../../../core/widgets/hero_scaffold.dart';
import '../cubit/profiling_cubit.dart';

/// 3-step profiling wizard: criteria → triggers → generate.
/// Mock AI output shown in a results view with scored prospects + talking points.
class ProfilingWizardScreen extends StatelessWidget {
  final String leadId;
  final String leadName;

  const ProfilingWizardScreen({
    super.key,
    required this.leadId,
    required this.leadName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfilingCubit(leadName: leadName),
      child: BlocBuilder<ProfilingCubit, ProfilingState>(
        builder: (context, state) {
          if (state.isComplete) return _ResultsView(state: state);
          if (state.isGenerating) {
            return HeroScaffold(
              header: HeroAppBar.simple(title: 'Generating'),
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CompassLoader(size: 40),
                    const SizedBox(height: 20),
                    Text(
                      'Researching prospects…',
                      style: AppTextStyles.heading3.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Scanning news, deals, filings',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
            );
          }
          return _WizardView(state: state);
        },
      ),
    );
  }
}

class _WizardView extends StatelessWidget {
  final ProfilingState state;
  const _WizardView({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProfilingCubit>();
    return HeroScaffold(
      header: HeroAppBar.simple(title: 'Profiling'),
      bottomBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Row(
            children: [
              if (state.currentStep > 0)
                Expanded(
                  child: CompassButton.secondary(
                    label: 'Back',
                    onPressed: cubit.prevStep,
                  ),
                ),
              if (state.currentStep > 0) const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: CompassButton(
                  label: state.currentStep == 2 ? 'Generate' : 'Next',
                  onPressed: state.canAdvanceStep
                      ? (state.currentStep == 2
                          ? cubit.generate
                          : cubit.nextStep)
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
        children: [
          CompassStepper(
            currentIndex: state.currentStep,
            steps: const [
              CompassStepperItem(label: 'Criteria', icon: Icons.tune),
              CompassStepperItem(label: 'Triggers', icon: Icons.bolt),
              CompassStepperItem(label: 'Generate', icon: Icons.auto_awesome),
            ],
          ),
          const SizedBox(height: 24),
          if (state.currentStep == 0) _Step1(state: state),
          if (state.currentStep == 1) _Step2(state: state),
          if (state.currentStep == 2) _Step3(state: state),
        ],
      ),
    );
  }
}

class _Step1 extends StatelessWidget {
  final ProfilingState state;
  const _Step1({required this.state});

  static const _geos = ['Mumbai', 'Delhi NCR', 'Bangalore', 'Hyderabad', 'Pune', 'Chennai', 'Kolkata', 'Ahmedabad'];
  static const _netWorths = ['₹5 Cr+', '₹25 Cr+', '₹50 Cr+', '₹100 Cr+', '₹500 Cr+'];
  static const _industries = ['Tech/SaaS', 'Pharma', 'Real Estate', 'Manufacturing', 'Financial Services', 'FMCG', 'Media', 'Infrastructure'];

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProfilingCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Geography', style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _geos.map((g) => CompassFilterChip(
                selected: state.geographies.contains(g),
                label: g,
                onTap: () => cubit.toggleGeography(g),
              )).toList(),
        ),
        const SizedBox(height: 20),
        Text('Min. net worth', style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _netWorths.map((n) => CompassChoiceChip<String>(
                value: n,
                groupValue: state.netWorthThreshold,
                label: n,
                onSelected: cubit.setNetWorth,
              )).toList(),
        ),
        const SizedBox(height: 20),
        Text('Industry focus', style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _industries.map((i) => CompassFilterChip(
                selected: state.industries.contains(i),
                label: i,
                onTap: () => cubit.toggleIndustry(i),
              )).toList(),
        ),
      ],
    );
  }
}

class _Step2 extends StatelessWidget {
  final ProfilingState state;
  const _Step2({required this.state});

  static const _triggers = [
    'IPO / Pre-IPO exit',
    'Startup fundraise / exit',
    'Promoter stake sale',
    'Real estate transaction',
    'Executive appointment',
    'Family succession',
    'Professional exit (Big 4, PE/VC)',
    'Bulk/block deal on BSE/NSE',
  ];
  static const _recencies = ['Last 30 days', 'Last 90 days', 'Last 6 months', 'Last 1 year'];

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProfilingCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Wealth trigger events', style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _triggers.map((t) => CompassFilterChip(
                selected: state.triggerEvents.contains(t),
                label: t,
                onTap: () => cubit.toggleTrigger(t),
              )).toList(),
        ),
        const SizedBox(height: 20),
        Text('Recency', style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _recencies.map((r) => CompassChoiceChip<String>(
                value: r,
                groupValue: state.recency,
                label: r,
                onSelected: cubit.setRecency,
              )).toList(),
        ),
      ],
    );
  }
}

class _Step3 extends StatelessWidget {
  final ProfilingState state;
  const _Step3({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CompassSectionHeader(title: 'Review criteria'),
        const SizedBox(height: 12),
        _summaryRow('Geography', state.geographies.join(', ')),
        _summaryRow('Min. net worth', state.netWorthThreshold ?? '—'),
        if (state.industries.isNotEmpty)
          _summaryRow('Industries', state.industries.join(', ')),
        _summaryRow('Triggers', state.triggerEvents.join(', ')),
        _summaryRow('Recency', state.recency ?? 'Any'),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.tealAccent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.tealAccent.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.tealAccent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tap Generate to run AI-powered prospect research based on your criteria.',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.tealAccent),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textHint)),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Results view — scored prospects + talking points
// ────────────────────────────────────────────────────────────────────

class _ResultsView extends StatelessWidget {
  final ProfilingState state;
  const _ResultsView({required this.state});

  @override
  Widget build(BuildContext context) {
    return HeroScaffold(
      header: HeroAppBar.simple(
        title: 'Prospects',
        subtitle: '${state.prospects.length} found',
      ),
      bottomBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: CompassButton(
            label: 'Done',
            onPressed: () => context.pop(),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          const CompassSectionHeader(title: 'Scored prospects'),
          const SizedBox(height: 12),
          ...state.prospects.map((p) => _ProspectCard(prospect: p)),
          const SizedBox(height: 24),
          const CompassSectionHeader(title: 'Talking points'),
          const SizedBox(height: 12),
          ...state.talkingPoints.asMap().entries.map((e) => _TalkingPoint(
                index: e.key + 1,
                text: e.value,
              )),
        ],
      ),
    );
  }
}

class _ProspectCard extends StatelessWidget {
  final dynamic prospect;
  const _ProspectCard({required this.prospect});

  Color get _scoreColor {
    final s = prospect.overallScore as double;
    if (s >= 4) return AppColors.successGreen;
    if (s >= 3) return AppColors.warmAmber;
    return AppColors.errorRed;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDefault.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _scoreColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '#${prospect.rank}',
                    style: AppTextStyles.caption.copyWith(
                      color: _scoreColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prospect.name as String,
                      style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${prospect.city} · ${prospect.industry}',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _scoreColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(prospect.overallScore as double).toStringAsFixed(1)}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: _scoreColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            prospect.estNetWorthRange as String,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.navyPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            prospect.triggerEvent as String,
            style: AppTextStyles.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceContent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline, size: 14, color: AppColors.tealAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    prospect.suggestedOutreachAngle as String,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TalkingPoint extends StatelessWidget {
  final int index;
  final String text;
  const _TalkingPoint({required this.index, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.navyPrimary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$index',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.navyPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: AppTextStyles.bodySmall.copyWith(height: 1.4)),
          ),
        ],
      ),
    );
  }
}
