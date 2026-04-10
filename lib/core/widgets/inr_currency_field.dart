import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/inr_formatter.dart';
import 'compass_text_field.dart';

/// Currency input field for Indian Rupees with live formatting (lakh/crore
/// grouping) and a "value in words" helper line below.
class INRCurrencyField extends StatefulWidget {
  final String? label;
  final double? value;
  final ValueChanged<double?> onChanged;
  final String? errorText;
  final bool isRequired;

  const INRCurrencyField({
    super.key,
    this.label,
    required this.value,
    required this.onChanged,
    this.errorText,
    this.isRequired = false,
  });

  @override
  State<INRCurrencyField> createState() => _INRCurrencyFieldState();
}

class _INRCurrencyFieldState extends State<INRCurrencyField> {
  late final TextEditingController _controller;
  String _wordsHelper = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value != null ? IndianCurrencyFormatter.format(widget.value!) : '',
    );
    _wordsHelper = widget.value != null
        ? IndianCurrencyFormatter.toWords(widget.value!)
        : '';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
    final parsed = digits.isEmpty ? null : double.tryParse(digits);
    final formatted = parsed != null
        ? IndianCurrencyFormatter.format(parsed)
        : '';
    if (formatted != _controller.text) {
      _controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    setState(() {
      _wordsHelper = parsed != null ? IndianCurrencyFormatter.toWords(parsed) : '';
    });
    widget.onChanged(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CompassTextField(
          controller: _controller,
          label: widget.label,
          isRequired: widget.isRequired,
          hint: '0',
          prefixIcon: Icons.currency_rupee,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          errorText: widget.errorText,
          onChanged: _onChanged,
        ),
        if (_wordsHelper.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              _wordsHelper,
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
          ),
      ],
    );
  }
}
