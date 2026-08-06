import '../../core/api/api_client.dart';
import '../../core/models/property_listing.dart';

/// Every filter `/api/market/secondary` accepts, named exactly as the site's `SecondaryFilter`
/// interface names them — the query string has to match or the backend ignores the value.
class SecondaryFilter {
  const SecondaryFilter({
    this.search = '',
    this.city = '',
    this.district = '',
    this.types = const [],
    this.rooms = const [],
    this.bathrooms = 0,
    this.segment = '',
    this.priceMin,
    this.priceMax,
    this.areaMin,
    this.areaMax,
    this.floorMin,
    this.floorMax,
    this.seller = '',
    this.payment = '',
    this.furnished = '',
    this.repair = '',
    this.tour = false,
    this.sort = 'newest',
    this.page = 1,
  });

  final String search;
  final String city;
  final String district;

  /// The API takes a comma-joined list for both of these.
  final List<String> types;
  final List<int> rooms;

  final int bathrooms;
  final String segment;
  final num? priceMin;
  final num? priceMax;
  final num? areaMin;
  final num? areaMax;
  final int? floorMin;
  final int? floorMax;
  final String seller;
  final String payment;
  final String furnished;
  final String repair;
  final bool tour;

  /// `newest` | `price_asc` | `price_desc` | `area_desc`
  final String sort;
  final int page;

  /// The site's grid asks for nine at a time.
  static const perPage = 9;

  bool get hasActive =>
      city.isNotEmpty ||
      district.isNotEmpty ||
      types.isNotEmpty ||
      rooms.isNotEmpty ||
      bathrooms > 0 ||
      segment.isNotEmpty ||
      priceMin != null ||
      priceMax != null ||
      areaMin != null ||
      areaMax != null ||
      floorMin != null ||
      floorMax != null ||
      seller.isNotEmpty ||
      payment.isNotEmpty ||
      furnished.isNotEmpty ||
      repair.isNotEmpty ||
      tour;

  SecondaryFilter copyWith({
    String? search,
    String? city,
    String? district,
    List<String>? types,
    List<int>? rooms,
    int? bathrooms,
    String? segment,
    num? priceMin,
    num? priceMax,
    num? areaMin,
    num? areaMax,
    int? floorMin,
    int? floorMax,
    String? seller,
    String? payment,
    String? furnished,
    String? repair,
    bool? tour,
    String? sort,
    int? page,
    bool clearRanges = false,
  }) => SecondaryFilter(
    search: search ?? this.search,
    city: city ?? this.city,
    district: district ?? this.district,
    types: types ?? this.types,
    rooms: rooms ?? this.rooms,
    bathrooms: bathrooms ?? this.bathrooms,
    segment: segment ?? this.segment,
    priceMin: clearRanges ? null : (priceMin ?? this.priceMin),
    priceMax: clearRanges ? null : (priceMax ?? this.priceMax),
    areaMin: clearRanges ? null : (areaMin ?? this.areaMin),
    areaMax: clearRanges ? null : (areaMax ?? this.areaMax),
    floorMin: clearRanges ? null : (floorMin ?? this.floorMin),
    floorMax: clearRanges ? null : (floorMax ?? this.floorMax),
    seller: seller ?? this.seller,
    payment: payment ?? this.payment,
    furnished: furnished ?? this.furnished,
    repair: repair ?? this.repair,
    tour: tour ?? this.tour,
    sort: sort ?? this.sort,
    page: page ?? this.page,
  );

  Map<String, dynamic> toQuery() => {
    if (search.isNotEmpty) 'search': search,
    if (city.isNotEmpty) 'city': city,
    if (district.isNotEmpty) 'district': district,
    if (types.isNotEmpty) 'type': types.join(','),
    if (rooms.isNotEmpty) 'rooms': rooms.join(','),
    if (bathrooms > 0) 'bathrooms': '$bathrooms',
    if (segment.isNotEmpty) 'segment': segment,
    'price_min': ?priceMin,
    'price_max': ?priceMax,
    'area_min': ?areaMin,
    'area_max': ?areaMax,
    'floor_min': ?floorMin,
    'floor_max': ?floorMax,
    if (seller.isNotEmpty) 'seller': seller,
    if (payment.isNotEmpty) 'payment': payment,
    if (furnished.isNotEmpty) 'mebel': furnished,
    if (repair.isNotEmpty) 'remont': repair,
    if (tour) 'tour': 'true',
    'sort': sort,
    'page': page,
    'per_page': perPage,
  };
}

/// Shared by `/secondary` and `/rent` — the two endpoints take the same filter.
class SecondaryRepository {
  const SecondaryRepository({this.endpoint = '/market/secondary'});

  /// `/market/secondary` or `/market/rent`.
  final String endpoint;

  ApiClient get _api => ApiClient.instance;

  /// The list endpoint answers with the `{items, total, page, pages}` envelope.
  Future<Paginated<PropertyListing>> list(SecondaryFilter filter) async {
    final res = await _api.get<dynamic>(endpoint, query: filter.toQuery());
    final data = res.data;
    if (data is! Map<String, dynamic>) return const Paginated.empty();
    return Paginated.fromJson(data, PropertyListing.fromJson);
  }

  Future<PropertyListing?> byId(int id) async {
    final res = await _api.get<dynamic>('$endpoint/$id');
    final data = res.data;
    return data is Map<String, dynamic> ? PropertyListing.fromJson(data) : null;
  }

  /// Slider bounds (`/secondary/ranges`) so the price and area filters start at the real extremes
  /// rather than a guess.
  Future<Map<String, num>> ranges() async {
    try {
      final res = await _api.get<dynamic>('$endpoint/ranges');
      final data = res.data;
      if (data is! Map) return const {};
      return {
        for (final entry in data.entries)
          if (entry.value is num) entry.key.toString(): entry.value as num,
      };
    } catch (_) {
      return const {};
    }
  }
}
