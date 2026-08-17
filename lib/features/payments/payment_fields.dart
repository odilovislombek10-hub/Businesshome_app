import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';

/// Karta raqamini `8600 0000 0000 0000` ko'rinishida guruhlaydi — saytdagi `onCardInput`.
class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue next) {
    final digits = next.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 16 ? digits.substring(0, 16) : digits;
    final buffer = StringBuffer();
    for (var i = 0; i < limited.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(limited[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// `MM/YY` — saytdagi `onExpiryInput`.
class ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue next) {
    final digits = next.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 4 ? digits.substring(0, 4) : digits;
    final text = limited.length >= 3
        ? '${limited.substring(0, 2)}/${limited.substring(2)}'
        : limited;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// To'lov formalarining umumiy maydoni: `rounded-xl border border-gray-200 px-3.5 py-3`.
class PaymentField extends StatelessWidget {
  const PaymentField({
    super.key,
    required this.controller,
    this.hint,
    this.label,
    this.formatters,
    this.keyboardType,
    this.textAlign = TextAlign.start,
    this.letterSpacing,
    this.fontSize,
    this.maxLength,
    this.width,
    this.onChanged,
  });

  final TextEditingController controller;
  final String? hint;
  final String? label;
  final List<TextInputFormatter>? formatters;
  final TextInputType? keyboardType;
  final TextAlign textAlign;
  final double? letterSpacing;
  final double? fontSize;
  final int? maxLength;
  final double? width;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: color, width: width),
    );

    final field = TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      textAlign: textAlign,
      maxLength: maxLength,
      onChanged: onChanged,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontSize: fontSize,
        letterSpacing: letterSpacing,
        fontWeight: fontSize != null ? FontWeight.w600 : null,
        color: AppColors.dark,
      ),
      decoration: InputDecoration(
        isDense: true,
        counterText: '',
        filled: true,
        fillColor: Colors.white,
        hintText: hint,
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          fontSize: fontSize,
          letterSpacing: letterSpacing,
          color: AppColors.dark.withValues(alpha: 0.25),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: border(AppColors.borderLight),
        enabledBorder: border(AppColors.borderLight),
        focusedBorder: border(AppColors.olive, 2),
      ),
    );

    if (label == null) return width == null ? field : SizedBox(width: width, child: field);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6), // mb-1.5
          child: Text(
            label!,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 12, // text-xs
              fontWeight: FontWeight.w500,
              color: AppColors.dark.withValues(alpha: 0.5),
            ),
          ),
        ),
        width == null ? field : SizedBox(width: width, child: field),
      ],
    );
  }
}

/// `bg-red-50 border border-red-200 rounded-xl px-4 py-3`
class PaymentError extends StatelessWidget {
  const PaymentError(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0xFFFEF2F2),
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: const Color(0xFFFECACA)),
    ),
    child: Text(
      message,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, color: const Color(0xFFB91C1C)),
    ),
  );
}

/// Test rejimi ogohlantirishi — `mode` `production` bo'lmaganda chiqadi.
class PaymentModeBadge extends StatelessWidget {
  const PaymentModeBadge(this.mode, {super.key});

  final String mode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.olive.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: AppColors.olive, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            mode == 'simulator' ? "Test rejimi — pul yechilmaydi" : 'Sandbox — pul yechilmaydi',
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 12,
              color: AppColors.dark.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
