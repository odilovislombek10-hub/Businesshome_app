/// `uz.ts` dagi `ads.*` kalitlari — qiymatlar aynan ko'chirilgan.
abstract final class AdsTexts {
  static const heroTitle = "Reklama e'lonlari";
  static const heroDesc = "Sotish, ijara va almashish uchun barcha turdagi e'lonlar";
  static const searchPlaceholder = 'Qidirish...';
  static const allCities = 'Barcha shaharlar';
  static const activeListings = "ta faol e'lon";
  static const updatedToday = 'Bugun yangilangan';

  static const allDeals = 'Barchasi';
  static const dealSell = 'Sotish';
  static const dealRent = 'Ijara';
  static const dealExchange = 'Almashish';

  static const filters = 'Filterlar';
  static const resetAll = 'Tozalash';
  static const propertyType = 'Mulk turi';
  static const rooms = 'Xonalar';
  static const priceRange = "Narx oralig'i";
  static const from = 'dan';
  static const to = 'gacha';
  static const priceUnit = "so'm";
  static const extras = "Qo'shimcha";
  static const urgentOnly = 'Faqat shoshilinch';
  static const topOnly = 'Faqat TOP';
  static const ownerOnly = 'Faqat egasidan';
  static const withAgent = 'Reltor bilan';

  static const resultsFound = "ta e'lon topildi";
  static const sortNewest = 'Eng yangi';
  static const sortPriceAsc = 'Narx: arzondan';
  static const sortPriceDesc = 'Narx: qimmatdan';
  static const sortAreaDesc = 'Maydon: kattadan';

  static const noResults = 'Hech narsa topilmadi';
  static const noResultsDesc = 'Boshqa filterlarni tanlang';

  static const urgent = 'Shoshilinch';
  static const roomShort = 'xona';
  static const bathroomShort = 'sanuzel';
  static const floorShort = 'qavat';
  static const currency = "so'm";
  static const perMonth = "so'm/oy";
  static const ownerBadge = 'Egasi';
  static const agentBadge = 'Agent';

  /// `ads.type*`
  static String typeLabel(String type) => switch (type) {
    'apartment' => 'Kvartira',
    'house' => 'Hovli uy',
    'office' => 'Ofis',
    'shop' => "Do'kon",
    'land' => 'Yer',
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
    'basseyn' => 'Basseyn',
    'hovli' => 'Hovli',
    'internet' => 'Internet',
    'kommunikatsiya' => 'Kommunikatsiya',
    'konditsioner' => 'Konditsioner',
    'lift' => 'Lift',
    'mebel' => 'Mebel',
    'metroga_yaqin' => 'Metro',
    'parking' => 'Parking',
    'smart_home' => 'Smart Home',
    'terasa' => 'Terasa',
    _ => value,
  };
}
