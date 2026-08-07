import '../../core/api/api_client.dart';
import '../../core/models/designer.dart';
import '../../core/models/property_listing.dart';

/// `/api/market/designers` qabul qiladigan barcha parametrlar — nomlari saytning
/// `DesignerFilter` interfeysi bilan aynan bir xil, aks holda backend qiymatni e'tiborsiz
/// qoldiradi.
class DesignerFilter {
  const DesignerFilter({
    this.search = '',
    this.specializations = const [],
    this.city = '',
    this.minRating = 0,
    this.minExperience = 0,
    this.priceMin = 0,
    this.priceMax = 0,
    this.sort = 'rating',
    this.page = 1,
  });

  final String search;

  /// API vergul bilan birlashtirilgan ro'yxat kutadi (`specialization=interior,exterior`).
  final List<String> specializations;
  final String city;
  final double minRating;
  final int minExperience;

  /// Saytda ular `signal(0)` — 0 "tanlanmagan" degani, so'rovga qo'shilmaydi.
  final num priceMin;
  final num priceMax;

  /// `rating` | `projects` | `price_asc` | `price_desc` | `experience`
  final String sort;
  final int page;

  /// Saytning ro'yxati bir martada oltitasini so'raydi.
  static const perPage = 6;

  /// Saytdagi `hasActiveFilters` — qidiruv va saralash bunga kirmaydi.
  bool get hasActive =>
      specializations.isNotEmpty ||
      city.isNotEmpty ||
      minRating > 0 ||
      minExperience > 0 ||
      priceMin > 0 ||
      priceMax > 0;

  DesignerFilter copyWith({
    String? search,
    List<String>? specializations,
    String? city,
    double? minRating,
    int? minExperience,
    num? priceMin,
    num? priceMax,
    String? sort,
    int? page,
  }) => DesignerFilter(
    search: search ?? this.search,
    specializations: specializations ?? this.specializations,
    city: city ?? this.city,
    minRating: minRating ?? this.minRating,
    minExperience: minExperience ?? this.minExperience,
    priceMin: priceMin ?? this.priceMin,
    priceMax: priceMax ?? this.priceMax,
    sort: sort ?? this.sort,
    page: page ?? this.page,
  );

  Map<String, dynamic> toQuery() => {
    if (search.isNotEmpty) 'search': search,
    if (specializations.isNotEmpty) 'specialization': specializations.join(','),
    if (city.isNotEmpty) 'city': city,
    if (minRating > 0) 'rating_min': minRating,
    if (minExperience > 0) 'exp_min': minExperience,
    if (priceMin > 0) 'price_min': priceMin,
    if (priceMax > 0) 'price_max': priceMax,
    'sort': sort,
    'page': page,
    'per_page': perPage,
  };
}

class DesignersRepository {
  const DesignersRepository();

  ApiClient get _api => ApiClient.instance;

  Future<Paginated<Designer>> list(DesignerFilter filter) async {
    final res = await _api.get<dynamic>('/market/designers', query: filter.toQuery());
    final data = res.data;
    if (data is! Map<String, dynamic>) return const Paginated.empty();
    return Paginated.fromJson(data, Designer.fromJson);
  }
}
