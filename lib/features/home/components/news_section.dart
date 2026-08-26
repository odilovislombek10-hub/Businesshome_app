import '../../../core/i18n/translate.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_image.dart';
import '../../../app/theme.dart';
import '../../../shared/widgets/entrance.dart';
import '../../../core/api/media_url.dart';
import '../../../core/models/content.dart';

/// The site's `news-section`: a white band with the heading and a "Barchasini ko'rish" link on
/// the right, then cards where the text sits above a 4:3 photo (`bg-gray-50 rounded-2xl`, text
/// block first, image pinned to the bottom with `mt-auto`).
class NewsSection extends StatelessWidget {
  const NewsSection({super.key, required this.news});

  final List<NewsItem> news;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40), // py-10
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    t('news.title'),
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontSize: 24,
                      color: AppColors.dark,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => context.go('/news'),
                  child: Text(
                    t('news.viewAll'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.dark.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32), // mb-8
            for (final item in news) ...[
              _NewsCard(item: item),
              const SizedBox(height: 24), // gap-6
            ],
          ],
        ),
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.item});

  final NewsItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // The site substitutes a stock photo rather than leaving the card imageless.
    final image = absoluteMediaUrl(item.image) ?? NewsItem.fallbackImage;

    return Pressable.builder(
      onTap: () => context.go('/news/${item.id}'),
      builder: (context, pressed) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surfaceAltLight, // bg-gray-50
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16), // p-5 pb-4
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.dateLabel.isNotEmpty) ...[
                    Text(
                      item.dateLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.dark.withValues(alpha: 0.4),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    item.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                      height: 1.35,
                    ),
                  ),
                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      item.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.dark.withValues(alpha: 0.5),
                        height: 1.6,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            AspectRatio(
              aspectRatio: 4 / 3,
              child: ZoomOnPress(
                pressed: pressed,
                child: AppImage(
                  imageUrl: image,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => const ColoredBox(color: AppColors.surfaceMutedLight),
                  errorWidget: (_, _, _) => const ColoredBox(color: AppColors.surfaceMutedLight),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
