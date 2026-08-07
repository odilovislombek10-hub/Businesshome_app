import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/constants/city_labels.dart';
import '../../core/models/brief.dart';
import '../../core/models/market_user.dart';
import '../../core/models/region.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/regions_service.dart';
import '../../core/utils/format.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/site_header.dart';
import '../../shared/widgets/site_icon.dart';
import '../../shared/widgets/specialist_bits.dart';
import 'birja_create_sheet.dart';
import 'birja_filter_sheet.dart';
import 'birja_repository.dart';
import 'birja_texts.dart';

/// Saytning `/birja` sahifasi — mijoz buyurtmalari taxtasi.
///
/// `birja.component.ts` ning mobil ko'rinishi: ustalar sahifasidagi terrakota hero (ikkita
/// statistika tabletkasi bilan), buyurtmalar soni + "Filterlar", "Yangi buyurtma" tugmasi va
/// buyurtma kartalari. Kartani bosish tafsilot oynasini ochadi; dizayner/usta rolidagi
/// foydalanuvchi javob yozib, ochilgan suhbatga o'tadi.
///
/// Yon panel boshqa ro'yxat sahifalaridagi kabi pastki oynaga olindi — [BirjaFilterSheet].
class BirjaScreen extends StatefulWidget {
  const BirjaScreen({super.key});

  @override
  State<BirjaScreen> createState() => _BirjaScreenState();
}

class _BirjaScreenState extends State<BirjaScreen> {
  final _repo = const BirjaRepository();
  final _scroll = ScrollController();

  BriefFilter _filter = const BriefFilter();
  late Future<List<Brief>> _future = _load(_filter);

  List<Brief>? _last;
  List<Region> _regions = const [];
  bool _scrolled = false;

  Future<List<Brief>> _load(BriefFilter filter) =>
      _repo.list(filter).then((items) => _last = items);

  @override
  void initState() {
    super.initState();
    RegionsService.instance.regions().then((regions) {
      if (mounted) setState(() => _regions = regions);
    });
    _scroll.addListener(() {
      final scrolled = _scroll.offset > 10;
      if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _apply(BriefFilter next) {
    setState(() {
      _filter = next;
      _future = _load(_filter);
    });
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<BriefFilter>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BirjaFilterSheet(filter: _filter, regions: _regions),
    );
    if (result != null) _apply(result);
  }

  /// Saytdagi `canRespond`: faqat buyurtma mo'ljallangan roldagi, muallif bo'lmagan foydalanuvchi.
  bool _canRespond(Brief brief) {
    final user = context.read<AuthService>().user;
    if (user == null || user.id == brief.authorId) return false;
    return (brief.target == 'designer' && user.role == MarketRole.designer) ||
        (brief.target == 'master' && user.role == MarketRole.master);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream, // bg-[#FAF9F6]
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scroll,
            slivers: [
              SliverToBoxAdapter(child: _hero(context)),
              SliverToBoxAdapter(child: _toolbar(context)),
              SliverToBoxAdapter(child: _results(context)),
              const SliverToBoxAdapter(child: SizedBox(height: 64)), // pb-16
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SiteHeader(scrolled: _scrolled, showSearch: false),
          ),
        ],
      ),
    );
  }

  // ── hero ──────────────────────────────────────────────────────────────────

  Widget _hero(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 76 + MediaQuery.paddingOf(context).top, 16, 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26), // rounded-[26px]
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  // Ustalar sahifasi bilan bir xil terrakota gradienti.
                  gradient: LinearGradient(
                    begin: Alignment(-0.87, -0.5),
                    end: Alignment(0.87, 0.5),
                    colors: [Color(0xFFB5764C), Color(0xFF9A5E3C), Color(0xFF5C4636)],
                    stops: [0, 0.55, 1],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.72, -0.64),
                    radius: 0.9,
                    colors: [Colors.white.withValues(alpha: 0.12), Colors.transparent],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.84, 0.84),
                    radius: 1,
                    colors: [Colors.black.withValues(alpha: 0.10), Colors.transparent],
                  ),
                ),
              ),
            ),
            Positioned.fill(child: CustomPaint(painter: const DotPatternPainter())),
            Positioned(
              right: -6,
              bottom: -34,
              child: SiteIcon(
                SiteIcons.wrench,
                size: 210,
                strokeWidth: 1.2,
                color: Colors.white.withValues(alpha: 0.09),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28), // saytda 40px; telefon kengligiga moslandi
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      BirjaTexts.heroBadge,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16), // mb-4
                  Text(
                    BirjaTexts.heroTitle,
                    style: theme.textTheme.displaySmall?.copyWith(
                      // `text-[50px]` telefonga sig'maydi — boshqa sahifalardagidek 30.
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      height: 1.02,
                      letterSpacing: -0.5,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12), // mb-3
                  Text(
                    BirjaTexts.heroDesc,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 15, // `text-[17px]` telefonda 15
                      height: 1.6,
                      color: Colors.white.withValues(alpha: 0.88),
                    ),
                  ),
                  const SizedBox(height: 22), // mb-[22px]
                  _statPills(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statPills(BuildContext context) {
    final theme = Theme.of(context);
    Widget pill(String value, String label) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );

    return FutureBuilder<List<Brief>>(
      future: _future,
      builder: (context, snapshot) {
        // Saytda ikkalasi ham kelgan ro'yxatdan sanaladi, `total` maydonidan emas.
        final items = snapshot.data ?? _last ?? const <Brief>[];
        return Wrap(
          spacing: 10, // gap-2.5
          runSpacing: 10,
          children: [
            pill('${items.length}', BirjaTexts.orders),
            pill('${items.where((b) => b.isOpen).length}', BirjaTexts.active),
          ],
        );
      },
    );
  }

  // ── sanoq + filtr + yangi buyurtma ────────────────────────────────────────

  Widget _toolbar(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthService>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: FutureBuilder<List<Brief>>(
                  future: _future,
                  builder: (context, snapshot) {
                    final items = snapshot.data ?? _last ?? const <Brief>[];
                    return Text(
                      '${items.length} ${BirjaTexts.ordersCount}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dark.withValues(alpha: 0.4),
                      ),
                    );
                  },
                ),
              ),
              Pressable(
                scale: 0.98,
                onTap: _openFilters,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: const Color(0xFFE7E3D8)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SiteIcon(SiteIcons.filters, size: 16, color: AppColors.dark),
                          const SizedBox(width: 6),
                          Text(
                            BirjaTexts.filters,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.dark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_filter.hasActive)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.olive,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Kirgan bo'lsa buyurtma joylash, aks holda kirish sahifasiga.
          Pressable(
            scale: 0.98,
            onTap: auth.isLoggedIn ? _openCreate : () => context.push('/login'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12), // py-3
              decoration: BoxDecoration(
                color: AppColors.olive,
                borderRadius: BorderRadius.circular(13), // rounded-[13px]
              ),
              child: Text(
                auth.isLoggedIn ? '+ ${BirjaTexts.newOrder}' : BirjaTexts.loginToPost,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Yangi buyurtma formasi — yopilganda tayyor tana qaytadi va darrov joylanadi.
  Future<void> _openCreate() async {
    final body = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BirjaCreateSheet(regions: _regions),
    );
    if (body == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repo.create(body);
      // Saytda ham joylangach ro'yxat qayta yuklanadi.
      _apply(_filter);
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text("Buyurtmani saqlab bo'lmadi")));
    }
  }

  // ── ro'yxat ───────────────────────────────────────────────────────────────

  Widget _results(BuildContext context) {
    return FutureBuilder<List<Brief>>(
      future: _future,
      builder: (context, snapshot) {
        final items = snapshot.data ?? _last;
        if (items == null) {
          if (snapshot.connectionState == ConnectionState.waiting) return _skeletons(context);
          return _empty(context);
        }
        if (items.isEmpty) return _empty(context);

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 18, // gap-[18px]
              crossAxisSpacing: 18,
              mainAxisExtent: _BriefCard.extent,
            ),
            itemCount: items.length,
            itemBuilder: (context, i) => Entrance.fadeIn(
              delay: Duration(milliseconds: i * 100),
              child: _BriefCard(
                brief: items[i],
                canRespond: _canRespond(items[i]),
                onOpen: () => _openDetail(items[i]),
                onRespond: () => _openRespond(items[i]),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Saytdagi `animate-pulse` skeletlari — to'rtta bo'sh karta.
  Widget _skeletons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: GridView.count(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 18,
        crossAxisSpacing: 18,
        childAspectRatio: 172 / _BriefCard.extent,
        children: [
          for (var i = 0; i < 4; i++)
            Pulse(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20), // rounded-[20px]
                  border: Border.all(color: const Color(0xFFE7E3D8)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _empty(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24), // py-16
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24), // rounded-[24px]
          border: Border.all(color: const Color(0xFFE7E3D8)),
        ),
        child: Column(
          children: [
            const Text('📋', style: TextStyle(fontSize: 42)),
            const SizedBox(height: 16), // mb-2 + gap-2
            Text(
              BirjaTexts.noOrders,
              textAlign: TextAlign.center,
              style: theme.textTheme.displaySmall?.copyWith(
                fontSize: 23, // text-[23px]
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              BirjaTexts.noOrdersDesc,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 15,
                height: 1.5,
                color: AppColors.dark.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── tafsilot va javob oynalari ────────────────────────────────────────────

  void _openDetail(Brief brief) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _BriefDetailSheet(
        brief: brief,
        canRespond: _canRespond(brief),
        onRespond: () {
          Navigator.of(context).pop();
          _openRespond(brief);
        },
      ),
    );
  }

  Future<void> _openRespond(Brief brief) async {
    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _RespondSheet(brief: brief),
    );
    if (message == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      final conversationId = await _repo.respond(brief.id, message);
      if (conversationId != null) {
        router.push('/chat/$conversationId');
      }
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text("Yuborib bo'lmadi")));
    }
  }
}

/// Bitta buyurtma kartasi.
///
/// Shablondagi tartib: nishoncha va ko'rish/javob sanog'i, sarlavha, tavsif, rasm tasmasi,
/// obyekt turi · shahar · maydon qatori, byudjet va "Yozish" tugmasi.
class _BriefCard extends StatelessWidget {
  const _BriefCard({
    required this.brief,
    required this.canRespond,
    required this.onOpen,
    required this.onRespond,
  });

  /// Ikki ustunli to'rda bitta katakning balandligi.
  static const extent = 268.0;

  final Brief brief;
  final bool canRespond;
  final VoidCallback onOpen;
  final VoidCallback onRespond;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Pressable(
      scale: 0.99,
      onTap: onOpen,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20), // rounded-[20px]
          border: Border.all(color: const Color(0xFFE7E3D8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Yuqori blok — pastida chegara.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE7E3D8))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECEDDF),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          BirjaTexts.targetLabel(brief.target).toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF62633C),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '👁 ${brief.viewsCount} · 💬 ${brief.responsesCount}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 9.5,
                          color: AppColors.dark.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8), // mb-2
                  Text(
                    brief.title,
                    maxLines: 2, // line-clamp-2
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontSize: 13.5, // text-[18px] → yarim kenglikda 13.5
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                    ),
                  ),
                  if (brief.description.isNotEmpty) ...[
                    const SizedBox(height: 4), // mt-1.5
                    Text(
                      brief.description,
                      maxLines: 2, // line-clamp-2
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                        height: 1.3,
                        color: AppColors.dark.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            if (brief.images.isNotEmpty) _images(context),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _infoLine(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: AppColors.dark.withValues(alpha: 0.5),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      BirjaTexts.budget.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.63, // tracking-[0.06em]
                        color: AppColors.dark.withValues(alpha: 0.4),
                      ),
                    ),
                    Text(
                      formatBudget(brief),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.dark,
                      ),
                    ),
                    if (canRespond) ...[
                      const SizedBox(height: 6),
                      Pressable(
                        onTap: onRespond,
                        child: Container(
                          width: double.infinity,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.olive,
                            borderRadius: BorderRadius.circular(10), // rounded-[10px]
                          ),
                          child: Text(
                            BirjaTexts.respond,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// `obyekt turi · shahar · maydon` — bo'sh maydonlar tushib qoladi.
  String _infoLine() => [
    if (brief.projectType != null) BirjaTexts.typeLabel(brief.projectType),
    if (brief.city != null) CityLabels.label(brief.city),
    if (brief.areaM2 != null) '${formatNumber(brief.areaM2)} m²',
  ].join(' · ');

  Widget _images(BuildContext context) {
    final theme = Theme.of(context);
    // Shablonda 120px; yarim kenglikda 60px yetadi. Uchtadan ko'pi "+N" bo'lib qoladi.
    final shown = brief.images.take(3).toList();
    final extra = brief.images.length - shown.length;
    return Container(
      height: 60,
      color: const Color(0xFFF5F3EC),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          for (final (i, image) in shown.indexed) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: CachedNetworkImage(
                  imageUrl: image,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => const ColoredBox(color: Color(0xFFE7E3D8)),
                  errorWidget: (_, _, _) => const ColoredBox(color: Color(0xFFE7E3D8)),
                ),
              ),
            ),
          ],
          if (extra > 0) ...[
            const SizedBox(width: 4),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFE7E3D8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    '+$extra',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Saytdagi `formatBudget` — millionlar "mln", qolgani "K" bilan qisqartiriladi.
String formatBudget(Brief brief) {
  final currency = brief.currency.toUpperCase() == 'USD' ? '\$' : "so'm";
  String short(int n) =>
      n >= 1000000 ? '${(n / 1000000).toStringAsFixed(1)} mln' : '${(n / 1000).round()} K';

  final from = brief.budgetFrom;
  final to = brief.budgetTo;
  if (from != null && from > 0 && to != null && to > 0) {
    return '${short(from)} - ${short(to)} $currency';
  }
  if (from != null && from > 0) return '${short(from)}+ $currency';
  if (to != null && to > 0) return '${short(to)} $currency gacha';
  return BirjaTexts.negotiable;
}

/// Buyurtma tafsiloti — saytdagi detail modalning ko'chirmasi.
class _BriefDetailSheet extends StatelessWidget {
  const _BriefDetailSheet({required this.brief, required this.canRespond, required this.onRespond});

  final Brief brief;
  final bool canRespond;
  final VoidCallback onRespond;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.92,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.borderLight)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '📋 ${brief.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Pressable(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.dark.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Center(
                      child: SiteIcon(SiteIcons.close, size: 16, color: AppColors.dark),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20), // p-5
              children: [
                _author(context),
                if (brief.images.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _label(theme, BirjaTexts.images),
                  const SizedBox(height: 8),
                  GridView.count(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2, // `grid-cols-2` mobilda
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    children: [
                      for (final image in brief.images)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: CachedNetworkImage(imageUrl: image, fit: BoxFit.cover),
                        ),
                    ],
                  ),
                ],
                if (brief.description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _label(theme, BirjaTexts.details),
                  const SizedBox(height: 8),
                  Text(
                    brief.description,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.6, color: AppColors.dark),
                  ),
                ],
                const SizedBox(height: 16),
                _facts(context),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.borderLight),
                const SizedBox(height: 8),
                Text(
                  '👁 ${brief.viewsCount} ${BirjaTexts.viewed}   💬 ${brief.responsesCount} ${BirjaTexts.responses}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 12,
                    color: AppColors.dark.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),

          if (canRespond)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.olive),
                    onPressed: onRespond,
                    child: const Text('✍ ${BirjaTexts.respondLong}'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _label(ThemeData theme, String text) => Text(
    text.toUpperCase(),
    style: theme.textTheme.labelSmall?.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppColors.dark.withValues(alpha: 0.5),
    ),
  );

  Widget _author(BuildContext context) {
    final theme = Theme.of(context);
    final name = brief.authorName ?? BirjaTexts.unknownAuthor;
    return Row(
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: ClipOval(
            child: brief.authorAvatar != null
                ? CachedNetworkImage(imageUrl: brief.authorAvatar!, fit: BoxFit.cover)
                : DecoratedBox(
                    decoration: BoxDecoration(gradient: avatarGradient(name)),
                    child: Center(
                      child: Text(
                        initialsOf(name),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark,
                ),
              ),
              if (brief.createdAt case final created?)
                Text(
                  _formatDate(created),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    color: AppColors.dark.withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.olive.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            BirjaTexts.targetLabel(brief.target),
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.olive,
            ),
          ),
        ),
      ],
    );
  }

  Widget _facts(BuildContext context) {
    final theme = Theme.of(context);

    Widget box(String label, String value, {bool accent = false}) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent ? AppColors.olive.withValues(alpha: 0.1) : AppColors.surfaceAltLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: accent ? AppColors.olive : AppColors.dark.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: accent
                ? theme.textTheme.titleLarge?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.olive,
                  )
                : theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
          ),
        ],
      ),
    );

    final cells = <Widget>[
      if (brief.projectType != null)
        box(BirjaTexts.propertyType, BirjaTexts.typeLabel(brief.projectType)),
      if (brief.city != null)
        box(
          BirjaTexts.location,
          brief.district == null
              ? CityLabels.label(brief.city)
              : '${CityLabels.label(brief.city)}, ${brief.district}',
        ),
      if (brief.areaM2 != null) box(BirjaTexts.area, '${formatNumber(brief.areaM2)} m²'),
      if (brief.deadline != null) box(BirjaTexts.deadline, brief.deadline!),
    ];

    return Column(
      children: [
        for (var i = 0; i < cells.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 12),
          // `stretch` ishlatib bo'lmaydi: ListView bolalariga cheksiz balandlik beradi va
          // qator o'zini o'lchay olmay, butun ro'yxat chizilmay qoladi.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: cells[i]),
                const SizedBox(width: 12),
                if (i + 1 < cells.length) Expanded(child: cells[i + 1]) else const Spacer(),
              ],
            ),
          ),
        ],
        if (cells.isNotEmpty) const SizedBox(height: 12),
        // Narx — shablonda `col-span-2`, ya'ni butun kenglikda.
        SizedBox(
          width: double.infinity,
          child: box(BirjaTexts.price, formatBudget(brief), accent: true),
        ),
      ],
    );
  }
}

String _formatDate(DateTime value) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(value.day)}.${two(value.month)}.${value.year} ${two(value.hour)}:${two(value.minute)}';
}

/// Javob yozish oynasi. Matn qaytariladi; yuborishni ekranning o'zi bajaradi.
class _RespondSheet extends StatefulWidget {
  const _RespondSheet({required this.brief});

  final Brief brief;

  @override
  State<_RespondSheet> createState() => _RespondSheetState();
}

class _RespondSheetState extends State<_RespondSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Padding(
        padding: const EdgeInsets.all(24), // p-6
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              BirjaTexts.respondTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '"${widget.brief.title}"',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 12,
                color: AppColors.dark.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16), // mb-4
            TextField(
              controller: _controller,
              maxLines: 5,
              onChanged: (_) => setState(() {}),
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.dark),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surfaceAltLight,
                hintText: BirjaTexts.respondPlaceholder,
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.dark.withValues(alpha: 0.4),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: AppColors.olive),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(BirjaTexts.cancel),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.olive),
                    onPressed: _controller.text.trim().isEmpty
                        ? null
                        : () => Navigator.of(context).pop(_controller.text.trim()),
                    child: const Text(BirjaTexts.send),
                  ),
                ),
              ],
            ),
            SafeArea(top: false, child: const SizedBox(height: 8)),
          ],
        ),
      ),
    );
  }
}
