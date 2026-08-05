import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
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
        padding: const EdgeInsets.fromLTRB(16, 40, 16, 40), // py-10
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kvartiralardan tashqari',
              style: theme.textTheme.displaySmall?.copyWith(fontSize: 24, color: AppColors.dark),
            ),
            const SizedBox(height: 32), // mb-8
            for (final category in categories) ...[
              _CategoryTile(category: category, top: topListings[category.id]),
              const SizedBox(height: 16), // gap-4
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, this.top});

  final PropertyCategory category;
  final PropertyListing? top;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // The listing's own photo wins over the category's static image — that is what the site shows
    // once the top listing arrives.
    final image =
        absoluteMediaUrl(top?.thumbnail) ??
        absoluteMediaUrl(category.image) ??
        _fallbackImage(_typeOf(category.link));

    return GestureDetector(
      onTap: () => context.go(category.link),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg), // rounded-2xl
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: image,
                fit: BoxFit.cover,
                placeholder: (_, _) => const ColoredBox(color: AppColors.oliveMuted),
                errorWidget: (_, _, _) => const ColoredBox(color: AppColors.oliveMuted),
              ),

              // `h-32 from-dark/70 to-transparent` across the top, behind the name.
              Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  height: 128,
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
                top: 16,
                left: 16,
                right: 16,
                child: Text(
                  category.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

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
