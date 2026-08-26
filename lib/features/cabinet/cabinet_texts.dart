import '../../core/i18n/translate.dart';
import 'package:flutter/painting.dart';

import '../../core/models/market_user.dart';
import 'cabinet_repository.dart';

/// Kabinet matnlari — `cabinet.*` kalitlari `core/i18n/translations/uz.ts` dan aynan olingan.
abstract final class CabinetTexts {
  // Boshqaruv panelidagi rolga qarab chiziladigan bloklar (`cabinet.component.ts`).
  static String get topListings => t('cabinet.topListings');
  static String get marketInsight => t('cabinet.marketInsight');
  static String get marketDesc => t('cabinet.marketDesc');
  static String get aboveMarket => t('cabinet.aboveMarket');
  static String get activeOrdersTitle => t('cabinet.activeOrdersTitle');
  static String get progress => t('cabinet.progress');
  static String get latestReview => t('cabinet.latestReview');
  static String get allReviews => t('cabinet.allReviews');
  static String get welcomeUser => t('cabinet.welcomeUser');
  static String get welcomeUserDesc => t('cabinet.welcomeUserDesc');

  // Profil bo'limi
  static String get uploadCover => t('cabinet.uploadCover');
  static String get availability => t('cabinet.availability');
  static String get editSpecialistProfile => t('cabinet.editSpecialistProfile');
  static const availableFromLabel = 'Qachondan boshlab yana qabul qila boshlaysiz?';
  static const coverTooLarge = "Fayl hajmi 5MB dan oshmasligi kerak";

  /// Bandlik holatlari — saytdagi `availabilityOptions`.
  static List<({String value, String label, String emoji, Color color})> get availabilityOptions =>
      <({String value, String label, String emoji, Color color})>[
        (
          value: 'available',
          label: t('cabinet.listingStatus.available'),
          emoji: '🟢',
          color: Color(0xFF10B981),
        ),
        (
          value: 'busy',
          label: t('cabinet.listingStatus.reserved'),
          emoji: '🟡',
          color: Color(0xFFF59E0B),
        ),
        (value: 'full', label: 'To\u02bcliq', emoji: '🔴', color: Color(0xFFEF4444)),
        (value: 'vacation', label: 'Ta\u02bctilda', emoji: '🏖️', color: Color(0xFF0EA5E9)),
        (value: 'offline', label: t('chat.offline'), emoji: '⚪', color: Color(0xFF64748B)),
      ];

  // Buyurtma kartasi
  static String get startDate => t('cabinet.startDate');
  static String get yesterday => t('cabinet.yesterday');
  static String get today => t('cabinet.today');
  static String get daysAgo => t('cabinet.daysAgo');

  // Buyurtmalarim
  static String get myOrdersEmpty => t('myOrders.empty');
  static String get writeReview => t('myOrders.writeReview');
  static String get reviewPlaceholder => t('myOrders.reviewPlaceholder');

  // Xizmat paketlari
  static String get servicesConfirmDelete => t('services.confirmDelete');

  // Chiqishni tasdiqlash oynasi
  static String get logoutConfirmTitle => t('cabinet.logoutConfirmTitle');
  static String get logoutConfirmMessage => t('cabinet.logoutConfirmMessage');
  static String get logoutConfirmYes => t('cabinet.logoutConfirmYes');
  static String get logoutConfirmCancel => t('cabinet.logoutConfirmCancel');

  static String get logout => t('cabinet.logout');
  static String get viewAll => t('cabinet.viewAll');
  static const marketplace = 'Marketplace';
  static String get unknownUser => t('cabinet.role.user');
  static String get kycRequired => t('cabinet.kycRequired');
  static String get kycMessage => t('cabinet.kycMessage');
  static const kycAction = 'OneID orqali kirish';

  /// `cabinet.tab.*`
  static Map<String, String> get tabLabels => <String, String>{
    'dashboard': t('cabinet.tab.dashboard'),
    'listings': t('cabinet.tab.listings'),
    'favorites': t('cabinet.tab.favorites'),
    'viewed': t('cabinet.tab.viewed'),
    'inquiries': t('cabinet.tab.inquiries'),
    'orders': t('cabinet.tab.orders'),
    'portfolio': t('cabinet.tab.portfolio'),
    'projects': t('cabinet.tab.projects'),
    'reels': t('cabinet.tab.reels'),
    'services': t('cabinet.tab.services'),
    'reviews': t('cabinet.tab.reviews'),
    'earnings': t('cabinet.tab.earnings'),
    'messages': t('cabinet.tab.messages'),
    'profile': t('cabinet.tab.profile'),
    'settings': t('cabinet.tab.settings'),
    'agent-profile': t('cabinet.tab.agentProfile'),
    'my-orders': t('cabinet.tab.myOrders'),
    'kyc': t('cabinet.tab.kyc'),
  };

  static String tabLabel(String id) => tabLabels[id] ?? 'Kabinet';

  /// `cabinet.stat.*` — API yorliqni kalit sifatida qaytaradi.
  static Map<String, String> get statLabels => <String, String>{
    'cabinet.stat.favorites': t('cabinet.tab.favorites'),
    'cabinet.stat.viewed': t('cabinet.stat.viewed'),
    'cabinet.stat.searches': t('cabinet.stat.searches'),
    'cabinet.stat.unread': t('cabinet.stat.unread'),
    'cabinet.stat.activeListings': t('cabinet.stat.activeListings'),
    'cabinet.stat.todayViews': t('cabinet.stat.todayViews'),
    'cabinet.stat.newInquiries': t('cabinet.stat.newInquiries'),
    'cabinet.stat.monthEarnings': t('cabinet.monthlyChart'),
    'cabinet.stat.activeOrders': t('cabinet.activeOrdersTitle'),
    'cabinet.stat.rating': t('cabinet.stat.rating'),
    'cabinet.stat.activeClients': t('cabinet.stat.activeClients'),
  };

  static String statLabel(String key) => statLabels[key] ?? key;

  /// Bosilganda qaysi bo'limga olib boradi — saytdagi `statRouteMap`.
  static Map<String, String> get statRoutes => <String, String>{
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
    MarketRole.user => t('cabinet.role.user'),
    MarketRole.agent => t('cabinet.role.agent'),
    MarketRole.designer => t('cabinet.favBadge.designer'),
    MarketRole.master => t('cabinet.favBadge.master'),
    MarketRole.developer => t('detail.developer'),
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
  static String get newListing => t('cabinet.newListing');
  static String get createListing => t('cabinet.createListing');
  static String get noListings => t('cabinet.noListings');
  static String get noListingsDesc => t('cabinet.noListingsDesc');
  static String get edit => t('cabinet.edit');
  static String get cancel => t('cabinet.logoutConfirmCancel');
  static String get deleteConfirmTitle => t('cabinet.deleteConfirmTitle');
  static String get deleteConfirmMessage => t('cabinet.deleteConfirmMessage');
  static String get deleteConfirmYes => t('cabinet.deleteConfirmYes');

  /// `cabinet.dealType.*`
  static String dealTypeLabel(String value) => switch (value) {
    'sell' => t('cabinet.dealType.sell'),
    'rent' => t('cabinet.dealType.rent'),
    'exchange' => t('cabinet.dealType.exchange'),
    _ => value,
  };

  /// Moderatsiya holati — saytdagi `modBadgeLabel`.
  static String modLabel(String value) => switch (value) {
    'active' => 'Aktiv',
    'pending' => 'Tasdiqlanmoqda',
    'rejected' => t('cabinet.reels.statusRejected'),
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
  static String get noOrders => t('cabinet.noOrders');

  /// `cabinet.orderStatus.*`
  static String orderStatusLabel(String status) => switch (status) {
    'pending' => t('cabinet.reels.statusPending'),
    'accepted' => t('cabinet.orderStatus.accepted'),
    'in_progress' => t('cabinet.inquiryStatus.in_progress'),
    'completed' => t('cabinet.orderStatus.completed'),
    'awaiting_confirm' => t('cabinet.orderStatus.awaiting_confirm'),
    'cancelled' => t('cabinet.orderStatus.cancelled'),
    'rejected' => t('cabinet.orderStatus.rejected'),
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
  static String get noFavorites => t('cabinet.noFavorites');
  static String get noFavoritesDesc => t('cabinet.noFavoritesDesc');
  static String get noFavoritesInCategory => t('cabinet.noFavoritesInCategory');
  static String get startSearch => t('cabinet.startSearch');

  /// `cabinet.favFilter.*` — filtr tugmalari; tartibi shablondagidek.
  static List<(String, String)> get _favFilters => <(String, String)>[
    ('new-project', t('cabinet.favFilter.newProject')),
    ('secondary', t('cabinet.favFilter.secondary')),
    ('rent', t('cabinet.dealType.rent')),
    ('viewer-apartment', t('cabinet.favFilter.viewer')),
    ('ads', t('cabinet.favFilter.ads')),
    ('designer', t('cabinet.favFilter.designer')),
    ('master', t('cabinet.favFilter.master')),
  ];

  static List<(String, String)> favoriteTabsFor(Set<String> sources) => [
    ('all', t('cabinet.favFilter.all')),
    for (final (key, label) in _favFilters)
      if (sources.contains(key)) (key, label),
  ];

  // ── loyihalarim ───────────────────────────────────────────────────────────
  static String get projectsSubtitle => t('cabinet.projects.subtitle');
  static String get projectAddNew => t('cabinet.newProject');
  static String get projectAddFirst => t('cabinet.projects.addFirst');
  static String get projectsEmpty => t('cabinet.projects.empty');
  static String get projectEdit => t('cabinet.projects.edit');
  static String get projectDraft => t('cabinet.projects.draft');
  static String get projectTitle => t('cabinet.projects.title');
  static String get projectTitlePlaceholder => t('cabinet.projects.titlePlaceholder');
  static String get projectDescription => t('cabinet.projects.description');
  static String get projectDescPlaceholder => t('cabinet.projects.descPlaceholder');
  static String get projectImages => t('cabinet.projects.images');
  static String get projectUploadImages => t('cabinet.projects.uploadImages');
  static String get projectCover => t('cabinet.projects.cover');
  static String get projectCity => t('cabinet.projects.city');
  static String get projectDistrict => t('cabinet.district');
  static String get projectArea => t('cabinet.projects.area');
  static String get projectType => t('cabinet.projects.projectType');
  static String get projectBudget => t('cabinet.projects.budget');
  static String get projectBudgetSuffix => t('createSpecialist.priceSuffix');
  static String get projectCompletedAt => t('cabinet.projects.completedAt');
  static const projectSaveError = "Loyihani saqlab bo'lmadi";
  static const projectDeleteError = "O'chirib bo'lmadi";
  static const projectsLoadError = "Loyihalarni yuklab bo'lmadi";
  static String get save => t('common.save');

  /// `createListing.type*` — obyekt turi ro'yxati.
  static List<(String, String)> get projectTypes => <(String, String)>[
    ('apartment', t('header.dropdown.apartment')),
    ('house', t('header.dropdown.house')),
    ('office', t('header.dropdown.office')),
    ('shop', t('header.dropdown.shop')),
  ];

  // ── xizmatlar (paketlar) ──────────────────────────────────────────────────
  static String get serviceAdd => t('services.add');
  static String get serviceEdit => t('services.edit');
  static String get servicesEmpty => t('services.empty');
  static String get servicesEmptyDesc => t('services.emptyDesc');
  static String get serviceTitle => t('services.title');
  static String get servicePrice => t('services.price');
  static String get serviceDelivery => t('services.delivery');
  static String get serviceFeatures => t('services.features');
  static String get serviceFeaturesHint => t('services.featuresHint');
  static String get serviceDays => t('services.days');
  static String get serviceRecommended => t('services.recommended');
  static String get serviceMakeRecommended => t('services.makeRecommended');
  static const servicesLoadError = "Paketlarni yuklab bo'lmadi";
  static const serviceSaveError = "Paketni saqlab bo'lmadi";
  static String get delete => t('common.delete');

  // ── so'rovlar (agent) ─────────────────────────────────────────────────────
  static String get inquiryReply => t('cabinet.reply');
  static String get inquiryCall => t('cabinet.call');
  static const inquiriesEmpty = "Hali so'rovlar yo'q";
  static const inquiriesLoadError = "So'rovlarni yuklab bo'lmadi";
  static const inquiryChatError = "Suhbatni ochib bo'lmadi";

  /// `cabinet.inquiryStatus.*` — yorliq, matn rangi va foni.
  static (String, Color, Color) inquiryStatusStyle(String status) => switch (status) {
    'new' => (t('cabinet.inquiryStatus.new'), Color(0xFF1D4ED8), Color(0xFFDBEAFE)),
    'in_progress' => (t('cabinet.inquiryStatus.in_progress'), Color(0xFFB45309), Color(0xFFFEF3C7)),
    'completed' => (t('cabinet.inquiryStatus.completed'), Color(0xFF047857), Color(0xFFD1FAE5)),
    _ => (status, Color(0xFF4B5563), Color(0xFFF3F4F6)),
  };

  // ── agentlik profili ──────────────────────────────────────────────────────
  static String get agentDisplayName => t('agentProfile.displayName');
  static String get agentAgency => t('agentProfile.agency');
  static String get agentBio => t('agentProfile.bio');
  static String get agentExperience => t('agentProfile.experience');
  static String get agentLicense => t('agentProfile.license');
  static const agentTelegram = 'Telegram';
  static const agentInstagram = 'Instagram';
  static const agentHandleHint = '@username';
  static const agentLoadError = "Profilni yuklab bo'lmadi";

  // ── KYC ───────────────────────────────────────────────────────────────────
  static String get kycIntro => t('kyc.intro');
  static String get kycPassport => t('kyc.passport');
  static String get kycDiploma => t('kyc.diploma');
  static String get kycLicense => t('kyc.license');
  static String get kycSubmit => t('kyc.submit');
  static const kycChooseFile = 'Fayl tanlash';
  static const kycSubmitError = "Hujjatlarni yuborib bo'lmadi";
  static const kycNeedPassport = 'Avval pasport nusxasini tanlang';

  /// `kyc.status.*` — yorliq, matn rangi va fon.
  static (String, Color, Color) kycStatusStyle(String status) => switch (status) {
    'approved' => (t('cabinet.reels.statusApproved'), Color(0xFF047857), Color(0xFFECFDF5)),
    'pending' => (t('kyc.status.pending'), Color(0xFFB45309), Color(0xFFFFFBEB)),
    'rejected' => (t('cabinet.reels.statusRejected'), Color(0xFFB91C1C), Color(0xFFFEF2F2)),
    _ => (t('kyc.status.none'), Color(0x993D3D3D), Color(0xFFF3F4F6)),
  };

  // ── sharhlar ──────────────────────────────────────────────────────────────
  static String get reviewReply => t('cabinet.reply');
  static String get reviewSendReply => t('reviews.sendReply');
  static String get reviewSpecialistReply => t('reviews.specialistReply');
  static String get reviewReplyPlaceholder => t('reviews.replyPlaceholder');
  static const reviewsEmpty = "Hali sharhlar yo'q";
  static const reviewsLoadError = "Sharhlarni yuklab bo'lmadi";
  static const reviewReplyError = "Javobni yuborib bo'lmadi";

  // ── daromad ───────────────────────────────────────────────────────────────
  static String get totalEarnings => t('cabinet.totalEarnings');
  static const earningsQuick = 'Tezkor:';
  static const earningsFrom = 'Dan';
  static const earningsTo = 'Gacha';
  static const earningsGrouping = 'Guruhlash';
  static const earningsChart = 'Daromad grafigi';
  static const earningsEmpty = "Bu davrda daromad yo'q";
  static const earningsLoadError = "Daromadni yuklab bo'lmadi";

  /// Tezkor davr tugmalari — kalit, yorliq va sarlavha ostidagi izoh.
  static List<(String, String, String)> get earningRanges => <(String, String, String)>[
    ('week', 'Hafta', 'Oxirgi 7 kun'),
    ('month', 'Oy', 'Oxirgi 30 kun'),
    ('quarter', '3 oy', 'Oxirgi 3 oy'),
    ('year', 'Yil', 'Oxirgi 1 yil'),
    ('all', t('cabinet.favFilter.all'), 'Barcha vaqt'),
  ];

  static List<(String, String)> get earningGranularities => <(String, String)>[
    ('day', "Kun bo'yicha"),
    ('month', "Oy bo'yicha"),
    ('year', "Yil bo'yicha"),
  ];

  static String earningsUnit(String granularity) => switch (granularity) {
    'day' => 'Kunlik',
    'year' => 'Yillik',
    _ => 'Oylik',
  };

  /// Saytdagi `formatEarningAmount` — 1.2B / 15M / 300K.
  static String earningAmount(num n) {
    if (n >= 1000000000) return '${(n / 1000000000).toStringAsFixed(1)}B';
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(0)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return '$n';
  }

  static const _monthsShort = [
    'Yan',
    'Fev',
    'Mar',
    'Apr',
    'May',
    'Iyn',
    'Iyl',
    'Avg',
    'Sen',
    'Okt',
    'Noy',
    'Dek',
  ];

  /// Saytdagi `formatEarningPeriod` — `YYYY` | `YYYY-MM` | `YYYY-MM-DD`.
  static String earningPeriod(String key) {
    final parts = key.split('-');
    if (parts.length == 1) return parts.first;
    if (parts.length == 2) {
      final month = int.tryParse(parts[1]) ?? 0;
      return month >= 1 && month <= 12 ? _monthsShort[month - 1] : key;
    }
    return '${parts[2]}/${parts[1]}';
  }

  // ── reels ─────────────────────────────────────────────────────────────────
  static String get reelsSubtitle => t('cabinet.reels.subtitle');
  static String get reelUpload => t('cabinet.reels.upload');
  static String get reelUploading => t('cabinet.reels.uploading');
  static String get reelsEmpty => t('cabinet.reels.empty');
  static String get reelsModerationNote => t('cabinet.reels.moderationNote');
  static String get reelRejectReason => t('cabinet.reels.rejectReason');
  static String get reelResubmit => t('cabinet.reels.resubmit');
  static String get reelViews => t('cabinet.views');
  static const reelTitlePrompt = 'Reel sarlavhasi:';
  static const reelTooBig = "Video 100 MB dan katta bo'lmasligi kerak";
  static const reelSent = 'Reel yuborildi. Admin tasdiqlashini kuting.';
  static const reelUploadError = "Reel yuklab bo'lmadi";
  static const reelsLoadError = "Reelslarni yuklab bo'lmadi";

  /// Moderatsiya nishonchasi — yorliq va foni.
  static (String, Color)? reelStatus(String status) => switch (status) {
    'pending' => (t('cabinet.reels.statusPending'), Color(0xFFF59E0B)),
    'approved' => (t('cabinet.reels.statusApproved'), Color(0xFF10B981)),
    'rejected' => (t('cabinet.reels.statusRejected'), Color(0xFFEF4444)),
    _ => null,
  };

  // ── portfolio ─────────────────────────────────────────────────────────────
  static String get addProject => t('cabinet.addProject');
  static String get noPortfolio => t('cabinet.noPortfolio');
  static const portfolioRemoveConfirm = "Rasmni o'chirishni xohlaysizmi?";
  static const portfolioUploadError = "Rasmlarni yuklab bo'lmadi";
  static const portfolioRemoveError = "O'chirib bo'lmadi";
  static const portfolioLoadError = "Portfolioni yuklab bo'lmadi";

  // ── buyurtmalar (dizayner/usta) ────────────────────────────────────────────
  static String get activeOrders => t('cabinet.activeOrdersTitle');
  static String get activeOrdersHint => t('cabinet.activeOrdersHint');
  static String get amountLabel => t('cabinet.amount');
  static String get soum => t('hero.currency');
  static const deadlineLabel = 'Muddat:';
  static const timeLabel = 'Vaqt:';
  static const doneLabel = 'Bajarildi:';
  static String get doneShort => t('cabinet.progress');
  static const noDeadline = 'Muddat belgilanmagan';
  static const noOrdersInCategory = "Bu kategoriyada buyurtmalar yo'q";

  /// Saralash tugmalari — yorliq, holat kaliti va faol holatdagi rangi.
  static List<(String, String, Color)> get orderFilters => <(String, String, Color)>[
    ('all', t('cabinet.favFilter.all'), Color(0xFF87885C)),
    ('pending', t('cabinet.inquiryStatus.new'), Color(0xFFF59E0B)),
    ('in_progress', t('cabinet.inquiryStatus.in_progress'), Color(0xFF87885C)),
    ('completed', t('cabinet.orderStatus.completed'), Color(0xFF10B981)),
  ];

  /// `orderProgressBarClass` — vaqt progressi chizig'ining rangi.
  static Color progressBarColor(String tone) => switch (tone) {
    'overdue' => const Color(0xFFEF4444), // bg-red-500
    'soon' => const Color(0xFFF59E0B), // bg-amber-500
    _ => const Color(0xFF0EA5E9), // bg-sky-500
  };

  // ── xabarlar ──────────────────────────────────────────────────────────────
  static String get noMessages => t('cabinet.noMessages');
  static String get noMessagesDesc => t('cabinet.noMessagesDesc');

  /// Saytdagi `formatRelativeTime` — `time.*` kalitlari bilan.
  static String relativeTime(DateTime? at) {
    if (at == null) return '';
    final diff = DateTime.now().difference(at).inSeconds;
    if (diff < 60) return t('time.now');
    if (diff < 3600) return '${diff ~/ 60} ${t('time.minAgo')}';
    if (diff < 86400) return '${diff ~/ 3600} ${t('time.hourAgo')}';
    if (diff < 7 * 86400) return '${diff ~/ 86400} ${t('time.dayAgo')}';
    final d = at.toLocal();
    return '${d.day}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  // ── profil ────────────────────────────────────────────────────────────────
  static String get basicInfo => t('cabinet.basicInfo');
  static String get fullName => t('cabinet.fullName');
  static String get phone => t('cabinet.phone');
  static String get region => t('cabinet.region');
  static String get roleFieldLabel => t('cabinet.role.label');
  static String get saveChanges => t('cabinet.saveChanges');
  static String get saving => t('cabinet.saving');
  static String get profileSaved => t('cabinet.profileSaved');
  static String get profileError => t('cabinet.profileError');
  static String get allRegions => t('cabinet.allRegions');
  static String get allDistricts => t('cabinet.allDistricts');
  static const avatarTooBig = "Fayl hajmi 5MB dan oshmasligi kerak";

  /// `getRoleColor()` — avatar o'rnidagi tekis fon.
  static Color roleColor(MarketRole role) => switch (role) {
    MarketRole.user => const Color(0xFF10B981), // emerald-500
    MarketRole.agent => const Color(0xFF3B82F6), // blue-500
    MarketRole.designer => const Color(0xFF87885C), // olive
    MarketRole.master => const Color(0xFF8B8B6B), // bronze
    MarketRole.developer => const Color(0xFFF59E0B), // amber-500
  };

  /// `getRoleBadgeColor()` — nishoncha foni.
  static Color roleBadgeBackground(MarketRole role) => switch (role) {
    MarketRole.user => const Color(0xFFD1FAE5), // emerald-100
    MarketRole.agent => const Color(0xFFDBEAFE), // blue-100
    MarketRole.designer => const Color(0x1A87885C), // olive/10
    MarketRole.master => const Color(0x1A8B8B6B), // bronze/10
    MarketRole.developer => const Color(0xFFFEF3C7), // amber-100
  };

  static Color roleBadgeForeground(MarketRole role) => switch (role) {
    MarketRole.user => const Color(0xFF047857), // emerald-700
    MarketRole.agent => const Color(0xFF1D4ED8), // blue-700
    MarketRole.designer => const Color(0xFF87885C),
    MarketRole.master => const Color(0xFF8B8B6B),
    MarketRole.developer => const Color(0xFFB45309), // amber-700
  };

  // ── sozlamalar ────────────────────────────────────────────────────────────
  static String get notifications => t('cabinet.notifications');
  static String get notificationsDesc => t('cabinet.notificationsDesc');
  static String get emailUpdates => t('cabinet.emailUpdates');
  static String get emailUpdatesDesc => t('cabinet.emailUpdatesDesc');
  static String get changePassword => t('cabinet.changePassword');
  static String get updatePassword => t('cabinet.updatePassword');
  static String get currentPassword => t('cabinet.currentPassword');
  static String get newPassword => t('cabinet.newPassword');
  static String get confirmNewPassword => t('cabinet.confirmNewPassword');
  static String get passwordChanged => t('cabinet.passwordChanged');
  static String get passwordError => t('cabinet.passwordError');

  /// `auth.errorPasswordMin` / `auth.errorPasswordMatch` — parol formasi shularni ko'rsatadi.
  static String get errorPasswordMin => t('auth.errorPasswordMin');
  static String get errorPasswordMatch => t('auth.errorPasswordMatch');
  static const currentPasswordMissing = 'Joriy parol kiritilmagan';

  /// Shablonda bu sarlavha tarjimasiz, to'g'ridan-to'g'ri yozilgan.
  static String get languageAndTheme => t('cabinet.languageTheme');
  static String get language => t('cabinet.language');
  static String get theme => t('cabinet.theme');
  static const themeLight = "☀ Yorug'";
  static const themeDark = "🌙 Qorong'u";
  static const languageUz = "O'zbekcha";

  static String get dangerZone => t('cabinet.dangerZone');
  static String get deleteAccount => t('cabinet.deleteAccount');
  static String get deleteAccountDesc => t('cabinet.deleteAccountDesc');
  static String get deleteAccountConfirm => t('cabinet.deleteAccountConfirm');

  /// `cabinet.favBadge.*` + rasm ustidagi rangi.
  static (String, Color)? favoriteBadge(String source) => switch (source) {
    'viewer-apartment' => ('3D', Color(0x99000000)),
    'new-project' => (t('cabinet.newProject'), Color(0xE687885C)),
    'rent' => (t('cabinet.dealType.rent'), Color(0xCC3B82F6)),
    'secondary' => (t('cabinet.favFilter.secondary'), Color(0xCCF59E0B)),
    'designer' => (t('cabinet.favBadge.designer'), Color(0xCCA855F7)),
    'master' => (t('cabinet.favBadge.master'), Color(0xCC14B8A6)),
    _ => null,
  };
}
