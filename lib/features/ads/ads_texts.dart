import '../../core/i18n/translate.dart';

/// `uz.ts` dagi `ads.*` kalitlari — qiymatlar aynan ko'chirilgan.
abstract final class AdsTexts {
  static String get heroTitle => t('ads.heroTitle');
  static String get heroDesc => t('ads.heroDesc');
  static String get searchPlaceholder => t('ads.searchPlaceholder');
  static String get allCities => t('ads.allCities');
  static String get activeListings => t('ads.activeListings');
  static String get updatedToday => t('ads.updatedToday');

  static String get allDeals => t('ads.allDeals');
  static String get dealSell => t('ads.dealSell');
  static String get dealRent => t('ads.dealRent');
  static String get dealExchange => t('ads.dealExchange');

  static String get filters => t('ads.filters');
  static String get resetAll => t('ads.resetAll');
  static String get propertyType => t('ads.propertyType');
  static String get rooms => t('ads.rooms');
  static String get priceRange => t('ads.priceRange');
  static String get from => t('ads.from');
  static String get to => t('ads.to');
  static String get priceUnit => t('ads.currency');
  static String get extras => t('ads.extras');
  static String get urgentOnly => t('ads.urgentOnly');
  static String get topOnly => t('ads.topOnly');
  static String get ownerOnly => t('ads.ownerOnly');
  static String get withAgent => t('rent.withAgent');

  static String get resultsFound => t('ads.resultsFound');
  static String get sortNewest => t('ads.sortNewest');
  static String get sortPriceAsc => t('ads.sortPriceAsc');
  static String get sortPriceDesc => t('ads.sortPriceDesc');
  static String get sortAreaDesc => t('ads.sortAreaDesc');

  static String get noResults => t('ads.noResults');
  static String get noResultsDesc => t('ads.noResultsDesc');

  static String get urgent => t('ads.urgent');
  static String get roomShort => t('ads.roomShort');
  static String get bathroomShort => t('ads.bathroomShort');
  static String get floorShort => t('ads.floorShort');
  static String get currency => t('ads.currency');
  static String get perMonth => t('ads.perMonth');
  static String get ownerBadge => t('ads.owner');
  static String get agentBadge => t('ads.agent');

  /// `ads.type*`
  static String typeLabel(String type) => switch (type) {
    'apartment' => t('ads.typeApartment'),
    'house' => t('ads.typeHouse'),
    'office' => t('ads.typeOffice'),
    'shop' => t('ads.typeShop'),
    'land' => t('ads.typeLand'),
    _ => type,
  };

  /// `ads.deal*`
  static String dealLabel(String deal) => switch (deal) {
    'sell' => dealSell,
    'rent' => dealRent,
    'exchange' => dealExchange,
    _ => deal,
  };

  /// `ads.amenity.*` — kartadagi ikkita qulaylik nishonchasi.
  static String amenityLabel(String value) => switch (value) {
    'basseyn' => t('ads.amenity.basseyn'),
    'hovli' => t('ads.amenity.hovli'),
    'internet' => t('ads.amenity.internet'),
    'kommunikatsiya' => t('ads.amenity.kommunikatsiya'),
    'konditsioner' => t('ads.amenity.konditsioner'),
    'lift' => t('ads.amenity.lift'),
    'mebel' => t('ads.amenity.mebel'),
    'metroga_yaqin' => t('ads.amenity.metroga_yaqin'),
    'parking' => t('ads.amenity.parking'),
    'smart_home' => t('ads.amenity.smart_home'),
    'terasa' => t('ads.amenity.terasa'),
    _ => value,
  };
}
