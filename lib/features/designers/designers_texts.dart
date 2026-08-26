import '../../core/i18n/translate.dart';

/// `/designers` sahifasidagi barcha matnlar — `core/i18n/translations/uz.ts` dan aynan ko'chirildi.
///
/// Hech biri qayta yozilmagan: `designers.*` kalitlari qanday bo'lsa shundoq.
abstract final class DesignersTexts {
  static const heroBadge = 'KATALOG'; // shablonda qattiq yozilgan, i18n'da yo'q
  static String get heroTitle => t('designers.heroTitle');
  static String get heroDesc => t('designers.heroDesc');
  static String get searchPlaceholder => t('designers.searchPlaceholder');
  static String get searchBtn => t('designers.searchBtn');
  static String get allCities => t('designers.allCities');

  static String get specialists => t('designers.specialists');
  static String get avgRating => t('designers.avgRating');
  static String get verified => t('designers.verified');

  static String get filters => t('designers.filters');
  static String get resetAll => t('designers.resetAll');
  static String get resultsFound => t('designers.resultsFound');

  static String get specialization => t('designers.specialization');
  static String get minRating => t('designers.minRating');
  static String get priceRange => t('designers.priceRange');
  static String get from => t('designers.from');
  static String get to => t('designers.to');
  static String get priceUnit => t('designers.priceUnit');
  static String get experience => t('designers.experience');
  static String get yearsShort => t('designers.yearsShort');

  static String get portfolio => t('designers.portfolio');
  static String get projects => t('designers.projects');
  static String get years => t('designers.years');
  static String get priceFromLabel => t('designers.priceFromLabel');
  static String get viewProfile => t('designers.viewProfile');

  static String get noResults => t('designers.noResults');
  static String get noResultsDesc => t('designers.noResultsDesc');

  /// Yon paneldagi tugmalar — `specializations` dan, `value: ''` (Barchasi) shablonda
  /// `@if (spec.value)` bilan chiqarib tashlanadi, shuning uchun bu yerda ham yo'q.
  static List<(String, String)> get specializationOptions => <(String, String)>[
    ('interior', t('designers.specInterior')),
    ('exterior', t('designers.specExterior')),
    ('landscape', t('designers.specLandscape')),
    ('architecture', t('designers.specArchitecture')),
  ];

  /// Kartadagi `designers.spec.<value>` — yorliqlari yuqoridagilar bilan bir xil.
  static String specLabel(String value) =>
      specializationOptions.firstWhere((o) => o.$1 == value, orElse: () => (value, value)).$2;

  /// `ratingOptions` dagi nol bo'lmagan qiymatlar.
  static List<double> get ratingOptions => <double>[4, 4.5, 4.8];

  /// `experienceOptions = [3, 5, 10, 15]`
  static List<int> get experienceOptions => <int>[3, 5, 10, 15];

  static List<(String, String)> get sortOptions => <(String, String)>[
    ('rating', t('designers.sortRating')),
    ('projects', t('designers.sortProjects')),
    ('price_asc', t('designers.sortPriceAsc')),
    ('price_desc', t('designers.sortPriceDesc')),
    ('experience', t('designers.sortExperience')),
  ];
}
