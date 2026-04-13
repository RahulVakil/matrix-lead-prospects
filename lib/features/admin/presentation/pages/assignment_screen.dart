import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/mock/mock_data_generators.dart';
import '../../../../core/widgets/hero_app_bar.dart';
import '../../../../core/widgets/hero_scaffold.dart';

class AssignmentScreen extends StatefulWidget {
  const AssignmentScreen({super.key});

  @override
  State<AssignmentScreen> createState() => _AssignmentScreenState();
}

class _AssignmentScreenState extends State<AssignmentScreen> {
  final Set<int> _selectedLeads = {};
  String? _selectedRmId;

  // Mock unassigned leads
  final _unassignedLeads = List.generate(12, (i) => _UnassignedLead(
    name: ['Vikash Mittal', 'Pooja Dalmia', 'Ravi Singhania', 'Anjali Kapoor',
           'Nikhil Joshi', 'Shreya Gupta', 'Sunil Reddy', 'Manisha Patel',
           'Arjun Shah', 'Kriti Bansal', 'Dhruv Mehta', 'Lavanya Iyer'][i],
    source: ['Campaign', 'Website', 'Referral', 'Seminar', 'Campaign', 'IFA',
             'Website', 'Referral', 'Cold Call', 'Campaign', 'IFA', 'Seminar'][i],
    aum: ['₹1.5Cr', '₹50L', 'Unknown', '₹2Cr', '₹25L', '₹80L',
          '₹3Cr', '₹40L', 'Unknown', '₹1Cr', '₹60L', '₹5Cr'][i],
    createdAgo: '${i + 1}h ago',
  ));

  @override
  Widget build(BuildContext context) {
    final rms = MockDataGenerators.allRMs;

    return HeroScaffold(
      header: HeroAppBar.simple(
        title: 'Assign leads',
        subtitle: '${_unassignedLeads.length} unassigned',
        actions: [
          if (_selectedLeads.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Badge(
                label: Text('${_selectedLeads.length}'),
                child: const Icon(Icons.checklist),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // RM selector
          Container(
            color: AppColors.surfacePrimary,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ASSIGN TO RM', style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedRmId,
                  decoration: InputDecoration(
                    hintText: 'Select Relationship Manager',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: rms.map((rm) => DropdownMenuItem(
                    value: rm.id,
                    child: Text('${rm.name} (${rm.branchName})', style: AppTextStyles.bodyMedium),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedRmId = v),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Select all
          Container(
            color: AppColors.surfacePrimary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Checkbox(
                  value: _selectedLeads.length == _unassignedLeads.length,
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        _selectedLeads.addAll(List.generate(_unassignedLeads.length, (i) => i));
                      } else {
                        _selectedLeads.clear();
                      }
                    });
                  },
                  activeColor: AppColors.navyPrimary,
                ),
                Text('Select All (${_unassignedLeads.length} unassigned)', style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          const Divider(height: 1),

          // Lead list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppDimensions.screenPadding),
              itemCount: _unassignedLeads.length,
              itemBuilder: (context, index) {
                final lead = _unassignedLeads[index];
                final isSelected = _selectedLeads.contains(index);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.navyPrimary.withValues(alpha: 0.05) : AppColors.surfacePrimary,
                      borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
                      border: Border.all(
                        color: isSelected ? AppColors.navyPrimary.withValues(alpha: 0.3) : AppColors.cardBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: isSelected,
                          onChanged: (v) {
                            setState(() {
                              if (v == true) {
                                _selectedLeads.add(index);
                              } else {
                                _selectedLeads.remove(index);
                              }
                            });
                          },
                          activeColor: AppColors.navyPrimary,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(lead.name, style: AppTextStyles.labelLarge),
                              Text(
                                '${lead.source}  ·  AUM: ${lead.aum}  ·  ${lead.createdAgo}',
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomBar: _selectedLeads.isNotEmpty && _selectedRmId != null
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.surfacePrimary,
                border: Border(top: BorderSide(color: AppColors.cardBorder)),
              ),
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${_selectedLeads.length} leads assigned successfully!'),
                      backgroundColor: AppColors.successGreen,
                    ),
                  );
                  setState(() => _selectedLeads.clear());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyPrimary,
                  foregroundColor: AppColors.textOnDark,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusFull)),
                ),
                child: Text('Assign ${_selectedLeads.length} Leads', style: AppTextStyles.buttonText),
              ),
            )
          : null,
    );
  }
}

class _UnassignedLead {
  final String name;
  final String source;
  final String aum;
  final String createdAgo;
  _UnassignedLead({required this.name, required this.source, required this.aum, required this.createdAgo});
}
