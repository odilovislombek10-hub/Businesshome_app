import '../../core/i18n/translate.dart';

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

  static List<ListingOption> get dealTypes => <ListingOption>[
    ListingOption('sell', t('createListing.sell')),
    ListingOption('rent', t('createListing.rent')),
    ListingOption('exchange', t('createListing.exchange')),
  ];

  static List<ListingOption> get propertyTypes => <ListingOption>[
    ListingOption('apartment', t('createListing.typeApartment')),
    ListingOption('house', t('createListing.typeHouse')),
    ListingOption('office', t('createListing.typeOffice')),
    ListingOption('shop', t('createListing.typeShop')),
    ListingOption('land', t('createListing.typeLand')),
    ListingOption('building', t('createListing.typeWarehouse')),
    ListingOption('parking', t('createListing.typeParking')),
  ];

  static List<ListingOption> get cities => <ListingOption>[
    ListingOption('tashkent_city', t('map.region.tashkent')),
    ListingOption('samarkand', t('map.region.samarkand')),
    ListingOption('bukhara', t('map.region.bukhara')),
    ListingOption('namangan', t('map.region.namangan')),
    ListingOption('andijan', t('map.region.andijan')),
    ListingOption('fergana', t('map.region.fergana')),
    ListingOption('nukus', t('auth.city.nukus')),
    ListingOption('karshi', t('auth.city.karshi')),
    ListingOption('termiz', t('auth.city.termiz')),
    ListingOption('urgench', t('auth.city.urgench')),
    ListingOption('navoi', t('map.region.navoiy')),
    ListingOption('jizzakh', t('map.region.jizzakh')),
    ListingOption('gulistan', t('auth.city.gulistan')),
    ListingOption('chirchik', t('auth.city.chirchik')),
  ];

  static List<ListingOption> get segments => <ListingOption>[
    ListingOption('elite', t('createListing.segment.elite'), icon: '🏆'),
    ListingOption('business', t('createListing.segment.business'), icon: '💼'),
    ListingOption('komfort', t('createListing.segment.komfort'), icon: '✨'),
    ListingOption('standart', t('createListing.segment.standart'), icon: '🏢'),
    ListingOption('economy', t('createListing.segment.economy'), icon: '🏘️'),
  ];

  static List<ListingOption> get repairTypes => <ListingOption>[
    ListingOption('needs', t('createListing.repairType.needs')),
    ListingOption('good', t('createListing.repairType.good')),
    ListingOption('fresh', t('createListing.repairType.fresh')),
  ];

  static List<ListingOption> get designStyles => <ListingOption>[
    ListingOption('classic', t('createListing.designStyle.classic')),
    ListingOption('neoclassic', t('createListing.designStyle.neoclassic')),
    ListingOption('loft', t('createListing.designStyle.loft')),
    ListingOption('hitech', t('createListing.designStyle.hitech')),
    ListingOption('modern', t('createListing.designStyle.modern')),
    ListingOption('minimalism', t('createListing.designStyle.minimalism')),
    ListingOption('luxury', t('createListing.designStyle.luxury')),
  ];

  static List<ListingOption> get floorMaterials => <ListingOption>[
    ListingOption('laminate', t('createListing.floorMat.laminate')),
    ListingOption('parquet', t('createListing.floorMat.parquet')),
    ListingOption('tile', t('createListing.floorMat.tile')),
    ListingOption('stone', t('createListing.floorMat.stone')),
    ListingOption('polymer', t('createListing.floorMat.polymer')),
  ];

  static List<ListingOption> get wallFinishes => <ListingOption>[
    ListingOption('wallpaper', t('createListing.wallFin.wallpaper')),
    ListingOption('paint', t('createListing.wallFin.paint')),
    ListingOption('plaster', t('createListing.wallFin.plaster')),
    ListingOption('decorativeStone', t('createListing.wallFin.decorativeStone')),
  ];

  static List<ListingOption> get ceilingTypes => <ListingOption>[
    ListingOption('simple', t('createListing.ceiling.simple')),
    ListingOption('stretched', t('createListing.ceiling.stretched')),
    ListingOption('multilevel', t('createListing.ceiling.multilevel')),
  ];

  static List<ListingOption> get windowTypes => <ListingOption>[
    ListingOption('wood', t('createListing.window.wood')),
    ListingOption('plastic2', t('createListing.window.plastic2')),
    ListingOption('plastic3', t('createListing.window.plastic3')),
    ListingOption('aluminum', t('createListing.window.aluminum')),
  ];

  static List<ListingOption> get kitchenTypes => <ListingOption>[
    ListingOption('studio', t('createListing.kitchen.studio')),
    ListingOption('separate', t('createListing.bathroomPrivate')),
  ];

  static List<ListingOption> get bathroomLayouts => <ListingOption>[
    ListingOption('combined', t('createListing.bathLayout.combined')),
    ListingOption('separate', t('createListing.bathroomPrivate')),
  ];

  static List<ListingOption> get heatingTypes => <ListingOption>[
    ListingOption('central', t('createListing.heating.central')),
    ListingOption('autonomous', t('createListing.heating.autonomous')),
  ];

  static List<ListingOption> get paymentOptions => <ListingOption>[
    ListingOption('cash', t('createListing.payment.cash'), icon: '💵'),
    ListingOption('mortgage', t('createListing.payment.mortgage'), icon: '🏦'),
    ListingOption('installment', t('createListing.payment.installment'), icon: '📅'),
  ];

  /// Qo'shimcha xonalar — kalit `ListingForm` maydoniga mos keladi.
  static List<ListingOption> get extraRooms => <ListingOption>[
    ListingOption('wardrobeCount', t('createListing.extraRoom.wardrobe'), icon: '👗'),
    ListingOption('storeroomCount', t('createListing.extraRoom.storeroom'), icon: '📦'),
    ListingOption('basementCount', t('createListing.extraRoom.basement'), icon: '🏚️'),
    ListingOption('garageCount', t('createListing.extraRoom.garage'), icon: '🚗'),
  ];

  /// Qulayliklar mulk turiga qarab boshqacha (`getAmenitiesForType`).
  static Map<String, List<ListingOption>> get amenities => <String, List<ListingOption>>{
    'apartment': [
      ListingOption('metroga_yaqin', t('createListing.amenityMetro'), icon: '🚇'),
      ListingOption('maktab_yaqin', t('amenity.nearSchool'), icon: '🏫'),
      ListingOption('shifoxona_yaqin', t('amenity.nearHospital'), icon: '🏥'),
      ListingOption('supermarket', t('amenity.nearSupermarket'), icon: '🛒'),
      ListingOption('yashil_zona', t('amenity.greenZone'), icon: '🌳'),
      ListingOption('lift', t('createListing.amenityLift'), icon: '🛗'),
      ListingOption('parking', t('createListing.amenityParking'), icon: '🅿️'),
      ListingOption('yer_osti_parking', t('amenity.undergroundPark'), icon: '🚙'),
      ListingOption('yopiq_hudud', t('amenity.gatedCommunity'), icon: '🚧'),
      ListingOption('konsyerj', t('amenity.concierge'), icon: '🛎️'),
      ListingOption('hovuz', t('createListing.amenityPool'), icon: '🏊'),
      ListingOption('sport_zal', t('amenity.gym'), icon: '🏋️'),
      ListingOption('sauna', t('amenity.sauna'), icon: '🧖'),
      ListingOption('bolalar_maydoni', t('amenity.playground'), icon: '🎠'),
      ListingOption('markaziy_isitish', t('amenity.centralHeating'), icon: '🔥'),
      ListingOption('avtonom_isitish', t('amenity.autonomousHeating'), icon: '♨️'),
      ListingOption('markaziy_gaz', t('amenity.centralGas'), icon: '🟦'),
      ListingOption('issiq_suv', t('amenity.hotWater'), icon: '💧'),
      ListingOption('konditsioner', t('createListing.amenityAC'), icon: '❄️'),
      ListingOption('wifi', t('amenity.wifi'), icon: '📶'),
      ListingOption('mebel', t('createListing.amenityFurniture'), icon: '🛋️'),
      ListingOption('oshxona_jihozi', t('amenity.kitchenware'), icon: '🍳'),
      ListingOption('kir_mashina', t('amenity.washer'), icon: '🧺'),
      ListingOption('muzlatgich', t('amenity.fridge'), icon: '🧊'),
      ListingOption('tv', t('amenity.tv'), icon: '📺'),
      ListingOption('smart_home', t('amenity.smartHome'), icon: '🏡'),
      ListingOption('domofon', t('amenity.intercom'), icon: '📞'),
      ListingOption('xavfsizlik', t('amenity.security'), icon: '🛡️'),
      ListingOption('videokuzatuv', t('amenity.cctv'), icon: '📹'),
      ListingOption('balkon_shisha', t('amenity.glazedBalcony'), icon: '🪟'),
      ListingOption('jalyuzi', t('amenity.blinds'), icon: '🎐'),
    ],
    'house': [
      ListingOption('hovli', t('createListing.amenityYard'), icon: '🌳'),
      ListingOption('garaj', t('createListing.extraRoom.garage'), icon: '🚗'),
      ListingOption('parking', t('createListing.amenityParking'), icon: '🅿️'),
      ListingOption('bog', t('amenity.garden'), icon: '🌷'),
      ListingOption('basseyn', t('createListing.amenityPool'), icon: '🏊'),
      ListingOption('sauna', t('amenity.sauna'), icon: '🧖'),
      ListingOption('barbekyu', t('amenity.bbq'), icon: '🍖'),
      ListingOption('quduq', t('amenity.well'), icon: '🕳️'),
      ListingOption('mevali_daraxt', t('amenity.fruitTrees'), icon: '🍎'),
      ListingOption('uzumzor', t('amenity.grapevine'), icon: '🍇'),
      ListingOption('issiqxona', t('amenity.greenhouse'), icon: '🌱'),
      ListingOption('omborxona', t('createListing.typeWarehouse'), icon: '🏚️'),
      ListingOption('tomorqa', t('amenity.vegetableGarden'), icon: '🥬'),
      ListingOption('terasa', t('amenity.terrace'), icon: '☀️'),
      ListingOption('mebel', t('createListing.amenityFurniture'), icon: '🛋️'),
      ListingOption('konditsioner', t('createListing.amenityAC'), icon: '❄️'),
      ListingOption('issiq_suv', t('amenity.hotWater'), icon: '💧'),
      ListingOption('kir_mashina', t('amenity.washer'), icon: '🧺'),
      ListingOption('wifi', t('amenity.wifi'), icon: '📶'),
      ListingOption('xavfsizlik', t('amenity.security'), icon: '🛡️'),
    ],
    'office': [
      ListingOption('metroga_yaqin', t('createListing.amenityMetro'), icon: '🚇'),
      ListingOption('parking', t('createListing.amenityParking'), icon: '🅿️'),
      ListingOption('lift', t('createListing.amenityLift'), icon: '🛗'),
      ListingOption('mebel', t('createListing.amenityFurniture'), icon: '🛋️'),
      ListingOption('konditsioner', t('createListing.amenityAC'), icon: '❄️'),
      ListingOption('wifi', t('amenity.wifi'), icon: '📶'),
      ListingOption('server_xona', t('amenity.serverRoom'), icon: '💻'),
      ListingOption('konferens_zal', t('amenity.conferenceRoom'), icon: '👥'),
      ListingOption('qabulxona', t('amenity.reception'), icon: '🛎️'),
      ListingOption('oshxona_zona', t('amenity.kitchenArea'), icon: '☕'),
      ListingOption('xavfsizlik', t('amenity.security'), icon: '🛡️'),
      ListingOption('videokuzatuv', t('amenity.cctv'), icon: '📹'),
      ListingOption('yong_alarmi', t('amenity.fireAlarm'), icon: '🚨'),
      ListingOption('markaziy_isitish', t('amenity.centralHeating'), icon: '🔥'),
    ],
    'shop': [
      ListingOption('parking', t('createListing.amenityParking'), icon: '🅿️'),
      ListingOption('vitrina', t('amenity.displayWindow'), icon: '🪟'),
      ListingOption('omborxona', t('createListing.typeWarehouse'), icon: '📦'),
      ListingOption('kocha_chiqishi', t('amenity.streetAccess'), icon: '🚶'),
      ListingOption('konditsioner', t('createListing.amenityAC'), icon: '❄️'),
      ListingOption('ventilatsiya', t('amenity.ventilation'), icon: '💨'),
      ListingOption('xavfsizlik', t('amenity.security'), icon: '🛡️'),
      ListingOption('videokuzatuv', t('amenity.cctv'), icon: '📹'),
      ListingOption('yong_alarmi', t('amenity.fireAlarm'), icon: '🚨'),
      ListingOption('metroga_yaqin', t('createListing.amenityMetro'), icon: '🚇'),
      ListingOption('yukyuklash_zona', t('amenity.loadingDock'), icon: '🚚'),
      ListingOption('wifi', t('amenity.wifi'), icon: '📶'),
      ListingOption('markaziy_isitish', t('amenity.centralHeating'), icon: '🔥'),
    ],
    'building': [
      ListingOption('lift', t('createListing.amenityLift'), icon: '🛗'),
      ListingOption('parking', t('createListing.amenityParking'), icon: '🅿️'),
      ListingOption('yer_osti_parking', t('amenity.undergroundPark'), icon: '🅿️'),
      ListingOption('xavfsizlik', t('amenity.security'), icon: '🛡️'),
      ListingOption('videokuzatuv', t('amenity.cctv'), icon: '📹'),
      ListingOption('yong_alarmi', t('amenity.fireAlarm'), icon: '🚨'),
      ListingOption('kommunikatsiya', t('amenity.communications'), icon: '⚡'),
      ListingOption('generator', t('amenity.generator'), icon: '🔌'),
      ListingOption('markaziy_isitish', t('amenity.centralHeating'), icon: '🔥'),
      ListingOption('ventilatsiya', t('amenity.ventilation'), icon: '💨'),
      ListingOption('wifi', t('amenity.wifi'), icon: '📶'),
      ListingOption('hovli', t('createListing.amenityYard'), icon: '🌳'),
      ListingOption('metroga_yaqin', t('createListing.amenityMetro'), icon: '🚇'),
    ],
    'land': [
      ListingOption('yol', t('amenity.road'), icon: '🛣️'),
      ListingOption('elektr', t('amenity.electricity'), icon: '⚡'),
      ListingOption('gaz', t('amenity.gas'), icon: '🔥'),
      ListingOption('suv', t('amenity.water'), icon: '💧'),
      ListingOption('kanalizatsiya', t('amenity.sewage'), icon: '🚰'),
      ListingOption('kommunikatsiya', t('amenity.communications'), icon: '📡'),
      ListingOption('tekis_yer', t('amenity.flatLand'), icon: '📐'),
      ListingOption('kadastr', t('amenity.cadastre'), icon: '📋'),
      ListingOption('devor', t('amenity.fence'), icon: '🧱'),
    ],
  };

  /// Noma'lum tur uchun saytda kvartira ro'yxati qaytariladi.
  static List<ListingOption> amenitiesFor(String propertyType) =>
      amenities[propertyType] ?? amenities['apartment']!;
}
