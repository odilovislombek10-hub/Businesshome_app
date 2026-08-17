import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';

/// Ro'yxatdan o'tish va parolni tiklash sahifalarining maydoni:
/// `px-4 py-3.5 bg-white border border-gray-200 rounded-xl text-[15px]`, xatoda `border-red-400`.
///
/// Kirish sahifasi boshqacha o'lchamda (`rounded-lg`, `border-gray-300`, `py-3`) — u o'z
/// maydonini o'zi chizadi.
class AuthField extends StatelessWidget {
  const AuthField({
    super.key,
    required this.controller,
    required this.hint,
    this.prefix,
    this.suffix,
    this.obscure = false,
    this.hasError = false,
    this.lines = 1,
    this.maxLength,
    this.digitsOnly = false,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.textStyle,
    this.textAlign = TextAlign.start,
  });

  final TextEditingController controller;
  final String hint;

  /// Maydon ichidagi qo'zg'almas matn (`+998`).
  final String? prefix;
  final Widget? suffix;
  final bool obscure;
  final bool hasError;
  final int lines;
  final int? maxLength;
  final bool digitsOnly;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;

  /// SMS kodi maydoni kattaroq va harflari yoyilgan holda chiziladi.
  final TextStyle? textStyle;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style =
        textStyle ?? theme.textTheme.bodyMedium?.copyWith(fontSize: 15, color: AppColors.dark);
    OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md), // rounded-xl
      borderSide: BorderSide(color: color, width: width),
    );
    final line = hasError ? const Color(0xFFF87171) : const Color(0xFFE5E7EB); // border-gray-200

    return TextField(
      controller: controller,
      obscureText: obscure,
      maxLines: obscure ? 1 : lines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      textAlign: textAlign,
      inputFormatters: [
        if (inputFormatters == null && digitsOnly) FilteringTextInputFormatter.digitsOnly,
        ...?inputFormatters,
      ],
      onChanged: onChanged,
      style: style,
      decoration: InputDecoration(
        isDense: true,
        counterText: '',
        filled: true,
        fillColor: Colors.white,
        hintText: hint,
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          fontSize: 15,
          color: AppColors.dark.withValues(alpha: 0.3),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // px-4 py-3.5
        prefixIcon: prefix == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(left: 16, right: 8),
                child: Text(
                  prefix!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.dark.withValues(alpha: 0.6),
                  ),
                ),
              ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: suffix == null
            ? null
            : Padding(padding: const EdgeInsets.only(right: 12), child: suffix),
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        border: border(line),
        enabledBorder: border(line),
        focusedBorder: border(hasError ? const Color(0xFFF87171) : AppColors.olive, 2),
      ),
    );
  }
}

/// `block text-sm font-semibold text-dark mb-2` — maydon yorlig'i.
class AuthLabel extends StatelessWidget {
  const AuthLabel(this.text, {super.key, this.required = false});

  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8), // mb-2
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: text),
            if (required)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Color(0xFFEF4444)),
              ),
          ],
        ),
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.dark,
        ),
      ),
    );
  }
}

/// `text-red-500 text-xs mt-1.5 ml-1` — maydon ostidagi xato satri.
class AuthFieldError extends StatelessWidget {
  const AuthFieldError(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6, left: 4),
    child: Text(
      message,
      style: Theme.of(
        context,
      ).textTheme.labelSmall?.copyWith(fontSize: 12, color: const Color(0xFFEF4444)),
    ),
  );
}
