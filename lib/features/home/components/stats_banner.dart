import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/widgets/app_image.dart';
import '../../../app/theme.dart';
import '../../../shared/widgets/entrance.dart';
import '../../../core/api/media_url.dart';
import '../../../core/models/homepage.dart';

/// The site's `stats-banner`: a city photo under an 85% olive wash, rounded-3xl, carrying two
/// headline numbers, the admin-defined feature pills, two buttons and — when one is configured —
/// a YouTube preview.
///
/// The site lays the video beside the text from `lg` up; on a phone everything stacks, which is
/// what `flex-col lg:flex-row` means here.
class StatsBanner extends StatelessWidget {
  const StatsBanner({super.key, required this.stats});

  final PlatformStats stats;

  static const _fallbackBackground =
      'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=1400&q=80';
  static const _fallbackThumbnail =
      'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=600&q=80';

  /// `Intl.NumberFormat('en-US')` — comma-grouped, unlike the space-grouped prices.
  static String _number(int value) {
    final digits = value.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = absoluteMediaUrl(stats.backgroundImage) ?? _fallbackBackground;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40), // py-10
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl), // rounded-3xl
        child: Stack(
          children: [
            Positioned.fill(
              child: AppImage(
                imageUrl: background,
                fit: BoxFit.cover,
                placeholder: (_, _) => const ColoredBox(color: AppColors.olive),
                errorWidget: (_, _, _) => const ColoredBox(color: AppColors.olive),
              ),
            ),
            Positioned.fill(child: ColoredBox(color: AppColors.olive.withValues(alpha: 0.85))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 24,
                    runSpacing: 16,
                    children: [
                      _Stat(label: 'Sotib olingan jami', value: _number(stats.totalProperties)),
                      _Stat(label: 'Onlayn sotib olingan', value: _number(stats.totalProjects)),
                    ],
                  ),
                  if (stats.features.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final feature in stats.features)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.cream.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              border: Border.all(color: AppColors.cream.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_featureIcon(feature.icon), size: 16, color: AppColors.cream),
                                const SizedBox(width: 8),
                                Text(
                                  feature.text ?? '',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.cream,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.cream,
                          foregroundColor: AppColors.dark,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        onPressed: () => context.go('/new-projects'),
                        child: const Text('Onlayn sotib olish'),
                      ),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.cream,
                          side: BorderSide(color: AppColors.cream.withValues(alpha: 0.2)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        onPressed: () => _open('https://wa.me/998901234567'),
                        child: const Text("Bog'lanish"),
                      ),
                    ],
                  ),
                  if (stats.youtubeUrl case final url?) ...[
                    const SizedBox(height: 32),
                    _VideoPreview(
                      thumbnail: absoluteMediaUrl(stats.videoThumbnail) ?? _fallbackThumbnail,
                      title: stats.videoTitle,
                      subtitle: stats.videoSubtitle,
                      onTap: () => _open(url),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _featureIcon(String? name) => switch (name) {
    'check' => Icons.check_circle_outline,
    'clock' => Icons.schedule,
    'shield' => Icons.verified_user_outlined,
    'star' => Icons.star_outline,
    _ => Icons.check,
  };

  static Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 12,
            color: AppColors.cream.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 24, // text-2xl on phones
            fontWeight: FontWeight.w700,
            color: AppColors.cream,
          ),
        ),
      ],
    );
  }
}

class _VideoPreview extends StatelessWidget {
  const _VideoPreview({required this.thumbnail, required this.onTap, this.title, this.subtitle});

  final String thumbnail;
  final VoidCallback onTap;
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Pressable.builder(
      onTap: onTap,
      builder: (context, pressed) => ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ZoomOnPress(
                pressed: pressed,
                child: AppImage(imageUrl: thumbnail, fit: BoxFit.cover),
              ),
              ColoredBox(color: AppColors.dark.withValues(alpha: 0.3)),
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626), // red-600
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
                ),
              ),
              if (title != null)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title!,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
