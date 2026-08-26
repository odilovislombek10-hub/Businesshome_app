import '../../core/i18n/translate.dart';

/// Shahar kodi → ko'rinadigan nomi.
///
/// Backend `city` maydonini kod bilan qaytaradi (`tashkent_city`, `samarkand`, …). Saytda bu
/// `shared/utils/regions.ts` dagi `cityOptions` orqali `auth.city.*` kalitiga, undan `uz.ts` dagi
/// matnga aylantiriladi — masalan e'lon kartasida `{{ property.district }},
/// {{ t(getCityLabel(property.city)) }}`. Shu jadval o'sha ikki faylning ko'chirmasi.
abstract final class CityLabels {
  static String get allCities => t('rent.allCities');

  /// `cityOptions` tartibida — filtr ro'yxatlari ham shu tartibda chiqadi.
  static List<(String, String)> get options => <(String, String)>[
    ('tashkent_city', t('map.region.tashkent')),
    ('samarkand', t('map.region.samarkand')),
    ('bukhara', t('map.region.bukhara')),
    ('andijan', t('map.region.andijan')),
    ('fergana', t('map.region.fergana')),
    ('namangan', t('map.region.namangan')),
    ('karshi', t('auth.city.karshi')),
    ('navoiy', t('map.region.navoiy')),
    ('urgench', t('auth.city.urgench')),
    ('sirdaryo', t('map.region.sirdaryo')),
    ('surxondaryo', t('map.region.surkhandarya')),
    ('jizzakh', t('map.region.jizzakh')),
    ('nukus', t('auth.city.nukus')),
  ];

  /// `cityOptions` da yo'q, lekin e'lonlarda uchraydigan kodlar.
  ///
  /// Backend `city` maydoniga `shared/data/uz-regions.ts` dagi viloyat kodini yozadi, u yerda esa
  /// `cityOptions` dan boshqacha kodlar bor (`tashkent_region`, `qashqadarya`, `khorezm`, …).
  /// Saytda ular yorliqsiz qolib, kartada xom kod ko'rinadi — bu yerda to'ldirildi. Yorliqlar
  /// `cityOptions` uslubida qisqa, chunki karta bir qatorga sig'ishi kerak.
  static Map<String, String> get _extra => <String, String>{
    'tashkent_region': t('hero.region.toshkentRegion'),
    'qashqadarya': t('map.region.kashkadarya'),
    'surkhandarya': t('map.region.surkhandarya'),
    'syrdarya': t('map.region.sirdaryo'),
    'navoi': t('map.region.navoiy'),
    'khorezm': t('map.region.khorezm'),
    'karakalpakstan': "Qoraqalpog'iston",
    'termiz': t('auth.city.termiz'),
    'gulistan': t('auth.city.gulistan'),
    'chirchik': t('auth.city.chirchik'),
  };

  static Map<String, String> get _byCode => <String, String>{
    for (final (code, label) in options) code: label,
    ..._extra,
  };

  /// Kod tanish bo'lmasa — saytdagidek — kodning o'zi qaytadi.
  static String label(String? code) {
    if (code == null || code.isEmpty) return '';
    return _byCode[code] ?? code;
  }
}
