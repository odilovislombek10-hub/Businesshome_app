import '../../core/i18n/translate.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/api/api_client.dart';
import '../../core/api/media_url.dart';
import '../../core/models/property_listing.dart';
import '../../core/services/favorites_service.dart';
import '../../core/services/currency_service.dart';
import '../../shared/widgets/app_image.dart';
import '../../shared/widgets/amenities_grid.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/property_contact_card.dart';
import '../../shared/widgets/property_location_map.dart';
import '../../shared/widgets/property_tours_card.dart';
import '../../shared/widgets/site_toast.dart';
import '../../shared/widgets/site_footer_section.dart';
import '../../shared/widgets/site_header.dart';
import '../../shared/widgets/site_icon.dart';
import '../secondary/secondary_repository.dart';
import 'rent_detail_texts.dart';

/// Saytning `/property/rent/:id` sahifasi — `rent-detail.component.ts`.
///
/// **Bu ikkilamchi mulk sahifasining nusxasi emas.** Ikkalasini dastur bilan solishtirganda
/// katta farqlar chiqdi: bu yerda "Oylik ijara" kartasi (yillik jami bilan), butun boshli
/// "Ijara shartlari" bloki (depozit, minimal muddat, kommunal, ko'chib kirish, uy hayvonlari,
/// mebel) va "Birinchi oylik umumiy" yakuni bor; ikkilamchidagi "Asosiy ma'lumot", ipoteka
/// kalkulyatori va shikoyat oynasi esa yo'q.
class RentDetailScreen extends StatefulWidget {
  const RentDetailScreen({super.key, required this.id});

  final int id;

  @override
  State<RentDetailScreen> createState() => _RentDetailScreenState();
}

class _RentDetailScreenState extends State<RentDetailScreen> {
  static const _repo = SecondaryRepository(endpoint: '/market/rent');
  final _scroll = ScrollController();

  late final Future<PropertyListing?> _future = _load();

  Future<PropertyListing?> _load() async {
    final property = await _repo.byId(widget.id);
    if (property != null) unawaited(_recordView(property.id));
    return property;
  }

  late final Future<List<PropertyListing>> _similar = _loadSimilar();
  bool _scrolled = false;
  late bool _favorite = FavoritesService.instance.isFavorite(widget.id, 'rent');

  Future<List<PropertyListing>> _loadSimilar() async {
    try {
      final page = await _repo.list(const SecondaryFilter());
      return page.items.where((item) => item.id != widget.id).take(4).toList();
    } catch (_) {
      return const [];
    }
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
    final result = await FavoritesService.instance.toggle(id, 'rent');
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
      backgroundColor: AppColors.surfaceAltLight,
      body: Stack(
        children: [
          FutureBuilder<PropertyListing?>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.olive));
              }
              final property = snapshot.data;
              if (property == null) return _notFound();
              return _body(property);
            },
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SiteHeader(scrolled: _scrolled, onSearch: (q) => context.go('/rent?search=$q')),
          ),
        ],
      ),
    );
  }

  Widget _notFound() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              RentDetailTexts.notFound,
              style: theme.textTheme.displaySmall?.copyWith(fontSize: 24, color: AppColors.dark),
            ),
            const SizedBox(height: 8),
            Text(
              RentDetailTexts.notFoundDesc,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.dark.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.olive),
              onPressed: () => context.go('/rent'),
              child: Text(RentDetailTexts.backToList),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(PropertyListing p) {
    final theme = Theme.of(context);
    return ListView(
      controller: _scroll,
      padding: EdgeInsets.fromLTRB(16, 124 + MediaQuery.paddingOf(context).top, 16, 0),
      children: [
        _breadcrumb(p),
        const SizedBox(height: 16),
        Text(
          p.title,
          style: theme.textTheme.displaySmall?.copyWith(fontSize: 24, color: AppColors.dark),
        ),
        const SizedBox(height: 8),
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
        _badges(p),
        const SizedBox(height: 16),
        _actions(p),
        const SizedBox(height: 24),

        _Gallery(images: p.images),
        const SizedBox(height: 24), // mt-6

        _rentCard(p),
        const SizedBox(height: 16), // space-y-4
        _rentalTerms(p),

        if (p.description?.isNotEmpty ?? false) ...[
          const SizedBox(height: 16),
          _card(
            RentDetailTexts.about,
            Text(
              p.description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.dark.withValues(alpha: 0.7),
                height: 1.6, // leading-relaxed
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
            propertyType: 'rent',
            propertyId: p.id,
          ),
        ],
        FutureBuilder<List<PropertyListing>>(
          future: _similar,
          builder: (context, snapshot) {
            final items = snapshot.data ?? const <PropertyListing>[];
            if (items.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _card(
                RentDetailTexts.similarRentals,
                Column(
                  children: [
                    for (final item in items) ...[
                      _similarCard(item),
                      if (item != items.last) const SizedBox(height: 16), // gap-4
                    ],
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 48),
        const SiteFooterSection(),
      ],
    );
  }

  Widget _breadcrumb(PropertyListing p) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      fontSize: 14,
      color: AppColors.dark.withValues(alpha: 0.5),
    );
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.go('/'),
          child: Text(RentDetailTexts.breadcrumbHome, style: muted),
        ),
        const SizedBox(width: 8),
        SiteIcon(SiteIcons.chevronRight, size: 12, color: AppColors.dark.withValues(alpha: 0.3)),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => context.go('/rent'),
          child: Text(RentDetailTexts.breadcrumbRent, style: muted),
        ),
        const SizedBox(width: 8),
        SiteIcon(SiteIcons.chevronRight, size: 12, color: AppColors.dark.withValues(alpha: 0.3)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            p.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.dark,
            ),
          ),
        ),
      ],
    );
  }

  /// Ijara sahifasida nishonchalar boshqacha: birinchisi ko'k "Ijaraga", so'ng mulk turi,
  /// mebel bo'lsa "Meblangan", 360° va balkon.
  Widget _badges(PropertyListing p) {
    final theme = Theme.of(context);
    Widget badge(String label, Color background, Color foreground) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(color: foreground, fontWeight: FontWeight.w700),
      ),
    );

    final furnished = _isFurnished(p);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        badge(RentDetailTexts.forRent, const Color(0xFFEFF6FF), const Color(0xFF2563EB)),
        if (p.type case final type?)
          badge(_typeLabel(type), AppColors.olive.withValues(alpha: 0.1), AppColors.olive),
        if (furnished)
          badge(RentDetailTexts.furnished, const Color(0xFFECFDF5), const Color(0xFF059669)),
        if (p.hasVirtualTour)
          badge(
            '360° ${RentDetailTexts.virtualTour}',
            const Color(0xFFEFF6FF),
            const Color(0xFF2563EB),
          ),
        // Modelda alohida `hasBalcony` yo'q — saytda ham u qulayliklardan chiqadi.
        if (p.amenities.contains('balkon') || p.amenities.contains('balkon_shisha'))
          badge(
            RentDetailTexts.withBalcony,
            AppColors.surfaceMutedLight,
            AppColors.dark.withValues(alpha: 0.6),
          ),
        badge('ID: ${p.id}', AppColors.surfaceMutedLight, AppColors.dark.withValues(alpha: 0.6)),
      ],
    );
  }

  /// Saytda mebel alohida maydon emas — qulayliklardan aniqlanadi.
  bool _isFurnished(PropertyListing p) => p.amenities.contains('mebel');

  /// Saytda `navigator.share`, u bo'lmasa havola nusxalanadi va
  /// "Link nusxalandi" chiqadi.
  Future<void> _share(PropertyListing p) async {
    await Clipboard.setData(ClipboardData(text: 'https://businesshome.uz/property/rent/${p.id}'));
    if (!mounted) return;
    showSiteToast(context, t('share.linkCopied'));
  }

  /// Saytda kirgan foydalanuvchi uchun ko'rish qayd etiladi — kabinetdagi
  /// "Yaqinda ko'rilgan" ro'yxati shundan to'ladi.
  Future<void> _recordView(int id) async {
    if (!await ApiClient.instance.isLoggedIn) return;
    try {
      await ApiClient.instance.post<dynamic>(
        '/market/cabinet/views',
        data: {'property_id': id, 'property_type': 'rent'},
      );
    } catch (_) {}
  }

  Widget _actions(PropertyListing p) {
    Widget button(SiteIconData icon, Color color, VoidCallback onTap, {Color? background}) =>
        Pressable(
          onTap: onTap,
          child: Container(
            width: 44, // w-11 h-11
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
      ],
    );
  }

  /// "Oylik ijara" kartasi — ikkilamchidagi "Narxi" kartasidan farqli, ostida yillik jami bor.
  Widget _rentCard(PropertyListing p) {
    final theme = Theme.of(context);
    final currency = CurrencyService.instance;
    final price = p.price ?? 0;

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
      padding: const EdgeInsets.all(16),
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
            RentDetailTexts.monthlyRent,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4), // mb-1
          Text.rich(
            TextSpan(
              text: currency.formatWithSymbol(price, from: p.currency ?? 'uzs'),
              children: [
                TextSpan(
                  text: '/oy',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 20, // text-xl
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            style: theme.textTheme.displaySmall?.copyWith(fontSize: 28, color: Colors.white),
          ),
          const SizedBox(height: 8), // mt-2
          Text(
            '${RentDetailTexts.yearlyTotal}: '
            '${currency.formatWithSymbol(price * 12, from: p.currency ?? 'uzs')}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (p.rooms != null) stat('${p.rooms}', RentDetailTexts.rooms),
              if (p.area != null) stat('${p.area!.round()}', 'm²'),
              if (p.floor != null)
                stat(
                  '${p.floor}${p.totalFloors == null ? '' : '/${p.totalFloors}'}',
                  RentDetailTexts.floor,
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// "Ijara shartlari" — ikkilamchi sahifada umuman yo'q blok.
  Widget _rentalTerms(PropertyListing p) {
    final currency = CurrencyService.instance;
    final price = p.price ?? 0;
    final from = p.currency ?? 'uzs';
    final furnished = _isFurnished(p);

    return _card(
      RentDetailTexts.rentalTerms,
      Column(
        children: [
          _term(
            SiteIcons.wallet,
            RentDetailTexts.deposit,
            currency.formatWithSymbol(price * 2, from: from),
            RentDetailTexts.depositHint,
          ),
          _term(
            SiteIcons.calendar,
            RentDetailTexts.minLease,
            RentDetailTexts.minLeaseValue,
            RentDetailTexts.longTermDiscount,
          ),
          _term(
            SiteIcons.zap,
            RentDetailTexts.utilities,
            RentDetailTexts.utilitiesNotIncluded,
            RentDetailTexts.utilitiesHint,
          ),
          _term(
            SiteIcons.check,
            RentDetailTexts.moveIn,
            RentDetailTexts.availableNow,
            RentDetailTexts.moveInHint,
            valueColor: const Color(0xFF059669), // text-emerald-600
          ),
          _term(
            SiteIcons.heart,
            RentDetailTexts.petPolicy,
            RentDetailTexts.petsNegotiable,
            RentDetailTexts.petDiscuss,
          ),
          _term(
            SiteIcons.house,
            RentDetailTexts.furnishing,
            furnished ? RentDetailTexts.furnished : RentDetailTexts.unfurnished,
            RentDetailTexts.furnishingHint,
            valueColor: furnished ? const Color(0xFF059669) : null,
          ),
          const SizedBox(height: 8),
          // "Birinchi oylik umumiy" — 1-oy + depozit, ya'ni uch oylik.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.olive.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        RentDetailTexts.totalMoveIn,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.dark,
                        ),
                      ),
                      Text(
                        '${RentDetailTexts.firstMonth} + ${RentDetailTexts.deposit}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 12,
                          color: AppColors.dark.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  currency.formatWithSymbol(price * 3, from: from),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.olive,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _term(SiteIconData icon, String label, String value, String hint, {Color? valueColor}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16), // gap-4
      child: Container(
        padding: const EdgeInsets.all(16), // p-4
        decoration: BoxDecoration(
          color: AppColors.surfaceAltLight,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Center(child: SiteIcon(icon, size: 18, color: AppColors.olive)),
            ),
            const SizedBox(width: 12), // gap-3
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 12,
                      color: AppColors.dark.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 2), // mb-0.5
                  Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: valueColor ?? AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 2), // mt-0.5
                  Text(
                    hint,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 11, // text-[11px]
                      color: AppColors.dark.withValues(alpha: 0.4),
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

  Widget _card(String title, Widget child) {
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
              fontSize: 18, // text-lg
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _similarCard(PropertyListing item) {
    final theme = Theme.of(context);
    final currency = CurrencyService.instance;
    final image = absoluteMediaUrl(item.images.firstOrNull);
    return Pressable(
      scale: 0.99,
      onTap: () => context.go('/property/rent/${item.id}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: SizedBox(
              width: 96,
              height: 80,
              child: image != null && image.isNotEmpty
                  ? AppImage(imageUrl: image, fit: BoxFit.cover)
                  : const ColoredBox(color: AppColors.surfaceMutedLight),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 4), // mt-1
                Text(
                  currency.formatWithSymbol(item.price ?? 0, from: item.currency ?? 'uzs'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2563EB), // text-blue-600
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (item.rooms != null) '${item.rooms} ${RentDetailTexts.roomShort}',
                    if (item.area != null) '${item.area!.round()} m²',
                    if (item.district?.isNotEmpty ?? false) item.district!,
                  ].join(' · '),
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
    );
  }

  static String _typeLabel(String type) => switch (type) {
    'apartment' => t('rent.typeApartment'),
    'house' => t('rent.typeHouse'),
    'office' => t('rent.typeOffice'),
    'shop' => t('rent.typeShop'),
    'land' => t('rent.typeLand'),
    'building' => t('rent.amenity.omborxona'),
    'parking' => t('header.dropdown.parking'),
    _ => type,
  };
}

/// Rasm galereyasi — ikkilamchi sahifadagi bilan bir xil xatti-harakat.
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
    if (widget.images.isEmpty) {
      return AspectRatio(
        aspectRatio: 4 / 3,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceMutedLight,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
      );
    }
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.images.length,
              onPageChanged: (index) => setState(() => _index = index),
              itemBuilder: (context, index) => AppImage(
                imageUrl: absoluteMediaUrl(widget.images[index]) ?? '',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        if (widget.images.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.images.length; i++)
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: i == _index ? AppColors.olive : AppColors.dark.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
