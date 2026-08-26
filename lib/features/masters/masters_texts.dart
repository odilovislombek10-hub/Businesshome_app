import '../../core/i18n/translate.dart';

/// `/masters` sahifasidagi barcha matnlar.
///
/// `masters.*` kalitlari `core/i18n/translations/uz.ts` dan aynan ko'chirildi; shablonda i18n'siz,
/// to'g'ridan-to'g'ri yozilganlari (Bandlik holati, Saralash, Narx…) ham shundoq olindi.
abstract final class MastersTexts {
  static const heroBadge = 'KATALOG'; // shablonda qattiq yozilgan
  static String get heroTitle => t('masters.heroTitle');
  static String get heroDesc => t('masters.heroDesc');

  static String get specialists => t('masters.specialists');
  static String get avgRating => t('masters.avgRating');
  static String get verified => t('masters.verified');

  static String get searchPlaceholder => t('masters.searchPlaceholder');
  static String get filters => t('masters.filters');
  static String get resetAll => t('masters.resetAll');
  static const count = 'ta'; // sarlavha yonidagi "{{ total() }} ta"
  static const sortLabel = 'Saralash:';

  static String get specialization => t('masters.specialization');
  static String get allSpecs => t('masters.allSpecs');
  static const availability = 'Bandlik holati';

  /// Shablonda `t('masters.city')` yozilgan, lekin `uz.ts` da bunday kalit yo'q — saytda yorliq
  /// o'rniga kalitning o'zi ("masters.city") chiqadi. Bu yerda ma'nosi bo'yicha yozildi.
  static String get city => t('common.city');
  static String get allCities => t('masters.allCities');
  static String get minRating => t('masters.minRating');
  static String get allRatings => t('masters.allSpecs');
  static const verifiedOnly = 'Faqat tasdiqlangan';

  static String get priceLabel => t('services.price');
  static String get viewProfile => t('masters.viewProfile');

  static String get noResults => t('masters.noResults');
  static String get noResultsDesc => t('masters.noResultsDesc');

  /// `specializations` — birinchisi ("Barchasi") shablonda ham ro'yxatda turadi va bosilganda
  /// tanlovni butunlay bo'shatadi.
  static List<(String, String)> get specializationOptions => <(String, String)>[
    ('plumber', t('masters.specPlumber')),
    ('electrician', t('masters.specElectrician')),
    ('painter', t('masters.specPainter')),
    ('carpenter', t('masters.specCarpenter')),
    ('tiler', t('masters.specTiler')),
    ('welder', t('masters.specWelder')),
  ];

  /// Kartadagi `masters.spec.<value>` — filtr ro'yxatida yo'q qiymatlar ham bor.
  static Map<String, String> get _cardSpecLabels => <String, String>{
    'qurilish': t('masters.spec.qurilish'),
    'construction': t('masters.spec.qurilish'),
    'other': t('masters.spec.other'),
  };

  static String specLabel(String value) {
    for (final (code, label) in specializationOptions) {
      if (code == value) return label;
    }
    return _cardSpecLabels[value] ?? value;
  }

  /// `availabilityOpts` — emojilari bilan, shablondagidek.
  static List<(String, String)> get availabilityOptions => <(String, String)>[
    ('', t('common.all')),
    ('available', "🟢 Bo'sh"),
    ('busy', '🟡 Band'),
  ];

  static const availableBadge = "🟢 Bo'sh";
  static const busyBadge = '🟡 Band';

  /// `ratingOptions` dagi nol bo'lmagan qiymatlar.
  static List<double> get ratingOptions => <double>[4, 4.5, 4.8];

  /// `sortOpts` — dizaynerlarnikidan farq qiladi: bu yerda tugmachalar, va `price_desc` yo'q.
  static List<(String, String)> get sortOptions => <(String, String)>[
    ('rating', t('masters.rating')),
    ('projects', 'Loyihalar'),
    ('price_asc', t('createSpecialist.tagAffordable')),
    ('experience', t('masters.experience')),
  ];
}
