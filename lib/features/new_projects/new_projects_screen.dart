import '../../core/i18n/translate.dart';
import '../../shared/widgets/app_image.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/constants/city_labels.dart';
import '../../core/models/project.dart';
import '../../core/utils/format.dart';
import '../../shared/utils/breakpoints.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/site_footer_section.dart';
import '../../shared/widgets/site_header.dart';
import '../../shared/widgets/site_icon.dart';
import '../../shared/widgets/skeleton.dart';
import 'new_projects_filter_sheet.dart';
import 'new_projects_repository.dart';
import 'new_projects_texts.dart';
import 'project_filter.dart';

/// Saytning `/new-projects` sahifasi — "Yangi Loyihalar".
///
/// `new-projects.component.ts` ning mobil ko'rinishi: rasm ustidagi to'q gradientli hero
/// (sarlavha, izoh, oq qidiruv kartasi, "Xaritadan qidirish" havolasi va ikki nuqtali
/// statistika), keyin `bg-gray-50` tanada faol filtr chiplari, saralash, "Filterlar" tugmasi va
/// loyiha kartalari to'ri.
///
/// **Hammasi mijoz tomonida:** endpoint filtr bilmaydi, sayt barcha loyihalarni bir marta olib
/// o'zi saralaydi — [ProjectFilter] shuni takrorlaydi.
class NewProjectsScreen extends StatefulWidget {
  const NewProjectsScreen({super.key});

  @override
  State<NewProjectsScreen> createState() => _NewProjectsScreenState();
}

class _NewProjectsScreenState extends State<NewProjectsScreen> {
  final _repo = ProjectsRepository();
  final _searchController = TextEditingController();
  final _scroll = ScrollController();

  late final Future<List<Project>> _future = _repo.fetchProjects();
  ProjectFilter _filter = const ProjectFilter();
  Timer? _debounce;
  bool _scrolled = false;

  /// Saytdagi `completionYears` — joriy yildan boshlab oltitasi.
  static final _years = [for (var i = 0; i <= 5; i++) '${DateTime.now().year + i}'];

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

  /// Filtr o'zgarsa sahifa 1 ga qaytadi — saytda har bir `set` dan keyin `currentPage.set(1)`.
  void _apply(ProjectFilter next, {bool keepPage = false}) {
    setState(() => _filter = keepPage ? next : next.copyWith(page: 1));
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _apply(_filter.copyWith(search: value));
    });
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<ProjectFilter>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => NewProjectsFilterSheet(filter: _filter, years: _years),
    );
    if (result != null) _apply(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAltLight, // bg-gray-50
      body: Stack(
        children: [
          FutureBuilder<List<Project>>(
            future: _future,
            builder: (context, snapshot) {
              final all = snapshot.data ?? const <Project>[];
              final filtered = _filter.apply(all);
              final page = _filter.pageOf(filtered);
              final loading = snapshot.connectionState == ConnectionState.waiting;

              return CustomScrollView(
                controller: _scroll,
                slivers: [
                  SliverToBoxAdapter(child: _hero(context, filtered.length)),
                  SliverToBoxAdapter(child: _toolbar(context, filtered.length)),
                  if (loading)
                    // Aylanuvchi belgi o'rniga kartalarning shakli — javob kelganda sahifa
                    // sakramaydi.
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      sliver: SliverGrid.count(
                        crossAxisCount: Bp.pick(context, base: 1, sm: 2, xl: 3),
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 20,
                        childAspectRatio: 172 / _ProjectCard.extent,
                        children: [
                          for (var i = 0; i < 4; i++)
                            const Pulse(
                              child: Skeleton(height: double.infinity, radius: AppRadius.lg),
                            ),
                        ],
                      ),
                    )
                  else if (page.isEmpty)
                    SliverToBoxAdapter(child: _empty(context))
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      sliver: SliverGrid.builder(
                        // Saytda `grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-5`.
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: Bp.pick(context, base: 1, sm: 2, xl: 3),
                          mainAxisSpacing: 20, // gap-5
                          crossAxisSpacing: 20,
                          mainAxisExtent: _ProjectCard.extent,
                        ),
                        itemCount: page.length,
                        itemBuilder: (context, i) => Entrance.fadeIn(
                          delay: Duration(milliseconds: i * 80),
                          child: _ProjectCard(project: page[i]),
                        ),
                      ),
                    ),
                  if (!loading && filtered.length > ProjectFilter.perPage)
                    SliverToBoxAdapter(child: _pagination(context, filtered.length)),
                  const SliverToBoxAdapter(child: SizedBox(height: 64)), // pb-16
                  const SliverToBoxAdapter(child: SiteFooterSection()),
                ],
              );
            },
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            // `/new-projects` saytdagi `ownSearchRoutes` da bor — header qidiruvi yashiriladi.
            child: SiteHeader(scrolled: _scrolled, showSearch: false),
          ),
        ],
      ),
    );
  }

  // ── hero ──────────────────────────────────────────────────────────────────

  Widget _hero(BuildContext context, int count) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        Positioned.fill(
          child: AppImage(
            imageUrl: 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=1920&q=80',
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              // `from-dark/90 via-dark/70 to-dark/50`, chapdan o'ngga.
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppColors.dark.withValues(alpha: 0.9),
                  AppColors.dark.withValues(alpha: 0.7),
                  AppColors.dark.withValues(alpha: 0.5),
                ],
              ),
            ),
          ),
        ),
        Padding(
          // `pt-32 … py-12`; telefonda header ostidan boshlanadi.
          padding: EdgeInsets.fromLTRB(16, 88 + MediaQuery.paddingOf(context).top, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                NewProjectsTexts.heroTitle,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontSize: 30, // text-3xl
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12), // mb-3
              Text(
                NewProjectsTexts.heroDesc,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 15, // `text-lg` telefonda 15
                  height: 1.5,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 20), // mb-8 → telefonda 20
              _searchCard(context),
              const SizedBox(height: 12), // mt-4
              _mapLink(context),
              const SizedBox(height: 16), // mt-8 → telefonda 16
              _stats(context, count),
            ],
          ),
        ),
      ],
    );
  }

  Widget _searchCard(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(8), // p-2
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg), // rounded-2xl
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 24, offset: Offset(0, 8))],
      ),
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
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14), // py-3.5
                    hintText: NewProjectsTexts.searchPlaceholder,
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 15,
                      color: AppColors.dark.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8), // gap-2
          // Shahar tanlovi — shablonda qidiruv kartasining ichida.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16), // px-4
            decoration: BoxDecoration(
              color: AppColors.surfaceAltLight,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _filter.city,
                isExpanded: true,
                padding: const EdgeInsets.symmetric(vertical: 6),
                icon: const SiteIcon(SiteIcons.chevronDown, size: 16),
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14, color: AppColors.dark),
                items: [
                  DropdownMenuItem(value: '', child: Text(NewProjectsTexts.allCities)),
                  for (final (value, label) in CityLabels.options)
                    DropdownMenuItem(value: value, child: Text(label)),
                ],
                onChanged: (v) => _apply(_filter.copyWith(city: v ?? '')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapLink(BuildContext context) {
    final theme = Theme.of(context);
    return Pressable(
      onTap: () => context.push('/map'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // px-4 py-2
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SiteIcon(SiteIcons.map, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              NewProjectsTexts.searchOnMap,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            const SiteIcon(SiteIcons.chevronRight, size: 14, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _stats(BuildContext context, int count) {
    final theme = Theme.of(context);
    Widget dot(Color color, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.7)),
        ),
      ],
    );

    return Wrap(
      spacing: 24, // gap-6
      runSpacing: 8,
      children: [
        dot(const Color(0xFF34D399), '$count ${NewProjectsTexts.activeListings}'),
        dot(AppColors.olive, NewProjectsTexts.updatedToday),
      ],
    );
  }

  // ── chiplar, saralash, filtr tugmasi ──────────────────────────────────────

  Widget _toolbar(BuildContext context, int count) {
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
          const SizedBox(width: 6),
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
      if (_filter.city.isNotEmpty)
        chip(CityLabels.label(_filter.city), () => _apply(_filter.copyWith(city: ''))),
      if (_filter.priceMin > 0 || _filter.priceMax > 0)
        chip(
          '${_filter.priceMin > 0 ? formatNumber(_filter.priceMin) : '0'} — '
          '${_filter.priceMax > 0 ? formatNumber(_filter.priceMax) : '...'}',
          () => _apply(_filter.copyWith(priceMin: 0, priceMax: 0)),
        ),
      if (_filter.completion.isNotEmpty)
        chip(_filter.completion, () => _apply(_filter.copyWith(completion: ''))),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10), // py-5 → telefonda ixchamroq
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (chips.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ...chips,
                Pressable(
                  onTap: () => _apply(ProjectFilter(search: _filter.search, sort: _filter.sort)),
                  child: Text(
                    NewProjectsTexts.resetAll,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.dark.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              // Shablonning mobil qatori: "Filterlar" tugmasi + natijalar soni.
              Pressable(
                scale: 0.98,
                onTap: _openFilters,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SiteIcon(SiteIcons.funnel, size: 16, color: AppColors.dark),
                          const SizedBox(width: 8),
                          Text(
                            NewProjectsTexts.filters,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.dark,
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
              const SizedBox(width: 12),
              Expanded(child: _sortSelect(context)),
            ],
          ),
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
          padding: const EdgeInsets.symmetric(vertical: 2),
          icon: const SiteIcon(SiteIcons.chevronDown, size: 16),
          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14, color: AppColors.dark),
          items: [
            for (final (value, label) in NewProjectsTexts.sortOptions)
              DropdownMenuItem(value: value, child: Text(label)),
          ],
          onChanged: (v) => v == null ? null : _apply(_filter.copyWith(sort: v)),
        ),
      ),
    );
  }

  Widget _empty(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      child: Column(
        children: [
          SiteIcon(SiteIcons.search, size: 40, color: AppColors.dark.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            NewProjectsTexts.noResults,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 20, // text-xl
              fontWeight: FontWeight.w600,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            NewProjectsTexts.noResultsDesc,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.dark.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24), // mb-6
          Pressable(
            scale: 0.98,
            onTap: () => _apply(ProjectFilter(search: _filter.search, sort: _filter.sort)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.olive,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                NewProjectsTexts.resetAll,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pagination(BuildContext context, int total) {
    final theme = Theme.of(context);
    final pages = (total / ProjectFilter.perPage).ceil();
    if (pages <= 1) return const SizedBox.shrink();

    // Uzun ro'yxatda bitta qatorga sig'ishi uchun joriy sahifa atrofidagi oyna.
    final from = (_filter.page - 2).clamp(1, pages);
    final to = (from + 4).clamp(1, pages);

    Widget button(Widget child, {VoidCallback? onTap, bool active = false}) => Pressable(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: active ? AppColors.olive : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: active ? AppColors.olive : AppColors.borderLight),
        ),
        child: Center(child: child),
      ),
    );

    void go(int p) {
      _apply(_filter.copyWith(page: p), keepPage: true);
      _scroll.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          button(
            const SiteIcon(SiteIcons.chevronLeft, size: 16, color: AppColors.dark),
            onTap: _filter.page > 1 ? () => go(_filter.page - 1) : null,
          ),
          for (var p = from; p <= to; p++)
            button(
              Text(
                '$p',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: p == _filter.page ? Colors.white : AppColors.dark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              active: p == _filter.page,
              onTap: () => go(p),
            ),
          button(
            const SiteIcon(SiteIcons.chevronRight, size: 16, color: AppColors.dark),
            onTap: _filter.page < pages ? () => go(_filter.page + 1) : null,
          ),
        ],
      ),
    );
  }
}

/// `/new-projects` ning o'z kartasi — bu **shared `property-card` emas**.
///
/// 4:3 rasm; chap yuqorida narx, o'ng yuqorida rasm soni va TOP, chap pastda 3D va topshirish
/// yili, o'ng pastda sevimli tugmasi. Pastida nom, quruvchi, joylashuv, uch ustunli
/// ko'rsatkichlar va segment/tasdiq yorliqlari.
class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project});

  /// Ikki ustunli to'rda bitta katakning balandligi.
  static const extent = 300.0;

  final Project project;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final images = <String>[
      for (final c in [project.cardImage, project.coverImage, ...project.cardImages])
        if (c != null && c.isNotEmpty) c,
    ];

    return Pressable(
      scale: 0.99,
      onTap: () {
        final dev = project.developer?.code;
        final code = project.slug.isEmpty ? '${project.id}' : project.slug;
        if (dev != null && dev.isNotEmpty) context.push('/$dev/$code');
      },
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (images.isNotEmpty)
                    AppImage(
                      imageUrl: _absolute(images.first),
                      fit: BoxFit.cover,
                      placeholder: (_, _) => const ColoredBox(color: AppColors.surfaceAltLight),
                      errorWidget: (_, _, _) => const ColoredBox(color: AppColors.surfaceAltLight),
                    )
                  else
                    const ColoredBox(color: AppColors.surfaceAltLight),

                  if (project.minPrice case final price?)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          '${NewProjectsTexts.from} ${formatNumber(price)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.dark,
                          ),
                        ),
                      ),
                    ),

                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      children: [
                        if (images.length > 1)
                          _badge(theme, '${images.length}', AppColors.dark.withValues(alpha: 0.7)),
                        if (project.isTop) ...[
                          const SizedBox(width: 4),
                          _badge(theme, t('ads.top'), const Color(0xE6F59E0B)),
                        ],
                      ],
                    ),
                  ),

                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Row(
                      children: [
                        if (project.hasTour) _badge(theme, '3D', const Color(0xF22563EB)),
                        if (project.completionYear.isNotEmpty) ...[
                          if (project.hasTour) const SizedBox(width: 4),
                          _badge(theme, project.completionYear, const Color(0xF287885C)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12), // p-4
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      maxLines: 1, // line-clamp-1
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dark,
                      ),
                    ),
                    if (project.developer?.name case final name?) ...[
                      const SizedBox(height: 4), // mb-1
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                          color: AppColors.dark.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                    if (project.locationLabel.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          SiteIcon(
                            SiteIcons.mapPin,
                            size: 11,
                            color: AppColors.dark.withValues(alpha: 0.4),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              project.locationLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 11,
                                color: AppColors.dark.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const Spacer(),
                    const Divider(height: 1, color: AppColors.borderLight),
                    const SizedBox(height: 8), // py-3
                    _features(theme),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Uch ustun: kvartiralar, bloklar, umumiy maydon — nol bo'lsa ham chiziladi.
  Widget _features(ThemeData theme) {
    Widget cell(String value, String label) => Expanded(
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 9.5,
              color: AppColors.dark.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );

    const separator = SizedBox(
      width: 1,
      height: 28,
      child: ColoredBox(color: AppColors.borderLight),
    );

    return Row(
      children: [
        cell(formatNumber(project.totalApartments ?? 0), t('newProjects.typeApartment')),
        separator,
        cell(formatNumber(project.totalBlocks ?? 0), t('newProjects.blocks')),
        separator,
        cell(formatNumber(project.totalArea ?? 0), 'm²'),
      ],
    );
  }

  Widget _badge(ThemeData theme, String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
    child: Text(
      text,
      style: theme.textTheme.labelSmall?.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
  );

  static String _absolute(String path) =>
      path.startsWith('http') ? path : 'https://businesshome.uz$path';
}
