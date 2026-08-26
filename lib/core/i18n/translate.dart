import '../services/language_service.dart';
import 'translations_ky.dart';
import 'translations_ru.dart';
import 'translations_uz.dart';

/// Saytdagi `TranslateService.t()` ning aynan o'zi: kalit bo'yicha tanlangan tildan matn
/// olinadi, topilmasa kalitning o'zi qaytadi.
///
/// Saytda tarjima topilmasa `key` qaytariladi (`this.dict()[key] ?? key`). Bu yerda oradan
/// yana bitta qadam qo'shildi — tanlangan tilda yo'q kalit o'zbekchadan olinadi, chunki
/// uchala fayl bir vaqtda yangilanmasligi mumkin.
String t(String key) {
  final dict = switch (LanguageService.instance.code) {
    'ru' => ruTranslations,
    'ky' => kyTranslations,
    _ => uzTranslations,
  };
  return dict[key] ?? uzTranslations[key] ?? key;
}

/// `{name}` kabi o'rinbosarlarni almashtiradi — saytda bu `.replace()` bilan qo'lda qilinadi.
String tp(String key, Map<String, Object?> values) {
  var text = t(key);
  for (final entry in values.entries) {
    text = text.replaceAll('{${entry.key}}', '${entry.value}');
  }
  return text;
}
