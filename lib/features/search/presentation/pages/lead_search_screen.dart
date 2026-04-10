import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/models/lead_model.dart';
import '../../../../core/repositories/lead_repository.dart';
import '../../../../routing/route_names.dart';

class LeadSearchScreen extends StatefulWidget {
  const LeadSearchScreen({super.key});

  @override
  State<LeadSearchScreen> createState() => _LeadSearchScreenState();
}

class _LeadSearchScreenState extends State<LeadSearchScreen> {
  final _controller = TextEditingController();
  List<LeadModel> _results = [];
  bool _isSearching = false;
  final List<String> _recentSearches = ['Rajesh', 'Mehta Industries', 'Mumbai'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() => _isSearching = true);
    final repo = getIt<LeadRepository>();
    final result = await repo.getLeads(searchQuery: query, pageSize: 30);
    setState(() {
      _results = result.items;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Leads'),
        backgroundColor: AppColors.navyPrimary,
        foregroundColor: AppColors.textOnDark,
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.surfacePrimary,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              autofocus: true,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: 'Search by name, phone, email, company...',
                hintStyle: AppTextStyles.inputHint,
                prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.textHint),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _results = []);
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.borderDefault),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.borderDefault),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.navyPrimary),
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator(color: AppColors.navyPrimary))
                : _controller.text.isEmpty
                    ? _buildRecentSearches()
                    : _results.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.search_off, size: 48, color: AppColors.textHint),
                                const SizedBox(height: 12),
                                Text('No leads found for "${_controller.text}"', style: AppTextStyles.bodyMedium),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(AppDimensions.screenPadding),
                            itemCount: _results.length,
                            itemBuilder: (context, index) {
                              final lead = _results[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: lead.temperature.color.withValues(alpha: 0.15),
                                  child: Text(
                                    lead.fullName.substring(0, 1),
                                    style: TextStyle(color: lead.temperature.color, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                title: Text(lead.fullName, style: AppTextStyles.labelLarge),
                                subtitle: Text(
                                  '${lead.source.label} · ${lead.stage.label} · Score: ${lead.score}',
                                  style: AppTextStyles.bodySmall,
                                ),
                                trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
                                onTap: () => context.push(RouteNames.leadDetailPath(lead.id)),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearches() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('RECENT SEARCHES', style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1)),
          const SizedBox(height: 12),
          ..._recentSearches.map((term) => ListTile(
                leading: const Icon(Icons.history, color: AppColors.textHint, size: 20),
                title: Text(term, style: AppTextStyles.bodyMedium),
                dense: true,
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  _controller.text = term;
                  _search(term);
                },
              )),
        ],
      ),
    );
  }
}
