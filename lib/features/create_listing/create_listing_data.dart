// BU FAYL SAYT MANBASIDAN AVTOMATIK YARATILGAN — qo'lda tahrirlamang.
// Manba: `features/create-listing/create-listing.component.ts`,
// `shared/utils/amenities.ts`, `core/i18n/translations/uz.ts`.

/// E'lon formasidagi bitta tanlov: qiymat backendga ketadi, yorliq ekranda ko'rinadi.
class ListingOption {
  const ListingOption(this.value, this.label, {this.icon});

  final String value;
  final String label;

  /// Saytda ba'zi tugmalarda emoji turadi (segment, to'lov turi, qo'shimcha xona).
  final String? icon;
}

abstract final class ListingOptions {
  static const rooms = [1, 2, 3, 4, 5, 6];
  static const bathrooms = [1, 2, 3, 4];

  static const dealTypes = <ListingOption>[
    ListingOption('sell', 'Sotish'),
    ListingOption('rent', 'Ijara'),
    ListingOption('exchange', 'Almashish'),
  ];

  static const propertyTypes = <ListingOption>[
    ListingOption('apartment', 'Kvartira'),
    ListingOption('house', 'Hovli uy'),
    ListingOption('office', 'Ofis'),
    ListingOption('shop', "Do'kon"),
    ListingOption('land', 'Yer'),
    ListingOption('building', 'Omborxona'),
    ListingOption('parking', 'Avto-turargoh'),
  ];

  static const cities = <ListingOption>[
    ListingOption('tashkent_city', 'Toshkent'),
    ListingOption('samarkand', 'Samarqand'),
    ListingOption('bukhara', 'Buxoro'),
    ListingOption('namangan', 'Namangan'),
    ListingOption('andijan', 'Andijon'),
    ListingOption('fergana', "Farg'ona"),
    ListingOption('nukus', 'Nukus'),
    ListingOption('karshi', 'Qarshi'),
    ListingOption('termiz', 'Termiz'),
    ListingOption('urgench', 'Urganch'),
    ListingOption('navoi', 'Navoiy'),
    ListingOption('jizzakh', 'Jizzax'),
    ListingOption('gulistan', 'Guliston'),
    ListingOption('chirchik', 'Chirchiq'),
  ];

  static const segments = <ListingOption>[
    ListingOption('elite', 'Elite', icon: '🏆'),
    ListingOption('business', 'Biznes', icon: '💼'),
    ListingOption('komfort', 'Komfort', icon: '✨'),
    ListingOption('standart', 'Standart', icon: '🏢'),
    ListingOption('economy', 'Ekonom', icon: '🏘️'),
  ];

  static const repairTypes = <ListingOption>[
    ListingOption('needs', 'Remont talab'),
    ListingOption('good', 'Yaxshi'),
    ListingOption('fresh', 'Yangi remont'),
  ];

  static const designStyles = <ListingOption>[
    ListingOption('classic', 'Klassik'),
    ListingOption('neoclassic', 'Neoklassika'),
    ListingOption('loft', 'Loft'),
    ListingOption('hitech', 'Hi-tech'),
    ListingOption('modern', 'Zamonaviy'),
    ListingOption('minimalism', 'Minimalizm'),
    ListingOption('luxury', 'Lyuks'),
  ];

  static const floorMaterials = <ListingOption>[
    ListingOption('laminate', 'Laminat'),
    ListingOption('parquet', 'Parket'),
    ListingOption('tile', 'Kafel'),
    ListingOption('stone', 'Tabiiy tosh'),
    ListingOption('polymer', 'Polimer'),
  ];

  static const wallFinishes = <ListingOption>[
    ListingOption('wallpaper', 'Oboi'),
    ListingOption('paint', "Bo'yoq"),
    ListingOption('plaster', 'Suvoq'),
    ListingOption('decorativeStone', 'Dekorativ tosh'),
  ];

  static const ceilingTypes = <ListingOption>[
    ListingOption('simple', 'Oddiy'),
    ListingOption('stretched', 'Natyajnoy'),
    ListingOption('multilevel', "Ko'p qatorli"),
  ];

  static const windowTypes = <ListingOption>[
    ListingOption('wood', "Yog'och"),
    ListingOption('plastic2', 'Plastik (2 kamerali)'),
    ListingOption('plastic3', 'Plastik (3 kamerali)'),
    ListingOption('aluminum', 'Alyumin'),
  ];

  static const kitchenTypes = <ListingOption>[
    ListingOption('studio', 'Studiya'),
    ListingOption('separate', 'Alohida'),
  ];

  static const bathroomLayouts = <ListingOption>[
    ListingOption('combined', 'Birgalikda'),
    ListingOption('separate', 'Alohida'),
  ];

  static const heatingTypes = <ListingOption>[
    ListingOption('central', 'Markaziy'),
    ListingOption('autonomous', 'Avtonom'),
  ];

  static const paymentOptions = <ListingOption>[
    ListingOption('cash', 'Naqd', icon: '💵'),
    ListingOption('mortgage', 'Ipoteka', icon: '🏦'),
    ListingOption('installment', "Muddatli to'lov", icon: '📅'),
  ];

  /// Qo'shimcha xonalar — kalit `ListingForm` maydoniga mos keladi.
  static const extraRooms = <ListingOption>[
    ListingOption('wardrobeCount', 'Garderob', icon: '👗'),
    ListingOption('storeroomCount', 'Ombor', icon: '📦'),
    ListingOption('basementCount', "Yerto'la", icon: '🏚️'),
    ListingOption('garageCount', 'Garaj', icon: '🚗'),
  ];

  /// Qulayliklar mulk turiga qarab boshqacha (`getAmenitiesForType`).
  static const amenities = <String, List<ListingOption>>{
    'apartment': [
      ListingOption('metroga_yaqin', 'Metro yaqin', icon: '🚇'),
      ListingOption('maktab_yaqin', 'Maktab yaqin', icon: '🏫'),
      ListingOption('shifoxona_yaqin', 'Shifoxona yaqin', icon: '🏥'),
      ListingOption('supermarket', 'Supermarket yaqin', icon: '🛒'),
      ListingOption('yashil_zona', 'Park / Yashil zona', icon: '🌳'),
      ListingOption('lift', 'Lift', icon: '🛗'),
      ListingOption('parking', 'Parking', icon: '🅿️'),
      ListingOption('yer_osti_parking', 'Yer osti parking', icon: '🚙'),
      ListingOption('yopiq_hudud', 'Yopiq hudud', icon: '🚧'),
      ListingOption('konsyerj', 'Konsyerj', icon: '🛎️'),
      ListingOption('hovuz', 'Basseyn', icon: '🏊'),
      ListingOption('sport_zal', 'Sport zali', icon: '🏋️'),
      ListingOption('sauna', 'Sauna', icon: '🧖'),
      ListingOption('bolalar_maydoni', 'Bolalar maydoni', icon: '🎠'),
      ListingOption('markaziy_isitish', 'Markaziy isitish', icon: '🔥'),
      ListingOption('avtonom_isitish', 'Avtonom isitish', icon: '♨️'),
      ListingOption('markaziy_gaz', 'Markaziy gaz', icon: '🟦'),
      ListingOption('issiq_suv', 'Issiq suv', icon: '💧'),
      ListingOption('konditsioner', 'Konditsioner', icon: '❄️'),
      ListingOption('wifi', 'Wi-Fi', icon: '📶'),
      ListingOption('mebel', 'Meblangan', icon: '🛋️'),
      ListingOption('oshxona_jihozi', 'Oshxona jihozi', icon: '🍳'),
      ListingOption('kir_mashina', 'Kir mashina', icon: '🧺'),
      ListingOption('muzlatgich', 'Muzlatgich', icon: '🧊'),
      ListingOption('tv', 'Televizor', icon: '📺'),
      ListingOption('smart_home', 'Smart Home', icon: '🏡'),
      ListingOption('domofon', 'Domofon', icon: '📞'),
      ListingOption('xavfsizlik', 'Xavfsizlik', icon: '🛡️'),
      ListingOption('videokuzatuv', 'Videokuzatuv', icon: '📹'),
      ListingOption('balkon_shisha', 'Shisha balkon', icon: '🪟'),
      ListingOption('jalyuzi', 'Jalyuzi', icon: '🎐'),
    ],
    'house': [
      ListingOption('hovli', 'Hovli', icon: '🌳'),
      ListingOption('garaj', 'Garaj', icon: '🚗'),
      ListingOption('parking', 'Parking', icon: '🅿️'),
      ListingOption('bog', "Bog'", icon: '🌷'),
      ListingOption('basseyn', 'Basseyn', icon: '🏊'),
      ListingOption('sauna', 'Sauna', icon: '🧖'),
      ListingOption('barbekyu', 'Barbekyu', icon: '🍖'),
      ListingOption('quduq', 'Quduq', icon: '🕳️'),
      ListingOption('mevali_daraxt', 'Mevali daraxtlar', icon: '🍎'),
      ListingOption('uzumzor', 'Uzumzor', icon: '🍇'),
      ListingOption('issiqxona', 'Issiqxona', icon: '🌱'),
      ListingOption('omborxona', 'Omborxona', icon: '🏚️'),
      ListingOption('tomorqa', 'Tomorqa', icon: '🥬'),
      ListingOption('terasa', 'Terasa', icon: '☀️'),
      ListingOption('mebel', 'Meblangan', icon: '🛋️'),
      ListingOption('konditsioner', 'Konditsioner', icon: '❄️'),
      ListingOption('issiq_suv', 'Issiq suv', icon: '💧'),
      ListingOption('kir_mashina', 'Kir mashina', icon: '🧺'),
      ListingOption('wifi', 'Wi-Fi', icon: '📶'),
      ListingOption('xavfsizlik', 'Xavfsizlik', icon: '🛡️'),
    ],
    'office': [
      ListingOption('metroga_yaqin', 'Metro yaqin', icon: '🚇'),
      ListingOption('parking', 'Parking', icon: '🅿️'),
      ListingOption('lift', 'Lift', icon: '🛗'),
      ListingOption('mebel', 'Meblangan', icon: '🛋️'),
      ListingOption('konditsioner', 'Konditsioner', icon: '❄️'),
      ListingOption('wifi', 'Wi-Fi', icon: '📶'),
      ListingOption('server_xona', 'Server xonasi', icon: '💻'),
      ListingOption('konferens_zal', 'Konferens zal', icon: '👥'),
      ListingOption('qabulxona', 'Qabulxona', icon: '🛎️'),
      ListingOption('oshxona_zona', 'Oshxona zonasi', icon: '☕'),
      ListingOption('xavfsizlik', 'Xavfsizlik', icon: '🛡️'),
      ListingOption('videokuzatuv', 'Videokuzatuv', icon: '📹'),
      ListingOption('yong_alarmi', "Yong'in alarmi", icon: '🚨'),
      ListingOption('markaziy_isitish', 'Markaziy isitish', icon: '🔥'),
    ],
    'shop': [
      ListingOption('parking', 'Parking', icon: '🅿️'),
      ListingOption('vitrina', 'Vitrina', icon: '🪟'),
      ListingOption('omborxona', 'Omborxona', icon: '📦'),
      ListingOption('kocha_chiqishi', "Ko'chadan chiqish", icon: '🚶'),
      ListingOption('konditsioner', 'Konditsioner', icon: '❄️'),
      ListingOption('ventilatsiya', 'Ventilatsiya', icon: '💨'),
      ListingOption('xavfsizlik', 'Xavfsizlik', icon: '🛡️'),
      ListingOption('videokuzatuv', 'Videokuzatuv', icon: '📹'),
      ListingOption('yong_alarmi', "Yong'in alarmi", icon: '🚨'),
      ListingOption('metroga_yaqin', 'Metro yaqin', icon: '🚇'),
      ListingOption('yukyuklash_zona', 'Yuk tushirish zonasi', icon: '🚚'),
      ListingOption('wifi', 'Wi-Fi', icon: '📶'),
      ListingOption('markaziy_isitish', 'Markaziy isitish', icon: '🔥'),
    ],
    'building': [
      ListingOption('lift', 'Lift', icon: '🛗'),
      ListingOption('parking', 'Parking', icon: '🅿️'),
      ListingOption('yer_osti_parking', 'Yer osti parking', icon: '🅿️'),
      ListingOption('xavfsizlik', 'Xavfsizlik', icon: '🛡️'),
      ListingOption('videokuzatuv', 'Videokuzatuv', icon: '📹'),
      ListingOption('yong_alarmi', "Yong'in alarmi", icon: '🚨'),
      ListingOption('kommunikatsiya', 'Kommunikatsiyalar', icon: '⚡'),
      ListingOption('generator', 'Generator', icon: '🔌'),
      ListingOption('markaziy_isitish', 'Markaziy isitish', icon: '🔥'),
      ListingOption('ventilatsiya', 'Ventilatsiya', icon: '💨'),
      ListingOption('wifi', 'Wi-Fi', icon: '📶'),
      ListingOption('hovli', 'Hovli', icon: '🌳'),
      ListingOption('metroga_yaqin', 'Metro yaqin', icon: '🚇'),
    ],
    'land': [
      ListingOption('yol', "Yo'l", icon: '🛣️'),
      ListingOption('elektr', 'Elektr', icon: '⚡'),
      ListingOption('gaz', 'Gaz', icon: '🔥'),
      ListingOption('suv', 'Suv', icon: '💧'),
      ListingOption('kanalizatsiya', 'Kanalizatsiya', icon: '🚰'),
      ListingOption('kommunikatsiya', 'Kommunikatsiyalar', icon: '📡'),
      ListingOption('tekis_yer', 'Tekis yer', icon: '📐'),
      ListingOption('kadastr', 'Kadastr hujjati', icon: '📋'),
      ListingOption('devor', 'Devor', icon: '🧱'),
    ],
  };

  /// Noma'lum tur uchun saytda kvartira ro'yxati qaytariladi.
  static List<ListingOption> amenitiesFor(String propertyType) =>
      amenities[propertyType] ?? amenities['apartment']!;
}
