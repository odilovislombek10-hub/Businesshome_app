import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/api/media_url.dart';
import '../../../core/models/property_listing.dart';
import '../../../core/models/specialist.dart';
import '../../../shared/widgets/entrance.dart';
import 'property_categories.dart' show priceLabel;

/// The site's `home-top-picks`: four small-card blocks — top secondary listings, top rentals, top
/// designers and top masters — each with a heading and a "Hammasini ko'rish →" link.
///
/// Two columns on a phone (`grid-cols-2 gap-3`), white cards with a `border-gray-100` and
/// `rounded-2xl`; listings use a 4:3 photo with a price chip, specialists a square one.
class HomeTopPicks extends StatelessWidget {
  const HomeTopPicks({
    super.key,
    required this.secondary,
    required this.rent,
    required this.designers,
    required this.masters,
  });

  final List<PropertyListing> secondary;
  final List<PropertyListing> rent;
  final List<Specialist> designers;
  final List<Specialist> masters;

  bool get isEmpty => secondary.isEmpty && rent.isEmpty && designers.isEmpty && masters.isEmpty;

  @override
  Widget build(BuildContext context) {
    if (isEmpty) return const SizedBox.shrink();
    return ColoredBox(
      color: AppColors.cream,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40), // py-10
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (secondary.isNotEmpty)
              _Block(
                title: 'Sotuvdagi top uylar',
                seeAllPath: '/secondary',
                children: [
                  for (final listing in secondary) _ListingTile(listing: listing, isRent: false),
                ],
              ),
            if (rent.isNotEmpty)
              _Block(
                title: 'Top ijara variantlari',
                seeAllPath: '/rent',
                children: [
                  for (final listing in rent) _ListingTile(listing: listing, isRent: true),
                ],
              ),
            if (designers.isNotEmpty)
              _Block(
                title: 'Eng yaxshi dizaynerlar',
                seeAllPath: '/designers',
                children: [
                  for (final person in designers)
                    _SpecialistTile(specialist: person, section: 'designers'),
                ],
              ),
            if (masters.isNotEmpty)
              _Block(
                title: 'Eng yaxshi ustalar',
                seeAllPath: '/masters',
                children: [
                  for (final person in masters)
                    _SpecialistTile(specialist: person, section: 'masters'),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Heading + "see all" link above a two-column grid. `space-y-12` between blocks.
class _Block extends StatelessWidget {
  const _Block({required this.title, required this.seeAllPath, required this.children});

  final String title;
  final String seeAllPath;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 48), // space-y-12
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontSize: 20, // text-xl
                    color: AppColors.dark,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => context.go(seeAllPath),
                child: Text(
                  "Hammasini ko'rish →",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.olive,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20), // mb-5
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12, // gap-3
            crossAxisSpacing: 12,
            // Taller than it looks: the text block needs room for title, district and stats.
            childAspectRatio: 0.62,
            children: children,
          ),
        ],
      ),
    );
  }
}

/// Shared card chrome: white, hairline border, rounded-2xl, image on top, text block under it.
class _SmallCard extends StatelessWidget {
  const _SmallCard({
    required this.onTap,
    required this.image,
    required this.aspectRatio,
    required this.body,
    this.chip,
    this.zoom = 1.05,
  });

  final VoidCallback onTap;
  final String? image;
  final double aspectRatio;
  final Widget body;
  final Widget? chip;

  /// `group-hover:scale-105` for listings, `scale-110` for specialists.
  final double zoom;

  @override
  Widget build(BuildContext context) {
    return Pressable.builder(
      onTap: onTap,
      builder: (context, pressed) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.surfaceMutedLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: aspectRatio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (image != null)
                    ZoomOnPress(
                      pressed: pressed,
                      scale: zoom,
                      child: CachedNetworkImage(
                        imageUrl: image!,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => const ColoredBox(color: AppColors.surfaceMutedLight),
                        errorWidget: (_, _, _) =>
                            const ColoredBox(color: AppColors.surfaceMutedLight),
                      ),
                    )
                  else
                    const ColoredBox(color: AppColors.surfaceMutedLight),
                  if (chip != null) Positioned(top: 8, left: 8, child: chip!),
                ],
              ),
            ),
            Expanded(
              child: Padding(padding: const EdgeInsets.all(12), child: body), // p-3
            ),
          ],
        ),
      ),
    );
  }
}

class _ListingTile extends StatelessWidget {
  const _ListingTile({required this.listing, required this.isRent});

  final PropertyListing listing;
  final bool isRent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final district = (listing.district?.trim().isNotEmpty ?? false)
        ? listing.district!.trim()
        : (listing.city?.trim() ?? '');

    return _SmallCard(
      onTap: () => context.go('/property/${isRent ? 'rent' : 'secondary'}/${listing.id}'),
      image: absoluteMediaUrl(listing.thumbnail),
      aspectRatio: 4 / 3,
      // Sale chips are white on the site, rentals olive.
      chip: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isRent
              ? AppColors.olive.withValues(alpha: 0.95)
              : Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Text(
          priceLabel(listing.price, isRent: isRent),
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isRent ? Colors.white : AppColors.dark,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            listing.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            district,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 12,
              color: AppColors.dark.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            [
              if (listing.rooms != null) '${listing.rooms} xona',
              if (listing.area != null) '${listing.area!.round()} m²',
            ].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 11,
              color: AppColors.dark.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecialistTile extends StatelessWidget {
  const _SpecialistTile({required this.specialist, required this.section});

  final Specialist specialist;
  final String section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SmallCard(
      onTap: () => context.go(specialist.pathIn(section)),
      image: absoluteMediaUrl(specialist.image),
      aspectRatio: 1,
      zoom: 1.10, // group-hover:scale-110
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            specialist.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            specialist.subtitle ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 12,
              color: AppColors.dark.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 6),
          // Rating when there is one, otherwise the city — the site's either/or.
          if (specialist.rating > 0)
            Row(
              children: [
                Text(
                  specialist.rating.toStringAsFixed(1),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${specialist.reviewsCount})',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    color: AppColors.dark.withValues(alpha: 0.4),
                  ),
                ),
              ],
            )
          else if (specialist.city != null)
            Text(
              specialist.city!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 11,
                color: AppColors.dark.withValues(alpha: 0.5),
              ),
            ),
        ],
      ),
    );
  }
}
