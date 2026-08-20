/// `uz.ts` dagi `map.search.*` kalitlari — aynan o'sha qiymatlar.
abstract final class MapSearchTexts {
  static const allCities = "Butun O'zbekiston";
  static const all = 'Barchasi';
  static const rent = 'Ijara';
  static const sell = 'Sotish';
  static const anyRooms = 'Xona';
  static const results = "ta e'lon";
  static const noResults = 'Hech narsa topilmadi';
  static const noResultsDesc = "Filterlarni o'zgartirib ko'ring";
  static const perMonth = "so'm/oy";
  static const som = "so'm";
  static const roomShort = 'xona';
  static const showMap = "Xaritani ko'rish";
  static const showList = "Ro'yxatni ko'rish";
  static const loadError = "Ma'lumotlarni yuklashda xatolik";
  static const retry = 'Qayta urinish';
  static const loadingMarkers = 'Xarita yuklanmoqda...';
  static const loadMore = "Ko'proq yuklash";
  static const allTypes = 'Turi';
  static const filters = 'Filterlar';
  static const details = 'Batafsil';

  /// Mulk turi tugmalari — saytdagi `propertyTypes` ro'yxati.
  static const propertyTypes = <(String, String)>[
    ('apartment', 'Kvartira'),
    ('house', 'Uy'),
    ('office', 'Ofis'),
    ('shop', "Do'kon"),
  ];
}
