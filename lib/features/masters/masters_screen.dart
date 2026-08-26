import '../../shared/widgets/app_image.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/constants/city_labels.dart';
import '../../core/models/master.dart';
import '../../core/models/property_listing.dart';
import '../../core/utils/format.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/site_header.dart';
import '../../shared/widgets/site_footer_section.dart';
import '../../shared/widgets/site_icon.dart';
import '../../shared/widgets/specialist_bits.dart';
import 'masters_filter_sheet.dart';
import 'masters_repository.dart';
import 'masters_texts.dart';

/// Saytning `/masters` sahifasi — "Ustalar bozori".
///
/// `masters.component.ts` ning mobil ko'rinishi: terrakota gradientli hero (nuqtali naqsh, kalit
/// suv belgisi, uchta statistika tabletkasi), keyin qidiruv qatori, sarlavha + saralash
/// tugmachalari, faol filtr chiplari va usta kartalari.
///
/// Shablonda qidiruv maydoni yon panelning eng tepasida turadi va mobilda u kartalardan yuqorida
/// chiqadi — shuning uchun bu yerda ham hero'dan keyin darrov qidiruv qatori keladi. Panelning
/// qolgan qismi ("Filterlar" tugmasi bilan) pastki oynaga olindi — [MastersFilterSheet].
class MastersScreen extends StatefulWidget {
  const MastersScreen({super.key});

  @override
  State<MastersScreen> createState() => _MastersScreenState();
}

class _MastersScreenState extends State<MastersScreen> {
  final _repo = const MastersRepository();
  final _searchController = TextEditingController();
  final _scroll = ScrollController();

  MasterFilter _filter = const MasterFilter();
  late Future<Paginated<Master>> _future = _load(_filter);

  /// Saytda ro'yxat yangi so'rov ketayotganda skeleton kartalar bilan almashadi; bu yerda esa
  /// oxirgi javob saqlanadi va skeletonlar faqat birinchi yuklashda chiziladi.
  Paginated<Master>? _last;

  Future<Paginated<Master>> _load(MasterFilter filter) =>
      _repo.list(filter).then((page) => _last = page);

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

  void _apply(MasterFilter next, {bool keepPage = false}) {
    setState(() {
      _filter = keepPage ? next : next.copyWith(page: 1);
      _future = _load(_filter);
    });
  }

  void _onSearch(String value) {
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
    _apply(const MasterFilter());
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<MasterFilter>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => MastersFilterSheet(filter: _filter),
    );
    if (result != null) _apply(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // `bg-[#FAF9F6]` — dizaynerlardagi gray-50 emas, krem.
      backgroundColor: AppColors.cream,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scroll,
            slivers: [
              SliverToBoxAdapter(child: _hero(context)),
              SliverToBoxAdapter(child: _searchRow(context)),
              SliverToBoxAdapter(child: _titleAndSort(context)),
              SliverToBoxAdapter(child: _chips(context)),
              SliverToBoxAdapter(child: _results(context)),
              const SliverToBoxAdapter(child: SizedBox(height: 64)), // pb-16
              // Shablon `<app-footer />` bilan tugaydi — har bir sahifada.
              const SliverToBoxAdapter(child: SiteFooterSection()),
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
                  // linear-gradient(120deg,#B5764C 0%,#9A5E3C 55%,#5C4636 100%)
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
            // `right:-6px; bottom:-34px` dagi 210×210 kalit suv belgisi.
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
                      MastersTexts.heroBadge,
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
                    MastersTexts.heroTitle,
                    style: theme.textTheme.displaySmall?.copyWith(
                      // Shablonda `text-[50px]` — telefonda bir qatorga sig'maydi, dizaynerlar
                      // sahifasidagi 30px bilan bir xil qilindi.
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      height: 1.02,
                      letterSpacing: -0.5,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12), // mb-3
                  Text(
                    MastersTexts.heroDesc,
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

    return FutureBuilder<Paginated<Master>>(
      future: _future,
      builder: (context, snapshot) => Wrap(
        spacing: 10, // gap-2.5
        runSpacing: 10,
        children: [
          pill('${snapshot.data?.total ?? _last?.total ?? 0}', MastersTexts.specialists),
          // 4.8 va 96% shablonda qattiq yozilgan.
          pill('4.8', MastersTexts.avgRating),
          pill('96%', MastersTexts.verified),
        ],
      ),
    );
  }

  // ── qidiruv + filtr ───────────────────────────────────────────────────────

  /// Yon panelning eng tepasidagi qidiruv maydoni + "Filterlar" tugmasi.
  Widget _searchRow(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12), // px-3
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3EC),
                borderRadius: BorderRadius.circular(AppRadius.md), // rounded-xl
                border: Border.all(color: const Color(0xFFE7E3D8)),
              ),
              child: Row(
                children: [
                  SiteIcon(
                    SiteIcons.search,
                    size: 16,
                    strokeWidth: 1.7,
                    color: AppColors.dark.withValues(alpha: 0.3),
                  ),
                  const SizedBox(width: 8), // gap-2
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearch,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: AppColors.dark,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10), // py-2.5
                        hintText: MastersTexts.searchPlaceholder,
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          color: AppColors.dark.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Pressable(
            scale: 0.98,
            onTap: _openFilters,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                        MastersTexts.filters,
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
    );
  }

  // ── sarlavha + saralash ───────────────────────────────────────────────────

  Widget _titleAndSort(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                MastersTexts.heroTitle,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontSize: 22, // text-[22px]
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(width: 10), // gap-2.5
              FutureBuilder<Paginated<Master>>(
                future: _future,
                builder: (context, snapshot) => Text(
                  '${snapshot.data?.total ?? _last?.total ?? 0} ${MastersTexts.count}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                MastersTexts.sortLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(width: 6), // gap-1.5
              for (final (value, label) in MastersTexts.sortOptions) ...[
                Pressable(
                  onTap: () => _apply(_filter.copyWith(sort: value)),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _filter.sort == value ? AppColors.olive : Colors.transparent,
                      borderRadius: BorderRadius.circular(9), // rounded-[9px]
                      border: Border.all(
                        color: _filter.sort == value ? AppColors.olive : const Color(0xFFE7E3D8),
                      ),
                    ),
                    child: Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _filter.sort == value ? Colors.white : const Color(0xFF6F6C5F),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── faol filtr chiplari ───────────────────────────────────────────────────

  Widget _chips(BuildContext context) {
    if (!_filter.hasActive) return const SizedBox.shrink();
    final theme = Theme.of(context);

    Widget chip(String label, VoidCallback onRemove) => Pressable(
      onTap: onRemove,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 6, 8, 6), // pl-3.5 pr-2 py-1.5
        decoration: BoxDecoration(
          color: const Color(0xFFECEDDF),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.olive.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF62633C),
              ),
            ),
            const SizedBox(width: 7), // gap-[7px]
            Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(color: AppColors.olive, shape: BoxShape.circle),
              child: const Center(
                child: SiteIcon(SiteIcons.close, size: 9, color: Colors.white, strokeWidth: 3),
              ),
            ),
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final spec in _filter.specializations)
            chip(MastersTexts.specLabel(spec), () => _toggleSpec(spec)),
          if (_filter.city.isNotEmpty)
            chip(CityLabels.label(_filter.city), () => _apply(_filter.copyWith(city: ''))),
          if (_filter.minRating > 0)
            chip('${_trim(_filter.minRating)}+ ★', () => _apply(_filter.copyWith(minRating: 0))),
          if (_filter.availability.isNotEmpty)
            chip(
              MastersTexts.availabilityOptions
                  .firstWhere(
                    (o) => o.$1 == _filter.availability,
                    orElse: () => ('', _filter.availability),
                  )
                  .$2,
              () => _apply(_filter.copyWith(availability: '')),
            ),
          if (_filter.verifiedOnly)
            chip(MastersTexts.verified, () => _apply(_filter.copyWith(verifiedOnly: false))),
          Pressable(
            onTap: _reset,
            child: Text(
              MastersTexts.resetAll,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.dark.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── ro'yxat ───────────────────────────────────────────────────────────────

  Widget _results(BuildContext context) {
    return FutureBuilder<Paginated<Master>>(
      future: _future,
      builder: (context, snapshot) {
        final page = snapshot.data ?? _last;
        if (page == null) {
          if (snapshot.connectionState == ConnectionState.waiting) return _skeletons(context);
          return _empty(context);
        }
        // Backend bilmaydigan ikki filtr shu yerda qo'llanadi — izohi `MasterFilter` da.
        final items = _filter.applyLocal(page.items);
        if (items.isEmpty) return _empty(context);

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Column(
            children: [
              // Telefonda ikki ustun — foydalanuvchi so'rovi (bir ekranda ko'proq karta).
              // Saytda `repeat(auto-fill, minmax(280px, 1fr))`, ya'ni telefonda bitta
              // bo'lardi; kattaroq ekranda kenglikka qarab hisoblanadi.
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = ((constraints.maxWidth + 18) / (280 + 18)).floor().clamp(2, 6);
                  return GridView.builder(
                    // Ichma-ich GridView atrofdagi paddingni meros qiladi.
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 18, // gap-[18px]
                      crossAxisSpacing: 18,
                      mainAxisExtent: _MasterCard.extent,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, i) => Entrance.fadeIn(
                      delay: Duration(milliseconds: i * 100),
                      child: _MasterCard(master: items[i]),
                    ),
                  );
                },
              ),
              if (page.pages > 1) ...[
                const SizedBox(height: 32), // mt-8
                _pagination(context, page),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Saytdagi `animate-pulse` skeleton kartalari — oltita, muqova + uch qator.
  Widget _skeletons(BuildContext context) {
    Widget bar(double widthFactor, double height) => FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFF1EFE8),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: GridView.count(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 18,
        crossAxisSpacing: 18,
        mainAxisExtent: _MasterCard.extent,
        children: [
          for (var i = 0; i < 6; i++)
            Pulse(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20), // rounded-[20px]
                  border: Border.all(color: const Color(0xFFE7E3D8)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 52, color: const Color(0xFFF1EFE8)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 28, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          bar(0.6, 16),
                          const SizedBox(height: 10),
                          bar(0.4, 12),
                          const SizedBox(height: 10),
                          bar(1, 30),
                        ],
                      ),
                    ),
                  ],
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
          // `border-dashed` — Flutter'da nuqtali chegara yo'q, oddiy chiziq qoldirildi.
          border: Border.all(color: const Color(0xFFE7E3D8)),
        ),
        child: Column(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: const Color(0xFFECEDDF),
                borderRadius: BorderRadius.circular(28), // rounded-[28px]
              ),
              child: const Center(child: Text('🔍', style: TextStyle(fontSize: 42))),
            ),
            const SizedBox(height: 16), // mb-2 + gap-2
            Text(
              MastersTexts.noResults,
              style: theme.textTheme.displaySmall?.copyWith(
                fontSize: 23, // text-[23px]
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              MastersTexts.noResultsDesc,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 15,
                height: 1.6,
                color: AppColors.dark.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16), // mt-4
            Pressable(
              onTap: _reset,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.olive,
                  borderRadius: BorderRadius.circular(13), // rounded-[13px]
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.olive.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  MastersTexts.resetAll,
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
      ),
    );
  }

  Widget _pagination(BuildContext context, Paginated<Master> page) {
    final theme = Theme.of(context);

    Widget button(Widget child, {VoidCallback? onTap, bool active = false}) => Pressable(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3), // gap-1.5
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: active ? AppColors.olive : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: active ? AppColors.olive : const Color(0xFFE7E3D8)),
        ),
        child: Center(child: child),
      ),
    );

    void go(int p) {
      _apply(_filter.copyWith(page: p), keepPage: true);
      _scroll.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        button(
          const SiteIcon(SiteIcons.chevronLeft, size: 16, color: AppColors.dark),
          onTap: page.page > 1 ? () => go(page.page - 1) : null,
        ),
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

String _trim(double value) => value == value.roundToDouble() ? '${value.toInt()}' : '$value';

/// Bitta usta kartasi.
///
/// Muqova (84px terrakota gradient + nuqtalar + kalit + bandlik nishonchasi), unga yarim chiqib
/// turgan avatar va o'ng tomonda reyting tabletkasi, keyin ism + tasdiq belgisi + shahar,
/// mutaxassislik va ikkita teg, pastda narx va "Profilni ko'rish".
class _MasterCard extends StatelessWidget {
  const _MasterCard({required this.master});

  /// Ikki ustunli to'rda bitta katakning balandligi.
  static const extent = 250.0;

  final Master master;

  @override
  Widget build(BuildContext context) {
    // Saytda butun karta bosiladi, tugma esa `stopPropagation` bilan — ikkalasi bir joyga boradi.
    return Pressable(
      scale: 0.99,
      onTap: () => context.push('/masters/${master.id}'),
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
            _cover(context),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _avatarRow(context),
                    const SizedBox(height: 8), // gap-[11px] → yarim kenglikda 8
                    _nameAndCity(context),
                    const SizedBox(height: 8),
                    _specAndTags(context),
                    const Spacer(),
                    const SizedBox(height: 8),
                    const Divider(height: 1, color: Color(0xFFE7E3D8)),
                    const SizedBox(height: 8), // pt-3
                    _priceRow(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cover(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 52,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-0.87, -0.5),
                  end: Alignment(0.87, 0.5),
                  colors: [Color(0xFFB5764C), Color(0xFF5C4636)],
                ),
              ),
            ),
          ),
          // 14×14 nuqtali naqsh, opacity-45.
          const Positioned.fill(
            child: CustomPaint(painter: DotPatternPainter(step: 14, alpha: 0.072)),
          ),
          Positioned(
            right: 8,
            bottom: -4,
            child: SiteIcon(
              SiteIcons.wrench,
              size: 40,
              strokeWidth: 1.3,
              color: Colors.white.withValues(alpha: 0.16),
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                master.isAvailable ? MastersTexts.availableBadge : MastersTexts.busyBadge,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF3A3A28),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarRow(BuildContext context) {
    final theme = Theme.of(context);
    // `-mt-8` — avatar muqovaning ustiga yarim chiqib turadi. Qator 64px baland, lekin joylashuvda
    // atigi 32px egallaydi: qolgan yarmi muqova ustiga chiqadi.
    return SizedBox(
      height: 22,
      child: OverflowBox(
        alignment: Alignment.bottomCenter,
        maxHeight: 44,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _avatar(context),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 2), // mb-1
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3EC),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: const Color(0xFFE7E3D8)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('★', style: TextStyle(color: Color(0xFFE0A93B), fontSize: 11)),
                    const SizedBox(width: 3),
                    Text(
                      '${master.rating}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '(${master.reviewsCount})',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 9.5,
                        color: AppColors.dark.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar(BuildContext context) {
    final theme = Theme.of(context);
    // w-16 h-16 rounded-full border-[3px] border-white
    Widget ring(Widget child) => Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(child: child),
    );

    if (master.avatar.isNotEmpty) {
      return ring(AppImage(imageUrl: master.avatar, fit: BoxFit.cover));
    }
    return ring(
      DecoratedBox(
        decoration: BoxDecoration(gradient: avatarGradient(master.fullName)),
        child: Center(
          child: Text(
            initialsOf(master.fullName),
            style: theme.textTheme.displaySmall?.copyWith(
              fontSize: 16, // text-[22px] → yarim kenglikda 16
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _nameAndCity(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                master.fullName,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontSize: 14, // text-[18px] → yarim kenglikda 14
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
            ),
            if (master.isVerified) ...[
              const SizedBox(width: 4), // gap-1.5
              Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(color: AppColors.olive, shape: BoxShape.circle),
                child: const Center(
                  child: SiteIcon(SiteIcons.check, size: 9, color: Colors.white, strokeWidth: 3),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 2), // mt-0.5
        Text(
          '📍 ${CityLabels.label(master.city)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.dark.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _specAndTags(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 5, // gap-1.5
      runSpacing: 5,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFB5694C).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            MastersTexts.specLabel(master.specialization),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF9A5E3C),
            ),
          ),
        ),
        // Shablon faqat dastlabki ikkitasini oladi: `master.tags.slice(0, 2)`.
        for (final tag in master.tags.take(2))
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3EC),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: const Color(0xFFE7E3D8)),
            ),
            child: Text(
              tag,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.dark.withValues(alpha: 0.5),
              ),
            ),
          ),
      ],
    );
  }

  Widget _priceRow(BuildContext context) {
    final theme = Theme.of(context);
    // Saytda narx va tugma yonma-yon; yarim kenglikda tugma pastga tushadi.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              MastersTexts.priceLabel.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.63, // tracking-[0.06em]
                color: AppColors.dark.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(width: 6),
            // Saytda `formatPrice()` — valyuta konvertatsiyasisiz.
            Expanded(
              child: Text(
                formatNumber(master.priceFrom),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.dark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Pressable(
          onTap: () => context.push('/masters/${master.id}'),
          child: Container(
            width: double.infinity,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.olive,
              borderRadius: BorderRadius.circular(9), // rounded-[11px]
            ),
            child: Text(
              MastersTexts.viewProfile,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
