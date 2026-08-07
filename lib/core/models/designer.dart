import '../api/media_url.dart';

/// `/api/market/designers` javobidagi bitta dizayner.
///
/// Maydonlar saytning `features/designers/designers.data.ts` dagi `Designer` interfeysi bilan
/// bir xil nomlanadi — bu endpoint camelCase qaytaradi.
class Designer {
  const Designer({
    required this.id,
    required this.fullName,
    required this.specialization,
    required this.avatar,
    required this.portfolio,
    required this.description,
    required this.city,
    required this.rating,
    required this.reviewsCount,
    required this.completedProjects,
    required this.priceFrom,
    required this.experience,
    required this.tags,
    required this.phone,
    this.coverImage,
    this.videoUrl,
    this.isVerified = false,
  });

  final int id;
  final String fullName;

  /// `interior` | `exterior` | `landscape` | `architecture`
  final String specialization;

  /// Bo'sh bo'lishi mumkin — u holda karta ism harflaridan avatar chizadi.
  final String avatar;
  final String? coverImage;

  /// Mutlaq manzillar — kartaga yo'l yechish kerak emas.
  final List<String> portfolio;
  final String description;

  /// Kod (`tashkent_city`) yoki tayyor nom bo'lishi mumkin — backendda ikkalasi ham uchraydi.
  final String city;
  final double rating;
  final int reviewsCount;
  final int completedProjects;
  final num priceFrom;
  final int experience;
  final List<String> tags;
  final String phone;

  /// Bo'lsa avatar ustida qizil "play" nishonchasi chiqadi va `/reels/designer-<id>` ga olib boradi.
  final String? videoUrl;
  final bool isVerified;

  static String? _text(dynamic value) {
    final s = value?.toString().trim();
    return s == null || s.isEmpty ? null : s;
  }

  factory Designer.fromJson(Map<String, dynamic> json) => Designer(
    id: (json['id'] as num?)?.toInt() ?? 0,
    fullName: json['fullName']?.toString() ?? '',
    specialization: json['specialization']?.toString() ?? '',
    avatar: absoluteMediaUrl(_text(json['avatar'])) ?? '',
    coverImage: absoluteMediaUrl(_text(json['coverImage'])),
    portfolio: <String>[
      for (final item in (json['portfolio'] as List?) ?? const []) ?absoluteMediaUrl(_text(item)),
    ],
    description: json['description']?.toString() ?? '',
    city: json['city']?.toString() ?? '',
    rating: (json['rating'] as num?)?.toDouble() ?? 0,
    reviewsCount: (json['reviewsCount'] as num?)?.toInt() ?? 0,
    completedProjects: (json['completedProjects'] as num?)?.toInt() ?? 0,
    priceFrom: (json['priceFrom'] as num?) ?? 0,
    experience: (json['experience'] as num?)?.toInt() ?? 0,
    tags: <String>[for (final tag in (json['tags'] as List?) ?? const []) ?_text(tag)],
    phone: json['phone']?.toString() ?? '',
    videoUrl: _text(json['videoUrl']),
    isVerified: json['isVerified'] == true,
  );
}
