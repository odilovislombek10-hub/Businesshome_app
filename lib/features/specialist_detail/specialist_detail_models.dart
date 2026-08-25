import '../../core/api/media_url.dart';

/// Dizayner/usta tafsilot javobidagi qo'shimcha maydonlar.
///
/// Ro'yxat javobiga (`Designer`, `Master`) nisbatan bu yerda reyting taqsimoti, javob
/// darajasi va xizmat paketlari ham keladi — ular faqat `/designers/{id}` va
/// `/masters/{id}` endpointlarida bor.
class SpecialistDetail {
  const SpecialistDetail({
    required this.id,
    required this.fullName,
    required this.specialization,
    this.avatar,
    this.coverImage,
    this.description,
    this.city,
    this.rating = 0,
    this.reviewsCount = 0,
    this.completedProjects = 0,
    this.experience = 0,
    this.priceFrom = 0,
    this.responseRate,
    this.isAvailable = false,
    this.isVerified = false,
    this.phone,
    this.telegram,
    this.instagram,
    this.portfolio = const [],
    this.tags = const [],
    this.ratingBreakdown = const RatingBreakdown(),
    this.servicePackages = const [],
  });

  final int id;
  final String fullName;
  final String specialization;
  final String? avatar;
  final String? coverImage;
  final String? description;
  final String? city;
  final double rating;
  final int reviewsCount;
  final int completedProjects;
  final int experience;
  final num priceFrom;

  /// 0..1 oralig'ida; ekranda foizga aylantiriladi.
  final double? responseRate;

  final bool isAvailable;
  final bool isVerified;
  final String? phone;
  final String? telegram;
  final String? instagram;
  final List<String> portfolio;
  final List<String> tags;
  final RatingBreakdown ratingBreakdown;
  final List<ServicePackage> servicePackages;

  int? get responseRatePercent => responseRate == null ? null : (responseRate! * 100).round();

  static String? _text(Object? value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  factory SpecialistDetail.fromJson(Map<String, dynamic> json) => SpecialistDetail(
    id: (json['id'] as num?)?.toInt() ?? 0,
    fullName: _text(json['fullName']) ?? '',
    specialization: _text(json['specialization']) ?? '',
    avatar: absoluteMediaUrl(_text(json['avatar'])),
    coverImage: absoluteMediaUrl(_text(json['coverImage'])),
    description: _text(json['description']),
    city: _text(json['city']),
    rating: (json['rating'] as num?)?.toDouble() ?? 0,
    reviewsCount: (json['reviewsCount'] as num?)?.toInt() ?? 0,
    completedProjects: (json['completedProjects'] as num?)?.toInt() ?? 0,
    experience: (json['experience'] as num?)?.toInt() ?? 0,
    priceFrom: json['priceFrom'] is num ? json['priceFrom'] as num : 0,
    responseRate: (json['responseRate'] as num?)?.toDouble(),
    isAvailable: json['isAvailable'] == true,
    isVerified: json['isVerified'] == true,
    phone: _text(json['phone']),
    telegram: _text(json['telegram']),
    instagram: _text(json['instagram']),
    portfolio: [
      for (final item in (json['portfolio'] as List? ?? const [])) ?absoluteMediaUrl(_text(item)),
    ],
    tags: [for (final tag in (json['tags'] as List? ?? const [])) ?_text(tag)],
    ratingBreakdown: RatingBreakdown.fromJson(json['ratingBreakdown']),
    servicePackages: [
      for (final row in (json['servicePackages'] as List? ?? const []))
        if (row is Map) ServicePackage.fromJson(row),
    ],
  );
}

/// Yulduzlar bo'yicha taqsimot — har biri foizda.
class RatingBreakdown {
  const RatingBreakdown({this.five = 0, this.four = 0, this.three = 0, this.two = 0, this.one = 0});

  final double five;
  final double four;
  final double three;
  final double two;
  final double one;

  bool get isEmpty => five == 0 && four == 0 && three == 0 && two == 0 && one == 0;

  /// 5 dan 1 gacha — ekranda shu tartibda chiziladi.
  List<(int, double)> get rows => [(5, five), (4, four), (3, three), (2, two), (1, one)];

  factory RatingBreakdown.fromJson(Object? json) {
    if (json is! Map) return const RatingBreakdown();
    double at(String key) => (json[key] as num?)?.toDouble() ?? 0;
    return RatingBreakdown(
      five: at('five'),
      four: at('four'),
      three: at('three'),
      two: at('two'),
      one: at('one'),
    );
  }
}

/// Mutaxassis kabinetda yaratadigan xizmat paketi.
class ServicePackage {
  const ServicePackage({
    required this.id,
    required this.title,
    required this.price,
    required this.deliveryDays,
    this.features = const [],
    this.isRecommended = false,
  });

  final int id;
  final String title;
  final num price;
  final int deliveryDays;
  final List<String> features;
  final bool isRecommended;

  factory ServicePackage.fromJson(Map row) => ServicePackage(
    id: (row['id'] as num?)?.toInt() ?? 0,
    title: row['title']?.toString() ?? '',
    price: row['price'] is num ? row['price'] as num : 0,
    deliveryDays: (row['deliveryDays'] as num?)?.toInt() ?? 0,
    features: [
      for (final f in (row['features'] as List? ?? const []))
        if (f != null) f.toString(),
    ],
    isRecommended: row['isRecommended'] == true,
  );
}

/// Mutaxassisga yozilgan sharh.
class SpecialistReview {
  const SpecialistReview({
    required this.id,
    required this.authorName,
    required this.rating,
    this.authorAvatar,
    this.text,
    this.replyText,
    this.createdAt,
  });

  final int id;
  final String authorName;
  final int rating;
  final String? authorAvatar;
  final String? text;
  final String? replyText;
  final DateTime? createdAt;

  static String? _text(Object? value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  factory SpecialistReview.fromJson(Map row) => SpecialistReview(
    id: (row['id'] as num?)?.toInt() ?? 0,
    authorName: _text(row['authorName']) ?? '',
    rating: (row['rating'] as num?)?.toInt() ?? 0,
    authorAvatar: absoluteMediaUrl(_text(row['authorAvatar'])),
    text: _text(row['text']),
    replyText: _text(row['replyText']),
    createdAt: DateTime.tryParse(row['createdAt']?.toString() ?? ''),
  );
}

/// Usta sahifasidagi narx jadvali qatori.
///
/// Usta kabinetdan o'z paketlarini kiritgan bo'lsa — shulardan yig'iladi.
/// Kiritmagan bo'lsa sayt mutaxassisligiga qarab standart taklifni ko'rsatadi:
/// narxlar `priceFrom` ga ko'paytma qo'llab hisoblanadi.
class ServiceRow {
  const ServiceRow({
    required this.name,
    required this.price,
    required this.unit,
    required this.description,
  });

  final String name;
  final num price;
  final String unit;
  final String description;
}
