import '../../core/i18n/translate.dart';

/// `uz.ts` dagi `map.search.*` kalitlari — aynan o'sha qiymatlar.
abstract final class MapSearchTexts {
  static String get allCities => t('map.search.allCities');
  static String get all => t('map.search.all');
  static String get rent => t('map.rent');
  static String get sell => t('map.search.sell');
  static String get anyRooms => t('map.search.anyRooms');
  static String get results => t('map.search.results');
  static String get noResults => t('map.search.noResults');
  static String get noResultsDesc => t('map.search.noResultsDesc');
  static String get perMonth => t('map.search.perMonth');
  static String get som => t('map.search.som');
  static String get roomShort => t('map.search.roomShort');
  static String get showMap => t('map.search.showMap');
  static String get showList => t('map.search.showList');
  static String get loadError => t('map.search.loadError');
  static String get retry => t('map.search.retry');
  static String get loadingMarkers => t('map.search.loadingMarkers');
  static String get loadMore => t('map.search.loadMore');
  static String get allTypes => t('map.search.allTypes');
  static String get filters => t('map.search.filters');
  static String get details => t('map.search.viewDetail');

  /// Mulk turi tugmalari — saytdagi `propertyTypes` ro'yxati.
  static List<(String, String)> get propertyTypes => <(String, String)>[
    ('apartment', t('map.search.typeApartment')),
    ('house', t('map.search.typeHouse')),
    ('office', t('map.search.typeOffice')),
    ('shop', t('map.search.typeShop')),
  ];
}
