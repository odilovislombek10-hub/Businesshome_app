import '../../core/api/media_url.dart';

/// `/api/market/cabinet/my-home` javobining modellari — saytdagi `my-home.types.ts` dan.
///
/// Ma'lumot quruvchining CRM'idan keladi: shartnoma, xonadon, moliya, to'lov grafigi,
/// qurilish jarayoni, bozor tahlili va hujjatlar. Bitta foydalanuvchida bir nechta mulk
/// bo'lishi mumkin — shuning uchun javob `properties` ro'yxati bilan ham keladi.
class MyHomeProperty {
  const MyHomeProperty({
    this.projectName = '',
    this.address = '',
    this.block = '',
    this.entrance = '',
    this.floor,
    this.apartmentNumber = '',
    this.area,
    this.rooms,
    this.unitType,
    this.status = '',
    this.coverImage,
    this.layoutImage,
    this.layoutImages = const [],
    this.deliveryDate = '',
  });

  final String projectName;
  final String address;
  final String block;
  final String entrance;
  final int? floor;
  final String apartmentNumber;
  final num? area;
  final int? rooms;

  /// `magazin` bo'lsa do'kon, aks holda kvartira.
  final String? unitType;
  final String status;
  final String? coverImage;
  final String? layoutImage;
  final List<String> layoutImages;
  final String deliveryDate;

  bool get isShop => unitType == 'magazin';

  factory MyHomeProperty.fromJson(Map<String, dynamic> json) => MyHomeProperty(
    projectName: json['project_name']?.toString() ?? '',
    address: json['address']?.toString() ?? '',
    block: json['block']?.toString() ?? '',
    entrance: json['entrance']?.toString() ?? '',
    floor: (json['floor'] as num?)?.toInt(),
    apartmentNumber: json['apartment_number']?.toString() ?? '',
    area: json['area'] as num?,
    rooms: (json['rooms'] as num?)?.toInt(),
    unitType: _text(json['unit_type']),
    status: json['status']?.toString() ?? '',
    coverImage: absoluteMediaUrl(_text(json['cover_image'])),
    layoutImage: absoluteMediaUrl(_text(json['layout_image'])),
    layoutImages: <String>[
      for (final item in (json['layout_images'] as List?) ?? const [])
        ?absoluteMediaUrl(_text(item)),
    ],
    deliveryDate: json['delivery_date']?.toString() ?? '',
  );
}

class MyHomeContract {
  const MyHomeContract({
    this.number = '',
    this.date = '',
    this.status = '',
    this.buyerFullName = '',
    this.developerName = '',
    this.paymentType = '',
    this.warrantyMonths,
    this.latePaymentTerms = '',
    this.additionalNotes = '',
    this.pdfUrl,
  });

  final String number;
  final String date;
  final String status;
  final String buyerFullName;
  final String developerName;
  final String paymentType;
  final int? warrantyMonths;
  final String latePaymentTerms;
  final String additionalNotes;
  final String? pdfUrl;

  factory MyHomeContract.fromJson(Map<String, dynamic> json) => MyHomeContract(
    number: json['number']?.toString() ?? '',
    date: json['date']?.toString() ?? '',
    status: json['status']?.toString() ?? '',
    buyerFullName: json['buyer_full_name']?.toString() ?? '',
    developerName: json['developer_name']?.toString() ?? '',
    paymentType: json['payment_type']?.toString() ?? '',
    warrantyMonths: (json['warranty_months'] as num?)?.toInt(),
    latePaymentTerms: json['late_payment_terms']?.toString() ?? '',
    additionalNotes: json['additional_notes']?.toString() ?? '',
    pdfUrl: absoluteMediaUrl(_text(json['pdf_url'])),
  );
}

class MyHomeFinance {
  const MyHomeFinance({
    this.totalPrice = 0,
    this.pricePerM2 = 0,
    this.paidAmount = 0,
    this.remainingAmount = 0,
    this.currentMarketPrice = 0,
    this.currentPricePerM2 = 0,
    this.growthPercent = 0,
    this.districtGrowthPercent = 0,
    this.districtGrowthMonths = 0,
    this.nextPaymentDate = '',
    this.nextPaymentAmount = 0,
  });

  final num totalPrice;
  final num pricePerM2;
  final num paidAmount;
  final num remainingAmount;
  final num currentMarketPrice;
  final num currentPricePerM2;
  final num growthPercent;
  final num districtGrowthPercent;
  final int districtGrowthMonths;
  final String nextPaymentDate;
  final num nextPaymentAmount;

  /// Saytdagi `paidPct()` — to'langan ulush foizi.
  int get paidPercent {
    if (totalPrice <= 0) return 0;
    return (paidAmount / totalPrice * 100).round().clamp(0, 100);
  }

  /// Saytdagi `investmentGrowth()` — bozor narxi va sotib olingan narx farqi.
  num get growth => currentMarketPrice - totalPrice;

  factory MyHomeFinance.fromJson(Map<String, dynamic> json) => MyHomeFinance(
    totalPrice: (json['total_price'] as num?) ?? 0,
    pricePerM2: (json['price_per_m2'] as num?) ?? 0,
    paidAmount: (json['paid_amount'] as num?) ?? 0,
    remainingAmount: (json['remaining_amount'] as num?) ?? 0,
    currentMarketPrice: (json['current_market_price'] as num?) ?? 0,
    currentPricePerM2: (json['current_price_per_m2'] as num?) ?? 0,
    growthPercent: (json['growth_percent'] as num?) ?? 0,
    districtGrowthPercent: (json['district_growth_percent'] as num?) ?? 0,
    districtGrowthMonths: (json['district_growth_months'] as num?)?.toInt() ?? 0,
    nextPaymentDate: json['next_payment_date']?.toString() ?? '',
    nextPaymentAmount: (json['next_payment_amount'] as num?) ?? 0,
  );
}

/// To'lov tarixidagi bitta yozuv.
class MyHomePayment {
  const MyHomePayment({
    required this.date,
    required this.amount,
    required this.status,
    this.receiptUrl,
  });

  final String date;
  final num amount;

  /// `paid` | `pending` | `upcoming` | `overdue`
  final String status;
  final String? receiptUrl;

  factory MyHomePayment.fromJson(Map<String, dynamic> json) => MyHomePayment(
    date: json['date']?.toString() ?? '',
    amount: (json['amount'] as num?) ?? 0,
    status: json['status']?.toString() ?? '',
    receiptUrl: absoluteMediaUrl(_text(json['receipt_url'])),
  );
}

/// To'lov grafigidagi bitta oy.
class MyHomeScheduleRow {
  const MyHomeScheduleRow({
    required this.n,
    required this.date,
    required this.amount,
    required this.paidAmount,
    required this.status,
    this.receiptUrl,
  });

  final int n;
  final String date;
  final num amount;
  final num paidAmount;

  /// `paid` | `partial` | `upcoming`
  final String status;
  final String? receiptUrl;

  factory MyHomeScheduleRow.fromJson(Map<String, dynamic> json) => MyHomeScheduleRow(
    n: (json['n'] as num?)?.toInt() ?? 0,
    date: json['date']?.toString() ?? '',
    amount: (json['amount'] as num?) ?? 0,
    paidAmount: (json['paid_amount'] as num?) ?? 0,
    status: json['status']?.toString() ?? '',
    receiptUrl: absoluteMediaUrl(_text(json['receipt_url'])),
  );
}

class MyHomeConstruction {
  const MyHomeConstruction({
    this.progress = 0,
    this.pacePercent = 0,
    this.stage = '',
    this.lastUpdate = '',
    this.stages = const [],
    this.photos = const [],
    this.aiSummary = '',
  });

  final int progress;

  /// Musbat — jadvaldan tez, manfiy — kechikmoqda.
  final num pacePercent;
  final String stage;
  final String lastUpdate;
  final List<(String, int)> stages;
  final List<String> photos;
  final String aiSummary;

  factory MyHomeConstruction.fromJson(Map<String, dynamic> json) => MyHomeConstruction(
    progress: (json['progress'] as num?)?.toInt() ?? 0,
    pacePercent: (json['pace_percent'] as num?) ?? 0,
    stage: json['stage']?.toString() ?? '',
    lastUpdate: json['last_update']?.toString() ?? '',
    stages: <(String, int)>[
      for (final item in (json['stages'] as List?) ?? const [])
        if (item is Map) (item['name']?.toString() ?? '', (item['progress'] as num?)?.toInt() ?? 0),
    ],
    photos: <String>[
      for (final item in (json['photos'] as List?) ?? const []) ?absoluteMediaUrl(_text(item)),
    ],
    aiSummary: json['ai_summary']?.toString() ?? '',
  );
}

class MyHomeSimilar {
  const MyHomeSimilar({
    required this.title,
    required this.price,
    this.area,
    this.rooms,
    this.district,
    this.pricePerM2,
  });

  final String title;
  final num price;
  final num? area;
  final int? rooms;
  final String? district;
  final num? pricePerM2;

  factory MyHomeSimilar.fromJson(Map<String, dynamic> json) => MyHomeSimilar(
    title: json['title']?.toString() ?? json['name']?.toString() ?? '',
    price: (json['price'] as num?) ?? 0,
    area: json['area'] as num?,
    rooms: (json['rooms'] as num?)?.toInt(),
    district: _text(json['district']),
    pricePerM2: json['price_per_m2'] as num?,
  );
}

class MyHomeMarket {
  const MyHomeMarket({this.similar = const [], this.history = const [], this.aiInsight = ''});

  final List<MyHomeSimilar> similar;

  /// `(sana, m² uchun median narx)` — narx dinamikasi grafigi uchun.
  final List<(String, num)> history;
  final String aiInsight;

  factory MyHomeMarket.fromJson(Map<String, dynamic> json) => MyHomeMarket(
    similar: <MyHomeSimilar>[
      for (final item in (json['similar_apartments'] as List?) ?? const [])
        if (item is Map<String, dynamic>) MyHomeSimilar.fromJson(item),
    ],
    history: <(String, num)>[
      for (final item in (json['price_history'] as List?) ?? const [])
        if (item is Map)
          (
            item['date']?.toString() ?? item['month']?.toString() ?? '',
            (item['median_price_per_m2'] as num?) ?? (item['market_price'] as num?) ?? 0,
          ),
    ],
    aiInsight: json['ai_insight']?.toString() ?? '',
  );
}

class MyHomeDocument {
  const MyHomeDocument({
    required this.id,
    required this.category,
    required this.name,
    required this.date,
    required this.sizeBytes,
    required this.url,
  });

  final String id;

  /// `contract` | `receipts` | `cadastre` | `warranty` | `layout` | `design` | `other`
  final String category;
  final String name;
  final String date;
  final int sizeBytes;
  final String url;

  factory MyHomeDocument.fromJson(Map<String, dynamic> json) => MyHomeDocument(
    id: json['id']?.toString() ?? '',
    category: json['category']?.toString() ?? 'other',
    name: json['name']?.toString() ?? '',
    date: json['date']?.toString() ?? '',
    sizeBytes: (json['size_bytes'] as num?)?.toInt() ?? 0,
    url: absoluteMediaUrl(_text(json['url'])) ?? '',
  );
}

/// Bitta mulk — saytdagi `MyHomePropertyItem`.
class MyHomeItem {
  const MyHomeItem({
    this.label,
    this.unitType,
    this.devCode,
    this.contractId,
    this.contract,
    this.property,
    this.finance,
    this.payments = const [],
    this.schedule = const [],
    this.construction,
    this.market,
    this.documents = const [],
  });

  final String? label;
  final String? unitType;

  /// `_meta` dan — to'lov chaqiruvida `dev_code` va `contract_id` bo'lib ketadi.
  final String? devCode;
  final int? contractId;
  final MyHomeContract? contract;
  final MyHomeProperty? property;
  final MyHomeFinance? finance;
  final List<MyHomePayment> payments;
  final List<MyHomeScheduleRow> schedule;
  final MyHomeConstruction? construction;
  final MyHomeMarket? market;
  final List<MyHomeDocument> documents;

  bool get isShop => unitType == 'magazin' || property?.isShop == true;

  /// Ro'yxatdagi sarlavha — saytdagi `propertyLabel()`.
  String labelFor(int index) {
    if (label != null && label!.isNotEmpty) return label!;
    final number = property?.apartmentNumber ?? '';
    if (number.isNotEmpty) return '№$number';
    return '${index + 1}-mulk';
  }

  factory MyHomeItem.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? section(String key) =>
        json[key] is Map<String, dynamic> ? json[key] as Map<String, dynamic> : null;

    final meta = section('_meta');
    return MyHomeItem(
      label: _text(json['label']),
      unitType: _text(json['unit_type']),
      devCode: meta == null ? null : _text(meta['dev_code']),
      contractId: (meta?['contract_id'] as num?)?.toInt(),
      contract: section('contract') == null ? null : MyHomeContract.fromJson(section('contract')!),
      property: section('property') == null ? null : MyHomeProperty.fromJson(section('property')!),
      finance: section('finance') == null ? null : MyHomeFinance.fromJson(section('finance')!),
      payments: <MyHomePayment>[
        for (final item in (json['payments'] as List?) ?? const [])
          if (item is Map<String, dynamic>) MyHomePayment.fromJson(item),
      ],
      schedule: <MyHomeScheduleRow>[
        for (final item in (json['schedule'] as List?) ?? const [])
          if (item is Map<String, dynamic>) MyHomeScheduleRow.fromJson(item),
      ],
      construction: section('construction') == null
          ? null
          : MyHomeConstruction.fromJson(section('construction')!),
      market: section('market') == null ? null : MyHomeMarket.fromJson(section('market')!),
      documents: <MyHomeDocument>[
        for (final item in (json['documents'] as List?) ?? const [])
          if (item is Map<String, dynamic>) MyHomeDocument.fromJson(item),
      ],
    );
  }
}

String? _text(dynamic value) {
  final s = value?.toString().trim();
  return s == null || s.isEmpty || s == 'null' ? null : s;
}
