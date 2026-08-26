import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_image.dart';
import '../../../app/theme.dart';
import '../../../shared/utils/breakpoints.dart';
import '../../../shared/widgets/entrance.dart';
import '../../../core/api/media_url.dart';
import '../../../core/models/homepage.dart';
import '../../../core/models/property_listing.dart';

/// The site's `property-categories` block — "Kvartiralardan tashqari".
///
/// One 4:3 tile per category (`grid-cols-1` on phones, `rounded-2xl`): the category photo, a dark
/// gradient with the name across the top, and — once the cheapest matching listing has loaded — a
/// second overlay along the bottom with that listing's title, district, area and price chip.
class PropertyCategories extends StatelessWidget {
  const PropertyCategories({super.key, required this.categories, required this.topListings});

  final List<PropertyCategory> categories;

  /// Keyed by category id; absent until the per-category request comes back.
  final Map<int, PropertyListing> topListings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: AppColors.cream,
      child: Padding(
        // `py-10 lg:py-12`
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: Bp.pick(context, base: 40.0, lg: 48.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kvartiralardan tashqari',
              style: theme.textTheme.displaySmall?.copyWith(fontSize: 24, color: AppColors.dark),
            ),
            const SizedBox(height: 20),
            _CategoryBento(categories: categories, topListings: topListings),
          ],
        ),
      ),
    );
  }
}

/// Bento arrangement for the category block.
///
/// A plain stack of full-width tiles ate most of a screen for five categories. This packs the
/// same set into roughly one third of that: the first category takes a tall hero cell on the
/// left, the next two stack beside it, and anything after that runs along a short strip
/// underneath. The eye gets one clear entry point instead of five equal blocks.
class _CategoryBento extends StatelessWidget {
  const _CategoryBento({required this.categories, required this.topListings});

  final List<PropertyCategory> categories;
  final Map<int, PropertyListing> topListings;

  static const _gap = 10.0;

  /// Height of the hero row. The two stacked cells split it, so each lands near 4:3.
  static const _heroHeight = 190.0;
  static const _stripHeight = 78.0;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    final hero = categories.first;
    final side = categories.skip(1).take(2).toList();
    final strip = categories.skip(3).toList();

    return Column(
      children: [
        SizedBox(
          height: _heroHeight,
          child: Row(
            children: [
              // Hero cell — the widest and the only one that keeps the listing overlay.
              Expanded(
                flex: side.isEmpty ? 1 : 53,
                child: _CategoryTile(category: hero, top: topListings[hero.id]),
              ),
              if (side.isNotEmpty) ...[
                const SizedBox(width: _gap),
                Expanded(
                  flex: 47,
                  child: Column(
                    children: [
                      for (final (i, category) in side.indexed) ...[
                        if (i > 0) const SizedBox(height: _gap),
                        Expanded(
                          child: _CategoryTile(
                            category: category,
                            top: topListings[category.id],
                            compact: true,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        if (strip.isNotEmpty) ...[
          const SizedBox(height: _gap),
          SizedBox(
            height: _stripHeight,
            child: Row(
              children: [
                for (final (i, category) in strip.indexed) ...[
                  if (i > 0) const SizedBox(width: _gap),
                  Expanded(
                    child: _CategoryTile(
                      category: category,
                      top: topListings[category.id],
                      compact: true,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, this.top, this.compact = false});

  final PropertyCategory category;
  final PropertyListing? top;

  /// The smaller cells: title only, no listing overlay — there is no room for it.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // The listing's own photo wins over the category's static image — that is what the site shows
    // once the top listing arrives.
    final image =
        absoluteMediaUrl(top?.thumbnail) ??
        absoluteMediaUrl(category.image) ??
        _fallbackImage(_typeOf(category.link));

    return Pressable.builder(
      onTap: () => context.go(category.link),
      // The bento gives each cell its size, so no AspectRatio here.
      builder: (context, pressed) => ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg), // rounded-2xl
        child: Stack(
          fit: StackFit.expand,
          children: [
            ZoomOnPress(
              pressed: pressed,
              child: AppImage(
                imageUrl: image,
                fit: BoxFit.cover,
                placeholder: (_, _) => const ColoredBox(color: AppColors.oliveMuted),
                errorWidget: (_, _, _) => const ColoredBox(color: AppColors.oliveMuted),
              ),
            ),

            // `h-32 from-dark/70 to-transparent` across the top, behind the name.
            Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: compact ? 60 : 128,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppColors.dark.withValues(alpha: 0.7), Colors.transparent],
                    ),
                  ),
                  child: const SizedBox(width: double.infinity),
                ),
              ),
            ),
            Positioned(
              top: compact ? 10 : 16,
              left: compact ? 10 : 16,
              right: compact ? 10 : 16,
              child: Text(
                category.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: compact ? 13 : 20,
                  height: 1.15,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // The listing overlay only fits the hero cell.
            if (!compact)
              if (top case final listing?)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Color(0xD9000000), Color(0x66000000), Colors.transparent],
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                listing.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _subtitle(listing),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            priceLabel(listing.price, isRent: category.link.startsWith('/rent')),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.dark,
                              fontWeight: FontWeight.w700,
                            ),
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

  static String _subtitle(PropertyListing listing) {
    final district = (listing.district?.trim().isNotEmpty ?? false)
        ? listing.district!.trim()
        : (listing.city?.trim() ?? '');
    final area = listing.area;
    return area == null ? district : '$district · ${area.round()} m²';
  }

  /// `?type=` from the category's link, which is also what the site filters the top listing by.
  static String? _typeOf(String link) => Uri.tryParse(link)?.queryParameters['type'];

  static String _fallbackImage(String? type) => switch (type) {
    'apartment' => 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800&q=80',
    'house' => 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800&q=80',
    'office' => 'https://images.unsplash.com/photo-1497366216548-37526070297c?w=800&q=80',
    'shop' => 'https://images.unsplash.com/photo-1604719312566-8912e9227c6a?w=800&q=80',
    'parking' => 'https://images.unsplash.com/photo-1545179605-1296651e9d43?w=800&q=80',
    'building' => 'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?w=800&q=80',
    'land' => 'https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=800&q=80',
    _ => 'https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=800&q=80',
  };
}

/// Short price for the chip, rounded the way the site rounds it: rent per month in millions or
/// thousands, sale in mlrd / mln / K.
String priceLabel(num? price, {required bool isRent}) {
  final value = price ?? 0;
  if (value == 0) return '—';
  if (isRent) {
    return value >= 1000000
        ? '${(value / 1000000).toStringAsFixed(1)} mln/oy'
        : '${(value / 1000).round()} K/oy';
  }
  if (value >= 1000000000) return '${(value / 1000000000).toStringAsFixed(1)} mlrd';
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(0)} mln';
  return '${(value / 1000).round()} K';
}
