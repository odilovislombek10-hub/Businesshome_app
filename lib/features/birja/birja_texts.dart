import '../../core/i18n/translate.dart';

/// `/birja` sahifasidagi barcha matnlar.
///
/// `birja.*` va `common.*` kalitlari `core/i18n/translations/uz.ts` dan aynan olingan.
/// Shablonda i18n'siz to'g'ridan-to'g'ri yozilganlari (Byudjet, Yozish, Hammasi…) ham shundoq.
abstract final class BirjaTexts {
  static const heroBadge = 'KATALOG'; // shablonda qattiq yozilgan

  /// **Diqqat:** `birja.title`, `birja.orders`, `birja.active` va `birja.noOrdersDesc` kalitlari
  /// `uz.ts` da **yo'q** — saytda ularning o'rniga kalitning o'zi ("birja.title") chiqadi.
  /// Bu yerda ma'nosi bo'yicha yozildi.
  static String get heroTitle => t('header.nav.birja');
  static String get heroDesc => t('birja.description');
  static const orders = 'buyurtma';
  static const active = 'faol';
  static const noOrdersDesc = "Filtrlarni o'zgartirib ko'ring yoki birinchi buyurtmani joylang";

  static String get newOrder => t('birja.newOrder');
  static String get loginToPost => t('birja.loginToPost');
  static const ordersCount = 'ta buyurtma'; // "{{ items().length }} ta buyurtma"
  static String get noOrders => t('birja.noOrders');

  static String get specialistType => t('birja.specialistType');
  static String get propertyType => t('birja.propertyType');
  static String get city => t('common.city');
  static String get sort => t('common.sort');
  static String get all => t('common.all');

  static String get filters => t('rent.filters');
  static String get resetAll => t('rent.resetAll');
  static const searchPlaceholder = 'Buyurtma qidirish...';

  static const budget = 'Byudjet';
  static const negotiable = 'Kelishuv';
  static String get respond => t('chat.write');
  static const respondLong = 'Buyurtmaga javob yozish';
  static const respondTitle = 'Buyurtmaga javob yozish';
  static const respondPlaceholder =
      'Salom! Sizning buyurtmangiz menga qiziq. Quyidagi shartlarda bajara olaman...';
  static String get cancel => t('common.cancel');
  static String get send => t('common.submit');

  static String get details => t('birja.details');
  static String get images => t('cabinet.projects.images');
  static String get location => t('map.locationTitle');
  static String get area => t('cabinet.projects.area');
  static String get deadline => t('mortgage.loanTerm');
  static String get price => t('services.price');
  static const viewed = "ko'rilgan";
  static const responses = 'javob';
  static String get unknownAuthor => t('cabinet.role.user');

  static List<(String, String)> get targetOptions => <(String, String)>[
    ('', t('common.all')),
    ('designer', t('header.nav.designer')),
    ('master', t('cabinet.favBadge.master')),
  ];

  static List<(String, String)> get typeOptions => <(String, String)>[
    ('', t('common.all')),
    ('apartment', t('header.dropdown.apartment')),
    ('house', t('rent.amenity.hovli')),
    ('office', t('header.dropdown.office')),
    ('shop', t('header.dropdown.shop')),
  ];

  static List<(String, String)> get sortOptions => <(String, String)>[
    ('new', t('birja.sortNewest')),
    ('budget_desc', t('birja.sortHighBudget')),
  ];

  static String targetLabel(String value) =>
      value == 'master' ? t('cabinet.favBadge.master') : t('header.nav.designer');

  static String typeLabel(String? value) {
    if (value == null) return '';
    for (final (code, label) in typeOptions) {
      if (code == value && code.isNotEmpty) return label;
    }
    return value;
  }
}
