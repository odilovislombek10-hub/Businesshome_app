import '../../../core/i18n/translate.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_image.dart';
import '../../../app/theme.dart';
import '../../../shared/widgets/entrance.dart';
import '../../../core/api/media_url.dart';
import '../../../core/models/page_content.dart';

/// The site's `promo-banner`: a 200px-tall photo strip (`h-[200px] rounded-xl`) under a
/// left-to-right black gradient, with a badge, display-font title, subtitle and a glass button
/// stacked over the left half.
///
/// It reads the same admin page content the hero does, and the whole section disappears when
/// `banner_enabled` is off.
class PromoBanner extends StatelessWidget {
  const PromoBanner({super.key, required this.content});

  final PageContent content;

  static const _fallbackImage =
      'https://images.unsplash.com/photo-1582407947304-fd86f028f716?w=1400&q=80';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final image = absoluteMediaUrl(content.bannerImageUrl) ?? _fallbackImage;

    return ColoredBox(
      color: AppColors.cream,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32), // py-8
        child: Pressable.builder(
          onTap: () => context.go(content.bannerLink),
          builder: (context, pressed) => ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md), // rounded-xl
            child: SizedBox(
              height: 200, // h-[200px]
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
                  // `from-black/80 via-black/55 to-black/10`, left to right.
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0xCC000000), Color(0x8C000000), Color(0x1A000000)],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16), // p-4 on phones
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.olive,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            content.bannerBadge ?? t('promo.badge'),
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              color: AppColors.cream,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          content.bannerTitle ?? 'Tashkent City 360',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontSize: 20, // text-xl
                            color: AppColors.cream,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          content.bannerSubtitle ?? t('promo.subtitle'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 12,
                            color: AppColors.cream.withValues(alpha: 0.85),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            t('promo.button'),
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 12,
                              color: AppColors.cream,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
