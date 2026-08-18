import '../../core/api/api_client.dart';
import '../../core/models/content.dart';

/// Yangilikka biriktirilgan loyiha — `NewsLinkedProject`.
class NewsProject {
  const NewsProject({
    required this.name,
    required this.slug,
    required this.developerName,
    required this.developerCode,
    this.address,
    this.coverImage,
    this.developerLogo,
    this.minPrice,
    this.totalApartments = 0,
  });

  final String name;
  final String slug;
  final String developerName;
  final String developerCode;
  final String? address;
  final String? coverImage;
  final String? developerLogo;
  final num? minPrice;
  final int totalApartments;

  static String? _text(Object? value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  static NewsProject? fromJson(Object? json) {
    if (json is! Map) return null;
    return NewsProject(
      name: _text(json['name']) ?? '',
      slug: _text(json['slug']) ?? '',
      developerName: _text(json['developer_name']) ?? '',
      developerCode: _text(json['developer_code']) ?? '',
      address: _text(json['address']),
      coverImage: _text(json['cover_image']),
      developerLogo: _text(json['developer_logo']),
      minPrice: json['min_price'] is num ? json['min_price'] as num : null,
      totalApartments: json['total_apartments'] is num
          ? (json['total_apartments'] as num).toInt()
          : 0,
    );
  }
}

/// `MarketNewsDetail` — ro'yxatdagi yozuv ustiga bog'langan loyiha qo'shiladi.
class NewsDetail {
  const NewsDetail({required this.item, this.project});

  final NewsItem item;
  final NewsProject? project;
}

/// Saytdagi `ContentService` ning yangiliklar qismi.
class NewsRepository {
  const NewsRepository();

  /// Saytda ro'yxat sahifasi `loadAllNews()` orqali 20 tagacha oladi.
  Future<List<NewsItem>> loadAll({int limit = 20}) async {
    final res = await ApiClient.instance.get<dynamic>(
      '/market/content/news',
      query: {'limit': limit},
    );
    final data = res.data;
    if (data is! List) return const [];
    return [
      for (final row in data)
        if (row is Map<String, dynamic>) NewsItem.fromJson(row),
    ];
  }

  Future<NewsDetail?> byId(int id) async {
    final res = await ApiClient.instance.get<dynamic>('/market/content/news/$id');
    // `ApiClient` 4xx da istisno tashlamaydi (API xato matnini javob tanasida beradi), shuning
    // uchun holat kodini o'zimiz tekshiramiz — aks holda `{"detail": "Not found"}` bo'sh
    // yangilikka aylanib qolardi.
    if (res.statusCode != 200) return null;
    final data = res.data;
    if (data is! Map<String, dynamic>) return null;
    return NewsDetail(
      item: NewsItem.fromJson(data),
      project: NewsProject.fromJson(data['project']),
    );
  }
}
