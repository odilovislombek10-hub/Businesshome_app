/// A new-build project as returned by /api/market/projects.
///
/// Fields are typed against a real API response rather than assumed: most of them are nullable
/// because the backend genuinely returns null for projects that haven't filled everything in
/// (cover_image, min_price, coordinates and the whole address breakdown are commonly empty).
class Project {
  final int id;
  final String name;
  final String slug;
  final String? address;
  final String? city;
  final String? region;
  final String? district;
  final String? description;
  final String? coverImage;
  final String? cardImage;
  final List<String> cardImages;
  final String? cardSubtitle;
  final String? projectLogo;
  final String? status;
  final String? startDate;
  final String? endDate;
  final double? totalArea;
  final int? totalBlocks;
  final int? totalApartments;
  final num? minPrice;
  final double? latitude;
  final double? longitude;
  final bool isTop;
  final Developer? developer;

  const Project({
    required this.id,
    required this.name,
    required this.slug,
    this.address,
    this.city,
    this.region,
    this.district,
    this.description,
    this.coverImage,
    this.cardImage,
    this.cardImages = const [],
    this.cardSubtitle,
    this.projectLogo,
    this.status,
    this.startDate,
    this.endDate,
    this.totalArea,
    this.totalBlocks,
    this.totalApartments,
    this.minPrice,
    this.latitude,
    this.longitude,
    this.isTop = false,
    this.developer,
  });

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] as int,
        name: (json['name'] ?? '') as String,
        slug: (json['slug'] ?? '') as String,
        address: json['address'] as String?,
        city: json['city'] as String?,
        region: json['region'] as String?,
        district: json['district'] as String?,
        description: json['description'] as String?,
        coverImage: json['cover_image'] as String?,
        cardImage: json['card_image'] as String?,
        cardImages: (json['card_images'] as List?)?.whereType<String>().toList() ?? const [],
        cardSubtitle: json['card_subtitle'] as String?,
        projectLogo: json['project_logo'] as String?,
        status: json['status'] as String?,
        startDate: json['start_date'] as String?,
        endDate: json['end_date'] as String?,
        totalArea: (json['total_area'] as num?)?.toDouble(),
        totalBlocks: json['total_blocks'] as int?,
        totalApartments: json['total_apartments'] as int?,
        minPrice: json['min_price'] as num?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        isTop: (json['is_top'] as bool?) ?? false,
        developer: json['developer'] is Map<String, dynamic>
            ? Developer.fromJson(json['developer'] as Map<String, dynamic>)
            : null,
      );

  /// First usable image: the card image is what the website shows in listings, with the cover and
  /// the extra card images as fallbacks.
  String? get thumbnail {
    for (final candidate in [cardImage, coverImage, ...cardImages]) {
      if (candidate != null && candidate.isNotEmpty) return candidate;
    }
    return null;
  }

  /// Human-readable location, skipping the parts the backend left empty.
  String get locationLabel =>
      [district, city, region, address].where((s) => s != null && s.isNotEmpty).take(2).join(', ');
}

class Developer {
  final String? code;
  final String? name;
  final String? logo;

  const Developer({this.code, this.name, this.logo});

  factory Developer.fromJson(Map<String, dynamic> json) => Developer(
        code: json['code'] as String?,
        name: json['name'] as String?,
        logo: json['logo'] as String?,
      );
}
