/// Saytning `shared/utils/index.ts` dagi `formatNumber` — har uch xonadan keyin bo'sh joy.
///
/// `450000000` → `450 000 000`. Bu valyutaga tegmaydi: sayt uni faqat xom sonni chiroyli
/// ko'rsatish uchun ishlatadi (masalan dizayner kartasidagi `formatPrice(designer.priceFrom)`),
/// konvertatsiya va belgi qo'shish `CurrencyService` ning ishi.
String formatNumber(num? value) {
  if (value == null) return '';
  final rounded = value.round();
  final digits = rounded.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  return '${rounded < 0 ? '-' : ''}$buffer';
}
