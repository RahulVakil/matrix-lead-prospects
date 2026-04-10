import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/enums/lead_temperature.dart';
import '../../../../core/models/lead_model.dart';
import '../../../../routing/route_names.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/lead_inbox_cubit.dart';

class LeadInboxScreen extends StatelessWidget {
  const LeadInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.currentUser;
    if (user == null) return const SizedBox.shrink();

    return BlocProvider(
      create: (_) => LeadInboxCubit(rmId: user.id)..loadLeads(refresh: true),
      child: const _LeadInboxBody(),
    );
  }
}

class _LeadInboxBody extends StatefulWidget {
  const _LeadInboxBody();

  @override
  State<_LeadInboxBody> createState() => _LeadInboxBodyState();
}

class _LeadInboxBodyState extends State<_LeadInboxBody> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeadInboxCubit, LeadInboxState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.surfaceTertiary,
          appBar: AppBar(
            title: const Text('Leads'),
            backgroundColor: AppColors.navyPrimary,
            foregroundColor: AppColors.textOnDark,
            elevation: 0,
          ),
          body: Column(
            children: [
              Container(
                color: AppColors.surfacePrimary,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (q) => context.read<LeadInboxCubit>().search(q),
                  decoration: AppDecorations.inputDecoration(
                    label: '',
                    hint: 'Search by name or phone',
                    suffixIcon: const Icon(Icons.search, color: AppColors.textHint),
                  ).copyWith(
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  style: AppTextStyles.bodyMedium,
                ),
              ),
              Container(
                color: AppColors.surfacePrimary,
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip(context, state, null, 'All', state.totalCount),
                      ...LeadTemperature.values
                          .where((t) => t != LeadTemperature.dormant)
                          .map((t) => _filterChip(
                                context,
                                state,
                                t,
                                t.label,
                                state.temperatureCounts[t] ?? 0,
                              )),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.navyPrimary))
                    : state.leads.isEmpty
                        ? _emptyState(context)
                        : RefreshIndicator(
                            color: AppColors.navyPrimary,
                            onRefresh: () => context.read<LeadInboxCubit>().loadLeads(refresh: true),
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                              itemCount: state.leads.length,
                              itemBuilder: (context, index) {
                                return _LeadListTile(
                                  lead: state.leads[index],
                                  onTap: () => context.push(RouteNames.leadDetailPath(state.leads[index].id)),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/leads/new'),
            backgroundColor: AppColors.navyPrimary,
            icon: const Icon(Icons.add, color: AppColors.textOnDark),
            label: Text('New Lead', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textOnDark)),
          ),
        );
      },
    );
  }

  Widget _filterChip(BuildContext context, LeadInboxState state, LeadTemperature? temp, String label, int count) {
    final isSelected = (state.temperatureFilter == temp) && (temp != null || state.temperatureFilter == null);
    final color = temp?.color ?? AppColors.navyPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        selected: isSelected,
        showCheckmark: false,
        label: Text('$label  $count'),
        onSelected: (_) => context.read<LeadInboxCubit>().setTemperatureFilter(temp),
        selectedColor: color.withValues(alpha: 0.15),
        backgroundColor: AppColors.surfaceTertiary,
        labelStyle: AppTextStyles.bodySmall.copyWith(
          color: isSelected ? color : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
        shape: const StadiumBorder(),
        side: BorderSide(
          color: isSelected ? color.withValues(alpha: 0.4) : AppColors.borderDefault,
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined, size: 44, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text('No leads match', style: AppTextStyles.bodyLarge),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () {
                _searchController.clear();
                context.read<LeadInboxCubit>().setTemperatureFilter(null);
                context.read<LeadInboxCubit>().search('');
              },
              child: const Text('Clear filters'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeadListTile extends StatelessWidget {
  final LeadModel lead;
  final VoidCallback onTap;

  const _LeadListTile({required this.lead, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: lead.temperature.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        lead.fullName,
                        style: AppTextStyles.labelLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lead.lastContactDisplay,
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: lead.stage.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    lead.stage.label,
                    style: AppTextStyles.caption.copyWith(
                      color: lead.stage.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
