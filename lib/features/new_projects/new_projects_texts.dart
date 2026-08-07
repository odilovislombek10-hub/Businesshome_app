/// `/new-projects` sahifasining matnlari — `newProjects.*` kalitlari `uz.ts` dan aynan olingan.
abstract final class NewProjectsTexts {
  static const heroTitle = 'Yangi Loyihalar';
  static const heroDesc =
      "O'zbekistondagi eng yangi novostroykalar — qurilayotgan binolar va kelgusi turar-joy loyihalari";
  static const searchPlaceholder = 'Qidirish: nomi, tuman...';
  static const searchOnMap = 'Xaritadan qidirish';
  static const allCities = 'Barcha shaharlar';

  static const activeListings = 'ta faol loyiha';
  static const updatedToday = 'Bugun yangilangan';

  static const filters = 'Filterlar';
  static const resetAll = 'Tozalash';
  static const resultsFound = 'ta topildi';
  static const city = 'Shahar';
  static const priceRange = "Narx oralig'i";
  static const from = 'dan';
  static const to = 'gacha';
  static const priceUnit = "so'm";
  static const completion = 'Topshirish muddati';
  static const completionHint = '2026 yoki 2026-Q2';

  static const noResults = 'Hech narsa topilmadi';
  static const noResultsDesc = "Qidiruv shartlarini o'zgartiring yoki filterlarni tozalang";

  static const sortOptions = <(String, String)>[
    ('newest', 'Eng yangi'),
    ('price_asc', 'Arzon → Qimmat'),
    ('price_desc', 'Qimmat → Arzon'),
    ('area_desc', 'Katta maydon'),
  ];
}
