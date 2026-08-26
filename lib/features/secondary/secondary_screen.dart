import '../../core/i18n/translate.dart';
import '../../shared/widgets/app_image.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/models/property_listing.dart';
import '../../core/models/region.dart';
import '../../core/services/currency_service.dart';
import '../../core/services/regions_service.dart';
import '../../shared/models/property_view.dart';
import '../../shared/utils/breakpoints.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/property_card.dart';
import '../../shared/widgets/site_header.dart';
import '../../shared/widgets/site_footer_section.dart';
import '../../shared/widgets/site_icon.dart';
import '../../shared/widgets/skeleton.dart';
import 'listings_config.dart';
import 'secondary_filter_sheet.dart';
import 'secondary_repository.dart';
import 'secondary_texts.dart';

/// The site's `/secondary` page — "Business e'lonlari".
///
/// Layout from `secondary.component.ts` at mobile width: a photo hero with a left-to-right dark
/// gradient carrying the title, the white search card and the "faol e'lon" counters; then a
/// `bg-gray-50` body with the active-filter chips, sort and currency controls, the single-column
/// card grid and pagination.
///
/// The filter panel is a full-screen overlay on phones (`lg:hidden fixed inset-0`), opened from
/// the button inside the search card — see [SecondaryFilterSheet].
class SecondaryScreen extends StatefulWidget {
  SecondaryScreen({super.key, ListingsConfig? config, this.initialCity, this.openFilters = false})
    : config = config ?? ListingsConfig.secondary;

  /// Which of the two listing pages this is — see [ListingsConfig].
  final ListingsConfig config;

  /// From `/secondary?city=` — the map and the footer link in with this.
  final String? initialCity;

  /// From `/secondary?filters=open`, the header's filter button.
  final bool openFilters;

  @override
  State<SecondaryScreen> createState() => _SecondaryScreenState();
}

class _SecondaryScreenState extends State<SecondaryScreen> {
  late final _repo = SecondaryRepository(endpoint: widget.config.endpoint);
  final _searchController = TextEditingController();
  final _scroll = ScrollController();

  late SecondaryFilter _filter = SecondaryFilter(city: widget.initialCity ?? '');
  late Future<Paginated<PropertyListing>> _future = _load(_filter);

  /// Oxirgi muvaffaqiyatli javob. Saytda shablonda spinner yo'q — yangi so'rov ketayotganda
  /// eski ro'yxat ekranda turaveradi, `loading()` faqat "topilmadi" blokini bosib turadi.
  Paginated<PropertyListing>? _last;

  Future<Paginated<PropertyListing>> _load(SecondaryFilter filter) =>
      _repo.list(filter).then((page) => _last = page);

  List<Region> _regions = const [];
  Timer? _debounce;
  bool _scrolled = false;

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
    if (widget.openFilters) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openFilters());
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Any filter change resets to page 1, as the site does.
  void _apply(SecondaryFilter next, {bool keepPage = false}) {
    setState(() {
      _filter = keepPage ? next : next.copyWith(page: 1);
      _future = _load(_filter);
    });
  }

  void _onSearch(String value) {
    // The site searches as you type; debounce so every keystroke is not a request.
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _apply(_filter.copyWith(search: value));
    });
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<SecondaryFilter>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) =>
          SecondaryFilterSheet(filter: _filter, regions: _regions, config: widget.config),
    );
    if (result != null) _apply(result);
  }

  String _cityLabel(String value) => _regions
      .firstWhere(
        (r) => r.value == value,
        orElse: () => Region(value: value, label: value),
      )
      .label;

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
              _results(context),
              SliverToBoxAdapter(child: _paginationBlock(context)),
              const SliverToBoxAdapter(child: SizedBox(height: 64)), // pb-16
              // Shablon `<app-footer />` bilan tugaydi — har bir sahifada.
              const SliverToBoxAdapter(child: SiteFooterSection()),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            // The site passes `[transparent]="false"` here — the bar is solid from the start.
            child: SiteHeader(scrolled: _scrolled, showSearch: false),
          ),
        ],
      ),
    );
  }

  Widget _hero(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        Positioned.fill(
          child: AppImage(imageUrl: widget.config.heroImage, fit: BoxFit.cover),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              // `from-dark/90 via-dark/70 to-dark/50`, left to right.
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
          // `pt-32 … py-12` plus the status bar, so the title clears the fixed header.
          // Tight to the header above and to the toolbar below — the site's `pt-32 py-12`
          // left a dead band at both ends on a phone.
          padding: EdgeInsets.fromLTRB(16, 88 + MediaQuery.paddingOf(context).top, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.config.heroTitle,
                style: theme.textTheme.displayMedium?.copyWith(
                  fontSize: 30, // text-3xl
                  color: Colors.white,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 12), // mb-3
              Text(
                widget.config.heroDesc,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 20),
              _searchCard(context),
              const SizedBox(height: 16), // mt-4
              Pressable(
                onTap: () => context.go('/map'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SiteIcon(SiteIcons.mapPin, size: 16, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        SecondaryTexts.searchOnMap,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FutureBuilder<Paginated<PropertyListing>>(
                future: _future,
                builder: (context, snapshot) => Wrap(
                  spacing: 24, // gap-6
                  runSpacing: 8,
                  children: [
                    _HeroStat(
                      dotColor: const Color(0xFF34D399), // emerald-400
                      label:
                          '${snapshot.data?.total ?? _last?.total ?? 0} '
                          '${SecondaryTexts.activeListings}',
                    ),
                    _HeroStat(dotColor: AppColors.olive, label: SecondaryTexts.updatedToday),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// The white `rounded-2xl p-2` card: search field, filter button, then the city select — the
  /// site stacks these on a phone (`flex-col sm:flex-row`).
  Widget _searchCard(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 24, offset: Offset(0, 8))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearch,
                  textInputAction: TextInputAction.search,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: AppColors.dark,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.config.searchPlaceholder,
                    hintStyle: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w400,
                      color: AppColors.dark.withValues(alpha: 0.4),
                    ),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: SiteIcon(SiteIcons.search, size: 18, color: AppColors.dark),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 42),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              Pressable(
                scale: 0.98, // active:scale-[0.98]
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
                            SecondaryTexts.filters,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.dark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Olive dot when something is filtered, as on the site.
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
          const SizedBox(height: 8),
          _CitySelect(
            regions: _regions,
            city: _filter.city,
            district: _filter.district,
            onChanged: (city, district) => _apply(_filter.copyWith(city: city, district: district)),
          ),
        ],
      ),
    );
  }

  /// Active-filter chips on one line, sort and currency on the next.
  Widget _toolbar(BuildContext context) {
    final theme = Theme.of(context);
    final chips = <Widget>[
      if (_filter.city.isNotEmpty)
        _FilterChip(
          label: _filter.district.isEmpty
              ? _cityLabel(_filter.city)
              : '${_cityLabel(_filter.city)} · ${_filter.district}',
          onRemove: () => _apply(_filter.copyWith(city: '', district: '')),
        ),
      for (final type in _filter.types)
        _FilterChip(
          label: SecondaryTexts.propertyTypes
              .firstWhere((t) => t.$1 == type, orElse: () => (type, type))
              .$2,
          onRemove: () => _apply(_filter.copyWith(types: [..._filter.types]..remove(type))),
        ),
      for (final room in _filter.rooms)
        _FilterChip(
          label: '${room == 5 ? '5+' : room} ${SecondaryTexts.roomShort}',
          onRemove: () => _apply(_filter.copyWith(rooms: [..._filter.rooms]..remove(room))),
        ),
      if (_filter.bathrooms > 0)
        _FilterChip(
          label:
              '${_filter.bathrooms == 4 ? '4+' : _filter.bathrooms} '
              '${SecondaryTexts.bathroomShort}',
          onRemove: () => _apply(_filter.copyWith(bathrooms: 0)),
        ),
      if (_filter.segment.isNotEmpty)
        _FilterChip(
          label: SecondaryTexts.segments
              .firstWhere((s) => s.$1 == _filter.segment, orElse: () => ('', _filter.segment))
              .$2,
          onRemove: () => _apply(_filter.copyWith(segment: '')),
        ),
      if (_filter.seller.isNotEmpty)
        _FilterChip(
          // The site tints the seller chip blue and the payment chip amber.
          background: const Color(0xFFEFF6FF),
          foreground: const Color(0xFF2563EB),
          label: SecondaryTexts.sellers
              .firstWhere((s) => s.$1 == _filter.seller, orElse: () => ('', _filter.seller))
              .$2,
          onRemove: () => _apply(_filter.copyWith(seller: '')),
        ),
      if (widget.config.hasPaymentFilter && _filter.payment.isNotEmpty)
        _FilterChip(
          background: const Color(0xFFFFFBEB),
          foreground: const Color(0xFFB45309),
          label: SecondaryTexts.payments
              .firstWhere((p) => p.$1 == _filter.payment, orElse: () => ('', _filter.payment))
              .$2,
          onRemove: () => _apply(_filter.copyWith(payment: '')),
        ),
    ];

    return Container(
      // py-5 on the site; halved here so the first row of cards starts higher up the screen.
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
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
                  onTap: () => _apply(SecondaryFilter(sort: _filter.sort)),
                  child: Text(
                    SecondaryTexts.resetAll,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.dark.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(child: _sortSelect(context)),
              const SizedBox(width: 12),
              _currencyToggle(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sortSelect(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _filter.sort,
          isExpanded: true,
          icon: const SiteIcon(SiteIcons.chevronDown, size: 16),
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.dark),
          items: [
            for (final (value, label) in SecondaryTexts.sortOptions)
              DropdownMenuItem(value: value, child: Text(label)),
          ],
          onChanged: (value) => value == null ? null : _apply(_filter.copyWith(sort: value)),
        ),
      ),
    );
  }

  /// so'm / $ pair — the same control the site puts beside the sort select.
  Widget _currencyToggle(BuildContext context) {
    final theme = Theme.of(context);
    final currency = CurrencyService.instance;
    Widget option(String value, String label) {
      final active = currency.display == value;
      return Pressable(
        onTap: () => currency.setDisplay(value).then((_) => setState(() {})),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: active ? AppColors.olive : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: active ? AppColors.cream : AppColors.dark.withValues(alpha: 0.6),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [option('uzs', t('secondary.currency')), option('usd', '\$')],
      ),
    );
  }

  Widget _results(BuildContext context) {
    return FutureBuilder<Paginated<PropertyListing>>(
      future: _future,
      builder: (context, snapshot) {
        // Yangi so'rov ketayotganda eski ro'yxat qoladi; spinner faqat birinchi yuklashda.
        final page = snapshot.data ?? _last;
        if (page == null) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Aylanuvchi belgi o'rniga kartalarning o'z shakli — javob kelganda sahifa
            // sakramaydi, chunki joy allaqachon egallangan.
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: PropertyCard.compactAspectRatio,
                children: [for (var i = 0; i < 4; i++) const Pulse(child: PropertyCardSkeleton())],
              ),
            );
          }
          return SliverToBoxAdapter(child: _empty(context));
        }
        if (page.items.isEmpty) {
          return SliverToBoxAdapter(child: _empty(context));
        }
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0), // mt-6
          // Saytda `grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-5`.
          sliver: SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: Bp.pick(context, base: 1, sm: 2, xl: 3),
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              childAspectRatio: Bp.pick(context, base: 3 / 4, sm: PropertyCard.compactAspectRatio),
            ),
            itemCount: page.items.length,
            itemBuilder: (context, i) => Entrance.fadeIn(
              delay: Duration(milliseconds: i * 100),
              child: PropertyCard(
                compact: Bp.isSm(context),
                property: PropertyView.fromListing(
                  page.items[i],
                  // Was hard-coded to 'secondary', so rent cards linked to the wrong detail page.
                  propertyType: widget.config.propertyType,
                ),
              ),
            ),
          ),
        );
      },
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
            SecondaryTexts.noResults,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.config.noResultsDesc,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.dark.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Pressable(
            onTap: () => _apply(SecondaryFilter(sort: _filter.sort)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.olive,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                SecondaryTexts.resetAll,
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Pagination lives under the grid now that the results are a SliverGrid.
  Widget _paginationBlock(BuildContext context) => FutureBuilder<Paginated<PropertyListing>>(
    future: _future,
    builder: (context, snapshot) {
      final page = snapshot.data ?? _last;
      if (page == null || page.items.isEmpty) return const SizedBox.shrink();
      return Padding(padding: const EdgeInsets.only(top: 24), child: _pagination(context, page));
    },
  );

  Widget _pagination(BuildContext context, Paginated<PropertyListing> page) {
    if (page.pages <= 1) return const SizedBox.shrink();
    final theme = Theme.of(context);
    // A window around the current page so long result sets stay one row.
    final from = (page.page - 2).clamp(1, page.pages);
    final to = (from + 4).clamp(1, page.pages);

    Widget button(Widget child, {VoidCallback? onTap, bool active = false}) => Pressable(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: active ? AppColors.olive : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.sm),
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
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          button(
            const SiteIcon(SiteIcons.chevronLeft, size: 16, color: AppColors.dark),
            onTap: page.page > 1 ? () => go(page.page - 1) : null,
          ),
          for (var p = from; p <= to; p++)
            button(
              Text(
                '$p',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: p == page.page ? Colors.white : AppColors.dark,
                  fontWeight: FontWeight.w600,
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
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.dotColor, required this.label});

  final Color dotColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.7)),
        ),
      ],
    );
  }
}

/// `bg-olive/10 text-olive rounded-full` chip with an × — the seller and payment chips override
/// the colours.
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.onRemove,
    this.background,
    this.foreground,
  });

  final String label;
  final VoidCallback onRemove;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = foreground ?? AppColors.olive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background ?? AppColors.olive.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(color: fg, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 6),
          Pressable(
            onTap: onRemove,
            child: SiteIcon(SiteIcons.close, size: 12, color: fg),
          ),
        ],
      ),
    );
  }
}

/// The site's `app-city-select`: region first, then its districts.
class _CitySelect extends StatelessWidget {
  const _CitySelect({
    required this.regions,
    required this.city,
    required this.district,
    required this.onChanged,
  });

  final List<Region> regions;
  final String city;
  final String district;
  final void Function(String city, String district) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = regions.where((r) => r.value == city).firstOrNull;

    Widget dropdown<T>({
      required T? value,
      required String hint,
      required List<DropdownMenuItem<T>> items,
      required ValueChanged<T?> onChangedInner,
    }) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAltLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: Text(
            hint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.dark.withValues(alpha: 0.4),
            ),
          ),
          icon: const SiteIcon(SiteIcons.chevronDown, size: 16),
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.dark),
          items: items,
          onChanged: onChangedInner,
        ),
      ),
    );

    return Column(
      children: [
        dropdown<String>(
          value: city.isEmpty ? null : city,
          hint: SecondaryTexts.allCities,
          items: [
            DropdownMenuItem(value: '', child: Text(SecondaryTexts.allCities)),
            for (final region in regions)
              DropdownMenuItem(value: region.value, child: Text(region.label)),
          ],
          onChangedInner: (value) => onChanged(value ?? '', ''),
        ),
        if (selected != null && selected.districts.isNotEmpty) ...[
          const SizedBox(height: 8),
          dropdown<String>(
            value: district.isEmpty ? null : district,
            hint: SecondaryTexts.anyDistrict,
            items: [
              DropdownMenuItem(value: '', child: Text(SecondaryTexts.anyDistrict)),
              for (final d in selected.districts)
                DropdownMenuItem(value: d.value, child: Text(d.label)),
            ],
            onChangedInner: (value) => onChanged(city, value ?? ''),
          ),
        ],
      ],
    );
  }
}
