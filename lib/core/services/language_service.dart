import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Saytdagi `TranslateService` ning ilovadagi ko'rinishi.
///
/// Sayt uch tilni beradi (`uz` / `ru` / `ky`) va tanlovni `lang` signalida saqlaydi. Ilovada
/// matnlar hozircha o'zbekcha yozilgan, shuning uchun bu xizmat tanlovni eslab qoladi va
/// tarjimasi bor joylarda (masalan header'dagi "Orqaga") to'g'ri so'zni beradi.
class LanguageService extends ChangeNotifier {
  LanguageService._();

  static final LanguageService instance = LanguageService._();

  static const _storageKey = 'market_lang';

  /// Saytdagi `Lang` turi.
  static const codes = ['uz', 'ru', 'ky'];

  String _code = 'uz';
  String get code => _code;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_storageKey);
    if (stored != null && codes.contains(stored)) {
      _code = stored;
      notifyListeners();
    }
  }

  Future<void> set(String code) async {
    if (_code == code || !codes.contains(code)) return;
    _code = code;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, code);
  }

  /// `header.back` — uz.ts, ru.ts va ky.ts dan aynan olingan.
  String get back => switch (_code) {
    'ru' => 'Назад',
    'ky' => 'Артка',
    _ => 'Orqaga',
  };
}
