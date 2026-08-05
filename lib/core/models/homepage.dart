/// Models for the `/homepage/*` and `/home/featured` endpoints that build businesshome.uz's
/// front page.
///
/// The API returns each translatable field twice (`*_uz` / `*_ru`) rather than resolving by
/// Accept-Language, so every model keeps both and exposes a single resolved getter. Uzbek is the
/// default; Russian is used only where the Uzbek value is missing.
library;

String? _str(Object? v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

int _int(Object? v) => switch (v) {
  int i => i,
  num n => n.toInt(),
  String s => int.tryParse(s) ?? 0,
  _ => 0,
};

class HeroSlide {
  const HeroSlide({
    required this.id,
    required this.image,
    this.titleUz,
    this.titleRu,
    this.link,
    this.sortOrder = 0,
  });

  final int id;
  final String image;
  final String? titleUz;
  final String? titleRu;
  final String? link;
  final int sortOrder;

  String? get title => titleUz ?? titleRu;

  factory HeroSlide.fromJson(Map<String, dynamic> json) => HeroSlide(
    id: _int(json['id']),
    image: _str(json['image']) ?? '',
    titleUz: _str(json['title_uz']),
    titleRu: _str(json['title_ru']),
    link: _str(json['link']),
    sortOrder: _int(json['sort_order']),
  );
}

class ServiceCard {
  const ServiceCard({
    required this.id,
    required this.icon,
    required this.titleUz,
    required this.descriptionUz,
    this.image,
    this.titleRu,
    this.descriptionRu,
    this.link,
    this.sortOrder = 0,
  });

  final int id;
  final String icon;
  final String? image;
  final String titleUz;
  final String? titleRu;
  final String descriptionUz;
  final String? descriptionRu;
  final String? link;
  final int sortOrder;

  String get title => titleUz.isNotEmpty ? titleUz : (titleRu ?? '');
  String get description => descriptionUz.isNotEmpty ? descriptionUz : (descriptionRu ?? '');

  factory ServiceCard.fromJson(Map<String, dynamic> json) => ServiceCard(
    id: _int(json['id']),
    icon: _str(json['icon']) ?? 'shield',
    image: _str(json['image']),
    titleUz: _str(json['title_uz']) ?? '',
    titleRu: _str(json['title_ru']),
    descriptionUz: _str(json['description_uz']) ?? '',
    descriptionRu: _str(json['description_ru']),
    link: _str(json['link']),
    sortOrder: _int(json['sort_order']),
  );
}

class PromoBanner {
  const PromoBanner({
    required this.id,
    required this.image,
    required this.position,
    this.imageMobile,
    this.titleUz,
    this.titleRu,
    this.descriptionUz,
    this.descriptionRu,
    this.link,
    this.buttonTextUz,
    this.buttonTextRu,
  });

  final int id;
  final String image;

  /// The site swaps to this below the `md` breakpoint — on a phone it is always the better source.
  final String? imageMobile;
  final String? titleUz;
  final String? titleRu;
  final String? descriptionUz;
  final String? descriptionRu;
  final String? link;
  final String? buttonTextUz;
  final String? buttonTextRu;

  /// Where the banner belongs on the page (the site keys its slots off this).
  final String position;

  String? get title => titleUz ?? titleRu;
  String? get description => descriptionUz ?? descriptionRu;
  String? get buttonText => buttonTextUz ?? buttonTextRu;
  String get bestImage => imageMobile ?? image;

  factory PromoBanner.fromJson(Map<String, dynamic> json) => PromoBanner(
    id: _int(json['id']),
    image: _str(json['image']) ?? '',
    imageMobile: _str(json['image_mobile']),
    titleUz: _str(json['title_uz']),
    titleRu: _str(json['title_ru']),
    descriptionUz: _str(json['description_uz']),
    descriptionRu: _str(json['description_ru']),
    link: _str(json['link']),
    buttonTextUz: _str(json['button_text_uz']),
    buttonTextRu: _str(json['button_text_ru']),
    position: _str(json['position']) ?? 'top',
  );
}

class PropertyCategory {
  const PropertyCategory({
    required this.id,
    required this.nameUz,
    required this.image,
    required this.link,
    this.nameRu,
    this.sortOrder = 0,
  });

  final int id;
  final String nameUz;
  final String? nameRu;
  final String image;
  final String link;
  final int sortOrder;

  String get name => nameUz.isNotEmpty ? nameUz : (nameRu ?? '');

  factory PropertyCategory.fromJson(Map<String, dynamic> json) => PropertyCategory(
    id: _int(json['id']),
    nameUz: _str(json['name_uz']) ?? '',
    nameRu: _str(json['name_ru']),
    image: _str(json['image']) ?? '',
    link: _str(json['link']) ?? '/',
    sortOrder: _int(json['sort_order']),
  );
}

class FeatureBadge {
  const FeatureBadge({this.icon, this.text});

  final String? icon;
  final String? text;

  factory FeatureBadge.fromJson(Map<String, dynamic> json) => FeatureBadge(
    icon: _str(json['icon']),
    // The badge payload is admin-authored and has drifted between `text` and `label`.
    text: _str(json['text']) ?? _str(json['label']),
  );
}

class PlatformStats {
  const PlatformStats({
    required this.totalProperties,
    required this.totalDevelopers,
    required this.totalUsers,
    required this.totalProjects,
    required this.citiesCount,
    this.youtubeUrl,
    this.videoTitle,
    this.videoSubtitle,
    this.videoThumbnail,
    this.backgroundImage,
    this.features = const [],
  });

  final int totalProperties;
  final int totalDevelopers;
  final int totalUsers;
  final int totalProjects;
  final int citiesCount;
  final String? youtubeUrl;
  final String? videoTitle;
  final String? videoSubtitle;
  final String? videoThumbnail;
  final String? backgroundImage;
  final List<FeatureBadge> features;

  factory PlatformStats.fromJson(Map<String, dynamic> json) => PlatformStats(
    totalProperties: _int(json['total_properties']),
    totalDevelopers: _int(json['total_developers']),
    totalUsers: _int(json['total_users']),
    totalProjects: _int(json['total_projects']),
    citiesCount: _int(json['cities_count']),
    youtubeUrl: _str(json['youtube_url']),
    videoTitle: _str(json['video_title']),
    videoSubtitle: _str(json['video_subtitle']),
    videoThumbnail: _str(json['video_thumbnail']),
    backgroundImage: _str(json['background_image']),
    features:
        (json['features'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(FeatureBadge.fromJson)
            .toList() ??
        const [],
  );
}
