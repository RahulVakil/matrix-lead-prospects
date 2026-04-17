import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/models/client_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/avatar_circle.dart';
import '../../../../core/widgets/compass_card.dart';
import '../../../../core/widgets/compass_chip.dart';
import '../../../../core/widgets/compass_empty_state.dart';
import '../../../../core/widgets/compass_loader.dart';
import '../../../../core/widgets/compass_text_field.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/clients_cubit.dart';

/// Role-aware client list:
///   RM    — all clients, no tabs (RM doesn't have reportees).
///   TL    — All / Reportee tabs; each card shows RM name.
///   Admin — all clients, no tabs; each card shows RM name.
///   IB    — never shown (app_shell routes to placeholder).
class ClientListScreen extends StatelessWidget {
  final bool showAll;
  const ClientListScreen({super.key, this.showAll = false});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.currentUser;
    final role = user?.role ?? UserRole.rm;

    // Admin always sees everyone; RM sees own; TL uses filter tabs.
    final rmId = (showAll || role == UserRole.admin) ? null : user?.id;

    return BlocProvider(
      create: (_) => ClientsCubit(rmId: rmId)..load(),
      child: _Body(role: role),
    );
  }
}

class _Body extends StatelessWidget {
  final UserRole role;
  const _Body({required this.role});

  bool get _showTabs => role == UserRole.teamLead;
  bool get _showRmName => role == UserRole.teamLead || role == UserRole.admin;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClientsCubit, ClientsState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.surfaceTertiary,
          body: Column(
            children: [
              Container(
                color: AppColors.surfacePrimary,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: CompassTextField(
                  hint: 'Search by name, code or group',
                  prefixIcon: Icons.search,
                  onChanged: (v) => context.read<ClientsCubit>().search(v),
                ),
              ),
              if (_showTabs)
                Container(
                  color: AppColors.surfacePrimary,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      CompassChoiceChip<ClientsFilter>(
                        value: ClientsFilter.all,
                        groupValue: state.filter,
                        label: 'All',
                        onSelected: context.read<ClientsCubit>().setFilter,
                      ),
                      CompassChoiceChip<ClientsFilter>(
                        value: ClientsFilter.reportee,
                        groupValue: state.filter,
                        label: 'Reportees',
                        onSelected: context.read<ClientsCubit>().setFilter,
                      ),
                    ],
                  ),
                ),
              const Divider(height: 1),
              Expanded(
                child: state.isLoading
                    ? const CompassLoader()
                    : state.clients.isEmpty
                        ? const CompassEmptyState(
                            icon: Icons.people_outline,
                            title: 'No clients found',
                          )
                        : ListView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(14, 14, 14, 96),
                            itemCount: state.clients.length,
                            itemBuilder: (_, i) => _ClientCard(
                              client: state.clients[i],
                              showRmName: _showRmName,
                              onTap: () => context
                                  .push('/clients/${state.clients[i].id}'),
                            ),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ClientCard extends StatelessWidget {
  final ClientModel client;
  final bool showRmName;
  final VoidCallback onTap;

  const _ClientCard({
    required this.client,
    required this.onTap,
    this.showRmName = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CompassCard(
        onTap: onTap,
        child: Row(
          children: [
            AvatarCircle(name: client.fullName),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: Text(client.fullName,
                              style: AppTextStyles.labelLarge,
                              overflow: TextOverflow.ellipsis)),
                      if (client.hasIbLead) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.navyPrimary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('IB',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    showRmName
                        ? '${client.clientCode} · ${client.aumDisplay} · RM: ${client.assignedRmName}'
                        : '${client.clientCode} · ${client.aumDisplay}',
                    style: AppTextStyles.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textHint, size: 18),
          ],
        ),
      ),
    );
  }
}
