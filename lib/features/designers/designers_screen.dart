import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../core/constants/city_labels.dart';
import '../../core/models/designer.dart';
import '../../core/models/property_listing.dart';
import '../../core/utils/format.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/site_header.dart';
import '../../shared/widgets/site_icon.dart';
import '../../shared/widgets/specialist_bits.dart';
import 'designers_filter_sheet.dart';
import 'designers_repository.dart';
import 'designers_texts.dart';

/// Saytning `/designers` sahifasi — "Dizaynerlar bozori".
///
/// `designers.component.ts` ning mobil ko'rinishi: olive→bronza gradientli hero banner (qidiruv
/// kartasi va uchta statistika tabletkasi ichida), keyin `bg-gray-50` tanada filtr chiplari va
/// saralash, undan so'ng dizayner kartalari.
///
/// Filtr paneli shablonda `aside` — mobilda kartalar ustida doim ochiq turadi. Ilovada u
/// ijara/ikkilamchidagi kabi qidiruv kartasidagi "Filterlar" tugmasi bilan ochiladigan pastki
/// oynaga olindi ([DesignersFilterSheet]): doim ochiq panel telefon ekranining yarmini egallab,
/// e'lonlarni pastga surib yuborardi.
class DesignersScreen extends StatefulWidget {
  const DesignersScreen({super.key});

  @override
  State<DesignersScreen> createState() => _DesignersScreenState();
}

class _DesignersScreenState extends State<DesignersScreen> {
  final _repo = const DesignersRepository();
  final _searchController = TextEditingController();
  final _scroll = ScrollController();

  DesignerFilter _filter = const DesignerFilter();
  late Future<Paginated<Designer>> _future = _load(_filter);

  /// Oxirgi muvaffaqiyatli javob. Saytda ro'yxat yangi so'rov ketayotganda ham ekranda turadi —
  /// shablonda umuman spinner yo'q, `loading()` faqat "topilmadi" blokini bosib turadi. Shu
  /// xatti-harakat saqlanishi uchun eski sahifa yangisi kelguncha ko'rsatiladi.
  Paginated<Designer>? _last;

  Future<Paginated<Designer>> _load(DesignerFilter filter) =>
      _repo.list(filter).then((page) => _last = page);

  /// Saytda bu `FavoritesService` orqali saqlanadi; ilovada hali sevimlilar xizmati yo'q, shuning
  /// uchun tugma faqat shu sahifa ichida holatini eslab qoladi.
  final _favorites = <int>{};

  Timer? _debounce;
  bool _scrolled = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final scrolled = _scroll.offset > 10;
      if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Saytdagidek: filtr o'zgarsa sahifa 1 ga qaytadi.
  void _apply(DesignerFilter next, {bool keepPage = false}) {
    setState(() {
      _filter = keepPage ? next : next.copyWith(page: 1);
      _future = _load(_filter);
    });
  }

  void _onSearch(String value) {
    // Sayt yozgan sari qidiradi; har bosishga so'rov ketmasin.
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _apply(_filter.copyWith(search: value));
    });
  }

  void _toggleSpec(String value) {
    final next = [..._filter.specializations];
    if (!next.remove(value)) next.add(value);
    _apply(_filter.copyWith(specializations: next));
  }

  void _reset() {
    _searchController.clear();
    _apply(const DesignerFilter());
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<DesignerFilter>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DesignersFilterSheet(filter: _filter),
    );
    if (result != null) _apply(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAltLight, // bg-gray-50
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
            // Shablonda `[transparent]="false"` — panel boshidanoq to'q.
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
      // `pt-32` + `py-5`, ustidagi qat'iy header uchun status paneli qo'shiladi.
      padding: EdgeInsets.fromLTRB(16, 76 + MediaQuery.paddingOf(context).top, 16, 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26), // rounded-[26px]
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  // linear-gradient(120deg,#8C8D60 0%,#777851 50%,#9A6E4F 100%)
                  gradient: LinearGradient(
                    begin: Alignment(-0.87, -0.5),
                    end: Alignment(0.87, 0.5),
                    colors: [Color(0xFF8C8D60), Color(0xFF777851), Color(0xFF9A6E4F)],
                    stops: [0, 0.5, 1],
                  ),
                ),
              ),
            ),
            // O'ng yuqoridagi yorug'lik dog'i — `radial-gradient(circle at 86% 18%, …)`.
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
            // Chap pastdagi soya — `radial-gradient(circle at 8% 92%, rgba(0,0,0,0.10), …)`.
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
            // 18×18 nuqtali naqsh, opacity-50.
            Positioned.fill(child: CustomPaint(painter: const DotPatternPainter())),
            // `-right-1 -bottom-8` dagi w-48 h-48 palitra suv belgisi, `text-white/[0.09]`.
            Positioned(
              right: -4,
              bottom: -32,
              child: SizedBox.square(
                dimension: 192,
                child: Stack(
                  children: [
                    SiteIcon(
                      SiteIcons.paletteOutline,
                      size: 192,
                      strokeWidth: 1.2,
                      color: Colors.white.withValues(alpha: 0.09),
                    ),
                    SiteIcon(
                      SiteIcons.paletteDots,
                      size: 192,
                      color: Colors.white.withValues(alpha: 0.09),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28), // p-7
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
                      DesignersTexts.heroBadge,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2, // tracking-wider
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16), // mb-4
                  Text(
                    DesignersTexts.heroTitle,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontSize: 30, // text-3xl
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                      letterSpacing: -0.5,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12), // mb-3
                  Text(
                    DesignersTexts.heroDesc,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 15,
                      height: 1.6, // leading-relaxed
                      color: Colors.white.withValues(alpha: 0.88),
                    ),
                  ),
                  const SizedBox(height: 20), // mb-5
                  _searchCard(context),
                  const SizedBox(height: 20), // mt-5
                  _statPills(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchCard(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(8), // p-2
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg), // rounded-2xl
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 50,
            offset: const Offset(0, 25),
          ),
        ],
      ),
      // Mobilda `flex-col gap-2` — maydonlar ustma-ust.
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 8),
              SiteIcon(SiteIcons.search, size: 20, color: AppColors.dark.withValues(alpha: 0.3)),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearch,
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15, color: AppColors.dark),
                  decoration: InputDecoration(
                    isDense: true,
                    // Saytda maydon `bg-transparent … focus:outline-none` — ilova mavzusi
                    // qo'yadigan ramka va foni bu yerda ataylab o'chiriladi.
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14), // py-3.5
                    hintText: DesignersTexts.searchPlaceholder,
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 15,
                      color: AppColors.dark.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
              // Ijara/ikkilamchidagi kabi — filtr tugmasi qidiruv maydonining o'ng yonida.
              Pressable(
                scale: 0.98,
                onTap: _openFilters,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAltLight,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SiteIcon(SiteIcons.filters, size: 16, color: AppColors.dark),
                          const SizedBox(width: 6),
                          Text(
                            DesignersTexts.filters,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.dark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Biror filtr tanlangan bo'lsa — olive nuqta.
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
          const SizedBox(height: 8), // gap-2
          _citySelect(context),
          const SizedBox(height: 8),
          // Ro'yxat yozgan sari yangilanadi, shuning uchun tugma faqat fokusni yopadi —
          // saytda ham u alohida so'rov yubormaydi.
          Pressable(
            scale: 0.98, // active:scale-[0.98]
            onTap: () => FocusScope.of(context).unfocus(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14), // py-3.5
              decoration: BoxDecoration(
                color: AppColors.olive,
                borderRadius: BorderRadius.circular(AppRadius.md), // rounded-xl
              ),
              child: Text(
                DesignersTexts.searchBtn,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _citySelect(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16), // px-4
      decoration: BoxDecoration(
        color: AppColors.surfaceAltLight, // bg-gray-50
        borderRadius: BorderRadius.circular(AppRadius.md), // rounded-xl
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _filter.city.isEmpty ? '' : _filter.city,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(vertical: 6),
          icon: const SiteIcon(SiteIcons.chevronDown, size: 16),
          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14, color: AppColors.dark),
          items: [
            const DropdownMenuItem(value: '', child: Text(DesignersTexts.allCities)),
            for (final (value, label) in CityLabels.options)
              DropdownMenuItem(value: value, child: Text(label)),
          ],
          onChanged: (value) => _apply(_filter.copyWith(city: value ?? '')),
        ),
      ),
    );
  }

  Widget _statPills(BuildContext context) {
    final theme = Theme.of(context);
    Widget pill(String value, String label) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), // px-3.5 py-2
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
          const SizedBox(width: 8), // gap-2
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

    return FutureBuilder<Paginated<Designer>>(
      future: _future,
      builder: (context, snapshot) => Wrap(
        spacing: 10, // gap-2.5
        runSpacing: 10,
        children: [
          pill('${snapshot.data?.total ?? _last?.total ?? 0}', DesignersTexts.specialists),
          // 4.8 va 96% shablonda qattiq yozilgan — API'dan kelmaydi.
          pill('4.8', DesignersTexts.avgRating),
          pill('96%', DesignersTexts.verified),
        ],
      ),
    );
  }

  // ── filtr chiplari + saralash ─────────────────────────────────────────────

  Widget _toolbar(BuildContext context) {
    final theme = Theme.of(context);

    Widget chip(String label, VoidCallback onRemove) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.olive.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.olive,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6), // gap-1.5
          Pressable(
            onTap: onRemove,
            child: const SiteIcon(
              SiteIcons.close,
              size: 14,
              color: AppColors.olive,
              strokeWidth: 2.5,
            ),
          ),
        ],
      ),
    );

    final chips = <Widget>[
      for (final spec in _filter.specializations)
        chip(DesignersTexts.specLabel(spec), () => _toggleSpec(spec)),
      if (_filter.city.isNotEmpty)
        chip(CityLabels.label(_filter.city), () => _apply(_filter.copyWith(city: ''))),
      if (_filter.minRating > 0)
        chip('${trimZero(_filter.minRating)}+ ★', () => _apply(_filter.copyWith(minRating: 0))),
    ];

    return Container(
      // py-5 saytda; telefonda birinchi karta yuqoriroq boshlansin uchun ikki barobar kamaytirildi.
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (chips.isNotEmpty || _filter.hasActive) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ...chips,
                if (_filter.hasActive)
                  Pressable(
                    onTap: _reset,
                    child: Text(
                      DesignersTexts.resetAll,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.dark.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16), // gap-4
          ],
          // Natijalar soni shablonda `hidden sm:block` — mobilda faqat saralash qoladi.
          _sortSelect(context),
        ],
      ),
    );
  }

  Widget _sortSelect(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12), // px-3
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.sm), // rounded-lg
        border: Border.all(color: AppColors.borderLight),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _filter.sort,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(vertical: 2), // py-2
          icon: const SiteIcon(SiteIcons.chevronDown, size: 16),
          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14, color: AppColors.dark),
          items: [
            for (final (value, label) in DesignersTexts.sortOptions)
              DropdownMenuItem(value: value, child: Text(label)),
          ],
          onChanged: (value) => value == null ? null : _apply(_filter.copyWith(sort: value)),
        ),
      ),
    );
  }

  // ── ro'yxat ───────────────────────────────────────────────────────────────

  Widget _results(BuildContext context) {
    return FutureBuilder<Paginated<Designer>>(
      future: _future,
      builder: (context, snapshot) {
        // Yangi so'rov ketayotganda eski ro'yxat qoladi; spinner faqat birinchi yuklashda.
        final page = snapshot.data ?? _last;
        if (page == null) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 64),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _empty(context);
        }
        if (page.items.isEmpty) return _empty(context);

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0), // gap-8 → telefonda ixchamroq
          child: Column(
            children: [
              for (final (i, designer) in page.items.indexed) ...[
                if (i > 0) const SizedBox(height: 20), // space-y-5
                Entrance.fadeIn(
                  delay: Duration(milliseconds: i * 100),
                  child: _DesignerCard(
                    designer: designer,
                    isFavorite: _favorites.contains(designer.id),
                    onFavorite: () => setState(() {
                      if (!_favorites.remove(designer.id)) _favorites.add(designer.id);
                    }),
                  ),
                ),
              ],
              if (page.pages > 1) ...[
                const SizedBox(height: 48), // mt-12
                _pagination(context, page),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _empty(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 96, horizontal: 24), // py-24
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.surfaceAltLight,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SiteIcon(
                  SiteIcons.users,
                  size: 40,
                  strokeWidth: 1.5,
                  color: AppColors.dark.withValues(alpha: 0.2),
                ),
              ),
            ),
            const SizedBox(height: 20), // mb-5
            Text(
              DesignersTexts.noResults,
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 8), // mb-2
            Text(
              DesignersTexts.noResultsDesc,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.dark.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24), // mb-6
            Pressable(
              scale: 0.98,
              onTap: _reset,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.olive,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  DesignersTexts.resetAll,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pagination(BuildContext context, Paginated<Designer> page) {
    final theme = Theme.of(context);

    Widget button(Widget child, {VoidCallback? onTap, bool active = false}) => Pressable(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3), // gap-1.5
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: active ? AppColors.olive : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md), // rounded-xl
          border: Border.all(color: active ? AppColors.olive : AppColors.borderLight),
        ),
        child: Center(child: child),
      ),
    );

    void go(int p) {
      _apply(_filter.copyWith(page: p), keepPage: true);
      // Saytda `scrollToTop()` — sahifa almashsa tepaga qaytadi.
      _scroll.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        button(
          const SiteIcon(SiteIcons.chevronLeft, size: 16, color: AppColors.dark),
          onTap: page.page > 1 ? () => go(page.page - 1) : null,
        ),
        // Saytda barcha sahifa raqamlari chiqadi (`pages()`); ro'yxat oltitalab bo'lgani uchun
        // ular telefonga ham sig'adi.
        for (var p = 1; p <= page.pages; p++)
          button(
            Text(
              '$p',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: p == page.page ? Colors.white : AppColors.dark.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
            active: p == page.page,
            onTap: () => go(p),
          ),
        button(
          const SiteIcon(SiteIcons.chevronRight, size: 16, color: AppColors.dark),
          onTap: page.hasMore ? () => go(page.page + 1) : null,
        ),
      ],
    );
  }
}

/// Bitta dizayner kartasi.
///
/// Shablonda `flex flex-col md:flex-row` — mobilda avatar bloki tepada, tafsilotlar pastda.
class _DesignerCard extends StatelessWidget {
  const _DesignerCard({required this.designer, required this.isFavorite, required this.onFavorite});

  final Designer designer;
  final bool isFavorite;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg), // rounded-2xl
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [_head(context), _body(context)]),
    );
  }

  Widget _head(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24), // p-6
      color: AppColors.surfaceAltLight.withValues(alpha: 0.3), // bg-gray-50/30
      child: Column(
        children: [
          _avatar(context),
          const SizedBox(height: 16), // mt-4
          Text(
            designer.fullName,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 18, // text-lg
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 4), // mt-1
          Text(
            DesignersTexts.specLabel(designer.specialization),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.olive,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12), // mt-3
          _stars(context),
          const SizedBox(height: 8), // mt-2
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SiteIcon(SiteIcons.mapPin, size: 14, color: AppColors.dark.withValues(alpha: 0.3)),
              const SizedBox(width: 6), // gap-1.5
              Flexible(
                child: Text(
                  CityLabels.label(designer.city),
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.dark.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatar(BuildContext context) {
    final theme = Theme.of(context);
    // w-24 h-24 rounded-full ring-4 ring-white shadow-lg
    //
    // `ring-*` rasmning tashqarisiga chiziladi, ya'ni suratni kesmaydi — shuning uchun kesish
    // (ClipOval) va halqa (border) ikkita alohida qatlam. Container'ning o'zida shape+clip
    // qilinsa, rasm to'rtburchak burchakli bo'lib qolar edi.
    Widget circle(Widget child) => Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(child: child),
    );

    final avatar = designer.avatar.isNotEmpty
        ? circle(CachedNetworkImage(imageUrl: designer.avatar, fit: BoxFit.cover))
        : circle(
            DecoratedBox(
              decoration: BoxDecoration(gradient: avatarGradient(designer.fullName)),
              child: Center(
                child: Text(
                  initialsOf(designer.fullName),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontSize: 30, // text-3xl
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          );

    return SizedBox(
      width: 110,
      height: 104,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          avatar,
          // -bottom-1 -right-1: tasdiq nishonchasi.
          Positioned(
            right: 3,
            bottom: 0,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981), // bg-emerald-500
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Center(
                child: SiteIcon(SiteIcons.check, size: 12, color: Colors.white, strokeWidth: 3),
              ),
            ),
          ),
          if (designer.videoUrl != null)
            Positioned(
              right: 1,
              top: 0,
              child: Pressable(
                onTap: () => context.push('/reels/designer-${designer.id}'),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626), // bg-red-600
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.only(left: 2), // ml-0.5
                      child: SiteIcon(SiteIcons.play, size: 12, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _stars(BuildContext context) {
    final theme = Theme.of(context);
    const amber = Color(0xFFFBBF24); // text-amber-400
    const grey = Color(0xFFD1D5DB); // text-gray-300

    Widget star(int index) {
      final rating = designer.rating;
      if (rating >= index) {
        return const SiteIcon(SiteIcons.ratingStar, size: 16, color: amber);
      }
      if (rating >= index - 0.5) {
        // Yarim yulduz: to'la yulduzning chap yarmi bo'sh kontur ustiga qo'yiladi.
        return SizedBox.square(
          dimension: 16,
          child: Stack(
            children: [
              const SiteIcon(SiteIcons.ratingStarOutline, size: 16, color: amber, strokeWidth: 1),
              ClipRect(
                clipper: _HalfClipper(),
                child: const SiteIcon(SiteIcons.ratingStar, size: 16, color: amber),
              ),
            ],
          ),
        );
      }
      return const SiteIcon(SiteIcons.ratingStarOutline, size: 16, color: grey, strokeWidth: 1.5);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 1; i <= 5; i++) ...[
          if (i > 1) const SizedBox(width: 4), // gap-1
          star(i),
        ],
        const SizedBox(width: 8), // gap-1 + ml-1
        Text(
          '${designer.rating}',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '(${designer.reviewsCount})',
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 12,
            color: AppColors.dark.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }

  Widget _body(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24), // p-6
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (designer.description.isNotEmpty) ...[
            Text(
              designer.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.6,
                color: AppColors.dark.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16), // mb-4
          ],
          _stats(context),
          if (designer.portfolio.isNotEmpty) ...[const SizedBox(height: 16), _portfolio(context)],
          if (designer.tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 6, // gap-1.5
              runSpacing: 6,
              children: [
                for (final tag in designer.tags)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAltLight,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      tag,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.dark.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 12), // pt-3
          _actions(context),
        ],
      ),
    );
  }

  Widget _stats(BuildContext context) {
    final theme = Theme.of(context);

    Widget cell(String value, String label, {Color? color}) => Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 18, // text-lg
              fontWeight: FontWeight.w700,
              color: color ?? AppColors.dark,
            ),
          ),
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 11,
              letterSpacing: 0.5, // tracking-wide
              color: AppColors.dark.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );

    const separator = SizedBox(
      width: 1,
      height: 40,
      child: ColoredBox(color: AppColors.borderLight),
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12), // py-3
      decoration: BoxDecoration(
        color: AppColors.surfaceAltLight,
        borderRadius: BorderRadius.circular(AppRadius.md), // rounded-xl
      ),
      child: Row(
        children: [
          cell('${designer.completedProjects}', DesignersTexts.projects),
          separator,
          cell('${designer.experience}', DesignersTexts.years),
          // Saytda `formatPrice()` — valyuta konvertatsiyasisiz, faqat raqam ajratiladi.
          separator,
          cell(
            formatNumber(designer.priceFrom),
            DesignersTexts.priceFromLabel,
            color: AppColors.olive,
          ),
        ],
      ),
    );
  }

  Widget _portfolio(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DesignersTexts.portfolio.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: AppColors.dark.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 8), // mb-2
        Row(
          children: [
            for (final (i, image) in designer.portfolio.indexed) ...[
              if (i > 0) const SizedBox(width: 8), // gap-2
              Expanded(
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm), // rounded-lg
                    child: CachedNetworkImage(
                      imageUrl: image,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => const ColoredBox(color: AppColors.surfaceAltLight),
                      errorWidget: (_, _, _) => const ColoredBox(color: AppColors.surfaceAltLight),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _actions(BuildContext context) {
    final theme = Theme.of(context);

    Widget iconButton(SiteIconData icon, {VoidCallback? onTap, bool active = false}) => Pressable(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFEF2F2) : Colors.transparent, // bg-red-50
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: active ? const Color(0xFFFCA5A5) : AppColors.borderLight, // border-red-300
            width: 2,
          ),
        ),
        child: Center(
          child: SiteIcon(
            icon,
            size: 20,
            color: active ? const Color(0xFFEF4444) : AppColors.dark.withValues(alpha: 0.5),
          ),
        ),
      ),
    );

    return Row(
      children: [
        Expanded(
          child: Pressable(
            scale: 0.98,
            onTap: () => context.push('/designers/${designer.id}'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12), // py-3
              decoration: BoxDecoration(
                color: AppColors.olive,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                DesignersTexts.viewProfile,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12), // gap-3
        iconButton(
          SiteIcons.phone,
          onTap: designer.phone.isEmpty
              ? null
              : () => launchUrl(Uri.parse('tel:${designer.phone}')),
        ),
        const SizedBox(width: 12),
        iconButton(SiteIcons.heart, onTap: onFavorite, active: isFavorite),
      ],
    );
  }
}

/// Yarim yulduz uchun — kenglikning chap yarmi.
class _HalfClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width / 2, size.height);

  @override
  bool shouldReclip(_HalfClipper oldClipper) => false;
}
