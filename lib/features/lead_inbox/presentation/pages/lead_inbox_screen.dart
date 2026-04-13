import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/enums/lead_stage.dart';
import '../../../../core/enums/lead_temperature.dart';
import '../../../../core/models/lead_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/compass_chip.dart';
import '../../../../core/widgets/compass_text_field.dart';
import '../../../../core/widgets/hero_app_bar.dart';
import '../../../../core/widgets/hero_scaffold.dart';
import '../../../../routing/route_names.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/lead_inbox_cubit.dart';

/// All Leads listing — alphabetical default, temperature + stage filters,
/// sort selector, search, IB convert action per card.
class LeadInboxScreen extends StatelessWidget {
  const LeadInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.currentUser;
    if (user == null) return const SizedBox.shrink();

    return BlocProvider(
      create: (_) => LeadInboxCubit(rmId: user.id)..loadLeads(refresh: true),
      child: const _InboxBody(),
    );
  }
}

class _InboxBody extends StatefulWidget {
  const _InboxBody();

  @override
  State<_InboxBody> createState() => _InboxBodyState();
}

class _InboxBodyState extends State<_InboxBody> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeadInboxCubit, LeadInboxState>(
      builder: (context, state) {
        final cubit = context.read<LeadInboxCubit>();
        return HeroScaffold(
          header: HeroAppBar.simple(title: 'All leads', subtitle: '${state.totalCount} total'),
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppColors.navyPrimary,
            onPressed: () => context.push('/leads/new'),
            child: const Icon(Icons.add, color: Colors.white),
          ),
          body: Column(
            children: [
              // Search
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                child: CompassTextField(
                  controller: _searchCtrl,
                  hint: 'Search by name, phone, company…',
                  prefixIcon: Icons.search,
                  onChanged: cubit.search,
                ),
              ),

              // Temperature filter chips
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  children: [
                    _chip('All', state.temperatureFilter == null,
                        () => cubit.setTemperatureFilter(null)),
                    ...LeadTemperature.values
                        .where((t) => t != LeadTemperature.dormant)
                        .map((t) => _chip(
                              t.label,
                              state.temperatureFilter == t,
                              () => cubit.setTemperatureFilter(t),
                              color: t.color,
                              count: state.temperatureCounts[t],
                            )),
                  ],
                ),
              ),

              // Stage filter chips
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  children: [
                    _chip('All stages', state.stageFilter == null,
                        () => cubit.setStageFilter(null)),
                    ...LeadStage.activePipeline.map((s) => _chip(
                          s.label,
                          state.stageFilter == s,
                          () => cubit.setStageFilter(s),
                          color: s.color,
                        )),
                  ],
                ),
              ),

              // Sort
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
                child: Row(
                  children: [
                    Text('Sort: ', style: AppTextStyles.caption),
                    const SizedBox(width: 4),
                    DropdownButton<String>(
                      value: state.sortBy ?? 'name',
                      underline: const SizedBox.shrink(),
                      isDense: true,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.navyPrimary,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'name', child: Text('Name A-Z')),
                        DropdownMenuItem(value: 'score', child: Text('Score')),
                        DropdownMenuItem(value: 'lastActivity', child: Text('Last activity')),
                        DropdownMenuItem(value: 'aum', child: Text('AUM')),
                        DropdownMenuItem(value: 'created', child: Text('Created')),
                      ],
                      onChanged: (v) {
                        if (v != null) cubit.setSort(v);
                      },
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // List
              Expanded(
                child: state.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.navyPrimary,
                        ),
                      )
                    : state.leads.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.inbox_outlined,
                                    size: 44, color: AppColors.textHint),
                                const SizedBox(height: 12),
                                Text('No leads match',
                                    style: AppTextStyles.bodyLarge),
                                const SizedBox(height: 4),
                                TextButton(
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    cubit.setTemperatureFilter(null);
                                    cubit.setStageFilter(null);
                                    cubit.search('');
                                  },
                                  child: const Text('Clear filters'),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            color: AppColors.navyPrimary,
                            onRefresh: () => cubit.loadLeads(refresh: true),
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(14, 10, 14, 96),
                              itemCount: state.leads.length,
                              itemBuilder: (_, i) => _LeadCard(
                                lead: state.leads[i],
                                onTap: () => context.push(
                                  RouteNames.leadDetailPath(state.leads[i].id),
                                ),
                                onConvertIB: () => context.push(
                                  '/ib-leads/new',
                                  extra: {
                                    'clientName': state.leads[i].fullName,
                                    'companyName': state.leads[i].companyName,
                                  },
                                ),
                              ),
                            ),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap,
      {Color? color, int? count}) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: CompassFilterChip(
        selected: selected,
        label: count != null ? '$label $count' : label,
        onTap: onTap,
        color: color,
      ),
    );
  }
}

class _LeadCard extends StatelessWidget {
  final LeadModel lead;
  final VoidCallback onTap;
  final VoidCallback onConvertIB;

  const _LeadCard({
    required this.lead,
    required this.onTap,
    required this.onConvertIB,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.borderDefault.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                // Temperature bar
                Container(
                  width: 3,
                  height: 40,
                  decoration: BoxDecoration(
                    color: lead.temperature.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lead.fullName,
                              style: AppTextStyles.labelLarge.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: lead.stage.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              lead.stage.label,
                              style: AppTextStyles.caption.copyWith(
                                color: lead.stage.color,
                                fontWeight: FontWeight.w700,
                                fontSize: 10.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${lead.source.label} · ${lead.lastContactDisplay}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textHint,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textHint),
                  padding: EdgeInsets.zero,
                  onSelected: (v) {
                    if (v == 'ib') onConvertIB();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'ib',
                      child: Text('Convert to IB lead'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
