import 'create_listing_texts.dart';

/// E'lon formasining holati — saytdagi `ListingForm` interfeysining aynan o'zi.
///
/// Maydonlar `mutable`: forma bitta ekranda to'ldiriladi va `setState` bilan yangilanadi,
/// har bir o'zgarishda butun obyektni nusxalash bu yerda foyda bermaydi.
class ListingForm {
  String dealType = 'sell';
  String propertyType = 'apartment';
  String title = '';
  String description = '';

  // Asosiy xonalar
  int rooms = 2;
  bool roomsEnabled = false; // omborxona uchun: alohida xona bormi
  int bathrooms = 1;
  bool? bathroomShared; // true = umumiy, false = alohida, null = tanlanmagan
  bool bathroomEnabled = false; // ofis/do'kon/ombor uchun toggle

  // Qo'shimcha xonalar (Sotish + Kvartira)
  final Map<String, int> extraRooms = {
    'wardrobeCount': 0,
    'storeroomCount': 0,
    'basementCount': 0,
    'garageCount': 0,
  };

  bool hasBalcony = false;
  bool hasLoggia = false;
  bool hasVremenka = false;
  double? vremenkaArea;

  // Remont
  bool hasRepair = false;
  String? repairType;
  String? designStyle;
  String? floorMaterial;
  String? wallFinish;
  String? ceilingType;
  String? windowType;
  String? kitchenType;
  String? bathroomLayout;
  String? heatingType;

  // Maydon
  double? livingArea;
  double? balconyArea;
  double? area;
  double? landArea;

  int? floor;
  int? totalFloors;

  String? segment;

  double? price;
  double? pricePerM2;
  String currency = 'UZS';
  final List<String> paymentOptions = [];

  String city = '';
  String district = '';
  String address = '';
  double? locationLat;
  double? locationLng;

  final List<String> amenities = [];
  bool urgent = false;

  // ── ko'rinish shartlari (saytdagi `computed`) ─────────────────────────────

  bool get isSell => dealType == 'sell';
  bool get isRent => dealType == 'rent';
  bool get isExchange => dealType == 'exchange';

  bool get isApartment => propertyType == 'apartment';
  bool get isHouse => propertyType == 'house';
  bool get isOffice => propertyType == 'office';
  bool get isShop => propertyType == 'shop';
  bool get isLand => propertyType == 'land';
  bool get isWarehouse => propertyType == 'building';
  bool get isParking => propertyType == 'parking';

  bool get isSellApartment => isSell && isApartment;
  bool get showRepairDetails => !isLand && !isWarehouse && !isParking;
  bool get showLandArea => isHouse || isLand;

  /// Umumiy maydon saytda yashash + balkon maydonidan avtomatik hisoblanadi.
  double? get computedArea {
    if (livingArea == null && balconyArea == null) return null;
    return (livingArea ?? 0) + (balconyArea ?? 0);
  }

  /// `secondary` yoki `rent` — endpoint shu bilan tanlanadi.
  String get kind => isRent ? 'rent' : 'secondary';

  // ── tekshiruv ─────────────────────────────────────────────────────────────

  /// Saytdagi `validate()` — xato matnlari ham o'sha yerdan.
  Map<String, String> validate({required bool hasImages, required bool isEdit}) {
    final errors = <String, String>{};

    final trimmedTitle = title.trim();
    if (trimmedTitle.length < 15) {
      errors['title'] =
          "Sarlavha kamida 15 belgi bo'lsin (masalan: 'Yashnobodda 3 xonali kvartira')";
    } else if (trimmedTitle.length > 200) {
      errors['title'] = 'Sarlavha 200 belgidan oshmasin';
    }

    final trimmedDesc = description.trim();
    if (trimmedDesc.length < 50) {
      errors['description'] =
          "Tavsif kamida 50 belgi bo'lsin — qisqacha xususiyatlarni ko'rsating "
          '(xonalar, holati, joylashuv)';
    } else if (trimmedDesc.length > 3000) {
      errors['description'] = 'Tavsif 3000 belgidan oshmasin';
    }

    final effectiveArea = (isLand ? landArea : area) ?? 0;
    final minArea = isLand ? 50 : 10;
    final maxArea = isLand ? 100000 : 10000;
    if (effectiveArea <= 0) {
      errors['area'] = CreateListingTexts.errorArea;
    } else if (effectiveArea < minArea || effectiveArea > maxArea) {
      errors['area'] = "Maydon $minArea–$maxArea m² oralig'ida bo'lsin";
    }

    final value = price ?? 0;
    if (value <= 0) {
      errors['price'] = CreateListingTexts.errorPrice;
    } else {
      final usd = currency == 'USD';
      final (minPrice, maxPrice) = isRent
          ? (usd ? 10 : 100000, usd ? 10000 : 200000000)
          : (usd ? 500 : 5000000, usd ? 10000000 : 500000000000);
      if (value < minPrice || value > maxPrice) {
        errors['price'] =
            'Narx ${_group(minPrice)}–${_group(maxPrice)} $currency oralig\'ida bo\'lsin';
      }
    }

    if (city.isEmpty) errors['city'] = CreateListingTexts.errorCity;
    if (address.trim().length < 5) {
      errors['address'] = "Manzilni to'liqroq yozing (kamida 5 belgi)";
    }

    if ((isApartment || isHouse) && floor != null && totalFloors != null) {
      if (floor! > totalFloors!) {
        errors['area'] = 'Qavat $floor jami qavatlardan ($totalFloors) katta bo\'lmasin';
      }
      if (totalFloors! > 100) {
        errors['area'] = "Jami qavatlar 100 dan oshmasin";
      }
    }

    if (!hasImages && !isEdit) {
      final existing = errors['title'];
      errors['title'] = '${existing != null ? '$existing · ' : ''}Kamida 1 ta rasm yuklang';
    }

    return errors;
  }

  static String _group(num value) {
    final digits = value.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  // ── qoralama ──────────────────────────────────────────────────────────────

  /// Avtomatik saqlash uchun — maydon nomlari saytdagi `ListingForm` bilan bir xil, shuning
  /// uchun saytda saqlangan qoralama ham o'qiladi.
  Map<String, dynamic> toJson() => {
    'dealType': dealType,
    'propertyType': propertyType,
    'title': title,
    'description': description,
    'rooms': rooms,
    'roomsEnabled': roomsEnabled,
    'bathrooms': bathrooms,
    'bathroomShared': bathroomShared,
    'bathroomEnabled': bathroomEnabled,
    ...extraRooms,
    'hasBalcony': hasBalcony,
    'hasLoggia': hasLoggia,
    'hasVremenka': hasVremenka,
    'vremenkaArea': vremenkaArea,
    'hasRepair': hasRepair,
    'repairType': repairType,
    'designStyle': designStyle,
    'floorMaterial': floorMaterial,
    'wallFinish': wallFinish,
    'ceilingType': ceilingType,
    'windowType': windowType,
    'kitchenType': kitchenType,
    'bathroomLayout': bathroomLayout,
    'heatingType': heatingType,
    'livingArea': livingArea,
    'balconyArea': balconyArea,
    'area': area,
    'landArea': landArea,
    'floor': floor,
    'totalFloors': totalFloors,
    'segment': segment,
    'price': price,
    'pricePerM2': pricePerM2,
    'currency': currency,
    'paymentOptions': paymentOptions,
    'city': city,
    'district': district,
    'address': address,
    'locationLat': locationLat,
    'locationLng': locationLng,
    'amenities': amenities,
    'urgent': urgent,
  };

  void applyJson(Map<String, dynamic> json) {
    String str(String key, String fallback) => json[key] is String ? json[key] as String : fallback;
    double? dbl(String key) => (json[key] as num?)?.toDouble();
    int? integer(String key) => (json[key] as num?)?.toInt();
    bool flag(String key, [bool fallback = false]) =>
        json[key] is bool ? json[key] as bool : fallback;
    List<String> strings(String key) =>
        json[key] is List ? [for (final v in json[key] as List) v.toString()] : const <String>[];

    dealType = str('dealType', dealType);
    propertyType = str('propertyType', propertyType);
    title = str('title', title);
    description = str('description', description);
    rooms = integer('rooms') ?? rooms;
    roomsEnabled = flag('roomsEnabled', roomsEnabled);
    bathrooms = integer('bathrooms') ?? bathrooms;
    bathroomShared = json['bathroomShared'] is bool ? json['bathroomShared'] as bool : null;
    bathroomEnabled = flag('bathroomEnabled', bathroomEnabled);
    for (final key in extraRooms.keys) {
      extraRooms[key] = integer(key) ?? 0;
    }
    hasBalcony = flag('hasBalcony');
    hasLoggia = flag('hasLoggia');
    hasVremenka = flag('hasVremenka');
    vremenkaArea = dbl('vremenkaArea');
    hasRepair = flag('hasRepair');
    repairType = json['repairType'] as String?;
    designStyle = json['designStyle'] as String?;
    floorMaterial = json['floorMaterial'] as String?;
    wallFinish = json['wallFinish'] as String?;
    ceilingType = json['ceilingType'] as String?;
    windowType = json['windowType'] as String?;
    kitchenType = json['kitchenType'] as String?;
    bathroomLayout = json['bathroomLayout'] as String?;
    heatingType = json['heatingType'] as String?;
    livingArea = dbl('livingArea');
    balconyArea = dbl('balconyArea');
    area = dbl('area');
    landArea = dbl('landArea');
    floor = integer('floor');
    totalFloors = integer('totalFloors');
    segment = json['segment'] as String?;
    price = dbl('price');
    pricePerM2 = dbl('pricePerM2');
    currency = str('currency', currency);
    paymentOptions
      ..clear()
      ..addAll(strings('paymentOptions'));
    city = str('city', city);
    district = str('district', district);
    address = str('address', address);
    locationLat = dbl('locationLat');
    locationLng = dbl('locationLng');
    amenities
      ..clear()
      ..addAll(strings('amenities'));
    urgent = flag('urgent');
  }

  // ── jo'natish ─────────────────────────────────────────────────────────────

  /// Saytdagi `payload` bilan aynan bir xil — maydon nomlari ham snake_case.
  Map<String, dynamic> toPayload({
    required String ownerName,
    required String ownerPhone,
    required bool isAgent,
  }) => {
    'title': title.trim(),
    'type': propertyType.isEmpty ? 'apartment' : propertyType,
    'price': price ?? 0,
    'currency': currency.toLowerCase(),
    'rooms': rooms,
    'bathrooms': bathrooms,
    'has_balcony': hasBalcony,
    'has_vremenka': hasVremenka ? true : null,
    'vremenka_area': vremenkaArea,
    'area': isLand ? (landArea ?? 0) : (area ?? 0),
    'land_area': landArea,
    'floor': floor ?? 0,
    'total_floors': totalFloors ?? 0,
    'segment': segment,
    'has_repair': hasRepair,
    'payment_options': paymentOptions,
    'city': city,
    'district': district,
    'address': address.trim(),
    'lat': locationLat ?? 0,
    'lng': locationLng ?? 0,
    'description': description.trim(),
    'amenities': amenities,
    'images': <String>[],
    // Video hozircha yuklanmaydi — saytda ham faqat tashqi `http(s)` havola yuboriladi.
    'video_url': null,
    'owner_name': ownerName,
    'owner_phone': ownerPhone,
    'owner_type': isAgent ? 'agent' : 'owner',
  };
}
