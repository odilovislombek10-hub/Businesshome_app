import '../../core/i18n/translate.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/constants/city_labels.dart';
import '../../core/services/currency_service.dart';
import '../../core/utils/format.dart';
import '../../shared/utils/breakpoints.dart';
import '../../shared/widgets/app_image.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/site_footer_section.dart';
import '../../shared/widgets/site_header.dart';
import '../../shared/widgets/site_icon.dart';
import 'ads_repository.dart';
import 'ads_texts.dart';

/// Saytning `/ads` sahifasi — `ads.component.ts`.
///
/// Tartib: rasm fonli sarlavha (qidiruv va shahar tanlash bilan), bitim turi
/// yorliqlari, faol filtrlar qatori va saralash, so'ng filtrlar paneli (mobilda
/// ro'yxat ustida) va e'lonlar to'ri.
class AdsScreen extends StatefulWidget {
  const AdsScreen({super.key});

  @override
  State<AdsScreen> createState() => _AdsScreenState();
}

class _AdsScreenState extends State<AdsScreen> {
  static const _repo = AdsRepository();

  final _scroll = ScrollController();
  final _search = TextEditingController();
  final _priceMin = TextEditingController();
  final _priceMax = TextEditingController();

  AdFilter _filter = const AdFilter();
  late Future<AdsPage> _future = _repo.list(_filter);
  bool _scrolled = false;

  static List<(String, String)> get _dealTypes => <(String, String)>[
    ('', AdsTexts.allDeals),
    ('sell', AdsTexts.dealSell),
    ('rent', AdsTexts.dealRent),
    ('exchange', AdsTexts.dealExchange),
  ];

  static List<String> get _types => <String>['apartment', 'house', 'office', 'shop', 'land'];
  static List<int> get _roomOptions => <int>[1, 2, 3, 4, 5];

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
    _scroll.dispose();
    _search.dispose();
    _priceMin.dispose();
    _priceMax.dispose();
    super.dispose();
  }

  void _apply(AdFilter next) {
    setState(() {
      _filter = next.page == _filter.page ? next.copyWith(page: 1) : next;
      _future = _repo.list(_filter);
    });
  }

  void _reset() {
    _search.clear();
    _priceMin.clear();
    _priceMax.clear();
    _apply(AdFilter(dealType: _filter.dealType));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAltLight, // bg-gray-50
      body: Stack(
        children: [
          FutureBuilder<AdsPage>(
            future: _future,
            builder: (context, snapshot) {
              final page = snapshot.data ?? const AdsPage.empty();
              final loading = snapshot.connectionState == ConnectionState.waiting;
              return ListView(
                controller: _scroll,
                padding: EdgeInsets.zero,
                children: [
                  _hero(page.total),
                  _dealTabs(),
                  _filterBar(page.total),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 0), // mt-6
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sidebar(),
                        const SizedBox(height: 32), // gap-8
                        if (page.items.isEmpty && !loading) _empty() else _grid(page.items),
                        if (page.pages > 1) ...[
                          const SizedBox(height: 48), // mt-12
                          _pagination(page.pages),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 64), // pb-16
                  const SiteFooterSection(),
                ],
              );
            },
          ),
          SiteHeader(scrolled: _scrolled),
        ],
      ),
    );
  }

  // ── sarlavha ───────────────────────────────────────────────────────────────

  Widget _hero(int total) {
    final theme = Theme.of(context);
    // Balandlik mazmunga qarab o'sadi — saytda ham `py-12` bilan cho'ziladi.
    return Stack(
      children: [
        Positioned.fill(
          child: Stack(
            fit: StackFit.expand,
            children: [
              const AppImage(
                imageUrl:
                    'https://images.unsplash.com/photo-1600585154526-990dced4db0d?w=1920&q=80',
                fit: BoxFit.cover,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
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
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 112, 16, 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AdsTexts.heroTitle,
                style: theme.textTheme.displaySmall?.copyWith(
                  // `text-3xl md:text-5xl`
                  fontSize: Bp.pick(context, base: 30.0, md: 48.0),
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12), // mb-3
              Text(
                AdsTexts.heroDesc,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 18, // text-lg
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 32), // mb-8
              _searchBar(theme),
              const SizedBox(height: 32), // mt-8
              Row(
                children: [
                  _stat(theme, const Color(0xFF34D399), '$total ${AdsTexts.activeListings}'),
                  const SizedBox(width: 24), // gap-6
                  _stat(theme, AppColors.olive, AdsTexts.updatedToday),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stat(ThemeData theme, Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 8), // gap-2
      Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: 14,
          color: Colors.white.withValues(alpha: 0.7),
        ),
      ),
    ],
  );

  Widget _searchBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(8), // p-2
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 8),
              SiteIcon(SiteIcons.search, size: 20, color: AppColors.dark.withValues(alpha: 0.4)),
              Expanded(
                child: TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value) => _apply(_filter.copyWith(search: value.trim())),
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: AdsTexts.searchPlaceholder,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8), // gap-2
          _citySelect(theme),
        ],
      ),
    );
  }

  Widget _citySelect(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceAltLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _filter.city,
          isExpanded: true,
          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14, color: AppColors.dark),
          items: [
            DropdownMenuItem(value: '', child: Text(AdsTexts.allCities)),
            for (final (value, label) in CityLabels.options)
              if (value.isNotEmpty) DropdownMenuItem(value: value, child: Text(label)),
          ],
          onChanged: (value) => _apply(_filter.copyWith(city: value ?? '')),
        ),
      ),
    );
  }

  // ── bitim turi yorliqlari ──────────────────────────────────────────────────

  Widget _dealTabs() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20), // py-5
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          padding: const EdgeInsets.all(4), // p-1
          decoration: BoxDecoration(
            color: AppColors.surfaceAltLight,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              for (final (value, label) in _dealTypes)
                Pressable(
                  onTap: () => _apply(_filter.copyWith(dealType: value)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: _filter.dealType == value ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _filter.dealType == value
                            ? AppColors.dark
                            : AppColors.dark.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── faol filtrlar va saralash ──────────────────────────────────────────────

  Widget _filterBar(int total) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8, // gap-2
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (_filter.city.isNotEmpty)
                _tag(
                  theme,
                  CityLabels.label(_filter.city),
                  () => _apply(_filter.copyWith(city: '')),
                ),
              if (_filter.type.isNotEmpty)
                _tag(
                  theme,
                  AdsTexts.typeLabel(_filter.type),
                  () => _apply(_filter.copyWith(type: '')),
                ),
              if (_filter.rooms > 0)
                _tag(
                  theme,
                  '${_filter.rooms == 5 ? '5+' : _filter.rooms} ${AdsTexts.roomShort}',
                  () => _apply(_filter.copyWith(rooms: 0)),
                ),
              if (_filter.agentOnly)
                _tag(
                  theme,
                  AdsTexts.withAgent,
                  () => _apply(_filter.copyWith(agentOnly: false)),
                  background: const Color(0xFFEFF6FF),
                  color: const Color(0xFF2563EB),
                ),
              if (_filter.hasActive)
                Pressable(
                  onTap: _reset,
                  child: Text(
                    AdsTexts.resetAll,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: AppColors.dark.withValues(alpha: 0.5),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16), // gap-4
          Row(
            children: [
              Expanded(
                child: Text(
                  '$total ${AdsTexts.resultsFound}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    color: AppColors.dark.withValues(alpha: 0.5),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _filter.sort,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: AppColors.dark,
                    ),
                    items: [
                      DropdownMenuItem(value: 'newest', child: Text(AdsTexts.sortNewest)),
                      DropdownMenuItem(value: 'price_asc', child: Text(AdsTexts.sortPriceAsc)),
                      DropdownMenuItem(value: 'price_desc', child: Text(AdsTexts.sortPriceDesc)),
                      DropdownMenuItem(value: 'area_desc', child: Text(AdsTexts.sortAreaDesc)),
                    ],
                    onChanged: (value) => _apply(_filter.copyWith(sort: value ?? 'newest')),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tag(
    ThemeData theme,
    String label,
    VoidCallback onRemove, {
    Color? background,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // px-3 py-1.5
      decoration: BoxDecoration(
        color: background ?? AppColors.olive.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color ?? AppColors.olive,
            ),
          ),
          const SizedBox(width: 6), // gap-1.5
          Pressable(
            onTap: onRemove,
            child: SiteIcon(SiteIcons.close, size: 12, color: color ?? AppColors.olive),
          ),
        ],
      ),
    );
  }

  // ── filtrlar paneli ────────────────────────────────────────────────────────

  Widget _sidebar() {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.surfaceMutedLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), // px-6 py-4
            decoration: BoxDecoration(
              color: AppColors.surfaceAltLight.withValues(alpha: 0.5),
              border: Border(bottom: BorderSide(color: AppColors.surfaceMutedLight)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    AdsTexts.filters,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.dark,
                    ),
                  ),
                ),
                if (_filter.hasActive)
                  Pressable(
                    onTap: _reset,
                    child: Text(
                      AdsTexts.resetAll,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.olive,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24), // p-6
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sidebarLabel(theme, AdsTexts.propertyType),
                _typeGrid(theme),
                _divider(),
                _sidebarLabel(theme, AdsTexts.rooms),
                Row(
                  children: [
                    for (final room in _roomOptions) ...[
                      if (room != _roomOptions.first) const SizedBox(width: 8),
                      Expanded(child: _roomChip(theme, room)),
                    ],
                  ],
                ),
                _divider(),
                _sidebarLabel(theme, AdsTexts.priceRange),
                Row(
                  children: [
                    Expanded(child: _priceField(theme, _priceMin, AdsTexts.from)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '—',
                        style: TextStyle(color: AppColors.dark.withValues(alpha: 0.3)),
                      ),
                    ),
                    Expanded(child: _priceField(theme, _priceMax, AdsTexts.to)),
                  ],
                ),
                const SizedBox(height: 8), // mt-2
                Text(
                  AdsTexts.priceUnit,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 12,
                    color: AppColors.dark.withValues(alpha: 0.3),
                  ),
                ),
                _divider(),
                _sidebarLabel(theme, AdsTexts.extras),
                _checkbox(theme, AdsTexts.urgentOnly, _filter.urgentOnly, (value) {
                  _apply(_filter.copyWith(urgentOnly: value));
                }),
                const SizedBox(height: 12), // space-y-3
                _checkbox(theme, AdsTexts.topOnly, _filter.topOnly, (value) {
                  _apply(_filter.copyWith(topOnly: value));
                }),
                const SizedBox(height: 12),
                _checkbox(theme, AdsTexts.ownerOnly, _filter.ownerOnly, (value) {
                  _apply(_filter.copyWith(ownerOnly: value, agentOnly: false));
                }),
                const SizedBox(height: 12),
                _checkbox(theme, AdsTexts.withAgent, _filter.agentOnly, (value) {
                  _apply(_filter.copyWith(agentOnly: value, ownerOnly: false));
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarLabel(ThemeData theme, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12), // mb-3
    child: Text(
      text,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.dark.withValues(alpha: 0.8),
      ),
    ),
  );

  Widget _divider() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24), // space-y-6
    child: Container(height: 1, color: AppColors.surfaceMutedLight),
  );

  Widget _typeGrid(ThemeData theme) {
    final rows = <Widget>[];
    for (var i = 0; i < _types.length; i += 2) {
      rows.add(
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : 8), // gap-2
          child: Row(
            children: [
              Expanded(child: _typeChip(theme, _types[i])),
              const SizedBox(width: 8),
              Expanded(
                child: i + 1 < _types.length
                    ? _typeChip(theme, _types[i + 1])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _typeChip(ThemeData theme, String type) {
    final active = _filter.type == type;
    return Pressable(
      onTap: () => _apply(_filter.copyWith(type: active ? '' : type)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // px-3 py-2.5
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.olive.withValues(alpha: 0.1) : AppColors.surfaceAltLight,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: active ? AppColors.olive.withValues(alpha: 0.3) : Colors.transparent,
          ),
        ),
        child: Text(
          AdsTexts.typeLabel(type),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: active ? AppColors.olive : AppColors.dark.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  Widget _roomChip(ThemeData theme, int room) {
    final active = _filter.rooms == room;
    return Pressable(
      onTap: () => _apply(_filter.copyWith(rooms: active ? 0 : room)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10), // py-2.5
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.olive : AppColors.surfaceAltLight,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Text(
          room == 5 ? '5+' : '$room',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: active ? Colors.white : AppColors.dark.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  Widget _priceField(ThemeData theme, TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
      onSubmitted: (_) => _apply(
        _filter.copyWith(
          priceMin: num.tryParse(_priceMin.text),
          priceMax: num.tryParse(_priceMax.text),
        ),
      ),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.surfaceAltLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
      ),
    );
  }

  Widget _checkbox(ThemeData theme, String label, bool value, ValueChanged<bool> onChanged) {
    return Pressable(
      scale: 0.99,
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: value ? AppColors.olive : Colors.transparent,
              borderRadius: BorderRadius.circular(6), // rounded-md
              border: Border.all(
                color: value ? AppColors.olive : const Color(0xFFD1D5DB),
                width: 2,
              ),
            ),
            child: value
                ? const Center(child: SiteIcon(SiteIcons.check, size: 12, color: Colors.white))
                : null,
          ),
          const SizedBox(width: 12), // gap-3
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              color: AppColors.dark.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  // ── ro'yxat ────────────────────────────────────────────────────────────────

  Widget _empty() {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 96), // py-24
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.surfaceMutedLight),
      ),
      child: Column(
        children: [
          Container(
            width: 80, // w-20
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.surfaceAltLight,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SiteIcon(
                SiteIcons.search,
                size: 32,
                color: AppColors.dark.withValues(alpha: 0.3),
              ),
            ),
          ),
          const SizedBox(height: 20), // mb-5
          Text(
            AdsTexts.noResults,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 20, // text-xl
              fontWeight: FontWeight.w600,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 8), // mb-2
          Text(
            AdsTexts.noResultsDesc,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              color: AppColors.dark.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24), // mb-6
          Pressable(
            onTap: _reset,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.olive,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                AdsTexts.resetAll,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
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

  /// `grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-5`
  Widget _grid(List<AdProperty> items) {
    final columns = Bp.pick(context, base: 1, sm: 2, xl: 3);
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += columns) {
      final slice = items.sublist(i, (i + columns).clamp(0, items.length));
      rows.add(
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : 20), // gap-5
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var c = 0; c < columns; c++) ...[
                if (c > 0) const SizedBox(width: 20),
                Expanded(child: c < slice.length ? _card(slice[c]) : const SizedBox.shrink()),
              ],
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _card(AdProperty ad) {
    final theme = Theme.of(context);
    final currency = CurrencyService.instance;
    return Pressable(
      scale: 0.99,
      onTap: () => context.push('/property/${ad.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.surfaceMutedLight),
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
                  if (ad.images.isEmpty)
                    const ColoredBox(color: AppColors.surfaceAltLight)
                  else
                    AppImage(imageUrl: ad.images.first, fit: BoxFit.cover),
                  Positioned(
                    top: 12, // top-3 left-3
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: currency.format(ad.price, from: ad.currency),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.dark,
                              ),
                            ),
                            TextSpan(
                              text:
                                  ' ${ad.dealType == 'rent' ? AdsTexts.perMonth : AdsTexts.currency}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 12,
                                color: AppColors.dark.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Row(
                      children: [
                        if (ad.isUrgent)
                          _imageBadge(theme, AdsTexts.urgent, const Color(0xFFEF4444)),
                        if (ad.isUrgent && ad.isTop) const SizedBox(width: 8),
                        if (ad.isTop) _imageBadge(theme, t('ads.top'), const Color(0xFFF59E0B)),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: Row(
                      children: [
                        _imageBadge(
                          theme,
                          AdsTexts.dealLabel(ad.dealType),
                          ad.dealType == 'rent'
                              ? const Color(0xFF2563EB)
                              : ad.dealType == 'exchange'
                              ? const Color(0xFF7C3AED)
                              : AppColors.olive,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.dark.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            '${ad.images.length}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16), // p-4
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ad.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 8), // mb-2
                  Text(
                    '${ad.district}, ${CityLabels.label(ad.city)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: AppColors.dark.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 12), // mb-3
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12), // py-3
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: AppColors.surfaceMutedLight)),
                    ),
                    child: Row(
                      children: [
                        if (ad.type != 'land') ...[
                          Expanded(child: _feature(theme, '${ad.rooms}', AdsTexts.roomShort)),
                          _featureDivider(),
                          Expanded(
                            child: _feature(theme, '${ad.bathrooms}', AdsTexts.bathroomShort),
                          ),
                          _featureDivider(),
                        ],
                        Expanded(child: _feature(theme, formatNumber(ad.area), 'm²')),
                        if (ad.type != 'land') ...[
                          _featureDivider(),
                          Expanded(
                            child: _feature(
                              theme,
                              '${ad.floor}/${ad.totalFloors}',
                              AdsTexts.floorShort,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12), // mt-3
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 6, // gap-1.5
                          runSpacing: 6,
                          children: [
                            for (final amenity in ad.amenities.take(2))
                              _amenityTag(theme, AdsTexts.amenityLabel(amenity)),
                            if (ad.amenities.length > 2)
                              _amenityTag(theme, '+${ad.amenities.length - 2}'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8), // ml-2
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: ad.ownerType == 'owner'
                              ? const Color(0xFFECFDF5)
                              : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          ad.ownerType == 'owner' ? AdsTexts.ownerBadge : AdsTexts.agentBadge,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: ad.ownerType == 'owner'
                                ? const Color(0xFF059669)
                                : const Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageBadge(ThemeData theme, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(AppRadius.sm),
    ),
    child: Text(
      label,
      style: theme.textTheme.labelSmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
  );

  Widget _feature(ThemeData theme, String value, String label) => Column(
    children: [
      Text(
        value,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.dark,
        ),
      ),
      Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: 11,
          color: AppColors.dark.withValues(alpha: 0.4),
        ),
      ),
    ],
  );

  Widget _featureDivider() => Container(
    width: 1,
    height: 32, // h-8
    color: AppColors.surfaceMutedLight,
  );

  Widget _amenityTag(ThemeData theme, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: AppColors.surfaceAltLight,
      borderRadius: BorderRadius.circular(AppRadius.sm),
    ),
    child: Text(
      label,
      style: theme.textTheme.labelSmall?.copyWith(
        fontSize: 11,
        color: AppColors.dark.withValues(alpha: 0.5),
      ),
    ),
  );

  // ── sahifalash ─────────────────────────────────────────────────────────────

  Widget _pagination(int pages) {
    final theme = Theme.of(context);
    final current = _filter.page;
    final numbers = <int>[
      for (var i = 1; i <= pages; i++)
        if (i == 1 || i == pages || (i - current).abs() <= 1) i,
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _pageButton(
          theme,
          child: const SiteIcon(SiteIcons.chevronLeft, size: 18, color: AppColors.dark),
          enabled: current > 1,
          onTap: () => _apply(_filter.copyWith(page: current - 1)),
        ),
        for (final page in numbers) ...[
          const SizedBox(width: 6), // gap-1.5
          _pageButton(
            theme,
            child: Text(
              '$page',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: page == current ? Colors.white : AppColors.dark.withValues(alpha: 0.6),
              ),
            ),
            active: page == current,
            onTap: () => _apply(_filter.copyWith(page: page)),
          ),
        ],
        const SizedBox(width: 6),
        _pageButton(
          theme,
          child: const SiteIcon(SiteIcons.chevronRight, size: 18, color: AppColors.dark),
          enabled: current < pages,
          onTap: () => _apply(_filter.copyWith(page: current + 1)),
        ),
      ],
    );
  }

  Widget _pageButton(
    ThemeData theme, {
    required Widget child,
    required VoidCallback onTap,
    bool enabled = true,
    bool active = false,
  }) {
    return Opacity(
      opacity: enabled ? 1 : 0.3,
      child: Pressable(
        onTap: enabled ? onTap : () {},
        child: Container(
          width: 40, // w-10
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.olive : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: active ? null : Border.all(color: AppColors.borderLight),
          ),
          child: child,
        ),
      ),
    );
  }
}
