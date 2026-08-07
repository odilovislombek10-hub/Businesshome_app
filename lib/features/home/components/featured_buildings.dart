import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/models/project.dart';
import '../../../shared/models/property_view.dart';
import '../../../shared/widgets/entrance.dart';
import '../../../shared/widgets/property_card.dart';

/// The site's `featured-buildings` block.
///
/// `pt-8 pb-6 bg-cream`, a display-font heading with a muted line under it, then the cards in a
/// single column on phones (`grid-cols-1 gap-4`) and a pill "view all" button at `mt-12`.
class FeaturedBuildings extends StatelessWidget {
  const FeaturedBuildings({super.key, required this.projects});

  final List<Project> projects;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: AppColors.cream,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "O'zbekistondagi yangi loyihalar bilan tanishing",
              style: theme.textTheme.displaySmall?.copyWith(
                fontSize: 20, // text-xl
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Yangi qurilayotgan loyihalarni kashf eting va doimo xabarda bo'ling.",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.dark.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 12),
            // Two per row so four cards fit one screen — the app's own choice, not the site's
            // single column. `animation-delay: (i * 100)ms` staggering is kept.
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16, // gap-4
              crossAxisSpacing: 16,
              childAspectRatio: PropertyCard.compactAspectRatio,
              children: [
                for (final (i, project) in projects.indexed)
                  Entrance.fadeIn(
                    delay: Duration(milliseconds: i * 100),
                    child: PropertyCard(property: PropertyView.fromProject(project), compact: true),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            Center(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.olive,
                  foregroundColor: AppColors.cream,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: const StadiumBorder(),
                ),
                onPressed: () => context.go('/new-projects'),
                child: const Text("Barcha yangi loyihalarni ko'rish"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
