import 'package:flutter/painting.dart';

import '../../core/models/market_user.dart';

/// Kabinet matnlari — `cabinet.*` kalitlari `core/i18n/translations/uz.ts` dan aynan olingan.
abstract final class CabinetTexts {
  static const logout = 'Chiqish';
  static const viewAll = "Barchasini ko'rish";
  static const marketplace = 'Marketplace';
  static const unknownUser = 'Foydalanuvchi';
  static const kycRequired = 'OneID tasdiqlash kerak';
  static const kycMessage =
      "E'lon berish va sotuvchi profilingiz ko'rinishi uchun davlat OneID orqali tasdiqlanish kerak";
  static const kycAction = 'OneID orqali kirish';

  /// `cabinet.tab.*`
  static const tabLabels = <String, String>{
    'dashboard': 'Bosh sahifa',
    'listings': "Mening e'lonlarim",
    'favorites': 'Sevimlilar',
    'viewed': "Yaqinda ko'rilganlar",
    'inquiries': "So'rovlar",
    'orders': 'Buyurtmalar',
    'portfolio': 'Portfolio',
    'projects': 'Loyihalarim',
    'reels': 'Reels',
    'services': 'Xizmatlar',
    'reviews': 'Sharhlar',
    'earnings': 'Daromad',
    'messages': 'Xabarlar',
    'profile': 'Profil',
    'settings': 'Sozlamalar',
    'agent-profile': 'Agentlik profili',
    'my-orders': 'Mening buyurtmalarim',
    'kyc': 'KYC tasdiqlash',
  };

  static String tabLabel(String id) => tabLabels[id] ?? 'Kabinet';

  /// `cabinet.stat.*` — API yorliqni kalit sifatida qaytaradi.
  static const statLabels = <String, String>{
    'cabinet.stat.favorites': 'Sevimlilar',
    'cabinet.stat.viewed': "Ko'rilganlar",
    'cabinet.stat.searches': 'Qidiruvlar',
    'cabinet.stat.unread': "O'qilmagan",
    'cabinet.stat.activeListings': "Faol e'lonlar",
    'cabinet.stat.todayViews': "Bugungi ko'rishlar",
    'cabinet.stat.newInquiries': "Yangi so'rovlar",
    'cabinet.stat.monthEarnings': 'Oylik daromad',
    'cabinet.stat.activeOrders': 'Faol buyurtmalar',
    'cabinet.stat.rating': 'Reyting',
    'cabinet.stat.activeClients': 'Faol mijozlar',
  };

  static String statLabel(String key) => statLabels[key] ?? key;

  /// Bosilganda qaysi bo'limga olib boradi — saytdagi `statRouteMap`.
  static const statRoutes = <String, String>{
    'cabinet.stat.activeListings': 'listings',
    'cabinet.stat.todayViews': 'listings',
    'cabinet.stat.newInquiries': 'inquiries',
    'cabinet.stat.monthEarnings': 'earnings',
    'cabinet.stat.activeOrders': 'orders',
    'cabinet.stat.rating': 'reviews',
    'cabinet.stat.activeClients': 'orders',
    'cabinet.stat.favorites': 'favorites',
    'cabinet.stat.viewed': 'viewed',
    'cabinet.stat.unread': 'messages',
  };

  /// `cabinet.role.*`
  static String roleLabel(MarketRole role) => switch (role) {
    MarketRole.user => 'Foydalanuvchi',
    MarketRole.agent => 'Agent',
    MarketRole.designer => 'Dizayner',
    MarketRole.master => 'Usta',
    MarketRole.developer => 'Quruvchi',
  };

  /// Boshqaruv panelidagi sarlavha ostidagi izoh — saytdagi `dashSubtitle`.
  static String dashSubtitle(MarketRole role) => switch (role) {
    MarketRole.designer => 'Faol loyihalaringiz va daromadingiz bir qarashda.',
    MarketRole.master => 'Faol buyurtmalaringiz va daromadingiz bir qarashda.',
    MarketRole.agent => "E'lonlaringiz va so'rovlaringiz bir qarashda.",
    _ => "Bugun nima qilamiz? Buyurtma va e'lonlaringiz shu yerda.",
  };

  static const greeting = 'Assalomu alaykum';

  // ── sevimlilar ────────────────────────────────────────────────────────────
  static const noFavorites = "Hali sevimlilar yo'q";
  static const noFavoritesDesc =
      "Yoqtirgan e'lonlaringizni saqlab qo'ying — ularni bu yerda topasiz";
  static const noFavoritesInCategory = "Bu kategoriyada sevimlilar yo'q";
  static const startSearch = 'Qidirishni boshlash';

  /// `cabinet.favFilter.*` — filtr tugmalari; tartibi shablondagidek.
  static const _favFilters = <(String, String)>[
    ('new-project', 'Yangi loyihalar'),
    ('secondary', 'Ikkilamchi'),
    ('rent', 'Ijara'),
    ('viewer-apartment', '3D kvartiralar'),
    ('ads', "E'lonlar"),
    ('designer', 'Dizaynerlar'),
    ('master', 'Ustalar'),
  ];

  static List<(String, String)> favoriteTabsFor(Set<String> sources) => [
    ('all', 'Hammasi'),
    for (final (key, label) in _favFilters)
      if (sources.contains(key)) (key, label),
  ];

  /// `cabinet.favBadge.*` + rasm ustidagi rangi.
  static (String, Color)? favoriteBadge(String source) => switch (source) {
    'viewer-apartment' => ('3D', Color(0x99000000)),
    'new-project' => ('Yangi loyiha', Color(0xE687885C)),
    'rent' => ('Ijara', Color(0xCC3B82F6)),
    'secondary' => ('Ikkilamchi', Color(0xCCF59E0B)),
    'designer' => ('Dizayner', Color(0xCCA855F7)),
    'master' => ('Usta', Color(0xCC14B8A6)),
    _ => null,
  };
}
