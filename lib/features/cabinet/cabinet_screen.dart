import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../shared/widgets/app_image.dart';
import '../../app/theme.dart';
import '../../core/models/market_user.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/theme_controller.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/site_icon.dart';
import '../../shared/widgets/specialist_bits.dart';
import 'cabinet_dashboard.dart';
import 'cabinet_favorites.dart';
import 'cabinet_listings.dart';
import 'cabinet_messages.dart';
import 'cabinet_my_orders.dart';
import 'cabinet_orders.dart';
import 'cabinet_portfolio.dart';
import 'cabinet_projects.dart';
import 'cabinet_reels.dart';
import 'cabinet_profile.dart';
import 'cabinet_settings.dart';
import 'cabinet_viewed.dart';
import 'cabinet_repository.dart';
import 'cabinet_texts.dart';

/// Saytning `/cabinet/:tab` sahifasi — shaxsiy kabinetning karkasi.
///
/// `cabinet.component.ts` da bu butun ekranni egallaydigan alohida makon: chapda yon panel
/// (rolga qarab o'zgaradigan menyu), o'ngda ichki yuqori panel va faol bo'lim. Telefonda yon
/// panel yashiringan va gamburger tugmasi bilan chapdan suriladi (`max-lg:-translate-x-full`) —
/// bu yerda ham shunday.
///
/// Kabinet `authGuard` ostida: kirmagan foydalanuvchi kirish sahifasiga yuboriladi.
class CabinetScreen extends StatefulWidget {
  const CabinetScreen({super.key, required this.tab});

  /// `dashboard` | `listings` | … — saytdagi `TabId` ro'yxati.
  final String tab;

  /// Saytdagi `validTabs`; noma'lum bo'lim `dashboard` ga tushadi.
  static const tabs = <String>[
    'dashboard',
    'listings',
    'favorites',
    'viewed',
    'inquiries',
    'orders',
    'portfolio',
    'projects',
    'reels',
    'services',
    'reviews',
    'earnings',
    'messages',
    'profile',
    'settings',
    'agent-profile',
    'my-orders',
    'kyc',
  ];

  @override
  State<CabinetScreen> createState() => _CabinetScreenState();
}

class _CabinetScreenState extends State<CabinetScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _repo = const CabinetRepository();

  late Future<List<RoleStat>> _stats = _repo.roleStats();

  /// Bo'limlar ochilgandagina so'raladi — saytda hammasi birdan yuklanadi, telefonda esa
  /// keraksiz so'rovlarni oldini olgan ma'qul.
  Future<List<FavoriteItem>>? _favorites;
  Future<List<ViewedItem>>? _viewed;
  Future<List<MyListing>>? _listings;
  Future<List<ClientOrder>>? _orders;
  Future<List<ChatConversation>>? _conversations;
  Future<List<ProviderOrder>>? _providerOrders;
  Future<List<String>>? _portfolio;
  Future<List<SpecialistProject>>? _projects;
  Future<List<MyReel>>? _reels;

  String get _tab => CabinetScreen.tabs.contains(widget.tab) ? widget.tab : 'dashboard';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.user;

    // `canActivate: [authGuard]` — kirmagan bo'lsa kabinet ochilmaydi.
    if (user == null) return const _SignedOutView();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.surfaceAltLight, // bg-gray-50
      drawer: Drawer(
        width: 268, // w-[268px]
        backgroundColor: Colors.white,
        child: _Sidebar(
          user: user,
          activeTab: _tab,
          onSelect: (id) {
            Navigator.of(context).pop();
            context.go('/cabinet/$id');
          },
          onLogout: _confirmLogout,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _topBar(context),
            Expanded(child: _content(context, user)),
          ],
        ),
      ),
    );
  }

  /// `h-16 … sticky top-0` ichki panel: gamburger, bo'lim nomi va mavzu tugmasi.
  Widget _topBar(BuildContext context) {
    final theme = Theme.of(context);
    final themeController = context.watch<ThemeController>();
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20), // px-5
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        children: [
          Pressable(
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surfaceAltLight,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Center(child: SiteIcon(SiteIcons.menu, size: 18, color: AppColors.dark)),
            ),
          ),
          const SizedBox(width: 12), // gap-3
          Expanded(
            child: Text(
              CabinetTexts.tabLabel(_tab),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.displaySmall?.copyWith(
                fontSize: 19, // text-[19px]
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
          ),
          Pressable(
            onTap: themeController.toggle,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceAltLight,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Center(
                child: Text(
                  themeController.isDark ? '☀️' : '🌙',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(BuildContext context, MarketUser user) {
    switch (_tab) {
      case 'dashboard':
        return CabinetDashboard(
          user: user,
          stats: _stats,
          onOpenTab: (id) => context.go('/cabinet/$id'),
          onRetry: () => setState(() => _stats = _repo.roleStats()),
        );
      case 'favorites':
        return CabinetFavorites(
          future: _favorites ??= _repo.favorites(),
          onRetry: () => setState(() => _favorites = _repo.favorites()),
        );
      case 'viewed':
        return CabinetViewed(future: _viewed ??= _repo.viewed());
      case 'my-orders':
        return CabinetMyOrders(future: _orders ??= _repo.myOrders());
      case 'listings':
        return CabinetListings(
          future: _listings ??= _repo.myListings(),
          canCreate: user.role == MarketRole.user || user.role == MarketRole.agent,
          onDelete: (listing) async {
            final messenger = ScaffoldMessenger.of(context);
            try {
              await _repo.deleteListing(listing);
              setState(() => _listings = _repo.myListings());
            } catch (_) {
              messenger.showSnackBar(const SnackBar(content: Text("E'lonni o'chirib bo'lmadi")));
            }
          },
        );
      case 'orders':
        return CabinetOrders(
          future: _providerOrders ??= _repo.providerOrders(),
          onOpen: (order) => context.go('/cabinet/orders/${order.id}'),
          onRetry: () => setState(() => _providerOrders = _repo.providerOrders()),
        );
      case 'portfolio':
        return CabinetPortfolio(
          future: _portfolio ??= _repo.portfolio(),
          onRetry: () => setState(() => _portfolio = _repo.portfolio()),
        );
      case 'projects':
        return CabinetProjects(
          future: _projects ??= _repo.myProjects(),
          onChanged: () => setState(() => _projects = _repo.myProjects()),
        );
      case 'reels':
        return CabinetReels(
          future: _reels ??= _repo.myReels(),
          role: user.role,
          onChanged: () => setState(() => _reels = _repo.myReels()),
        );
      case 'messages':
        return CabinetMessages(
          future: _conversations ??= _repo.conversations(),
          onOpen: (conv) => context.go('/chat/${conv.id}'),
          onRetry: () => setState(() => _conversations = _repo.conversations()),
        );
      case 'profile':
        return CabinetProfile(user: user);
      case 'settings':
        return CabinetSettings(onDeleted: () => context.go('/'));
      default:
        return _NotPortedYet(tab: _tab);
    }
  }

  Future<void> _confirmLogout() async {
    final auth = context.read<AuthService>();
    final router = GoRouter.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(CabinetTexts.logout),
        content: const Text('Hisobingizdan chiqmoqchimisiz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(CabinetTexts.logout),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await auth.logout();
    router.go('/');
  }
}

/// Yon panel — rol banneri, "Marketplace" havolasi, menyu va chiqish tugmasi.
class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.user,
    required this.activeTab,
    required this.onSelect,
    required this.onLogout,
  });

  final MarketUser user;
  final String activeTab;
  final ValueChanged<String> onSelect;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _banner(context),
        // "Marketplace" — bosh sahifaga qaytish.
        InkWell(
          onTap: () => context.go('/'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.borderLight)),
            ),
            child: Row(
              children: [
                SiteIcon(
                  SiteIcons.arrowLeft,
                  size: 14,
                  strokeWidth: 2.5,
                  color: AppColors.dark.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 8),
                Text(
                  CabinetTexts.marketplace,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12), // p-3
            children: [
              for (final id in sidebarTabsFor(user.role)) ...[
                _item(context, id),
                const SizedBox(height: 3), // space-y-[3px]
              ],
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.borderLight)),
          ),
          child: InkWell(
            onTap: onLogout,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const SiteIcon(SiteIcons.logout, size: 16, color: Color(0xFFDC2626)),
                  const SizedBox(width: 10),
                  Text(
                    CabinetTexts.logout,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _item(BuildContext context, String id) {
    final theme = Theme.of(context);
    final active = id == activeTab;
    return InkWell(
      onTap: () => onSelect(id),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.olive : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md), // rounded-xl
        ),
        child: Row(
          children: [
            SiteIcon(
              _tabIcon(id),
              size: 18,
              color: active ? Colors.white : AppColors.dark.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 10), // gap-2.5
            Expanded(
              child: Text(
                CabinetTexts.tabLabel(id),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : AppColors.dark.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Rol banneri: gradient, nuqtali naqsh, suv belgisi, avatar va rol nishonchasi.
  Widget _banner(BuildContext context) {
    final theme = Theme.of(context);
    // Yon panel Drawer sifatida ochiladi va status paneli ostidan boshlanadi — banner o'sha
    // balandlikka cho'ziladi, matni esa pastroqdan boshlanadi.
    final safeTop = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: 92 + safeTop,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(decoration: BoxDecoration(gradient: roleGradient(user.role))),
          // `opacity-[0.16]`, 15×15 nuqtalar.
          const CustomPaint(painter: DotPatternPainter(step: 15, alpha: 0.16)),
          Positioned(
            right: 10,
            bottom: -14,
            child: SiteIcon(
              roleWatermark(user.role),
              size: 92,
              strokeWidth: 1.3,
              color: Colors.white.withValues(alpha: 0.13),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(18, 20 + safeTop, 18, 20), // padding: 20px 18px
            child: Row(
              children: [
                SizedBox(
                  width: 50,
                  height: 50,
                  child: ClipOval(
                    child: user.avatar != null && user.avatar!.isNotEmpty
                        ? AppImage(imageUrl: user.avatar!, fit: BoxFit.cover)
                        : ColoredBox(
                            color: Colors.white.withValues(alpha: 0.9),
                            child: Center(
                              child: Text(
                                // Saytda kabinet avatarida **bitta** harf.
                                user.fullName.isEmpty ? 'U' : user.fullName[0].toUpperCase(),
                                style: theme.textTheme.displaySmall?.copyWith(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.olive,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12), // gap-3
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        user.fullName.isEmpty ? CabinetTexts.unknownUser : user.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          CabinetTexts.roleLabel(user.role).toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Rolga qarab menyu — saytdagi `sidebarItems()` ning aynan tartibi.
List<String> sidebarTabsFor(MarketRole role) {
  final items = <String>['dashboard'];
  // `canCreateListing()` — "Mulk e'lonlari faqat user/agent uchun".
  if (role == MarketRole.user || role == MarketRole.agent) {
    items.add('listings');
  }

  if (role == MarketRole.agent) {
    items.addAll(['inquiries', 'earnings']);
  } else if (role == MarketRole.designer || role == MarketRole.master) {
    items.addAll([
      'orders',
      'portfolio',
      'projects',
      'reels',
      'services',
      'reviews',
      'earnings',
      'kyc',
    ]);
  } else {
    items.addAll(['favorites', 'viewed', 'my-orders']);
  }

  if (role == MarketRole.agent) {
    items.addAll(['agent-profile', 'kyc']);
  }

  items.addAll(['messages', 'profile', 'settings']);
  return items;
}

SiteIconData _tabIcon(String id) => switch (id) {
  'dashboard' => SiteIcons.dashboard,
  'favorites' => SiteIcons.heart,
  'viewed' => SiteIcons.clock,
  'inquiries' || 'messages' => SiteIcons.message,
  'portfolio' => SiteIcons.image,
  'projects' => SiteIcons.briefcase,
  'reels' => SiteIcons.reel,
  'reviews' => SiteIcons.ratingStar,
  'earnings' => SiteIcons.wallet,
  'profile' || 'agent-profile' => SiteIcons.user,
  'settings' => SiteIcons.settings,
  'kyc' => SiteIcons.shield,
  _ => SiteIcons.list,
};

SiteIconData roleWatermark(MarketRole role) => switch (role) {
  MarketRole.master => SiteIcons.wrench,
  MarketRole.designer => SiteIcons.paletteOutline,
  _ => SiteIcons.house,
};

/// `getRoleGradient()` — har bir rol uchun o'ziga xos gradient.
LinearGradient roleGradient(MarketRole role) {
  const bronze = AppColors.bronze;
  final colors = switch (role) {
    MarketRole.designer => [AppColors.olive, AppColors.olive.withValues(alpha: 0.85), bronze],
    MarketRole.master => [bronze, bronze.withValues(alpha: 0.9), AppColors.dark],
    MarketRole.agent => [
      const Color(0xFF3B82F6),
      const Color(0xFF3B82F6).withValues(alpha: 0.85),
      const Color(0xFF334155),
    ],
    MarketRole.developer => [
      const Color(0xFFF59E0B),
      const Color(0xFFF59E0B).withValues(alpha: 0.85),
      bronze,
    ],
    MarketRole.user => [
      AppColors.olive.withValues(alpha: 0.8),
      AppColors.olive.withValues(alpha: 0.6),
      AppColors.dark.withValues(alpha: 0.7),
    ],
  };
  return LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors);
}

/// Kirmagan holat — saytda `authGuard` kirish sahifasiga yuboradi.
class _SignedOutView extends StatelessWidget {
  const _SignedOutView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Kabinet')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SiteIcon(SiteIcons.user, size: 40, color: AppColors.dark.withValues(alpha: 0.2)),
              const SizedBox(height: 16),
              Text(
                'Kabinetga kirish uchun hisobingizga kiring',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(color: AppColors.dark),
              ),
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.olive),
                onPressed: () => context.push('/login'),
                child: const Text('Kirish'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hali ko'chirilmagan bo'lim — nima yetishmayotgani ochiq aytiladi.
class _NotPortedYet extends StatelessWidget {
  const _NotPortedYet({required this.tab});

  final String tab;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              CabinetTexts.tabLabel(tab),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Bu bo'lim keyingi bosqichda ko'chiriladi.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.dark.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
