import 'package:flutter/painting.dart';

import '../../core/models/market_user.dart';
import 'cabinet_repository.dart';

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

  // ── mening e'lonlarim ─────────────────────────────────────────────────────
  static const newListing = "Yangi e'lon berish";
  static const createListing = "E'lon yaratish";
  static const noListings = "Sizda hali e'lonlar yo'q";
  static const noListingsDesc = "Birinchi e'loningizni yarating va mijozlar bilan bog'laning";
  static const edit = 'Tahrirlash';
  static const cancel = 'Bekor qilish';
  static const deleteConfirmTitle = "E'lonni o'chirish";
  static const deleteConfirmMessage = "Bu e'lonni o'chirmoqchimisiz?";
  static const deleteConfirmYes = "Ha, o'chirish";

  /// `cabinet.dealType.*`
  static String dealTypeLabel(String value) => switch (value) {
    'sell' => 'Sotuv',
    'rent' => 'Ijara',
    'exchange' => 'Almashish',
    _ => value,
  };

  /// Moderatsiya holati — saytdagi `modBadgeLabel`.
  static String modLabel(String value) => switch (value) {
    'active' => 'Aktiv',
    'pending' => 'Tasdiqlanmoqda',
    'rejected' => 'Rad etilgan',
    'paused' => 'Yashirilgan',
    'sold' => 'Yopilgan',
    _ => value,
  };

  /// Nishoncha rangi — saytdagi `modBadgeClass` (`/85` shaffofligi bilan).
  static Color modColor(String value) => switch (value) {
    'active' => const Color(0xD910B981),
    'pending' => const Color(0xD9F59E0B),
    'rejected' => const Color(0xD9EF4444),
    'paused' => const Color(0xD9F97316),
    'sold' => const Color(0xD93B82F6),
    _ => const Color(0xD96B7280),
  };

  // ── mening buyurtmalarim ──────────────────────────────────────────────────
  static const noOrders = "Hech qanday buyurtma yo'q";

  /// `cabinet.orderStatus.*`
  static String orderStatusLabel(String status) => switch (status) {
    'pending' => 'Kutilmoqda',
    'accepted' => 'Qabul qilindi',
    'in_progress' => 'Jarayonda',
    'completed' => 'Tugatilgan',
    'awaiting_confirm' => 'Tasdiqlash kutilmoqda',
    'cancelled' => 'Bekor qilingan',
    'rejected' => 'Rad etildi',
    _ => status,
  };

  /// Saytdagi `getOrderStatusClass` — `bg-*-100 text-*-700`.
  static Color orderStatusBackground(String status) => switch (status) {
    'pending' => const Color(0xFFFEF3C7),
    'in_progress' => const Color(0xFFDBEAFE),
    'completed' => const Color(0xFFD1FAE5),
    'cancelled' => const Color(0xFFFEE2E2),
    _ => const Color(0xFFF3F4F6),
  };

  static Color orderStatusForeground(String status) => switch (status) {
    'pending' => const Color(0xFFB45309),
    'in_progress' => const Color(0xFF1D4ED8),
    'completed' => const Color(0xFF047857),
    'cancelled' => const Color(0xFFB91C1C),
    _ => const Color(0xFF4B5563),
  };

  /// `dd.MM.yyyy` — saytdagi `formatDeadline`.
  static String formatDeadline(String? iso) {
    if (iso == null || iso.length < 10) return '';
    final parts = iso.substring(0, 10).split('-');
    if (parts.length != 3) return iso;
    return '${parts[2]}.${parts[1]}.${parts[0]}';
  }

  /// Saytdagi `deadlineState` — ohang va matn.
  static (String, String) deadlineState(ClientOrder order) {
    final days = order.daysLeft;
    if (days == null) return ('none', '');
    if (order.isClosed) return ('closed', formatDeadline(order.deadlineAt));
    if (days < 0) return ('overdue', '${-days} kun kechikdi');
    if (days == 0) return ('overdue', 'Bugun muddati');
    if (days <= 3) return ('soon', '$days kun qoldi');
    return ('ok', '$days kun qoldi');
  }

  /// `deadlineBadgeClass` ranglari.
  static Color deadlineBackground(String tone) => switch (tone) {
    'overdue' => const Color(0xFFFEE2E2),
    'soon' => const Color(0xFFFEF3C7),
    'ok' => const Color(0xFFE0F2FE),
    _ => const Color(0xFFF1F5F9),
  };

  static Color deadlineForeground(String tone) => switch (tone) {
    'overdue' => const Color(0xFFB91C1C),
    'soon' => const Color(0xFFB45309),
    'ok' => const Color(0xFF0369A1),
    _ => const Color(0xFF475569),
  };

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
