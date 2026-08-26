import '../../../core/i18n/translate.dart';
import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/models/content.dart';

/// The site's `features-section` — "Nima uchun Business Home?".
///
/// The one dark band on an otherwise cream page: a slate gradient background, a centred heading
/// with the brand name picked out in olive, and glass cards (`bg-white/5`, `border-white/10`,
/// `rounded-2xl`) each led by an olive gradient icon tile.
class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key, required this.features});

  final List<FeatureItem> features;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: const BoxDecoration(
        // `from-slate-800 via-slate-900 to-slate-800`
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceDark, AppColors.scaffoldDark, AppColors.surfaceDark],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48), // py-12
        child: Column(
          children: [
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Nima uchun '),
                  TextSpan(
                    text: 'Business Home',
                    style: TextStyle(color: AppColors.olive.withValues(alpha: 0.9)),
                  ),
                  const TextSpan(text: '?'),
                ],
              ),
              textAlign: TextAlign.center,
              style: theme.textTheme.displaySmall?.copyWith(fontSize: 24, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              t('featuresSection.subtitle'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textMutedDark),
            ),
            const SizedBox(height: 32), // mb-8
            for (final feature in features) ...[
              _FeatureCard(feature: feature),
              const SizedBox(height: 16), // gap-4
            ],
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.feature});

  final FeatureItem feature;

  /// The icon names the site's `@switch` handles, mapped to their Material equivalents.
  static IconData _icon(String name) => switch (name) {
    'shield' => Icons.verified_user_outlined,
    'eye' => Icons.visibility_outlined,
    'wallet' => Icons.account_balance_wallet_outlined,
    'home' => Icons.home_outlined,
    'star' => Icons.star_outline,
    'check' => Icons.check_circle_outline,
    'chart' => Icons.bar_chart,
    'clock' => Icons.schedule,
    'users' => Icons.group_outlined,
    'headset' => Icons.headset_mic_outlined,
    _ => Icons.check_circle_outline,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20), // p-5
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.olive, AppColors.oliveMuted],
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(_icon(feature.icon), color: Colors.white, size: 22),
          ),
          const SizedBox(height: 16),
          Text(feature.title, style: theme.textTheme.titleMedium?.copyWith(color: Colors.white)),
          const SizedBox(height: 8),
          Text(
            feature.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textMutedDark,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
