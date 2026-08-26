import '../../core/i18n/translate.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../shared/widgets/app_image.dart';
import '../../app/theme.dart';
import '../../core/api/media_url.dart';
import '../../core/models/property_listing.dart';
import '../../core/services/favorites_service.dart';
import '../../core/services/currency_service.dart';
import '../../shared/utils/breakpoints.dart';
import '../../shared/widgets/amenities_grid.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/property_contact_card.dart';
import '../../shared/widgets/property_location_map.dart';
import '../../shared/widgets/property_tours_card.dart';
import '../../shared/widgets/report_modal.dart';
import '../../shared/widgets/site_toast.dart';
import '../../shared/widgets/site_header.dart';
import '../../shared/widgets/site_icon.dart';
import '../../core/api/api_client.dart';
import 'secondary_repository.dart';

/// `/property/secondary/:id` — the site's `secondary-detail` page.
///
/// Order from the template: breadcrumb, title with address, the badge row, the three action
/// buttons, the photo gallery, the olive gradient price card with its three stat boxes, key
/// facts, description, amenities, and the owner's contact card.
class SecondaryDetailScreen extends StatefulWidget {
  const SecondaryDetailScreen({super.key, required this.id});

  final int id;

  @override
  State<SecondaryDetailScreen> createState() => _SecondaryDetailScreenState();
}

class _SecondaryDetailScreenState extends State<SecondaryDetailScreen> {
  final _repo = SecondaryRepository();
  final _scroll = ScrollController();

  late final Future<PropertyListing?> _future = _load();
  bool _scrolled = false;
  late bool _favorite = FavoritesService.instance.isFavorite(widget.id, 'secondary');
  List<PropertyListing> _similar = const [];

  /// Saytda e'lon ochilgach ikkita qo'shimcha ish bo'ladi: o'xshash e'lonlar
  /// yuklanadi va (kirgan foydalanuvchi uchun) ko'rish qayd etiladi.
  Future<PropertyListing?> _load() async {
    final property = await _repo.byId(widget.id);
    if (property != null) {
      unawaited(_loadSimilar(property));
      unawaited(_recordView(property.id));
    }
    return property;
  }

  Future<void> _loadSimilar(PropertyListing p) async {
    try {
      final items = await _repo.similar(type: p.type, city: p.city);
      if (!mounted) return;
      setState(() {
        _similar = items.where((x) => x.id != p.id).take(4).toList();
      });
    } catch (_) {
      // Saytda ham xatolik jim yutiladi — bo'lim shunchaki chizilmaydi.
    }
  }

  Future<void> _recordView(int id) async {
    if (!await ApiClient.instance.isLoggedIn) return;
    try {
      await ApiClient.instance.post<dynamic>(
        '/market/cabinet/views',
        data: {'property_id': id, 'property_type': 'secondary'},
      );
    } catch (_) {}
  }

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
    super.dispose();
  }

  /// Saytda sevimlilar serverda saqlanadi (`FavoritesService`).
  Future<void> _toggleFavorite(int id) async {
    final result = await FavoritesService.instance.toggle(id, 'secondary');
    if (!mounted) return;
    if (result == null) {
      context.push('/login');
      return;
    }
    setState(() => _favorite = result);
    showSiteToast(
      context,
      result ? "❤ Sevimlilarga qo'shildi" : 'Sevimlilardan olib tashlandi',
      kind: result ? ToastKind.success : ToastKind.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAltLight, // bg-gray-50
      body: Stack(
        children: [
          FutureBuilder<PropertyListing?>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final property = snapshot.data;
              if (property == null) return _notFound(context);
              return _body(context, property);
            },
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            // Detal yo'li `/property/secondary/:id` — `ownSearchRoutes` ga tushmaydi,
            // shuning uchun header qidiruvi ko'rinadi.
            child: SiteHeader(
              scrolled: _scrolled,
              onSearch: (q) => context.go('/secondary?search=$q'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _notFound(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t('detail.notFound'),
              style: theme.textTheme.displaySmall?.copyWith(fontSize: 24, color: AppColors.dark),
            ),
            const SizedBox(height: 8),
            Text(
              t('detail.notFoundDesc'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.dark.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.olive),
              onPressed: () => context.go('/secondary'),
              child: Text(t('detail.backToList')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, PropertyListing p) {
    final theme = Theme.of(context);
    return ListView(
      controller: _scroll,
      padding: EdgeInsets.fromLTRB(
        16,
        124 + MediaQuery.paddingOf(context).top, // pt-20; header qidiruv qatori bilan keladi
        16,
        48,
      ),
      children: [
        _breadcrumb(context, p),
        const SizedBox(height: 16), // mb-4

        Text(
          p.title,
          style: theme.textTheme.displaySmall?.copyWith(
            fontSize: 24, // text-2xl
            color: AppColors.dark,
          ),
        ),
        const SizedBox(height: 8), // mb-2
        Row(
          children: [
            SiteIcon(SiteIcons.mapPin, size: 14, color: AppColors.dark.withValues(alpha: 0.6)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                [p.district, p.address].where((s) => s?.isNotEmpty ?? false).join(', '),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.dark.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12), // mt-3
        _badges(context, p),
        const SizedBox(height: 16),
        _actions(context, p),
        const SizedBox(height: 24), // mb-6

        _Gallery(images: p.images),
        const SizedBox(height: 16), // mt-4

        _priceCard(context, p),
        const SizedBox(height: 16),

        _card(context, t('detail.keyFacts'), _keyFacts(context, p)),
        if (p.description?.isNotEmpty ?? false) ...[
          const SizedBox(height: 16),
          _card(
            context,
            t('detail.aboutTitle'),
            Text(
              p.description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.dark.withValues(alpha: 0.7),
                height: 1.6,
              ),
            ),
          ),
        ],
        if (p.amenities.isNotEmpty) ...[
          const SizedBox(height: 16),
          AmenitiesGrid(amenities: p.amenities, propertyType: p.type),
        ],
        if (PropertyToursCard(
              propertyId: p.id,
              propertyTitle: p.title,
              videoUrl: p.videoUrl,
              videoThumbnail: p.videoThumbnail,
              has360Tour: p.hasVirtualTour,
            )
            case final tours when tours.hasAnyTour) ...[
          const SizedBox(height: 16),
          tours,
        ],
        if (p.lat != null && p.lng != null) ...[
          const SizedBox(height: 16),
          PropertyLocationMap(
            lat: p.lat!,
            lng: p.lng!,
            address: [p.district, p.address].where((s) => s?.isNotEmpty ?? false).join(', '),
            title: p.title,
          ),
        ],
        if (p.owner case final owner?) ...[
          const SizedBox(height: 16),
          PropertyContactCard(
            owner: owner,
            propertyTitle: p.title,
            propertyType: 'secondary',
            propertyId: p.id,
          ),
        ],
        if (_similar.isNotEmpty) ...[const SizedBox(height: 16), _similarBlock(context)],
      ],
    );
  }

  Widget _breadcrumb(BuildContext context, PropertyListing p) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: AppColors.dark.withValues(alpha: 0.5),
    );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Pressable(
            onTap: () => context.go('/'),
            child: Text(t('rent.home'), style: muted),
          ),
          const SizedBox(width: 8),
          const SiteIcon(SiteIcons.chevronRight, size: 12),
          const SizedBox(width: 8),
          Pressable(
            onTap: () => context.go('/secondary'),
            child: Text(t('header.nav.business'), style: muted),
          ),
          const SizedBox(width: 8),
          const SiteIcon(SiteIcons.chevronRight, size: 12),
          const SizedBox(width: 8),
          Text(
            p.title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.dark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Type, 360° tour, balcony and the id — the site's badge row, colours included.
  Widget _badges(BuildContext context, PropertyListing p) {
    final theme = Theme.of(context);
    Widget badge(String label, Color background, Color foreground, {VoidCallback? onTap}) {
      final chip = Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      return onTap == null ? chip : Pressable(scale: 0.97, onTap: onTap, child: chip);
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (p.type case final type?)
          badge(
            _typeLabel(type).toUpperCase(),
            AppColors.olive.withValues(alpha: 0.1),
            AppColors.olive,
          ),
        if (p.hasVirtualTour)
          badge(
            t('tours.360Title'),
            const Color(0xFFEFF6FF), // blue-50
            const Color(0xFF2563EB),
            onTap: () => _open(p.videoUrl),
          ),
        badge('ID: ${p.id}', AppColors.surfaceMutedLight, AppColors.dark.withValues(alpha: 0.6)),
      ],
    );
  }

  /// Favourite, share and report — three 44×44 `rounded-xl` buttons.
  Widget _actions(BuildContext context, PropertyListing p) {
    Widget button(SiteIconData icon, Color color, VoidCallback onTap, {Color? background}) =>
        Pressable(
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: background ?? Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Center(child: SiteIcon(icon, size: 18, color: color)),
          ),
        );

    return Row(
      children: [
        button(
          SiteIcons.heart,
          _favorite ? const Color(0xFFEF4444) : AppColors.dark.withValues(alpha: 0.6),
          () => _toggleFavorite(p.id),
          background: _favorite ? const Color(0xFFFEF2F2) : null,
        ),
        button(SiteIcons.share, AppColors.dark.withValues(alpha: 0.6), () => _share(p)),
        button(
          SiteIcons.xCircle,
          AppColors.dark.withValues(alpha: 0.6),
          () => ReportSheet.show(context, propertyId: p.id, propertyType: 'secondary'),
        ),
      ],
    );
  }

  /// `from-olive to-olive/80 rounded-2xl` card: the price, then rooms / area / floor boxes.
  Widget _priceCard(BuildContext context, PropertyListing p) {
    final theme = Theme.of(context);
    final currency = CurrencyService.instance;

    Widget stat(String value, String label) => Container(
      constraints: const BoxConstraints(minWidth: 80),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: theme.textTheme.titleMedium?.copyWith(color: Colors.white)),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(16), // p-4
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.olive, AppColors.olive.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('detail.price'),
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            p.price == null ? '—' : currency.formatWithSymbol(p.price!, from: p.currency ?? 'uzs'),
            style: theme.textTheme.displaySmall?.copyWith(fontSize: 28, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (p.rooms != null) stat('${p.rooms}', t('secondary.rooms')),
              if (p.area != null) stat('${p.area!.round()} m²', t('detail.area')),
              if (p.floor != null)
                stat(
                  '${p.floor}${p.totalFloors == null ? '' : '/${p.totalFloors}'}',
                  t('rent.floor'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// `bg-white rounded-2xl border p-6` block with a bold heading.
  Widget _card(BuildContext context, String title, Widget child) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24), // p-6
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.surfaceMutedLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 16), // mb-4
          child,
        ],
      ),
    );
  }

  Widget _keyFacts(BuildContext context, PropertyListing p) {
    final theme = Theme.of(context);
    final currency = CurrencyService.instance;
    final facts = <(String, String)>[
      if (p.type case final type?) (t('detail.type'), _typeLabel(type)),
      if (p.rooms != null) (t('secondary.rooms'), '${p.rooms}'),
      if (p.bathrooms != null) (t('rent.bathrooms'), '${p.bathrooms}'),
      if (p.area != null) (t('detail.area'), '${p.area!.round()} m²'),
      if (p.floor != null) (t('rent.floor'), '${p.floor} / ${p.totalFloors ?? ''}'),
      (t('detail.balcony'), p.hasBalcony ? t('common.yes') : t('common.no')),
      if (p.status case final status?) (t('detail.status'), _statusLabel(status)),
      if (p.price != null && (p.area ?? 0) > 0)
        (
          t('detail.pricePerM2'),
          currency.formatWithSymbol(p.price! / p.area!, from: p.currency ?? 'uzs'),
        ),
    ];

    // Saytda `grid-cols-2 md:grid-cols-4` — yorliq tepada, qiymat pastda.
    final columns = Bp.pick(context, base: 2, md: 4);
    final rows = <Widget>[];
    for (var i = 0; i < facts.length; i += columns) {
      final slice = facts.sublist(i, (i + columns).clamp(0, facts.length));
      rows.add(
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : 16), // gap-4
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var c = 0; c < columns; c++) ...[
                if (c > 0) const SizedBox(width: 16),
                Expanded(
                  child: c < slice.length
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              slice[c].$1.toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 12,
                                color: AppColors.dark.withValues(alpha: 0.4),
                              ),
                            ),
                            const SizedBox(height: 4), // mb-1
                            Text(
                              slice[c].$2,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: slice[c].$1 == t('detail.status')
                                    ? (p.status == 'available'
                                          ? const Color(0xFF059669)
                                          : const Color(0xFFD97706))
                                    : AppColors.dark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }

  /// Saytda ulashish tugmasi `navigator.share` ni sinaydi, bo'lmasa havolani
  /// nusxalab "Link nusxalandi" deydi. Ilovada nusxalash qismi qoladi.
  Future<void> _share(PropertyListing p) async {
    await Clipboard.setData(
      ClipboardData(text: 'https://businesshome.uz/property/secondary/${p.id}'),
    );
    if (!mounted) return;
    showSiteToast(context, t('share.linkCopied'));
  }

  /// `detail.similarProperties` — bir xil tur va shahardagi to'rtta e'lon.
  Widget _similarBlock(BuildContext context) {
    final theme = Theme.of(context);
    return _card(
      context,
      t('detail.similarProperties'),
      Column(
        children: [
          for (var i = 0; i < _similar.length; i++) ...[
            if (i > 0) const SizedBox(height: 16), // gap-4
            _similarRow(context, theme, _similar[i]),
          ],
        ],
      ),
    );
  }

  Widget _similarRow(BuildContext context, ThemeData theme, PropertyListing p) {
    final currency = CurrencyService.instance;
    final image = p.images.isEmpty ? null : absoluteMediaUrl(p.images.first);
    return Pressable(
      scale: 0.99,
      onTap: () => context.push('/property/secondary/${p.id}'),
      child: Container(
        padding: const EdgeInsets.all(12), // p-3
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.md)),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: SizedBox(
                width: 96, // w-24
                height: 80, // h-20
                child: image == null || image.isEmpty
                    ? const ColoredBox(color: AppColors.surfaceMutedLight)
                    : AppImage(imageUrl: image, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12), // gap-3
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 4), // mt-1
                  Text(
                    p.price == null
                        ? '—'
                        : currency.formatWithSymbol(p.price!, from: p.currency ?? 'uzs'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.olive,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${p.rooms ?? ''} x',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                          color: AppColors.dark.withValues(alpha: 0.5),
                        ),
                      ),
                      _dot(),
                      Text(
                        '${p.area?.round() ?? ''} m²',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                          color: AppColors.dark.withValues(alpha: 0.5),
                        ),
                      ),
                      if (p.district case final district?) ...[
                        _dot(),
                        Flexible(
                          child: Text(
                            district,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 11,
                              color: AppColors.dark.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ],
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

  Widget _dot() => Container(
    width: 2,
    height: 2,
    margin: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(color: AppColors.dark.withValues(alpha: 0.2), shape: BoxShape.circle),
  );

  static String _typeLabel(String type) => switch (type) {
    'apartment' => t('secondary.type.apartment'),
    'house' => t('secondary.type.house'),
    'office' => t('secondary.type.office'),
    'shop' => t('secondary.type.shop'),
    'building' => t('secondary.type.building'),
    'land' => t('rent.typeLand'),
    _ => type,
  };

  static String _statusLabel(String status) => switch (status) {
    'available' => t('detail.statusValue.available'),
    'reserved' => t('detail.statusValue.reserved'),
    'sold' => t('detail.statusValue.sold'),
    _ => status,
  };

  static Future<void> _open(String? url) async {
    final uri = Uri.tryParse(url ?? '');
    if (uri != null && uri.hasScheme) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// The site's `app-property-gallery`: a swipeable 4:3 strip with a counter.
class _Gallery extends StatefulWidget {
  const _Gallery({required this.images});

  final List<String> images;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final images = [for (final image in widget.images) ?absoluteMediaUrl(image)];
    if (images.isEmpty) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: images.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => AppImage(
                imageUrl: images[i],
                fit: BoxFit.cover,
                placeholder: (_, _) => const ColoredBox(color: AppColors.surfaceMutedLight),
                errorWidget: (_, _, _) => const ColoredBox(color: AppColors.surfaceMutedLight),
              ),
            ),
            if (images.length > 1)
              Positioned(
                right: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.dark.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '${_index + 1}/${images.length}',
                    style: theme.textTheme.labelSmall?.copyWith(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
