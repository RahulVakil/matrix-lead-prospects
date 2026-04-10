import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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

class ClientListScreen extends StatelessWidget {
  const ClientListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.currentUser;
    return BlocProvider(
      create: (_) => ClientsCubit(rmId: user?.id)..load(),
      child: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

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
                      value: ClientsFilter.direct,
                      groupValue: state.filter,
                      label: 'Direct',
                      onSelected: context.read<ClientsCubit>().setFilter,
                    ),
                    CompassChoiceChip<ClientsFilter>(
                      value: ClientsFilter.reportee,
                      groupValue: state.filter,
                      label: 'Reportee',
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
                            padding: const EdgeInsets.fromLTRB(14, 14, 14, 96),
                            itemCount: state.clients.length,
                            itemBuilder: (_, i) => _ClientCard(
                              client: state.clients[i],
                              onTap: () =>
                                  context.push('/clients/${state.clients[i].id}'),
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
  final VoidCallback onTap;

  const _ClientCard({required this.client, required this.onTap});

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
                  Text(client.fullName, style: AppTextStyles.labelLarge),
                  const SizedBox(height: 2),
                  Text(
                    '${client.clientCode} · ${client.aumDisplay}',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textHint, size: 18),
          ],
        ),
      ),
    );
  }
}
