import '../../core/api/api_client.dart';
import '../../core/models/homepage.dart';
import '../../core/models/page_content.dart';
import '../../core/models/project.dart';

/// Everything the front page needs, in the same shape the site's `HomeComponent` assembles.
///
/// Each section is fetched independently: the site renders whatever arrives and leaves the rest
/// out, so one failing endpoint must not blank the whole page. That is why every method here
/// swallows errors and returns an empty result instead of throwing.
class HomeRepository {
  final _api = ApiClient.instance;

  Future<List<HeroSlide>> heroSlides() =>
      _list('/market/homepage/hero-slides', HeroSlide.fromJson);

  Future<List<PropertyCategory>> categories() =>
      _list('/market/homepage/categories', PropertyCategory.fromJson);

  Future<List<ServiceCard>> services() =>
      _list('/market/homepage/services', ServiceCard.fromJson);

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
