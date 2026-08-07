import '../../core/api/api_client.dart';

/// `/api/market/cabinet/role-stats` dagi bitta ko'rsatkich.
///
/// [label] — tarjima kaliti (`cabinet.stat.activeListings` kabi), qiymati emas.
class RoleStat {
  const RoleStat({
    required this.label,
    required this.value,
    required this.sparkline,
    this.suffix,
    this.trend,
  });

  final String label;
  final num value;

  /// Bo'lsa, qiymat ostida kichkina izoh sifatida chiqadi (masalan valyuta).
  final String? suffix;

  /// Foizdagi o'zgarish; `null` yoki `0` bo'lsa nishoncha chizilmaydi.
  final num? trend;

  /// Karta o'ng pastidagi mayda grafik uchun nuqtalar.
  final List<num> sparkline;

  factory RoleStat.fromJson(Map<String, dynamic> json) => RoleStat(
    label: json['label']?.toString() ?? '',
    value: (json['value'] as num?) ?? 0,
    suffix: json['suffix']?.toString(),
    trend: json['trend'] as num?,
    sparkline: <num>[
      for (final v in (json['sparkline'] as List?) ?? const [])
        if (v is num) v,
    ],
  );
}

/// Kabinetning umumiy so'rovlari. Har bir bo'lim o'z ma'lumotini alohida oladi — saytda ham
/// shunday, bitta so'rov yiqilsa qolgani chiziladi.
class CabinetRepository {
  const CabinetRepository();

  ApiClient get _api => ApiClient.instance;

  Future<List<RoleStat>> roleStats() async {
    final res = await _api.get<dynamic>('/market/cabinet/role-stats');
    final data = res.data;
    if (data is! List) return const [];
    return data.whereType<Map<String, dynamic>>().map(RoleStat.fromJson).toList();
  }
}
