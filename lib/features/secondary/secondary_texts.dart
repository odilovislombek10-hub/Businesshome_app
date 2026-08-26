/// Every string the `/secondary` page prints, taken verbatim from the site's `i18n/uz.ts`.
abstract final class SecondaryTexts {
  static const heroTitle = "Business e'lonlari";
  static const heroDesc =
      "Ikkilamchi turar va noturar binolar — sotib olish uchun kvartira, hovli uy, ofis, "
      "do'kon va bino";
  static const searchPlaceholder = 'Nma qidiryapsiz';
  static const filters = 'Filterlar';
  static const searchOnMap = 'Xaritadan qidirish';
  static const activeListings = "ta faol e'lon";
  static const updatedToday = 'Bugun yangilangan';
  static const resetAll = 'Tozalash';
  static const resultsFound = "ta e'lon topildi";
  static const propertyType = 'Mulk turi';
  static const rooms = 'Xonalar';
  static const priceRange = "Narx oralig'i";
  static const extras = "Qo'shimcha";
  static const noResults = 'Hech narsa topilmadi';
  static const noResultsDesc = 'Boshqa filterlarni tanlang';
  static const allOption = 'Barchasi';

  /// `rent.any` — tuman tanlashdagi "hammasi" varianti.
  static const anyDistrict = "Farqi yo'q";

  // Sorting, in the order the site lists the options.
  static const sortOptions = <(String, String)>[
    ('newest', 'Eng yangi'),
    ('price_asc', 'Narx: arzondan'),
    ('price_desc', 'Narx: qimmatdan'),
    ('area_desc', 'Maydon: kattadan'),
  ];

  /// `rent.*` keys the secondary page reuses.
  static const segment = 'Segment';
  static const bathrooms = 'Sanuzellar';
  static const floor = 'Qavat';
  static const seller = 'Sotuvchi';
  static const payment = "To'lov";
  static const furnished = 'Meblangan';
  static const repair = 'Remont';
  static const roomShort = 'xona';
  static const bathroomShort = 'sanuzel';
  static const allCities = 'Barcha shaharlar';

  static const propertyTypes = <(String, String)>[
    ('', 'Barcha turlar'),
    ('apartment', 'Kvartira'),
    ('house', 'Hovli uy'),
    ('office', 'Ofis'),
    ('shop', "Do'kon"),
    ('building', 'Bino'),
    ('land', 'Yer'),
  ];

  static const segments = <(String, String)>[
    ('elite', 'Elite'),
    ('business', 'Biznes'),
    ('standart', 'Standart'),
    ('economy', 'Ekonom'),
  ];

  static const sellers = <(String, String)>[
    ('owner', 'Uy egasi'),
    ('agent', 'Reltor'),
    ('noAgent', 'Reltorsiz'),
  ];

  static const payments = <(String, String)>[
    ('mortgage', 'Ipoteka'),
    ('installment', 'Rassrochka'),
    ('cash', 'Foizsiz'),
  ];

  /// `rent.furnishedYes/No` and `rent.repairYes/No` — not a plain yes/no pair.
  static const furnishedOptions = <(String, String)>[
    ('', allOption),
    ('yes', 'Meblangan'),
    ('no', 'Mebelsiz'),
  ];

  static const repairOptions = <(String, String)>[
    ('', allOption),
    ('yes', 'Remontli'),
    ('no', 'Remontsiz'),
  ];

  /// The single checkbox under "Qo'shimcha".
  static const hasVirtualTour = '3D virtual tur mavjud';

  /// Range input placeholders (`rent.from` / `rent.to`).
  static const rangeFrom = 'dan';
  static const rangeTo = 'gacha';

  /// `areaLabelKey()` swaps the label when every selected type is house or land.
  static const areaM2 = 'Kvadratura (m²)';
  static const areaLand = 'Yer maydoni (sotix)';

  static const roomOptions = [1, 2, 3, 4, 5];
  static const bathroomOptions = [1, 2, 3, 4];

  /// The hero photo the site hard-codes behind the search box.
  static const heroImage =
      'https://images.unsplash.com/photo-1600047509807-ba8f99d2cdde?w=1920&q=80';
}
