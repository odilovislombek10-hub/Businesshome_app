import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Uzbek phone input, formatted the way the site's field is: a fixed `+998` prefix and the
/// national number grouped as `90 123 45 67`.
class PhoneField extends StatelessWidget {
  const PhoneField({super.key, required this.controller, this.enabled = true, this.label});

  final TextEditingController controller;
  final bool enabled;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(9),
        _UzPhoneFormatter(),
      ],
      decoration: InputDecoration(
        labelText: label ?? 'Telefon raqam',
        prefixText: '+998 ',
        hintText: '90 123 45 67',
      ),
      validator: (v) => isCompletePhone(v) ? null : 'Telefon raqamni to‘liq kiriting',
    );
  }
}

/// The backend's `normalize_phone` (helpers/otp.py) keeps digits only, prepends `998` to a
/// nine-digit national number and returns it with a leading `+`. Send exactly that so the value
/// the server stores matches whatever the field showed.
String normalizePhone(String input) {
  final digits = input.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return '';
  return digits.startsWith('998') ? '+$digits' : '+998$digits';
}

/// True once the national part is the full nine digits Uzbek numbers have.
bool isCompletePhone(String? input) {
  final digits = (input ?? '').replaceAll(RegExp(r'\D'), '');
  final national = digits.startsWith('998') ? digits.substring(3) : digits;
  return national.length == 9;
}

/// Groups the nine national digits as `90 123 45 67` while typing.
class _UzPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      // Spaces after the 2nd, 5th and 7th digit — the grouping the site uses.
      if (i == 2 || i == 5 || i == 7) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
