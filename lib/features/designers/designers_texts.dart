/// `/designers` sahifasidagi barcha matnlar — `core/i18n/translations/uz.ts` dan aynan ko'chirildi.
///
/// Hech biri qayta yozilmagan: `designers.*` kalitlari qanday bo'lsa shundoq.
abstract final class DesignersTexts {
  static const heroBadge = 'KATALOG'; // shablonda qattiq yozilgan, i18n'da yo'q
  static const heroTitle = 'Dizaynerlar bozori';
  static const heroDesc =
      'Sertifikatli interyer, eksteryer, landshaft va arxitektura dizaynerlarini toping';
  static const searchPlaceholder = 'Dizayner qidirish...';
  static const searchBtn = 'Qidirish';
  static const allCities = 'Barcha shaharlar';

  static const specialists = 'Mutaxassislar';
  static const avgRating = "o'rtacha reyting";
  static const verified = 'Tasdiqlangan';

  static const filters = 'Filterlar';
  static const resetAll = 'Tozalash';
  static const resultsFound = 'ta dizayner topildi';

  static const specialization = 'Mutaxassislik';
  static const minRating = 'Minimal reyting';
  static const priceRange = "Narx oralig'i";
  static const from = 'dan';
  static const to = 'gacha';
  static const priceUnit = "so'm";
  static const experience = 'Tajriba';
  static const yearsShort = 'yil';

  static const portfolio = 'Portfolio';
  static const projects = 'loyiha';
  static const years = 'yil+';
  static const priceFromLabel = 'Narxdan';
  static const viewProfile = "Profilni ko'rish";

  static const noResults = 'Dizayner topilmadi';
  static const noResultsDesc = 'Boshqa filterlarni tanlang';

  /// Yon paneldagi tugmalar — `specializations` dan, `value: ''` (Barchasi) shablonda
  /// `@if (spec.value)` bilan chiqarib tashlanadi, shuning uchun bu yerda ham yo'q.
  static const specializationOptions = <(String, String)>[
    ('interior', 'Interer dizayn'),
    ('exterior', 'Eksterer dizayn'),
    ('landscape', 'Landshaft'),
    ('architecture', 'Arxitektura'),
  ];

  /// Kartadagi `designers.spec.<value>` — yorliqlari yuqoridagilar bilan bir xil.
  static String specLabel(String value) =>
      specializationOptions.firstWhere((o) => o.$1 == value, orElse: () => (value, value)).$2;

  /// `ratingOptions` dagi nol bo'lmagan qiymatlar.
  static const ratingOptions = <double>[4, 4.5, 4.8];

  /// `experienceOptions = [3, 5, 10, 15]`
  static const experienceOptions = <int>[3, 5, 10, 15];

  static const sortOptions = <(String, String)>[
    ('rating', "Reyting bo'yicha"),
    ('projects', "Loyihalar bo'yicha"),
    ('price_asc', 'Narx: arzondan'),
    ('price_desc', 'Narx: qimmatdan'),
    ('experience', "Tajriba bo'yicha"),
  ];
}
