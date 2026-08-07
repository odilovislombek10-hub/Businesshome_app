/// `/birja` sahifasidagi barcha matnlar.
///
/// `birja.*` va `common.*` kalitlari `core/i18n/translations/uz.ts` dan aynan olingan.
/// Shablonda i18n'siz to'g'ridan-to'g'ri yozilganlari (Byudjet, Yozish, Hammasi…) ham shundoq.
abstract final class BirjaTexts {
  static const heroBadge = 'KATALOG'; // shablonda qattiq yozilgan

  /// **Diqqat:** `birja.title`, `birja.orders`, `birja.active` va `birja.noOrdersDesc` kalitlari
  /// `uz.ts` da **yo'q** — saytda ularning o'rniga kalitning o'zi ("birja.title") chiqadi.
  /// Bu yerda ma'nosi bo'yicha yozildi.
  static const heroTitle = 'Birja';
  static const heroDesc = 'Mijoz buyurtmasi joylaydi, mutaxassis javob beradi';
  static const orders = 'buyurtma';
  static const active = 'faol';
  static const noOrdersDesc = "Filtrlarni o'zgartirib ko'ring yoki birinchi buyurtmani joylang";

  static const newOrder = 'Yangi buyurtma';
  static const loginToPost = 'Kirib joylash';
  static const ordersCount = 'ta buyurtma'; // "{{ items().length }} ta buyurtma"
  static const noOrders = "Hozircha buyurtmalar yo'q";

  static const specialistType = 'Mutaxassis turi';
  static const propertyType = 'Obyekt turi';
  static const city = 'Shahar';
  static const sort = 'Saralash';
  static const all = 'Hammasi';

  static const filters = 'Filterlar';
  static const resetAll = 'Tozalash';
  static const searchPlaceholder = 'Buyurtma qidirish...';

  static const budget = 'Byudjet';
  static const negotiable = 'Kelishuv';
  static const respond = 'Yozish';
  static const respondLong = 'Buyurtmaga javob yozish';
  static const respondTitle = 'Buyurtmaga javob yozish';
  static const respondPlaceholder =
      'Salom! Sizning buyurtmangiz menga qiziq. Quyidagi shartlarda bajara olaman...';
  static const cancel = 'Bekor qilish';
  static const send = 'Yuborish';

  static const details = 'Tafsilot';
  static const images = 'Rasmlar';
  static const location = 'Joylashuv';
  static const area = 'Maydon';
  static const deadline = 'Muddat';
  static const price = 'Narx';
  static const viewed = "ko'rilgan";
  static const responses = 'javob';
  static const unknownAuthor = 'Foydalanuvchi';

  static const targetOptions = <(String, String)>[
    ('', 'Hammasi'),
    ('designer', 'Dizayner'),
    ('master', 'Usta'),
  ];

  static const typeOptions = <(String, String)>[
    ('', 'Hammasi'),
    ('apartment', 'Kvartira'),
    ('house', 'Hovli'),
    ('office', 'Ofis'),
    ('shop', "Do'kon"),
  ];

  static const sortOptions = <(String, String)>[
    ('new', 'Eng yangi'),
    ('budget_desc', 'Yuqori smeta'),
  ];

  static String targetLabel(String value) => value == 'master' ? 'Usta' : 'Dizayner';

  static String typeLabel(String? value) {
    if (value == null) return '';
    for (final (code, label) in typeOptions) {
      if (code == value && code.isNotEmpty) return label;
    }
    return value;
  }
}
