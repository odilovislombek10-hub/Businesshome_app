import '../../core/i18n/translate.dart';

/// `/new-projects` sahifasining matnlari — `newProjects.*` kalitlari `uz.ts` dan aynan olingan.
abstract final class NewProjectsTexts {
  static String get heroTitle => t('newProjects.heroTitle');
  static String get heroDesc => t('newProjects.heroDesc');
  static String get searchPlaceholder => t('newProjects.searchPlaceholder');
  static String get searchOnMap => t('newProjects.searchOnMap');
  static String get allCities => t('newProjects.allCities');

  static String get activeListings => t('newProjects.activeListings');
  static String get updatedToday => t('newProjects.updatedToday');

  static String get filters => t('newProjects.filters');
  static String get resetAll => t('newProjects.resetAll');
  static String get resultsFound => t('newProjects.resultsFound');
  static String get city => t('newProjects.city');
  static String get priceRange => t('newProjects.priceRange');
  static String get from => t('newProjects.from');
  static String get to => t('newProjects.to');
  static String get priceUnit => t('newProjects.priceUnit');
  static String get completion => t('newProjects.completion');
  static const completionHint = '2026 yoki 2026-Q2';

  static String get noResults => t('newProjects.noResults');
  static String get noResultsDesc => t('newProjects.noResultsDesc');

  static List<(String, String)> get sortOptions => <(String, String)>[
    ('newest', t('newProjects.sortNewest')),
    ('price_asc', t('newProjects.sortPriceAsc')),
    ('price_desc', t('newProjects.sortPriceDesc')),
    ('area_desc', t('newProjects.sortAreaDesc')),
  ];
}
