import '../api/media_url.dart';

/// `/api/market/masters` javobidagi bitta usta.
///
/// Maydonlar saytning `features/masters/masters.data.ts` dagi `Master` interfeysi bilan bir xil
/// nomlanadi — bu endpoint camelCase qaytaradi.
class Master {
  const Master({
    required this.id,
    required this.fullName,
    required this.specialization,
    required this.avatar,
    required this.city,
    required this.rating,
    required this.reviewsCount,
    required this.priceFrom,
    required this.tags,
    required this.phone,
    this.isVerified = false,
    this.isAvailable = true,
  });

  final int id;
  final String fullName;

  /// `plumber` | `electrician` | `painter` | `carpenter` | `tiler` | `welder`, lekin bazada
  /// filtr ro'yxatida yo'q qiymatlar ham bor (`qurilish`, `other`) — kartada ular ham chiqadi.
  final String specialization;

  /// Bo'sh bo'lishi mumkin — u holda karta ism harflaridan avatar chizadi.
  final String avatar;

  /// Kod (`tashkent_city`) yoki tayyor nom bo'lishi mumkin.
  final String city;
  final double rating;
  final int reviewsCount;
  final num priceFrom;
  final List<String> tags;
  final String phone;
  final bool isVerified;

  /// Karta muqovasidagi "🟢 Bo'sh" / "🟡 Band" nishonchasi.
  final bool isAvailable;

  static String? _text(dynamic value) {
    final s = value?.toString().trim();
    return s == null || s.isEmpty ? null : s;
  }

  factory Master.fromJson(Map<String, dynamic> json) => Master(
    id: (json['id'] as num?)?.toInt() ?? 0,
    fullName: json['fullName']?.toString() ?? '',
    specialization: json['specialization']?.toString() ?? '',
    avatar: absoluteMediaUrl(_text(json['avatar'])) ?? '',
    city: json['city']?.toString() ?? '',
    rating: (json['rating'] as num?)?.toDouble() ?? 0,
    reviewsCount: (json['reviewsCount'] as num?)?.toInt() ?? 0,
    priceFrom: (json['priceFrom'] as num?) ?? 0,
    tags: <String>[for (final tag in (json['tags'] as List?) ?? const []) ?_text(tag)],
    phone: json['phone']?.toString() ?? '',
    isVerified: json['isVerified'] == true,
    // Shablon `master.isAvailable === false` ni tekshiradi, ya'ni yo'q bo'lsa "Bo'sh".
    isAvailable: json['isAvailable'] != false,
  );
}
