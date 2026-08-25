/// `/api/viewer/projects/{dev}/{slug}` javobi — saytdagi `ApiProject`.
///
/// Sahifadagi barcha boy bo'limlar (`features`, `architecture`, `highlights`, …) shu
/// javobning `market_settings` qismidan keladi va adminkadan to'ldiriladi. Bo'sh bo'lsa
/// bo'lim umuman chizilmaydi — saytda ham har biri `@if (…length > 0)` bilan o'ralgan.
class ProjectDetail {
  const ProjectDetail({
    required this.id,
    required this.name,
    required this.slug,
    required this.developerCode,
    required this.developerName,
    this.address,
    this.description,
    this.coverImage,
    this.status,
    this.developerLogo,
    this.totalApartments = 0,
    this.totalBlocks = 0,
    this.totalArea,
    this.startDate,
    this.endDate,
    this.minPrice,
    this.lat,
    this.lng,
    this.settings = const ProjectMarketSettings(),
  });

  final int id;
  final String name;
  final String slug;
  final String developerCode;
  final String developerName;
  final String? address;
  final String? description;
  final String? coverImage;
  final String? status;
  final String? developerLogo;
  final int totalApartments;
  final int totalBlocks;
  final num? totalArea;
  final String? startDate;
  final String? endDate;
  final num? minPrice;
  final double? lat;
  final double? lng;
  final ProjectMarketSettings settings;

  static String? _text(Object? value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  factory ProjectDetail.fromJson(Map<String, dynamic> json) {
    final developer = json['developer'];
    return ProjectDetail(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: _text(json['name']) ?? '',
      slug: _text(json['slug']) ?? '',
      developerCode: developer is Map ? (_text(developer['code']) ?? '') : '',
      developerName: developer is Map ? (_text(developer['name']) ?? '') : '',
      address: _text(json['address']),
      description: _text(json['description']),
      coverImage: _text(json['cover_image']),
      status: _text(json['status']),
      developerLogo: developer is Map ? _text(developer['logo']) : null,
      totalApartments: (json['total_apartments'] as num?)?.toInt() ?? 0,
      totalBlocks: (json['total_blocks'] as num?)?.toInt() ?? 0,
      totalArea: json['total_area'] is num ? json['total_area'] as num : null,
      startDate: _text(json['start_date']),
      endDate: _text(json['end_date']),
      minPrice: json['min_price'] is num ? json['min_price'] as num : null,
      lat: (json['latitude'] as num?)?.toDouble(),
      lng: (json['longitude'] as num?)?.toDouble(),
      settings: ProjectMarketSettings.fromJson(json['market_settings']),
    );
  }
}

/// Adminkadan to'ldiriladigan sahifa mazmuni.
class ProjectMarketSettings {
  const ProjectMarketSettings({
    this.heroVideoUrl,
    this.heroPosterUrl,
    this.brochureUrl,
    this.projectLogo,
    this.pageSubtitle,
    this.pageDescription,
    this.galleryImages = const [],
    this.features = const [],
    this.architect,
    this.architectureTabs = const [],
    this.highlightCategories = const [],
    this.gallerySections = const [],
    this.smartHomeTabs = const [],
    this.documentCategories = const [],
  });

  final String? heroVideoUrl;
  final String? heroPosterUrl;
  final String? brochureUrl;
  final String? projectLogo;
  final String? pageSubtitle;
  final String? pageDescription;
  final List<String> galleryImages;
  final List<ProjectFeature> features;
  final ProjectArchitect? architect;
  final List<ProjectTab> architectureTabs;
  final List<HighlightCategory> highlightCategories;
  final List<GallerySection> gallerySections;
  final List<SmartHomeTab> smartHomeTabs;
  final List<DocumentCategory> documentCategories;

  static String? _text(Object? value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  /// Adminka ikki tilda saqlaydi (`title_uz` / `title_ru`); sayt tanlangan tilni, bo'lmasa
  /// o'zbekchani oladi.
  static String localized(Map row, String field) =>
      _text(row['${field}_uz']) ?? _text(row['${field}_ru']) ?? '';

  static List<String> _urls(Object? raw) {
    if (raw is! List) return const [];
    // Ba'zi ro'yxatlar oddiy satr, ba'zilari `{url, hotspots}` obyekti.
    final urls = <String>[];
    for (final row in raw) {
      if (row is String && row.trim().isNotEmpty) {
        urls.add(row);
      } else if (row is Map) {
        final url = _text(row['url']);
        if (url != null) urls.add(url);
      }
    }
    return urls;
  }

  factory ProjectMarketSettings.fromJson(Object? json) {
    if (json is! Map) return const ProjectMarketSettings();
    final architecture = json['architecture'];
    final highlights = json['highlights'];
    return ProjectMarketSettings(
      heroVideoUrl: _text(json['hero_video_url']),
      heroPosterUrl: _text(json['hero_poster_url']),
      brochureUrl: _text(json['brochure_url']),
      projectLogo: _text(json['project_logo']),
      pageSubtitle: _text(json['page_subtitle']),
      pageDescription: _text(json['page_description']),
      galleryImages: _urls(json['gallery_images']),
      features: [
        for (final row in (json['features'] as List? ?? const []))
          if (row is Map) ProjectFeature.fromJson(row),
      ],
      architect: (architecture is Map && architecture['architect'] is Map)
          ? ProjectArchitect.fromJson(architecture['architect'] as Map)
          : null,
      architectureTabs: [
        for (final row
            in ((architecture is Map ? architecture['tabs'] : null) as List? ?? const []))
          if (row is Map) ProjectTab.fromJson(row),
      ],
      highlightCategories: [
        for (final row
            in ((highlights is Map ? highlights['categories'] : null) as List? ?? const []))
          if (row is Map) HighlightCategory.fromJson(row),
      ],
      gallerySections: [
        for (final row in (json['gallery_sections'] as List? ?? const []))
          if (row is Map) GallerySection.fromJson(row),
      ],
      smartHomeTabs: [
        for (final row in (json['smart_home'] as List? ?? const []))
          if (row is Map) SmartHomeTab.fromJson(row),
      ],
      documentCategories: [
        for (final row in (json['documents'] as List? ?? const []))
          if (row is Map) DocumentCategory.fromJson(row),
      ],
    );
  }
}

class ProjectFeature {
  const ProjectFeature({required this.image, required this.title, required this.subtitle});

  final String image;
  final String title;
  final String subtitle;

  factory ProjectFeature.fromJson(Map row) => ProjectFeature(
    image: row['image']?.toString() ?? '',
    title: ProjectMarketSettings.localized(row, 'title'),
    subtitle: ProjectMarketSettings.localized(row, 'subtitle'),
  );
}

/// Arxitektura bo'limining yorlig'i va uning slaydlari.
class ProjectTab {
  const ProjectTab({required this.label, required this.slides});

  final String label;
  final List<String> slides;

  factory ProjectTab.fromJson(Map row) => ProjectTab(
    label: ProjectMarketSettings.localized(row, 'label'),
    slides: [
      for (final slide in (row['slides'] as List? ?? const []))
        if (slide is Map && slide['image'] != null) slide['image'].toString(),
    ],
  );
}

class HighlightCategory {
  const HighlightCategory({required this.label, required this.items});

  final String label;
  final List<HighlightItem> items;

  factory HighlightCategory.fromJson(Map row) => HighlightCategory(
    label: ProjectMarketSettings.localized(row, 'label'),
    items: [
      for (final item in (row['items'] as List? ?? const []))
        if (item is Map) HighlightItem.fromJson(item),
    ],
  );
}

class HighlightItem {
  const HighlightItem({required this.image, required this.title, required this.description});

  final String image;
  final String title;
  final String description;

  factory HighlightItem.fromJson(Map row) => HighlightItem(
    image: row['image']?.toString() ?? '',
    title: ProjectMarketSettings.localized(row, 'title'),
    description: ProjectMarketSettings.localized(row, 'description'),
  );
}

class GallerySection {
  const GallerySection({required this.label, required this.images});

  final String label;
  final List<GalleryImage> images;

  factory GallerySection.fromJson(Map row) => GallerySection(
    label: ProjectMarketSettings.localized(row, 'label'),
    images: [
      for (final image in (row['images'] as List? ?? const []))
        if (image is Map && image['url'] != null)
          GalleryImage.fromJson(image)
        else if (image is String && image.trim().isNotEmpty)
          GalleryImage(url: image, hotspots: const []),
    ],
  );
}

/// Galereya rasmi va uning ustidagi nuqtalari.
class GalleryImage {
  const GalleryImage({required this.url, required this.hotspots});

  final String url;
  final List<GalleryHotspot> hotspots;

  factory GalleryImage.fromJson(Map row) => GalleryImage(
    url: row['url'].toString(),
    hotspots: [
      for (final spot in (row['hotspots'] as List? ?? const []))
        if (spot is Map) GalleryHotspot.fromJson(spot),
    ],
  );
}

/// Rasm ustidagi nuqta — foizda joylashadi, bosilganda izohi chiqadi.
class GalleryHotspot {
  const GalleryHotspot({
    required this.x,
    required this.y,
    required this.label,
    required this.description,
  });

  final double x;
  final double y;
  final String label;
  final String description;

  factory GalleryHotspot.fromJson(Map row) => GalleryHotspot(
    x: (row['x'] as num?)?.toDouble() ?? 0,
    y: (row['y'] as num?)?.toDouble() ?? 0,
    label: ProjectMarketSettings.localized(row, 'label'),
    description: ProjectMarketSettings.localized(row, 'description'),
  );
}

/// Arxitektura bo'limidagi loyiha muallifi.
class ProjectArchitect {
  const ProjectArchitect({
    required this.name,
    required this.role,
    required this.description,
    this.avatar,
  });

  final String name;
  final String role;
  final String description;
  final String? avatar;

  factory ProjectArchitect.fromJson(Map row) => ProjectArchitect(
    name: row['name']?.toString() ?? '',
    role: ProjectMarketSettings.localized(row, 'role'),
    description: ProjectMarketSettings.localized(row, 'description'),
    avatar: ProjectMarketSettings._text(row['avatar']),
  );
}

/// "Aqlli uy" bo'limining bir yorlig'i: fon rasmi, matni va mahsulotlari.
class SmartHomeTab {
  const SmartHomeTab({
    required this.icon,
    required this.title,
    required this.description,
    required this.image,
    required this.products,
  });

  /// `zap` | `droplets` | `thermometer` | `wifi` — saytda shu to'rttasi chiziladi.
  final String icon;
  final String title;
  final String description;
  final String image;
  final List<({String name, String image})> products;

  factory SmartHomeTab.fromJson(Map row) => SmartHomeTab(
    icon: row['icon']?.toString() ?? '',
    title: ProjectMarketSettings.localized(row, 'title'),
    description: ProjectMarketSettings.localized(row, 'description'),
    image: row['image']?.toString() ?? '',
    products: [
      for (final product in (row['products'] as List? ?? const []))
        if (product is Map)
          (
            name: ProjectMarketSettings.localized(product, 'name'),
            image: product['image']?.toString() ?? '',
          ),
    ],
  );
}

class DocumentCategory {
  const DocumentCategory({required this.label, required this.documents});

  final String label;
  final List<({String name, String url})> documents;

  factory DocumentCategory.fromJson(Map row) => DocumentCategory(
    label: ProjectMarketSettings.localized(row, 'title'),
    documents: [
      for (final doc in (row['documents'] as List? ?? const []))
        if (doc is Map && doc['file_url'] != null)
          (name: doc['filename']?.toString() ?? '', url: doc['file_url'].toString()),
    ],
  );
}
