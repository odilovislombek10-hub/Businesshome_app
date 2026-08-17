import 'package:dio/dio.dart';

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

/// `/api/market/cabinet/my-listings` dagi bitta e'lon.
class MyListing {
  const MyListing({
    required this.id,
    required this.title,
    required this.price,
    required this.source,
    required this.views,
    required this.inquiries,
    required this.images,
    this.currency,
    this.dealType,
    this.area,
    this.city,
    this.moderationStatus,
    this.rejectedReason,
    this.createdAt,
  });

  final int id;
  final String title;
  final num price;

  /// `secondary` | `rent` | `ads` — tahrirlash havolasiga `?kind=` bo'lib boradi.
  final String source;
  final int views;
  final int inquiries;

  /// Mutlaq manzillar.
  final List<String> images;

  /// `uzs` | `usd`
  final String? currency;

  /// `sell` | `rent` | `exchange`
  final String? dealType;
  final num? area;
  final String? city;

  /// `pending` | `active` | `rejected` | `paused` | `sold`
  final String? moderationStatus;
  final String? rejectedReason;
  final DateTime? createdAt;

  factory MyListing.fromJson(Map<String, dynamic> json) => MyListing(
    id: (json['id'] as num?)?.toInt() ?? 0,
    title: json['title']?.toString() ?? '',
    price: (json['price'] as num?) ?? 0,
    source: json['source']?.toString() ?? '',
    views: (json['views'] as num?)?.toInt() ?? 0,
    inquiries: (json['inquiries'] as num?)?.toInt() ?? 0,
    images: <String>[
      // Ba'zi javoblarda faqat `image`, ba'zilarida `images` massivi keladi.
      for (final item in (json['images'] as List?) ?? const []) ?absoluteMediaUrl(_text(item)),
      ?absoluteMediaUrl(_text(json['image'])),
    ],
    currency: _text(json['currency']),
    dealType: _text(json['dealType']),
    area: json['area'] as num?,
    city: _text(json['city']),
    moderationStatus: _text(json['moderationStatus']),
    rejectedReason: _text(json['rejectedReason']),
    createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
  );
}

/// `/api/market/cabinet/orders?role=client` dagi bitta buyurtma.
///
/// Mijozning o'z buyurtmalari — kabinetdagi "Mening buyurtmalarim" bo'limi shundan chiziladi.
class ClientOrder {
  const ClientOrder({
    required this.id,
    required this.title,
    required this.status,
    required this.price,
    required this.progress,
    this.providerName,
    this.deadlineAt,
    this.conversationId,
    this.hasReview = false,
  });

  final int id;
  final String title;

  /// `pending` | `accepted` | `in_progress` | `awaiting_confirm` | `completed` |
  /// `cancelled` | `rejected`
  final String status;
  final num price;
  final int progress;
  final String? providerName;
  final String? deadlineAt;
  final int? conversationId;
  final bool hasReview;

  /// Yopilgan buyurtmada muddat rangi neytral bo'ladi — saytdagi `isOrderClosed`.
  bool get isClosed => status == 'completed' || status == 'cancelled' || status == 'rejected';

  /// Muddatgacha necha kun qolgani; manfiy — kechikkan. Saytdagi `daysUntilDeadline`.
  int? get daysLeft {
    final iso = deadlineAt;
    if (iso == null || iso.length < 10) return null;
    final target = DateTime.tryParse(iso.substring(0, 10));
    if (target == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return target.difference(today).inDays;
  }

  factory ClientOrder.fromJson(Map<String, dynamic> json) => ClientOrder(
    id: (json['id'] as num?)?.toInt() ?? 0,
    title: json['title']?.toString() ?? json['serviceName']?.toString() ?? '',
    status: json['status']?.toString() ?? '',
    price: (json['price'] as num?) ?? (json['amount'] as num?) ?? 0,
    progress: (json['progress'] as num?)?.toInt() ?? 0,
    providerName: _text(json['providerName']),
    deadlineAt: _text(json['deadline_at']),
    conversationId: (json['conversation_id'] as num?)?.toInt(),
    hasReview: json['hasReview'] == true,
  );
}

/// Kabinetning umumiy so'rovlari. Har bir bo'lim o'z ma'lumotini alohida oladi — saytda ham
/// shunday, bitta so'rov yiqilsa qolgani chiziladi.
/// `/api/market/cabinet/orders?role=provider` dagi bitta buyurtma — dizayner/usta ko'radi.
class ProviderOrder {
  const ProviderOrder({
    required this.id,
    required this.clientName,
    required this.serviceName,
    required this.amount,
    required this.status,
    required this.progress,
    this.clientAvatar,
    this.description,
    this.deadlineAt,
    this.acceptedAt,
    this.createdAt,
    this.conversationId,
  });

  final int id;
  final String clientName;
  final String serviceName;
  final num amount;

  /// `pending` | `accepted` | `in_progress` | `awaiting_confirm` | `completed` |
  /// `cancelled` | `rejected`
  final String status;
  final int progress;
  final String? clientAvatar;
  final String? description;
  final String? deadlineAt;

  /// Vaqt progressining boshlanish nuqtasi — saytdagi `accepted_at || started_at || created_at`.
  final String? acceptedAt;
  final String? createdAt;
  final int? conversationId;

  /// Saytdagi `activeOrders` — yopilmagan buyurtmalar.
  bool get isActive =>
      status == 'pending' ||
      status == 'accepted' ||
      status == 'in_progress' ||
      status == 'awaiting_confirm';

  DateTime? get _deadline {
    final iso = deadlineAt;
    if (iso == null || iso.length < 10) return null;
    return DateTime.tryParse(iso.substring(0, 10));
  }

  int? get daysLeft {
    final target = _deadline;
    if (target == null) return null;
    final now = DateTime.now();
    return target.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  /// Saytdagi `orderTimeProgress` — qabul qilingandan muddatgacha o'tgan vaqt foizi.
  (int, String, String) get timeProgress {
    final deadline = _deadline;
    if (deadline == null) return (0, 'ok', '');
    final startIso = acceptedAt ?? createdAt;
    final start = DateTime.tryParse(startIso ?? '') ?? DateTime.now();
    final now = DateTime.now();
    final total = deadline.difference(start).inMilliseconds;
    final days = daysLeft ?? 0;

    if (total <= 0) {
      return days < 0 ? (100, 'overdue', '${-days} kun kechikdi') : (100, 'soon', 'Bugun muddati');
    }
    final elapsed = now.difference(start).inMilliseconds;
    final percent = (elapsed / total * 100).round().clamp(0, 100);
    if (days < 0) return (100, 'overdue', '${-days} kun kechikdi');
    if (days == 0) return (percent, 'overdue', 'Bugun muddati');
    if (percent >= 66 || days <= 3) return (percent, 'soon', '$days kun qoldi');
    return (percent, 'ok', '$days kun qoldi');
  }

  factory ProviderOrder.fromJson(Map<String, dynamic> json) => ProviderOrder(
    id: (json['id'] as num?)?.toInt() ?? 0,
    clientName: json['clientName']?.toString() ?? '',
    serviceName: json['serviceName']?.toString() ?? '',
    amount: (json['amount'] as num?) ?? 0,
    status: json['status']?.toString() ?? '',
    progress: (json['progress'] as num?)?.toInt() ?? 0,
    clientAvatar: absoluteMediaUrl(_text(json['clientAvatar'])),
    description: _text(json['description']),
    deadlineAt: _text(json['deadline_at']),
    acceptedAt: _text(json['accepted_at']) ?? _text(json['started_at']),
    createdAt: _text(json['created_at']) ?? _text(json['startDate']),
    conversationId: (json['conversation_id'] as num?)?.toInt(),
  );
}

/// `/api/market/cabinet/specialist-projects` — dizayner/usta bajargan loyihasi.
class SpecialistProject {
  const SpecialistProject({
    required this.id,
    required this.title,
    required this.description,
    required this.images,
    required this.isPublished,
    this.coverImage,
    this.city,
    this.district,
    this.areaM2,
    this.projectType,
    this.budget,
    this.completedAt,
  });

  final int id;
  final String title;
  final String description;
  final List<String> images;

  /// `false` bo'lsa kartada "Qoralama" nishonchasi chiqadi.
  final bool isPublished;
  final String? coverImage;
  final String? city;
  final String? district;
  final num? areaM2;

  /// `apartment` | `house` | `office` | `shop`
  final String? projectType;
  final num? budget;
  final String? completedAt;

  /// Kartadagi rasm — muqova bo'lmasa birinchi rasm.
  String? get thumbnail {
    if (coverImage != null && coverImage!.isNotEmpty) return coverImage;
    return images.isEmpty ? null : images.first;
  }

  factory SpecialistProject.fromJson(Map<String, dynamic> json) => SpecialistProject(
    id: (json['id'] as num?)?.toInt() ?? 0,
    title: json['title']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    images: <String>[
      for (final item in (json['images'] as List?) ?? const []) ?absoluteMediaUrl(_text(item)),
    ],
    isPublished: json['is_published'] != false,
    coverImage: absoluteMediaUrl(_text(json['cover_image'])),
    city: _text(json['city']),
    district: _text(json['district']),
    areaM2: json['area_m2'] as num?,
    projectType: _text(json['project_type']),
    budget: json['budget'] as num?,
    completedAt: _text(json['completed_at']),
  );
}

/// `/api/market/cabinet/reels` — mutaxassisning o'z reeli.
class MyReel {
  const MyReel({
    required this.id,
    required this.title,
    required this.moderationStatus,
    required this.playCount,
    required this.likeCount,
    this.thumbnail,
    this.videoUrl,
    this.rejectedReason,
  });

  final int id;
  final String title;

  /// `pending` | `approved` | `rejected`
  final String moderationStatus;
  final int playCount;
  final int likeCount;
  final String? thumbnail;
  final String? videoUrl;
  final String? rejectedReason;

  factory MyReel.fromJson(Map<String, dynamic> json) => MyReel(
    id: (json['id'] as num?)?.toInt() ?? 0,
    title: json['title']?.toString() ?? '',
    moderationStatus: json['moderation_status']?.toString() ?? '',
    playCount: (json['play_count'] as num?)?.toInt() ?? 0,
    likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
    thumbnail: absoluteMediaUrl(_text(json['thumbnail'])),
    videoUrl: absoluteMediaUrl(_text(json['video_url'])),
    rejectedReason: _text(json['rejected_reason']),
  );
}

/// `/api/market/chat/conversations` dagi bitta suhbat.
class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.otherName,
    required this.unreadCount,
    this.otherAvatar,
    this.otherIsOnline = false,
    this.propertyTitle,
    this.lastText,
    this.lastMessageAt,
  });

  final int id;
  final String otherName;
  final String? otherAvatar;
  final bool otherIsOnline;

  /// Suhbat qaysi e'lon ustida ketayotgani — bo'lsa ism ostida zaytun rangda chiqadi.
  final String? propertyTitle;
  final String? lastText;
  final DateTime? lastMessageAt;
  final int unreadCount;

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    final other = json['other_user'];
    final otherMap = other is Map<String, dynamic> ? other : const <String, dynamic>{};
    final last = json['last_message'];
    return ChatConversation(
      id: (json['id'] as num?)?.toInt() ?? 0,
      otherName: otherMap['name']?.toString() ?? '',
      otherAvatar: absoluteMediaUrl(otherMap['avatar']?.toString()),
      otherIsOnline: otherMap['is_online'] == true,
      propertyTitle: json['property_title']?.toString(),
      lastText: last is Map && last['text'] != null ? last['text'].toString() : null,
      lastMessageAt: DateTime.tryParse(json['last_message_at']?.toString() ?? ''),
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
    );
  }
}

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

  Future<List<MyListing>> myListings() async {
    final res = await _api.get<dynamic>('/market/cabinet/my-listings');
    final data = res.data;
    if (data is! List) return const [];
    return data.whereType<Map<String, dynamic>>().map(MyListing.fromJson).toList();
  }

  /// O'chirish manbaga qarab ikki xil yo'ldan boradi — saytdagi `deleteAd` va
  /// `deleteUserListing`.
  Future<void> deleteListing(MyListing listing) async {
    final path = listing.source == 'ads'
        ? '/market/ads/${listing.id}'
        : '/market/my-listings/${listing.source}/${listing.id}';
    await _api.delete<dynamic>(path);
  }

  /// Saytda mijoz buyurtmalari `role=client` bilan so'raladi.
  Future<List<ClientOrder>> myOrders() async {
    final res = await _api.get<dynamic>('/market/cabinet/orders', query: {'role': 'client'});
    final data = res.data;
    if (data is! List) return const [];
    return data.whereType<Map<String, dynamic>>().map(ClientOrder.fromJson).toList();
  }

  Future<List<SpecialistProject>> myProjects() async {
    final res = await _api.get<dynamic>('/market/cabinet/specialist-projects');
    final data = res.data;
    if (data is! List) return const [];
    return data.whereType<Map<String, dynamic>>().map(SpecialistProject.fromJson).toList();
  }

  /// Yangi loyiha yoki mavjudini yangilash — saytdagi `saveProject`.
  Future<void> saveProject(Map<String, dynamic> payload, {int? id}) async {
    if (id == null) {
      await _api.post<dynamic>('/market/cabinet/specialist-projects', data: payload);
    } else {
      await _api.put<dynamic>('/market/cabinet/specialist-projects/$id', data: payload);
    }
  }

  Future<void> deleteProject(int id) async {
    await _api.delete<dynamic>('/market/cabinet/specialist-projects/$id');
  }

  Future<List<MyReel>> myReels() async {
    final res = await _api.get<dynamic>('/market/cabinet/reels');
    final data = res.data;
    if (data is! List) return const [];
    return data.whereType<Map<String, dynamic>>().map(MyReel.fromJson).toList();
  }

  /// Video + sarlavha. [kind] — dizayner/usta uchun rol kaliti.
  Future<void> uploadReel({required String path, required String title, String? kind}) async {
    final form = FormData.fromMap({
      'title': title,
      'video': await MultipartFile.fromFile(path),
      'kind': ?kind,
    });
    final res = await _api.post<dynamic>('/market/cabinet/reels', data: form);
    if (res.statusCode != null && res.statusCode! >= 400) {
      final data = res.data;
      final detail = data is Map ? data['detail']?.toString() : null;
      throw Exception(detail ?? 'reel upload failed');
    }
  }

  Future<void> deleteReel(int id) async {
    await _api.delete<dynamic>('/market/cabinet/reels/$id');
  }

  /// Rad etilgan reelni qayta moderatsiyaga yuborish.
  Future<void> resubmitReel(int id) async {
    await _api.post<dynamic>('/market/cabinet/reels/$id/submit', data: const <String, dynamic>{});
  }

  /// Mutaxassis profili — portfolio rasmlari shu javobda keladi.
  Future<List<String>> portfolio() async {
    final res = await _api.get<dynamic>('/market/cabinet/my-profile', refresh: true);
    final data = res.data;
    if (data is! Map) return const [];
    return <String>[
      for (final item in (data['portfolio'] as List?) ?? const []) ?absoluteMediaUrl(_text(item)),
    ];
  }

  /// `POST /market/cabinet/specialist-profile/portfolio` — bir nechta rasm birdan.
  Future<List<String>> addPortfolio(List<String> paths) async {
    final form = FormData();
    for (final path in paths) {
      form.files.add(MapEntry('files', await MultipartFile.fromFile(path)));
    }
    final res = await _api.post<dynamic>(
      '/market/cabinet/specialist-profile/portfolio',
      data: form,
    );
    final data = res.data;
    if (data is! Map) return const [];
    return <String>[
      for (final item in (data['portfolio'] as List?) ?? const []) ?absoluteMediaUrl(_text(item)),
    ];
  }

  /// O'chirishda backend rasm manzilini **tanada** kutadi.
  Future<List<String>> removePortfolio(String url) async {
    final res = await _api.delete<dynamic>(
      '/market/cabinet/specialist-profile/portfolio',
      data: {'url': url},
    );
    final data = res.data;
    if (data is! Map) return const [];
    return <String>[
      for (final item in (data['portfolio'] as List?) ?? const []) ?absoluteMediaUrl(_text(item)),
    ];
  }

  /// Dizayner/usta buyurtmalari — saytda `getOrders('provider')`.
  Future<List<ProviderOrder>> providerOrders() async {
    final res = await _api.get<dynamic>('/market/cabinet/orders', query: {'role': 'provider'});
    final data = res.data;
    if (data is! List) return const [];
    return data.whereType<Map<String, dynamic>>().map(ProviderOrder.fromJson).toList();
  }

  /// Saytdagi `chatService.getConversations()` — javob `{items: [...]}` ko'rinishida.
  Future<List<ChatConversation>> conversations() async {
    final res = await _api.get<dynamic>('/market/chat/conversations');
    final data = res.data;
    final items = data is Map ? data['items'] : data;
    if (items is! List) return const [];
    return items.whereType<Map<String, dynamic>>().map(ChatConversation.fromJson).toList();
  }

  /// Saytdagi `confirmDeleteAccount` — tasdiqlangandan keyin hisobni o'chiradi.
  Future<void> deleteAccount() async {
    await _api.post<dynamic>('/market/cabinet/account/delete', data: const <String, dynamic>{});
  }

  Future<List<RoleStat>> roleStats() async {
    final res = await _api.get<dynamic>('/market/cabinet/role-stats');
    final data = res.data;
    if (data is! List) return const [];
    return data.whereType<Map<String, dynamic>>().map(RoleStat.fromJson).toList();
  }
}
