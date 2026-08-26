import '../../core/i18n/translate.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_image.dart';
import '../../app/theme.dart';
import '../../core/services/favorites_service.dart';
import '../../core/services/currency_service.dart';
import '../models/property_view.dart';
import 'site_icon.dart';
import 'site_toast.dart';

/// Port of the site's `app-property-card`.
///
/// A 3:4 photo with everything laid over it (`rounded-xl`, `from-dark via-dark/40 to-transparent`
/// scrim): badges and the favourite button along the top, then title, developer, location, the
/// stats row, the price and a full-width "Batafsil" bar along the bottom.
///
/// With several photos the site splits the card into equal zones and swaps image on hover/touch;
/// here each zone is a tap target doing the same.
class PropertyCard extends StatefulWidget {
  const PropertyCard({
    super.key,
    required this.property,
    this.onFavorite,
    this.isFavorite = false,
    this.compact = false,
  });

  final PropertyView property;
  final VoidCallback? onFavorite;
  final bool isFavorite;

  /// Half-width, two-per-row layout. Same card, smaller: the type badges and the developer line
  /// drop out and the remaining text steps down a size, so it still reads at ~170px wide.
  final bool compact;

  /// Slightly taller than the full-width 3:4 so the price and the button clear the bottom edge.
  static const compactAspectRatio = 0.66;

  @override
  State<PropertyCard> createState() => _PropertyCardState();
}

class _PropertyCardState extends State<PropertyCard> {
  @override
  void initState() {
    super.initState();
    // Sevimlilar ro'yxati o'zgarsa yurakcha rangi yangilanadi.
    FavoritesService.instance.addListener(_onFavoritesChanged);
  }

  @override
  void dispose() {
    FavoritesService.instance.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  void _onFavoritesChanged() {
    if (mounted) setState(() {});
  }

  int _active = 0;

  /// Saytdagi `FavoritesService.toggle` — kirmagan bo'lsa login sahifasi.
  Future<void> _toggleFavorite(BuildContext context) async {
    final result = await FavoritesService.instance.toggle(
      widget.property.id,
      widget.property.propertyType,
      developerCode: widget.property.developerCode,
    );
    if (!context.mounted) return;
    if (result == null) {
      context.push('/login');
      return;
    }
    showSiteToast(
      context,
      result ? "❤ Sevimlilarga qo'shildi" : 'Sevimlilardan olib tashlandi',
      kind: result ? ToastKind.success : ToastKind.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.property;
    final images = property.images;

    return GestureDetector(
      onTap: () => context.go(property.detailPath),
      child: AspectRatio(
        aspectRatio: widget.compact ? PropertyCard.compactAspectRatio : 3 / 4,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md), // rounded-xl
          child: Stack(
            fit: StackFit.expand,
            children: [
              for (var i = 0; i < images.length; i++)
                AnimatedOpacity(
                  opacity: _active == i ? 1 : 0,
                  duration: const Duration(milliseconds: 500),
                  child: AppImage(
                    imageUrl: images[i],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (_, _) => const ColoredBox(color: AppColors.oliveMuted),
                    errorWidget: (_, _, _) => const ColoredBox(color: AppColors.oliveMuted),
                  ),
                ),

              // Equal-width zones that switch image, mirroring the site's hover strips.
              if (images.length > 1)
                Row(
                  children: [
                    for (var i = 0; i < images.length; i++)
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTapDown: (_) => setState(() => _active = i),
                        ),
                      ),
                  ],
                ),

              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [AppColors.dark, Color(0x663D3D3D), Colors.transparent],
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.all(widget.compact ? 10 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Leave room on the right for the favourite button (`pr-12` on the site).
                    Padding(
                      padding: const EdgeInsets.only(right: 44),
                      child: Wrap(spacing: 6, runSpacing: 6, children: _badges(context, property)),
                    ),
                    _Info(property: property, compact: widget.compact),
                  ],
                ),
              ),

              Positioned(
                top: widget.compact ? 10 : 16,
                right: widget.compact ? 10 : 16,
                child: _FavoriteButton(
                  isFavorite:
                      widget.isFavorite ||
                      FavoritesService.instance.isFavorite(
                        widget.property.id,
                        widget.property.propertyType,
                        widget.property.developerCode,
                      ),
                  onPressed: widget.onFavorite ?? () => _toggleFavorite(context),
                  compact: widget.compact,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _badges(BuildContext context, PropertyView property) => [
    // At half width only the two shortest badges fit; the rest would wrap over the photo.
    if (widget.compact) ...[
      if (property.isTop)
        _Badge(label: t('ads.top'), background: Color(0xFFF59E0B), icon: SiteIcons.star),
      if (property.hasTour)
        _Badge(
          label: '3D',
          background: AppColors.dark.withValues(alpha: 0.7),
          icon: SiteIcons.box3d,
        ),
    ] else ...[
      if (property.isTop)
        _Badge(
          label: t('ads.top'),
          background: Color(0xFFF59E0B), // amber-500
          icon: SiteIcons.star,
        ),
      if (property.segmentLabel case final segment?)
        _Badge(label: segment, background: AppColors.olive),
      if (property.hasTour)
        _Badge(
          label: '3D',
          background: AppColors.dark.withValues(alpha: 0.7),
          icon: SiteIcons.box3d,
        ),
      if (property.tier == 'ultra')
        const _Badge(label: 'Ultra', background: Color(0xFFF59E0B), icon: SiteIcons.star)
      else if (property.tier == 'pro' || property.verified)
        const _Badge(
          label: 'Pro',
          background: Color(0xFF2563EB), // blue-600
          icon: SiteIcons.check,
        ),
      if (property.completion case final completion?)
        _Badge(
          label: '${t('propertyCard.completion')}: $completion',
          background: AppColors.olive.withValues(alpha: 0.8),
        ),
    ],
  ];
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.background, this.icon});

  final String label;
  final Color background;
  final SiteIconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            SiteIcon(icon!, size: 12, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.isFavorite, this.onPressed, this.compact = false});

  final bool isFavorite;
  final VoidCallback? onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: compact ? 30 : 36,
        height: compact ? 30 : 36,
        decoration: BoxDecoration(
          color: isFavorite ? AppColors.olive : Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Center(
          child: SiteIcon(
            SiteIcons.heart,
            size: 16,
            color: isFavorite ? AppColors.cream : AppColors.dark.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.property, this.compact = false});

  final PropertyView property;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = CurrencyService.instance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (!compact && property.projectLogo != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: AppImage(
                  imageUrl: property.projectLogo!,
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                property.name,
                maxLines: compact ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: compact ? 14 : 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.cream,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
        if (!compact && property.developer != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              if (property.developerLogo case final logo?) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: AppImage(imageUrl: logo, width: 16, height: 16, fit: BoxFit.cover),
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  property.developer!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _shadowed(theme.textTheme.bodyMedium, Colors.white),
                ),
              ),
            ],
          ),
        ],
        if (property.location.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              SiteIcon(SiteIcons.mapPin, size: 14, color: AppColors.cream.withValues(alpha: 0.7)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  property.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: compact ? 11 : 14,
                    color: AppColors.cream.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ],
        if (_stats.isNotEmpty) ...[
          SizedBox(height: compact ? 4 : 8),
          Wrap(
            spacing: compact ? 8 : 12,
            runSpacing: 4,
            children: [
              // Only the first two stats fit on a half-width card.
              for (final (icon, label) in compact ? _stats.take(2) : _stats)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SiteIcon(icon, size: compact ? 11 : 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: _shadowed(
                        theme.textTheme.labelSmall?.copyWith(fontSize: compact ? 10 : 11),
                        Colors.white,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
        if (_price(currency) case final price?) ...[
          SizedBox(height: compact ? 4 : 8),
          Text(
            price,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _shadowed(
              theme.textTheme.titleLarge?.copyWith(
                fontSize: compact ? 14 : 18,
                fontWeight: FontWeight.w700,
              ),
              Colors.white,
            ),
          ),
        ],
        if (!compact && property.payment != null) ...[
          const SizedBox(height: 8),
          _Badge(
            label: "Boshlang'ich to'lov (%): ${property.payment}",
            background: AppColors.olive.withValues(alpha: 0.8),
          ),
        ],
        SizedBox(height: compact ? 6 : 8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: compact ? 6 : 10),
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                t('propertyCard.details'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: compact ? 12 : 14,
                  color: AppColors.olive,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: compact ? 4 : 8),
              SiteIcon(SiteIcons.arrowRight, size: compact ? 12 : 16, color: AppColors.olive),
            ],
          ),
        ),
      ],
    );
  }

  /// The stats row, in the site's order: apartments, area, blocks, rooms, floors.
  List<(SiteIconData, String)> get _stats => [
    if (property.totalApartments case final value?) (SiteIcons.house, '$value'),
    if (property.totalArea case final value?) (SiteIcons.ruler, '${value.toStringAsFixed(0)} m²'),
    if (property.totalBlocks case final value?) (SiteIcons.building, '$value blok'),
    if (property.rooms case final value?) (SiteIcons.house, '$value xona'),
    if (property.totalFloors case final value?) (SiteIcons.floors, '$value qavat'),
  ];

  /// Price per m² wins over the total, which wins over a plain price — the site's order.
  ///
  /// Listings carry their own currency, so the conversion source is the listing's, not a blanket
  /// UZS. Rent is a monthly figure and gets the "/oy" tail the site appends.
  String? _price(CurrencyService currency) {
    final suffix = property.isMonthly ? '/oy' : '';
    if (property.minPricePerM2 case final value?) {
      return '1m²: ${currency.formatWithSymbol(value, from: property.priceCurrency)}';
    }
    if (property.minPrice case final value?) {
      return currency.formatWithSymbol(value, from: property.priceCurrency);
    }
    if (property.price case final value?) {
      return '${currency.formatWithSymbol(value, from: property.priceCurrency)}$suffix';
    }
    return null;
  }

  /// `drop-shadow-sm` — the site relies on it to keep light text readable over a photo.
  TextStyle? _shadowed(TextStyle? style, Color color) => style?.copyWith(
    color: color,
    fontWeight: FontWeight.w500,
    shadows: const [Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1))],
  );
}
