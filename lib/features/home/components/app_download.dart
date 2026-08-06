import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme.dart';

/// The site's `app-download` band: an "iOS & Android" pill, the display-font pitch, and the two
/// olive store buttons. On a phone the site stacks this column (`flex-col lg:flex-row`).
class AppDownload extends StatelessWidget {
  const AppDownload({super.key, this.appStoreUrl, this.googlePlayUrl});

  final String? appStoreUrl;
  final String? googlePlayUrl;

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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: AppColors.dark.withValues(alpha: 0.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.phone_iphone, size: 16, color: AppColors.dark),
                  const SizedBox(width: 8),
                  Text(
                    'iOS & Android',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.dark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24), // mb-6
            Text(
              "O'zbekistonning eng ishonchli mulk qidiruv ilovasini yuklab oling",
              style: theme.textTheme.displaySmall?.copyWith(
                fontSize: 30, // text-3xl
                color: AppColors.dark,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "BusinessHome ilovasini o'rnating va aqlliroq qidiruvni boshlang.",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w400,
                color: AppColors.dark.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 32), // mb-8
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _StoreButton(
                  icon: Icons.apple,
                  caption: 'Download on the',
                  store: 'App Store',
                  url: appStoreUrl,
                ),
                _StoreButton(
                  icon: Icons.shop,
                  caption: 'GET IT ON',
                  store: 'Google Play',
                  url: googlePlayUrl,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreButton extends StatelessWidget {
  const _StoreButton({required this.icon, required this.caption, required this.store, this.url});

  final IconData icon;
  final String caption;
  final String store;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () async {
        final uri = Uri.tryParse(url ?? '');
        if (uri != null && uri.hasScheme) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.olive,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  caption,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  store,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
