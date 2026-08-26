import '../../core/i18n/translate.dart';

/// Every string the `/secondary` page prints, taken verbatim from the site's `i18n/uz.ts`.
abstract final class SecondaryTexts {
  static String get heroTitle => t('secondary.heroTitle');
  static String get heroDesc => t('secondary.heroDesc');
  static String get searchPlaceholder => t('secondary.searchPlaceholder');
  static String get filters => t('secondary.filters');
  static String get searchOnMap => t('secondary.searchOnMap');
  static String get activeListings => t('secondary.activeListings');
  static String get updatedToday => t('secondary.updatedToday');
  static String get resetAll => t('secondary.resetAll');
  static String get resultsFound => t('secondary.resultsFound');
  static String get propertyType => t('secondary.propertyType');
  static String get rooms => t('secondary.rooms');
  static String get priceRange => t('secondary.priceRange');
  static String get extras => t('secondary.extras');
  static String get noResults => t('secondary.noResults');
  static String get noResultsDesc => t('secondary.noResultsDesc');
  static String get allOption => t('secondary.allOption');

  /// `rent.any` — tuman tanlashdagi "hammasi" varianti.
  static String get anyDistrict => t('rent.any');

  // Sorting, in the order the site lists the options.
  static List<(String, String)> get sortOptions => <(String, String)>[
    ('newest', t('secondary.sortNewest')),
    ('price_asc', t('secondary.sortPriceAsc')),
    ('price_desc', t('secondary.sortPriceDesc')),
    ('area_desc', t('secondary.sortAreaDesc')),
  ];

  /// `rent.*` keys the secondary page reuses.
  static String get segment => t('rent.segment');
  static String get bathrooms => t('rent.bathrooms');
  static String get floor => t('rent.floor');
  static String get seller => t('rent.seller');
  static String get payment => t('rent.payment');
  static String get furnished => t('secondary.furnished');
  static String get repair => t('rent.repair');
  static String get roomShort => t('secondary.roomShort');
  static String get bathroomShort => t('secondary.bathroomShort');
  static String get allCities => t('secondary.allCities');

  static List<(String, String)> get propertyTypes => <(String, String)>[
    ('', t('secondary.allTypes')),
    ('apartment', t('secondary.type.apartment')),
    ('house', t('secondary.type.house')),
    ('office', t('secondary.type.office')),
    ('shop', t('secondary.type.shop')),
    ('building', t('secondary.type.building')),
    ('land', t('rent.typeLand')),
  ];

  static List<(String, String)> get segments => <(String, String)>[
    ('elite', t('rent.segmentElite')),
    ('business', t('rent.segmentBusiness')),
    ('standart', t('rent.segmentStandart')),
    ('economy', t('rent.segmentEconomy')),
  ];

  static List<(String, String)> get sellers => <(String, String)>[
    ('owner', t('rent.sellerOwner')),
    ('agent', t('rent.sellerAgent')),
    ('noAgent', t('rent.sellerNoAgent')),
  ];

  static List<(String, String)> get payments => <(String, String)>[
    ('mortgage', t('rent.paymentMortgage')),
    ('installment', t('rent.paymentInstallment')),
    ('cash', t('rent.paymentCash')),
  ];

  /// `rent.furnishedYes/No` and `rent.repairYes/No` — not a plain yes/no pair.
  static List<(String, String)> get furnishedOptions => <(String, String)>[
    ('', allOption),
    ('yes', t('secondary.furnished')),
    ('no', t('rent.furnishedNo')),
  ];

  static List<(String, String)> get repairOptions => <(String, String)>[
    ('', allOption),
    ('yes', t('rent.repairYes')),
    ('no', t('rent.repairNo')),
  ];

  /// The single checkbox under "Qo'shimcha".
  static String get hasVirtualTour => t('secondary.hasVirtualTour');

  /// Range input placeholders (`rent.from` / `rent.to`).
  static String get rangeFrom => t('secondary.from');
  static String get rangeTo => t('secondary.to');

  /// `areaLabelKey()` swaps the label when every selected type is house or land.
  static String get areaM2 => t('rent.areaM2');
  static String get areaLand => t('rent.areaLand');

  static const roomOptions = [1, 2, 3, 4, 5];
  static const bathroomOptions = [1, 2, 3, 4];

  /// The hero photo the site hard-codes behind the search box.
  static const heroImage =
      'https://images.unsplash.com/photo-1600047509807-ba8f99d2cdde?w=1920&q=80';
}
