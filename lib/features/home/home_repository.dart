import '../../core/api/api_client.dart';
import '../../core/models/content.dart';
import '../../core/models/developer_summary.dart';
import '../../core/models/homepage.dart';
import '../../core/models/page_content.dart';
import '../../core/models/project.dart';
import '../../core/models/property_listing.dart';
import '../../core/models/reel.dart';
import '../../core/models/specialist.dart';
import 'components/property_price_map.dart' show RegionPrice;

/// Everything the front page needs, in the same shape the site's `HomeComponent` assembles.
///
/// Each section is fetched independently: the site renders whatever arrives and leaves the rest
/// out, so one failing endpoint must not blank the whole page. That is why every method here
/// swallows errors and returns an empty result instead of throwing.
class HomeRepository {
  final _api = ApiClient.instance;

  Future<List<HeroSlide>> heroSlides() => _list('/market/homepage/hero-slides', HeroSlide.fromJson);

  Future<List<PropertyCategory>> categories() =>
      _list('/market/homepage/categories', PropertyCategory.fromJson);

  Future<List<ServiceCard>> services() => _list('/market/homepage/services', ServiceCard.fromJson);

  Future<List<DeveloperSummary>> developers() =>
      _list('/market/developers', DeveloperSummary.fromJson);

  /// Admin-editable key/value settings — contact phone, store links and so on.
  ///
  /// Whatever the admin panel changes here shows up on the next launch, exactly as it does on the
  /// site: the widgets read these values instead of hard-coding them.
  Future<Map<String, String>> settings() async {
    try {
      final res = await _api.get<dynamic>('/market/content/settings');
      final data = res.data;
      if (data is! Map) return const {};
      return {
        for (final entry in data.entries)
          if (entry.value != null) entry.key.toString(): entry.value.toString(),
      };
    } catch (_) {
      return const {};
    }
  }

  /// Region price statistics for the map. `deal_type` picks rent (monthly) or the secondary
  /// market (per m²) — the two tabs the site offers.
  Future<Map<String, RegionPrice>> priceMap({required bool rent}) async {
    try {
      final res = await _api.get<dynamic>(
        '/market/regions/price-map',
        query: {'deal_type': rent ? 'rent' : 'secondary'},
      );
      return RegionPrice.parseList(res.data);
    } catch (_) {
      return const {};
    }
  }

  Future<List<FeatureItem>> features() => _list('/market/content/features', FeatureItem.fromJson);

  Future<List<NewsItem>> news() =>
      _list('/market/content/news', NewsItem.fromJson, query: {'limit': 6});

  Future<List<Reel>> reels() => _list('/market/reels', Reel.fromJson, query: {'limit': 10});

  /// The four "top picks" strips. Counts match the site: 4 listings each, 6 specialists each.
  Future<List<PropertyListing>> topSecondary() =>
      _list('/market/secondary', PropertyListing.fromJson, query: {'page': 1, 'per_page': 4});

  Future<List<PropertyListing>> topRent() =>
      _list('/market/rent', PropertyListing.fromJson, query: {'page': 1, 'per_page': 4});

  Future<List<Specialist>> topDesigners() =>
      _list('/market/designers', Specialist.fromJson, query: {'page': 1, 'per_page': 6});

  Future<List<Specialist>> topMasters() =>
      _list('/market/masters', Specialist.fromJson, query: {'page': 1, 'per_page': 6});

  Future<List<PromoBanner>> promoBanners() =>
      _list('/market/homepage/promo-banners', PromoBanner.fromJson);

  /// "Tanlangan binolar" — the site's `featured-buildings` block, which is just the first page of
  /// projects (`getProjects({per_page: 6})`), not the `/market/home/featured` endpoint. That one
  /// returns a sponsored master/designer pair for the category cards, a different section.
  Future<List<Project>> featured() =>
      _list('/viewer/projects', Project.fromJson, query: {'per_page': 6});

  /// Hero copy and stat labels. The site's hero reads the `new-projects` page content on the home
  /// page too — same slug, deliberately.
  Future<PageContent?> heroContent() async {
    try {
      final res = await _api.get<dynamic>('/market/content/pages/new-projects');
      final data = res.data;
      return data is Map<String, dynamic> ? PageContent.fromJson(data) : null;
    } catch (_) {
      return null;
    }
  }

  /// The cheapest listing matching a category, used for the overlay on its tile.
  ///
  /// The category's `link` carries the filter (`/secondary?type=house`), so the type comes from
  /// there and the endpoint from whether the link points at rent or the secondary market — the
  /// same two branches the site takes.
  Future<PropertyListing?> topListingForCategory(PropertyCategory category) async {
    final type = Uri.tryParse(category.link)?.queryParameters['type'];
    if (type == null || type.isEmpty) return null;
    final isRent = category.link.startsWith('/rent');
    try {
      final res = await _api.get<dynamic>(
        isRent ? '/market/rent' : '/market/secondary',
        query: {'type': type, 'page': 1, 'per_page': 1},
      );
      final data = res.data;
      final items = data is Map<String, dynamic> ? data['items'] : null;
      if (items is! List || items.isEmpty) return null;
      final first = items.first;
      return first is Map<String, dynamic> ? PropertyListing.fromJson(first) : null;
    } catch (_) {
      return null;
    }
  }

  Future<PlatformStats?> stats() async {
    try {
      final res = await _api.get<dynamic>('/market/homepage/stats');
      final data = res.data;
      return data is Map<String, dynamic> ? PlatformStats.fromJson(data) : null;
    } catch (_) {
      return null;
    }
  }

  Future<List<T>> _list<T>(
    String path,
    T Function(Map<String, dynamic>) parse, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final res = await _api.get<dynamic>(path, query: query);
      final data = res.data;
      final items = switch (data) {
        List list => list,
        // A few endpoints wrap their payload; accept that shape rather than failing on it.
        Map<String, dynamic> map => map['items'] ?? map['results'] ?? map['data'],
        _ => null,
      };
      if (items is! List) return const [];
      return items.whereType<Map<String, dynamic>>().map(parse).toList();
    } catch (_) {
      return const [];
    }
  }
}
