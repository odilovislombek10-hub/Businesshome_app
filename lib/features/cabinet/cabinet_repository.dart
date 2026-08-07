import '../../core/api/api_client.dart';
import '../../core/api/media_url.dart';

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

/// `/api/market/cabinet/favorites/detailed` dagi bitta sevimli.
///
/// [source] qaysi katalogdan ekanini aytadi: `new-project` | `secondary` | `rent` | `ads` |
/// `viewer-apartment` | `designer` | `master`.
class FavoriteItem {
  const FavoriteItem({
    required this.propertyId,
    required this.title,
    required this.price,
    required this.source,
    this.image,
    this.type,
    this.metadata,
  });

  final int propertyId;
  final String title;
  final num price;
  final String source;
  final String? image;
  final String? type;

  /// 3D kvartira va yangi loyihalar uchun quruvchi/loyiha kodlari shu yerda keladi.
  final Map<String, dynamic>? metadata;

  bool get isSpecialist => source == 'designer' || source == 'master';

  /// Saytdagi `getFavoriteRoute()`.
  String? get detailRoute {
    final meta = metadata;
    if (source == 'viewer-apartment' && meta != null) {
      final dev = meta['dev_code'];
      final project = meta['project_code'];
      if (dev != null && project != null) return '/$dev/$project';
    }
    if (source == 'new-project' && meta != null) {
      final dev = meta['developer_code'];
      final project = meta['project_code'];
      if (dev != null && project != null) return '/$dev/$project';
    }
    return switch (source) {
      'rent' => '/property/rent/$propertyId',
      'secondary' => '/property/secondary/$propertyId',
      'designer' => '/designers/$propertyId',
      'master' => '/masters/$propertyId',
      _ => '/property/$propertyId',
    };
  }

  factory FavoriteItem.fromJson(Map<String, dynamic> json) => FavoriteItem(
    propertyId: (json['property_id'] as num?)?.toInt() ?? 0,
    title: json['title']?.toString() ?? '',
    price: (json['price'] as num?) ?? 0,
    source: json['source']?.toString() ?? '',
    image: absoluteMediaUrl(_text(json['image'])),
    type: _text(json['type']),
    metadata: json['metadata'] is Map<String, dynamic>
        ? json['metadata'] as Map<String, dynamic>
        : null,
  );
}

/// `/api/market/cabinet/views` — yaqinda ko'rilgan mulk.
class ViewedItem {
  const ViewedItem({
    required this.propertyId,
    required this.title,
    required this.price,
    required this.source,
    this.image,
  });

  final int propertyId;
  final String title;
  final num price;
  final String source;
  final String? image;

  /// Shablonda faqat ijara va ikkilamchi ajratiladi.
  String get detailRoute =>
      source == 'rent' ? '/property/rent/$propertyId' : '/property/secondary/$propertyId';

  factory ViewedItem.fromJson(Map<String, dynamic> json) => ViewedItem(
    propertyId: (json['property_id'] as num?)?.toInt() ?? 0,
    title: json['title']?.toString() ?? '',
    price: (json['price'] as num?) ?? 0,
    source: json['source']?.toString() ?? '',
    image: absoluteMediaUrl(_text(json['image'])),
  );
}

String? _text(dynamic value) {
  final s = value?.toString().trim();
  return s == null || s.isEmpty ? null : s;
}

/// Kabinetning umumiy so'rovlari. Har bir bo'lim o'z ma'lumotini alohida oladi — saytda ham
/// shunday, bitta so'rov yiqilsa qolgani chiziladi.
class CabinetRepository {
  const CabinetRepository();

  ApiClient get _api => ApiClient.instance;

  Future<List<FavoriteItem>> favorites() async {
    final res = await _api.get<dynamic>('/market/cabinet/favorites/detailed');
    final data = res.data;
    if (data is! List) return const [];
    return data.whereType<Map<String, dynamic>>().map(FavoriteItem.fromJson).toList();
  }

  /// Sayt yigirmatasini so'raydi.
  Future<List<ViewedItem>> viewed() async {
    final res = await _api.get<dynamic>('/market/cabinet/views', query: {'limit': 20});
    final data = res.data;
    if (data is! List) return const [];
    return data.whereType<Map<String, dynamic>>().map(ViewedItem.fromJson).toList();
  }

  Future<List<RoleStat>> roleStats() async {
    final res = await _api.get<dynamic>('/market/cabinet/role-stats');
    final data = res.data;
    if (data is! List) return const [];
    return data.whereType<Map<String, dynamic>>().map(RoleStat.fromJson).toList();
  }
}
