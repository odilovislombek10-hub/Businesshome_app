import '../api/media_url.dart';

/// `/api/market/birja` dagi bitta buyurtma (project brief).
///
/// Maydonlar saytning `BirjaItem` interfeysi bilan bir xil nomlanadi — bu endpoint boshqalardan
/// farqli o'laroq **snake_case** qaytaradi.
class Brief {
  const Brief({
    required this.id,
    required this.target,
    required this.title,
    required this.description,
    required this.status,
    required this.viewsCount,
    required this.responsesCount,
    required this.images,
    this.projectType,
    this.city,
    this.district,
    this.areaM2,
    this.budgetFrom,
    this.budgetTo,
    this.currency = 'UZS',
    this.deadline,
    this.authorId,
    this.authorName,
    this.authorAvatar,
    this.createdAt,
  });

  final int id;

  /// `designer` | `master` — buyurtma kimga mo'ljallangan.
  final String target;
  final String title;
  final String description;

  /// `open` | `in_progress` | `closed`
  final String status;
  final int viewsCount;
  final int responsesCount;

  /// `attachments` dan faqat `type == 'image'` bo'lganlari, mutlaq manzilda.
  final List<String> images;

  /// `apartment` | `house` | `office` | `shop`
  final String? projectType;
  final String? city;
  final String? district;
  final num? areaM2;
  final int? budgetFrom;
  final int? budgetTo;
  final String currency;
  final String? deadline;

  final int? authorId;
  final String? authorName;
  final String? authorAvatar;
  final DateTime? createdAt;

  bool get isOpen => status == 'open';

  static String? _text(dynamic value) {
    final s = value?.toString().trim();
    return s == null || s.isEmpty ? null : s;
  }

  factory Brief.fromJson(Map<String, dynamic> json) {
    final author = json['author'];
    final authorMap = author is Map<String, dynamic> ? author : const <String, dynamic>{};
    return Brief(
      id: (json['id'] as num?)?.toInt() ?? 0,
      target: json['target']?.toString() ?? 'designer',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'open',
      viewsCount: (json['views_count'] as num?)?.toInt() ?? 0,
      responsesCount: (json['responses_count'] as num?)?.toInt() ?? 0,
      images: <String>[
        for (final item in (json['attachments'] as List?) ?? const [])
          if (item is Map && item['type'] == 'image') ?absoluteMediaUrl(_text(item['url'])),
      ],
      projectType: _text(json['project_type']),
      city: _text(json['city']),
      district: _text(json['district']),
      areaM2: json['area_m2'] as num?,
      budgetFrom: (json['budget_from'] as num?)?.toInt(),
      budgetTo: (json['budget_to'] as num?)?.toInt(),
      currency: json['currency']?.toString() ?? 'UZS',
      deadline: _text(json['deadline']),
      authorId: (authorMap['id'] as num?)?.toInt(),
      authorName: _text(authorMap['name']),
      authorAvatar: absoluteMediaUrl(_text(authorMap['avatar'])),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}
