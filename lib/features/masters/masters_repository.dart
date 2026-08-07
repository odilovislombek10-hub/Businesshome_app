import '../../core/api/api_client.dart';
import '../../core/models/master.dart';
import '../../core/models/property_listing.dart';

/// `/api/market/masters` filtri.
///
/// Saytda alohida interfeys yo'q — `getMasters()` `DesignerFilter` ni qayta ishlatadi va
/// `filterParams` shu maydonlarni yuboradi.
///
/// **Diqqat:** [availability] va [verifiedOnly] so'rovga **qo'shilmaydi**. Saytda ham shunday —
/// `market_masters_router.py` da bunday parametr yo'q, `filterParams` ularni umuman jo'natmaydi.
/// Ular faqat chip sifatida ko'rinadi. Backendga parametr qo'shilmaguncha bu ikkisi yuklangan
/// sahifa ichida, mahalliy tarzda saraladi — aks holda tugmalar umuman ishlamas edi.
class MasterFilter {
  const MasterFilter({
    this.search = '',
    this.specializations = const [],
    this.city = '',
    this.minRating = 0,
    this.availability = '',
    this.verifiedOnly = false,
    this.sort = 'rating',
    this.page = 1,
  });

  final String search;

  /// API vergul bilan birlashtirilgan ro'yxat kutadi.
  final List<String> specializations;
  final String city;
  final double minRating;

  /// `''` | `available` | `busy`
  final String availability;
  final bool verifiedOnly;

  /// `rating` | `projects` | `price_asc` | `experience`
  final String sort;
  final int page;

  static const perPage = 6;

  bool get hasActive =>
      specializations.isNotEmpty ||
      city.isNotEmpty ||
      minRating > 0 ||
      availability.isNotEmpty ||
      verifiedOnly;

  MasterFilter copyWith({
    String? search,
    List<String>? specializations,
    String? city,
    double? minRating,
    String? availability,
    bool? verifiedOnly,
    String? sort,
    int? page,
  }) => MasterFilter(
    search: search ?? this.search,
    specializations: specializations ?? this.specializations,
    city: city ?? this.city,
    minRating: minRating ?? this.minRating,
    availability: availability ?? this.availability,
    verifiedOnly: verifiedOnly ?? this.verifiedOnly,
    sort: sort ?? this.sort,
    page: page ?? this.page,
  );

  Map<String, dynamic> toQuery() => {
    if (search.isNotEmpty) 'search': search,
    if (specializations.isNotEmpty) 'specialization': specializations.join(','),
    if (city.isNotEmpty) 'city': city,
    if (minRating > 0) 'rating_min': minRating,
    'sort': sort,
    'page': page,
    'per_page': perPage,
  };

  /// Backend bilmaydigan ikki filtr — kelgan sahifa ustidan qo'llanadi.
  List<Master> applyLocal(List<Master> items) => [
    for (final m in items)
      if ((availability.isEmpty || (availability == 'available') == m.isAvailable) &&
          (!verifiedOnly || m.isVerified))
        m,
  ];
}

class MastersRepository {
  const MastersRepository();

  ApiClient get _api => ApiClient.instance;

  Future<Paginated<Master>> list(MasterFilter filter) async {
    final res = await _api.get<dynamic>('/market/masters', query: filter.toQuery());
    final data = res.data;
    if (data is! Map<String, dynamic>) return const Paginated.empty();
    return Paginated.fromJson(data, Master.fromJson);
  }
}
