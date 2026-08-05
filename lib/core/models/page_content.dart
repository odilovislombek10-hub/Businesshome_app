/// Admin-authored copy for a page's hero block, from `/api/market/content/pages/{slug}`.
///
/// The home page's hero reads the `new-projects` page content — that is what the site does
/// (`hero-section.component.ts` requests exactly that slug), not a mistake in the path.
class PageContent {
  const PageContent({
    this.heroBadge,
    this.heroTitle,
    this.heroDescription,
    this.heroBgUrl,
    this.stats = const [],
  });

  final String? heroBadge;
  final String? heroTitle;
  final String? heroDescription;
  final String? heroBgUrl;

  /// The three value/label pairs shown under the hero.
  final List<PageStat> stats;

  factory PageContent.fromJson(Map<String, dynamic> json) {
    String? read(String key) {
      final value = json[key]?.toString().trim();
      return (value == null || value.isEmpty) ? null : value;
    }

    final stats = <PageStat>[];
    for (var i = 1; i <= 3; i++) {
      final value = read('stat${i}_value');
      final label = read('stat${i}_label');
      if (value != null || label != null) {
        stats.add(PageStat(value: value ?? '', label: label ?? ''));
      }
    }

    return PageContent(
      heroBadge: read('hero_badge'),
      heroTitle: read('hero_title'),
      heroDescription: read('hero_description'),
      heroBgUrl: read('hero_bg_url'),
      stats: stats,
    );
  }
}

class PageStat {
  const PageStat({required this.value, required this.label});

  final String value;
  final String label;
}
