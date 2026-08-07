/// `/masters` sahifasidagi barcha matnlar.
///
/// `masters.*` kalitlari `core/i18n/translations/uz.ts` dan aynan ko'chirildi; shablonda i18n'siz,
/// to'g'ridan-to'g'ri yozilganlari (Bandlik holati, Saralash, Narx…) ham shundoq olindi.
abstract final class MastersTexts {
  static const heroBadge = 'KATALOG'; // shablonda qattiq yozilgan
  static const heroTitle = 'Ustalar bozori';
  static const heroDesc =
      'Tajribali santexnik, elektrik, kafelchi, payvandchi va boshqa qurilish ustalarini toping';

  static const specialists = 'Mutaxassislar';
  static const avgRating = "o'rtacha reyting";
  static const verified = 'Tasdiqlangan';

  static const searchPlaceholder = 'Usta qidirish...';
  static const filters = 'Filterlar';
  static const resetAll = 'Tozalash';
  static const count = 'ta'; // sarlavha yonidagi "{{ total() }} ta"
  static const sortLabel = 'Saralash:';

  static const specialization = 'Mutaxassislik';
  static const allSpecs = 'Barchasi';
  static const availability = 'Bandlik holati';

  /// Shablonda `t('masters.city')` yozilgan, lekin `uz.ts` da bunday kalit yo'q — saytda yorliq
  /// o'rniga kalitning o'zi ("masters.city") chiqadi. Bu yerda ma'nosi bo'yicha yozildi.
  static const city = 'Shahar';
  static const allCities = 'Barcha shaharlar';
  static const minRating = 'Minimal reyting';
  static const allRatings = 'Barchasi';
  static const verifiedOnly = 'Faqat tasdiqlangan';

  static const priceLabel = 'Narx';
  static const viewProfile = "Profilni ko'rish";

  static const noResults = 'Usta topilmadi';
  static const noResultsDesc = 'Boshqa filterlarni tanlang';

  /// `specializations` — birinchisi ("Barchasi") shablonda ham ro'yxatda turadi va bosilganda
  /// tanlovni butunlay bo'shatadi.
  static const specializationOptions = <(String, String)>[
    ('plumber', 'Santexnik'),
    ('electrician', 'Elektrik'),
    ('painter', "Bo'yoqchi"),
    ('carpenter', 'Duradgor'),
    ('tiler', 'Plitachi'),
    ('welder', 'Payvandchi'),
  ];

  /// Kartadagi `masters.spec.<value>` — filtr ro'yxatida yo'q qiymatlar ham bor.
  static const _cardSpecLabels = <String, String>{
    'qurilish': 'Quruvchi',
    'construction': 'Quruvchi',
    'other': 'Boshqa',
  };

  static String specLabel(String value) {
    for (final (code, label) in specializationOptions) {
      if (code == value) return label;
    }
    return _cardSpecLabels[value] ?? value;
  }

  /// `availabilityOpts` — emojilari bilan, shablondagidek.
  static const availabilityOptions = <(String, String)>[
    ('', 'Hammasi'),
    ('available', "🟢 Bo'sh"),
    ('busy', '🟡 Band'),
  ];

  static const availableBadge = "🟢 Bo'sh";
  static const busyBadge = '🟡 Band';

  /// `ratingOptions` dagi nol bo'lmagan qiymatlar.
  static const ratingOptions = <double>[4, 4.5, 4.8];

  /// `sortOpts` — dizaynerlarnikidan farq qiladi: bu yerda tugmachalar, va `price_desc` yo'q.
  static const sortOptions = <(String, String)>[
    ('rating', 'Reyting'),
    ('projects', 'Loyihalar'),
    ('price_asc', 'Arzon'),
    ('experience', 'Tajriba'),
  ];
}
