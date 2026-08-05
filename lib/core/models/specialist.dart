/// A designer or master, as returned by `/api/market/designers` and `/api/market/masters`.
///
/// Both endpoints share this shape — the site renders them with the same card, only the heading
/// and the link differ.
class Specialist {
  const Specialist({
    required this.id,
    required this.name,
    this.subtitle,
    this.avatar,
    this.cover,
    this.rating = 0,
    this.reviewsCount = 0,
    this.city,
    this.experience,
    this.url,
  });

  final int id;
  final String name;

  /// Speciality line under the name (`interior`, `santexnik`, …).
  final String? subtitle;
  final String? avatar;
  final String? cover;
  final double rating;
  final int reviewsCount;
  final String? city;
  final int? experience;

  /// The API hands back a ready path (`/designers/8`); fall back to building one.
  final String? url;

  /// The card prefers the wide cover and falls back to the avatar.
  String? get image => (cover?.isNotEmpty ?? false) ? cover : avatar;

  String pathIn(String section) => url ?? '/$section/$id';

  factory Specialist.fromJson(Map<String, dynamic> json) => Specialist(
    id: (json['id'] as num?)?.toInt() ?? 0,
    name: json['name']?.toString() ?? '',
    subtitle: json['subtitle']?.toString(),
    avatar: json['avatar']?.toString(),
    cover: json['cover']?.toString(),
    rating: (json['rating'] as num?)?.toDouble() ?? 0,
    reviewsCount: (json['reviews_count'] as num?)?.toInt() ?? 0,
    city: json['city']?.toString(),
    experience: (json['experience'] as num?)?.toInt(),
    url: json['url']?.toString(),
  );
}
