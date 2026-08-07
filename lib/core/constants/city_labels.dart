/// Shahar kodi → ko'rinadigan nomi.
///
/// Backend `city` maydonini kod bilan qaytaradi (`tashkent_city`, `samarkand`, …). Saytda bu
/// `shared/utils/regions.ts` dagi `cityOptions` orqali `auth.city.*` kalitiga, undan `uz.ts` dagi
/// matnga aylantiriladi — masalan e'lon kartasida `{{ property.district }},
/// {{ t(getCityLabel(property.city)) }}`. Shu jadval o'sha ikki faylning ko'chirmasi.
abstract final class CityLabels {
  static const allCities = 'Barcha shaharlar';

  /// `cityOptions` tartibida — filtr ro'yxatlari ham shu tartibda chiqadi.
  static const options = <(String, String)>[
    ('tashkent_city', 'Toshkent'),
    ('samarkand', 'Samarqand'),
    ('bukhara', 'Buxoro'),
    ('andijan', 'Andijon'),
    ('fergana', "Farg'ona"),
    ('namangan', 'Namangan'),
    ('karshi', 'Qarshi'),
    ('navoiy', 'Navoiy'),
    ('urgench', 'Urganch'),
    ('sirdaryo', 'Sirdaryo'),
    ('surxondaryo', 'Surxondaryo'),
    ('jizzakh', 'Jizzax'),
    ('nukus', 'Nukus'),
  ];

  /// `cityOptions` da yo'q, lekin e'lonlarda uchraydigan kodlar.
  ///
  /// Backend `city` maydoniga `shared/data/uz-regions.ts` dagi viloyat kodini yozadi, u yerda esa
  /// `cityOptions` dan boshqacha kodlar bor (`tashkent_region`, `qashqadarya`, `khorezm`, …).
  /// Saytda ular yorliqsiz qolib, kartada xom kod ko'rinadi — bu yerda to'ldirildi. Yorliqlar
  /// `cityOptions` uslubida qisqa, chunki karta bir qatorga sig'ishi kerak.
  static const _extra = <String, String>{
    'tashkent_region': 'Toshkent viloyati',
    'qashqadarya': 'Qashqadaryo',
    'surkhandarya': 'Surxondaryo',
    'syrdarya': 'Sirdaryo',
    'navoi': 'Navoiy',
    'khorezm': 'Xorazm',
    'karakalpakstan': "Qoraqalpog'iston",
    'termiz': 'Termiz',
    'gulistan': 'Guliston',
    'chirchik': 'Chirchiq',
  };

  static final _byCode = <String, String>{
    for (final (code, label) in options) code: label,
    ..._extra,
  };

  /// Kod tanish bo'lmasa — saytdagidek — kodning o'zi qaytadi.
  static String label(String? code) {
    if (code == null || code.isEmpty) return '';
    return _byCode[code] ?? code;
  }
}
