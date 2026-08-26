import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/api/media_url.dart';
import '../../core/constants/city_labels.dart';
import '../../core/models/property_listing.dart';
import '../../core/utils/format.dart';
import '../../shared/widgets/my_location_button.dart';
import '../../shared/widgets/app_image.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/site_header.dart';
import '../../shared/widgets/site_icon.dart';
import '../../shared/widgets/yandex_map.dart';
import '../secondary/secondary_repository.dart';
import 'map_search_repository.dart';
import 'map_search_texts.dart';

/// Saytning `/map` sahifasi — `map-search.component.ts`.
///
/// Mobilda sayt ro'yxat va xaritani **yonma-yon emas, navbat bilan** ko'rsatadi: tepadagi
/// tugma ikkisini almashtiradi (`mapViewMobile()`). Filtrlar ham yopiq turadi, "Filterlar"
/// tugmasi bilan ochiladi (`filtersExpanded()`).
class MapSearchScreen extends StatefulWidget {
  const MapSearchScreen({super.key});

  @override
  State<MapSearchScreen> createState() => _MapSearchScreenState();
}

class _MapSearchScreenState extends State<MapSearchScreen> {
  static const _repo = MapSearchRepository();
  static const _secondary = SecondaryRepository();
  static const _rent = SecondaryRepository(endpoint: '/market/rent');

  String _city = 'tashkent_city';
  String _dealType = ''; // '' | rent | sell
  String _type = '';
  int _rooms = 0;

  bool _filtersOpen = false;
  bool _mapView = true;
  bool _loading = true;
  bool _failed = false;

  List<MapMarker> _markers = const [];
  List<MapCluster> _clusters = const [];

  /// Karta va uning turi — "Barchasi" da ro'yxat sotuv va ijaradan aralash keladi.
  List<({PropertyListing item, bool rent})> _cards = const [];
  int _total = 0;
  int _page = 1;
  String? _selectedId;

  static const _emptyPage = Paginated<PropertyListing>.empty();

  MapViewport? _viewport;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Map<String, dynamic> _filters({bool withViewport = true}) => {
    if (_city.isNotEmpty) 'city': _city,
    if (_type.isNotEmpty) 'type': _type,
    if (_rooms > 0) 'rooms': _rooms,
    if (withViewport && _viewport != null) ..._viewport!.toQuery(),
  };

  /// Saytda belgilar va yon ro'yxat alohida so'rovlar bilan yuklanadi.
  Future<void> _load({bool keepCards = false}) async {
    setState(() {
      _loading = true;
      _failed = false;
      if (!keepCards) _page = 1;
    });

    final wantSell = _dealType.isEmpty || _dealType == 'sell';
    final wantRent = _dealType.isEmpty || _dealType == 'rent';

    try {
      final results = await Future.wait([
        wantSell ? _repo.points(rent: false, filters: _filters()) : Future.value(const MapPoints()),
        wantRent ? _repo.points(rent: true, filters: _filters()) : Future.value(const MapPoints()),
      ]);

      final markers = <MapMarker>[];
      final clusters = <MapCluster>[];
      for (final result in results) {
        clusters.addAll(result.clusters);
        for (final point in result.points) {
          markers.add(
            MapMarker(
              // Ijara va ikkilamchi `id` lari to'qnashmasligi uchun saytda ham prefiks bor.
              id: '${point.rent ? 'rent' : 'sell'}-${point.id}',
              lat: point.lat,
              lng: point.lng,
              label: _priceLabel(point),
              hint: point.title,
              rent: point.rent,
              selected: _selectedId == '${point.rent ? 'rent' : 'sell'}-${point.id}',
            ),
          );
        }
      }

      // Saytda xaritada yangi qurilish loyihalari ham belgi bo'lib turadi.
      for (final project in await _repo.projects()) {
        markers.add(
          MapMarker(
            id: 'project-${project.id}',
            lat: project.lat,
            lng: project.lng,
            label: project.price > 0 ? _shortPrice(project.price) : project.title,
            hint: project.title,
            selected: _selectedId == 'project-${project.id}',
          ),
        );
      }

      // Saytda "Barchasi" tanlansa ikkala ro'yxat parallel so'raladi va aralashtiriladi.
      // Sahifa hajmi `SecondaryRepository.perPage` — ilovadagi boshqa ro'yxatlar bilan bir xil.
      final listFilter = SecondaryFilter(
        city: _city,
        types: _type.isEmpty ? const [] : [_type],
        rooms: _rooms == 0 ? const [] : [_rooms],
        page: _page,
      );
      final lists = await Future.wait([
        if (wantSell) _secondary.list(listFilter) else Future.value(_emptyPage),
        if (wantRent) _rent.list(listFilter) else Future.value(_emptyPage),
      ]);

      final fresh = <({PropertyListing item, bool rent})>[
        for (final item in lists[0].items) (item: item, rent: false),
        for (final item in lists[1].items) (item: item, rent: true),
      ];

      if (!mounted) return;
      setState(() {
        _markers = markers;
        _clusters = clusters;
        _cards = keepCards ? [..._cards, ...fresh] : fresh;
        _total = lists[0].total + lists[1].total;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  /// Saytdagi `formatPriceLabel` — so'mda sotuv "mln/mlrd", ijara to'liq raqam.
  /// Loyiha belgisidagi narx — "N mlrd" / "N mln".
  String _shortPrice(num value) {
    if (value >= 1000000000) return '${(value / 1000000000).toStringAsFixed(1)} mlrd';
    return '${(value / 1000000).toStringAsFixed(0)} mln';
  }

  String _priceLabel(MapPoint point) {
    final value = point.price;
    if (point.rent) return formatNumber(value);
    if (value >= 1000000000) return '${(value / 1000000000).toStringAsFixed(1)} mlrd';
    return '${(value / 1000000).toStringAsFixed(0)} mln';
  }

  void _apply() {
    _viewport = null;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAltLight,
      body: Column(
        children: [
          // Sahifa `h-screen pt-16` — header qat'iy emas, tepada o'z joyini egallaydi.
          const SiteHeader(showSearch: false),
          _filterBar(),
          Expanded(child: _mapView ? _map() : _list()),
        ],
      ),
    );
  }

  // ── filtrlar paneli ────────────────────────────────────────────────────────

  Widget _filterBar() {
    final theme = Theme.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // px-4 py-3
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _cityPicker()),
              const SizedBox(width: 8), // gap-2
              _barButton(
                MapSearchTexts.filters,
                active: _filtersOpen,
                onTap: () => setState(() => _filtersOpen = !_filtersOpen),
              ),
              const SizedBox(width: 8),
              Pressable(
                scale: 0.95, // active:scale-95
                onTap: () => setState(() => _mapView = !_mapView),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.olive,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    _mapView ? MapSearchTexts.showList : MapSearchTexts.showMap,
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
          if (_filtersOpen) ...[
            const SizedBox(height: 12), // mt-3
            _dealTypeTabs(),
            const SizedBox(height: 12),
            _typeChips(),
            const SizedBox(height: 12),
            _roomChips(),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${_markers.length} ${MapSearchTexts.results}',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 12,
                color: AppColors.dark.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cityPicker() {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceAltLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _city,
            isDense: true,
            isExpanded: true,
            icon: SiteIcon(
              SiteIcons.chevronDown,
              size: 14,
              color: AppColors.dark.withValues(alpha: 0.4),
            ),
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14, color: AppColors.dark),
            items: [
              const DropdownMenuItem(value: '', child: Text(MapSearchTexts.allCities)),
              for (final (code, label) in CityLabels.options)
                DropdownMenuItem(value: code, child: Text(label)),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _city = value);
              _apply();
            },
          ),
        ),
      ),
    );
  }

  Widget _barButton(String label, {required bool active, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return Pressable(
      scale: 0.98,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // px-3 py-2
        decoration: BoxDecoration(
          color: active ? AppColors.olive : AppColors.surfaceAltLight,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: active ? AppColors.olive : AppColors.borderLight),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: active ? Colors.white : AppColors.dark.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  /// `bg-gray-100 rounded-xl p-0.5` ichidagi uchta tugma — tanlangani oq.
  Widget _dealTypeTabs() {
    final theme = Theme.of(context);
    Widget tab(String value, String label) {
      final active = _dealType == value;
      return Expanded(
        child: Pressable(
          scale: 0.98,
          onTap: () {
            setState(() => _dealType = value);
            _apply();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6), // py-1.5
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              boxShadow: active ? const [BoxShadow(color: Color(0x14000000), blurRadius: 3)] : null,
            ),
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: active ? AppColors.dark : AppColors.dark.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(2), // p-0.5
      decoration: BoxDecoration(
        color: AppColors.surfaceMutedLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          tab('', MapSearchTexts.all),
          tab('rent', MapSearchTexts.rent),
          tab('sell', MapSearchTexts.sell),
        ],
      ),
    );
  }

  Widget _typeChips() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final (value, label) in MapSearchTexts.propertyTypes) ...[
          _chip(
            label,
            active: _type == value,
            onTap: () {
              setState(() => _type = _type == value ? '' : value);
              _apply();
            },
          ),
          const SizedBox(width: 6),
        ],
      ],
    ),
  );

  Widget _roomChips() => Row(
    children: [
      for (final count in [0, 1, 2, 3, 4]) ...[
        _chip(
          count == 0 ? MapSearchTexts.anyRooms : '$count',
          active: _rooms == count,
          onTap: () {
            setState(() => _rooms = count);
            _apply();
          },
        ),
        const SizedBox(width: 6),
      ],
    ],
  );

  Widget _chip(String label, {required bool active, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return Pressable(
      scale: 0.98,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), // px-2.5 py-1.5
        decoration: BoxDecoration(
          color: active ? Colors.white : AppColors.surfaceMutedLight,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          boxShadow: active ? const [BoxShadow(color: Color(0x14000000), blurRadius: 3)] : null,
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: active ? AppColors.dark : AppColors.dark.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  /// `w-10 h-10 bg-white rounded-xl shadow-lg` — xarita ustidagi tugma.
  Widget _mapControl(SiteIconData icon, VoidCallback onTap, {bool rotate = false}) => Pressable(
    onTap: onTap,
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.surfaceMutedLight),
        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 10)],
      ),
      child: Center(
        child: rotate
            // Kichraytirish belgisi — chiziq (saytda `minus`).
            ? Container(width: 16, height: 2, color: AppColors.dark)
            : SiteIcon(icon, size: 18, color: AppColors.dark),
      ),
    ),
  );

  // ── xarita ─────────────────────────────────────────────────────────────────

  final _mapKey = GlobalKey<YandexMapViewState>();
  bool _satellite = false;

  Widget _map() => Stack(
    children: [
      Positioned.fill(
        child: YandexMapView(
          key: _mapKey,
          markers: _markers,
          clusters: _clusters,
          onMarkerTap: (id) => setState(() {
            _selectedId = id;
            _mapView = false; // saytda karta chiqadi; mobilda ro'yxatga o'tish tabiiyroq
          }),
          onViewportChanged: (latMin, latMax, lngMin, lngMax, zoom) {
            // Sayt xarita to'xtagach shu chegaralar bilan qayta so'raydi.
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 300), () {
              _viewport = MapViewport(
                latMin: latMin,
                latMax: latMax,
                lngMin: lngMin,
                lngMax: lngMax,
                zoom: zoom,
              );
              _load();
            });
          },
        ),
      ),
      // Saytdagi "Map Controls" — o'ng yuqorida to'rtta tugma.
      Positioned(
        top: 16, // top-4 right-4
        right: 16,
        child: Column(
          children: [
            _mapControl(SiteIcons.plus, () => _mapKey.currentState?.zoomIn()),
            const SizedBox(height: 8), // gap-2
            _mapControl(SiteIcons.close, () => _mapKey.currentState?.zoomOut(), rotate: true),
            const SizedBox(height: 8),
            _mapControl(SiteIcons.map, () => _mapKey.currentState?.resetMap()),
            const SizedBox(height: 8),
            _mapControl(SiteIcons.globe, () {
              setState(() => _satellite = !_satellite);
              _mapKey.currentState?.setMapType(_satellite ? 'satellite' : 'map');
            }),
          ],
        ),
      ),
      // Saytda `absolute bottom-52 left-4` — xarita faqat ko'rinishni siljitadi.
      Positioned(
        bottom: 208,
        left: 16,
        child: MyLocationButton(onLocated: (lat, lng) => _mapKey.currentState?.centerOn(lat, lng)),
      ),
      if (_loading)
        Positioned(
          top: 12,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 6)],
              ),
              child: Text(
                MapSearchTexts.loadingMarkers,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 12,
                  color: AppColors.dark.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        ),
    ],
  );

  // ── ro'yxat ────────────────────────────────────────────────────────────────

  Widget _list() {
    if (_failed) return _errorBox();
    if (_loading && _cards.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.olive));
    }
    if (_cards.isEmpty) return _emptyBox();

    return ListView.separated(
      padding: const EdgeInsets.all(12), // p-3
      itemCount: _cards.length + (_cards.length < _total ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 8), // space-y-2
      itemBuilder: (context, index) {
        if (index == _cards.length) return _loadMore();
        return _card(_cards[index]);
      },
    );
  }

  Widget _card(({PropertyListing item, bool rent}) card) {
    final theme = Theme.of(context);
    final item = card.item;
    final rent = card.rent;
    final image = absoluteMediaUrl(item.images.firstOrNull);
    return Pressable(
      scale: 0.99,
      onTap: () => context.go('/property/${rent ? 'rent' : 'secondary'}/${item.id}'),
      child: Container(
        padding: const EdgeInsets.all(12), // p-3
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: SizedBox(
                width: 112, // w-28
                height: 96, // h-24
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: image != null && image.isNotEmpty
                          ? AppImage(imageUrl: image, fit: BoxFit.cover)
                          : const ColoredBox(color: AppColors.surfaceMutedLight),
                    ),
                    Positioned(
                      bottom: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: rent ? const Color(0xFF3B82F6) : AppColors.olive,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          rent ? MapSearchTexts.rent : MapSearchTexts.sell,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10, // text-[10px]
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12), // gap-3
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      text: formatNumber(item.price),
                      children: [
                        TextSpan(
                          text: ' ${rent ? MapSearchTexts.perMonth : MapSearchTexts.som}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.dark.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 4), // mt-1
                  Text(
                    (item.district?.isNotEmpty ?? false)
                        ? item.district!
                        : CityLabels.label(item.city),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 12,
                      color: AppColors.dark.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 8), // mt-2
                  Text(
                    '${item.rooms} ${MapSearchTexts.roomShort}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 12,
                      color: AppColors.dark.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadMore() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Pressable(
      scale: 0.98,
      onTap: () {
        _page++;
        _load(keepCards: true);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Text(
          _loading ? MapSearchTexts.loadingMarkers : MapSearchTexts.loadMore,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.dark.withValues(alpha: 0.7),
          ),
        ),
      ),
    ),
  );

  Widget _emptyBox() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32), // px-8
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              MapSearchTexts.noResults,
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 18, // text-lg
                fontWeight: FontWeight.w600,
                color: AppColors.dark.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 4), // mb-1
            Text(
              MapSearchTexts.noResultsDesc,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                color: AppColors.dark.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorBox() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, // w-16 h-16
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFFEF2F2), // bg-red-50
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: SiteIcon(SiteIcons.alertCircle, size: 28, color: Color(0xFFDC2626)),
              ),
            ),
            const SizedBox(height: 16), // mb-4
            Text(
              MapSearchTexts.loadError,
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.dark.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 12), // mt-3
            Pressable(
              scale: 0.98,
              onTap: _apply,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.olive,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  MapSearchTexts.retry,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
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
}
