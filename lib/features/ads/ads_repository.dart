import '../../core/api/api_client.dart';
import '../../core/api/media_url.dart';

/// `/api/market/ads` — saytdagi `AdProperty`.
class AdProperty {
  const AdProperty({
    required this.id,
    required this.title,
    required this.type,
    required this.dealType,
    required this.price,
    required this.images,
    this.currency = 'uzs',
    this.rooms = 0,
    this.bathrooms = 0,
    this.area = 0,
    this.floor = 0,
    this.totalFloors = 0,
    this.city = '',
    this.district = '',
    this.amenities = const [],
    this.isUrgent = false,
    this.isTop = false,
    this.ownerType = 'owner',
  });

  final int id;
  final String title;

  /// `apartment` | `house` | `office` | `shop` | `land`
  final String type;

  /// `sell` | `rent` | `exchange`
  final String dealType;
  final num price;
  final String currency;
  final int rooms;
  final int bathrooms;
  final num area;
  final int floor;
  final int totalFloors;
  final String city;
  final String district;
  final List<String> images;
  final List<String> amenities;
  final bool isUrgent;
  final bool isTop;

  /// `owner` | `agent`
  final String ownerType;

  factory AdProperty.fromJson(Map<String, dynamic> json) {
    final owner = json['owner'];
    return AdProperty(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      dealType: json['dealType']?.toString() ?? 'sell',
      price: (json['price'] as num?) ?? 0,
      currency: json['currency']?.toString() ?? 'uzs',
      rooms: (json['rooms'] as num?)?.toInt() ?? 0,
      bathrooms: (json['bathrooms'] as num?)?.toInt() ?? 0,
      area: (json['area'] as num?) ?? 0,
      floor: (json['floor'] as num?)?.toInt() ?? 0,
      totalFloors: (json['totalFloors'] as num?)?.toInt() ?? 0,
      city: json['city']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      images: [
        for (final image in (json['images'] as List? ?? const []))
          if (absoluteMediaUrl(image?.toString()) case final url? when url.isNotEmpty) url,
      ],
      amenities: (json['amenities'] as List? ?? const []).whereType<String>().toList(),
      isUrgent: json['isUrgent'] == true,
      isTop: json['isTop'] == true,
      ownerType: owner is Map ? (owner['type']?.toString() ?? 'owner') : 'owner',
    );
  }
}

/// Saytdagi `AdFilter` — barcha maydonlar so'rov parametri bo'lib ketadi.
class AdFilter {
  const AdFilter({
    this.search = '',
    this.city = '',
    this.type = '',
    this.dealType = '',
    this.rooms = 0,
    this.priceMin,
    this.priceMax,
    this.urgentOnly = false,
    this.topOnly = false,
    this.ownerOnly = false,
    this.agentOnly = false,
    this.sort = 'newest',
    this.page = 1,
  });

  final String search;
  final String city;
  final String type;
  final String dealType;
  final int rooms;
  final num? priceMin;
  final num? priceMax;
  final bool urgentOnly;
  final bool topOnly;
  final bool ownerOnly;
  final bool agentOnly;
  final String sort;
  final int page;

  static const perPage = 12;

  bool get hasActive =>
      search.isNotEmpty ||
      city.isNotEmpty ||
      type.isNotEmpty ||
      rooms > 0 ||
      priceMin != null ||
      priceMax != null ||
      urgentOnly ||
      topOnly ||
      ownerOnly ||
      agentOnly;

  AdFilter copyWith({
    String? search,
    String? city,
    String? type,
    String? dealType,
    int? rooms,
    num? priceMin,
    num? priceMax,
    bool? urgentOnly,
    bool? topOnly,
    bool? ownerOnly,
    bool? agentOnly,
    String? sort,
    int? page,
    bool clearPrice = false,
  }) => AdFilter(
    search: search ?? this.search,
    city: city ?? this.city,
    type: type ?? this.type,
    dealType: dealType ?? this.dealType,
    rooms: rooms ?? this.rooms,
    priceMin: clearPrice ? null : (priceMin ?? this.priceMin),
    priceMax: clearPrice ? null : (priceMax ?? this.priceMax),
    urgentOnly: urgentOnly ?? this.urgentOnly,
    topOnly: topOnly ?? this.topOnly,
    ownerOnly: ownerOnly ?? this.ownerOnly,
    agentOnly: agentOnly ?? this.agentOnly,
    sort: sort ?? this.sort,
    page: page ?? this.page,
  );

  Map<String, dynamic> toQuery() => {
    if (search.isNotEmpty) 'search': search,
    if (city.isNotEmpty) 'city': city,
    if (type.isNotEmpty) 'type': type,
    if (dealType.isNotEmpty) 'deal_type': dealType,
    if (rooms > 0) 'rooms': rooms,
    'price_min': ?priceMin,
    'price_max': ?priceMax,
    if (urgentOnly) 'urgent': 'true',
    if (topOnly) 'top': 'true',
    if (ownerOnly) 'seller': 'owner',
    if (agentOnly) 'seller': 'agent',
    'sort': sort,
    'page': page,
    'per_page': perPage,
  };
}

class AdsPage {
  const AdsPage({required this.items, required this.total, required this.pages});
  const AdsPage.empty() : items = const [], total = 0, pages = 1;

  final List<AdProperty> items;
  final int total;
  final int pages;
}

class AdsRepository {
  const AdsRepository();

  Future<AdsPage> list(AdFilter filter) async {
    final res = await ApiClient.instance.get<dynamic>('/market/ads', query: filter.toQuery());
    final data = res.data;
    if (data is! Map) return const AdsPage.empty();
    return AdsPage(
      items: [
        for (final row in (data['items'] as List? ?? const []))
          if (row is Map<String, dynamic>) AdProperty.fromJson(row),
      ],
      total: (data['total'] as num?)?.toInt() ?? 0,
      pages: (data['pages'] as num?)?.toInt() ?? 1,
    );
  }
}
