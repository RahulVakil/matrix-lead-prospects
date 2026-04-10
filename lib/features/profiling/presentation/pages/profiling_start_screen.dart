import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/constants/app_dimensions.dart';

class ProfilingStartScreen extends StatefulWidget {
  final String leadId;
  final String leadName;

  const ProfilingStartScreen({super.key, required this.leadId, this.leadName = ''});

  @override
  State<ProfilingStartScreen> createState() => _ProfilingStartScreenState();
}

class _ProfilingStartScreenState extends State<ProfilingStartScreen> {
  final _panController = TextEditingController();
  bool _kycReady = false;
  bool _riskProfileDone = false;
  bool _suitabilityDone = false;
  bool _sourceOfFundsDone = false;

  @override
  void dispose() {
    _panController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Start Profiling'),
        backgroundColor: AppColors.navyPrimary,
        foregroundColor: AppColors.textOnDark,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.tealAccent.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.tealAccent.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.tealAccent, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Complete the profiling checklist below to submit for checker review.',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.tealAccent),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text('IDENTITY VERIFICATION', style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1)),
          const SizedBox(height: 12),

          TextFormField(
            controller: _panController,
            decoration: AppDecorations.inputDecoration(
              label: 'PAN Number *',
              hint: 'e.g. ABCDE1234F',
            ),
            textCapitalization: TextCapitalization.characters,
            maxLength: 10,
          ),
          const SizedBox(height: 24),

          Text('CHECKLIST', style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1)),
          const SizedBox(height: 12),

          _checklistItem('KYC Documents Collected', _kycReady, (v) => setState(() => _kycReady = v ?? false)),
          _checklistItem('Risk Profile Assessment', _riskProfileDone, (v) => setState(() => _riskProfileDone = v ?? false)),
          _checklistItem('Suitability Questionnaire', _suitabilityDone, (v) => setState(() => _suitabilityDone = v ?? false)),
          _checklistItem('Source of Funds Documented', _sourceOfFundsDone, (v) => setState(() => _sourceOfFundsDone = v ?? false)),
          const SizedBox(height: 24),

          Text('DOCUMENT UPLOAD', style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1)),
          const SizedBox(height: 12),

          _uploadTile('PAN Card', false),
          const SizedBox(height: 8),
          _uploadTile('Address Proof', false),
          const SizedBox(height: 8),
          _uploadTile('Bank Statement', false),
          const SizedBox(height: 8),
          _uploadTile('Photograph', false),
          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Draft saved'), backgroundColor: AppColors.tealAccent),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusFull)),
                  ),
                  child: const Text('Save Draft'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _canSubmit ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.tealAccent,
                    foregroundColor: AppColors.textOnDark,
                    disabledBackgroundColor: AppColors.disabledButton,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusFull)),
                  ),
                  child: Text('Submit for Review', style: AppTextStyles.buttonText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  bool get _canSubmit =>
      _panController.text.length == 10 && _kycReady && _riskProfileDone && _suitabilityDone && _sourceOfFundsDone;

  Widget _checklistItem(String label, bool value, ValueChanged<bool?> onChanged) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      title: Text(label, style: AppTextStyles.bodyMedium),
      activeColor: AppColors.tealAccent,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
    );
  }

  Widget _uploadTile(String label, bool uploaded) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: uploaded ? AppColors.successGreen : AppColors.borderDefault),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            uploaded ? Icons.check_circle : Icons.upload_file,
            color: uploaded ? AppColors.successGreen : AppColors.textHint,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('File upload simulated'), backgroundColor: AppColors.tealAccent),
              );
            },
            child: Text(uploaded ? 'Replace' : 'Upload', style: AppTextStyles.labelSmall.copyWith(color: AppColors.tealAccent)),
          ),
        ],
      ),
    );
  }

  void _submit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profiling submitted for review!'), backgroundColor: AppColors.successGreen),
    );
    Navigator.pop(context);
  }
}
