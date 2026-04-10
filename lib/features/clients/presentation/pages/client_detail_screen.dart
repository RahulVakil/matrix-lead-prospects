import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/models/client_model.dart';
import '../../../../core/repositories/client_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/inr_formatter.dart';
import '../../../../core/widgets/avatar_circle.dart';
import '../../../../core/widgets/compass_app_bar.dart';
import '../../../../core/widgets/compass_button.dart';
import '../../../../core/widgets/compass_card.dart';
import '../../../../core/widgets/compass_loader.dart';
import '../../../../core/widgets/compass_section_header.dart';

class ClientDetailScreen extends StatefulWidget {
  final String clientId;
  const ClientDetailScreen({super.key, required this.clientId});

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  ClientModel? _client;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final client = await getIt<ClientRepository>().getClientById(widget.clientId);
    if (!mounted) return;
    setState(() {
      _client = client;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        appBar: CompassAppBar(title: 'Client'),
        body: CompassLoader(),
      );
    }
    if (_client == null) {
      return const Scaffold(
        appBar: CompassAppBar(title: 'Client'),
        body: Center(child: Text('Client not found')),
      );
    }

    final c = _client!;
    return Scaffold(
      backgroundColor: AppColors.surfaceTertiary,
      appBar: CompassAppBar(title: c.fullName, subtitle: c.clientCode),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
        children: [
          CompassCard(
            child: Row(
              children: [
                AvatarCircle(name: c.fullName, size: 56),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(c.fullName, style: AppTextStyles.heading3),
                      const SizedBox(height: 4),
                      Text(
                        IndianCurrencyFormatter.shortForm(c.aum),
                        style: AppTextStyles.heading2.copyWith(
                          color: AppColors.navyPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        c.isDirect ? 'Direct relationship' : 'Reportee',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          CompassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CompassSectionHeader(title: 'Details'),
                const SizedBox(height: 10),
                _row('Client Code', c.clientCode),
                if (c.groupName != null) _row('Group', c.groupName!),
                if (c.phone != null) _row('Phone', c.phone!),
                if (c.email != null) _row('Email', c.email!),
                if (c.city != null) _row('City', c.city!),
                if (c.products.isNotEmpty) _row('Products', c.products.join(', ')),
                _row('RM', c.assignedRmName),
                _row('Onboarded', '${c.onboardedAt.day}/${c.onboardedAt.month}/${c.onboardedAt.year}'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          CompassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CompassSectionHeader(title: 'Actions'),
                const SizedBox(height: 12),
                CompassButton(
                  label: 'Capture IB Lead',
                  icon: Icons.business_center,
                  onPressed: () => context.push(
                    '/ib-leads/new',
                    extra: {
                      'clientName': c.fullName,
                      'clientCode': c.clientCode,
                      'companyName': c.groupName,
                    },
                  ),
                ),
                const SizedBox(height: 10),
                CompassButton.secondary(
                  label: 'Run Coverage Check',
                  icon: Icons.shield_outlined,
                  onPressed: () => context.push('/coverage'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: AppTextStyles.bodySmall),
          ),
          Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }
}
