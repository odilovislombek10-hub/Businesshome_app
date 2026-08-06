/// Admin-managed marketing content: the "why us" features and the news list.
///
/// Both come back with `*_uz` / `*_ru` / `*_ky` variants and are resolved here, Uzbek first.
library;

String? _text(Object? value) {
  final s = value?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

/// One card of the site's `features-section`, from `/api/market/content/features`.
class FeatureItem {
  const FeatureItem({
    required this.id,
    required this.icon,
    required this.title,
    required this.description,
  });

  final int id;

  /// A short name (`shield`, `eye`, `wallet`, …) the site switches on to pick an illustration.
  final String icon;
  final String title;
  final String description;

  factory FeatureItem.fromJson(Map<String, dynamic> json) => FeatureItem(
    id: (json['id'] as num?)?.toInt() ?? 0,
    icon: _text(json['icon']) ?? 'check',
    title: _text(json['title_uz']) ?? _text(json['title_ru']) ?? '',
    description: _text(json['description_uz']) ?? _text(json['description_ru']) ?? '',
  );
}

/// One entry of `/api/market/content/news`.
class NewsItem {
  const NewsItem({
    required this.id,
    required this.title,
    required this.description,
    this.image,
    this.publishedAt,
  });

  final int id;
  final String title;
  final String description;
  final String? image;
  final DateTime? publishedAt;

  /// "15 yanvar 2026" — the site spells the month out rather than printing a numeric date.
  String get dateLabel {
    final date = publishedAt;
    if (date == null) return '';
    return '${date.day} ${_months[date.month - 1]} ${date.year}';
  }

  static const _months = [
    'yanvar',
    'fevral',
    'mart',
    'aprel',
    'may',
    'iyun',
    'iyul',
    'avgust',
    'sentabr',
    'oktabr',
    'noyabr',
    'dekabr',
  ];

  /// The site falls back to this photo when a news item has no image of its own.
  static const fallbackImage =
      'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=800&q=80';

  factory NewsItem.fromJson(Map<String, dynamic> json) => NewsItem(
    id: (json['id'] as num?)?.toInt() ?? 0,
    title: _text(json['title_uz']) ?? _text(json['title_ru']) ?? '',
    description: _text(json['description_uz']) ?? _text(json['description_ru']) ?? '',
    image: _text(json['image']),
    publishedAt: DateTime.tryParse(json['published_at']?.toString() ?? ''),
  );
}
