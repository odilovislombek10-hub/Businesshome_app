import '../../../core/i18n/translate.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/models/project.dart';
import '../../../shared/models/property_view.dart';
import '../../../shared/utils/breakpoints.dart';
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
        // `pt-8 sm:pt-10 lg:pt-16 pb-6 sm:pb-8`
        padding: EdgeInsets.fromLTRB(
          16,
          Bp.pick(context, base: 32.0, sm: 40.0, lg: 64.0),
          16,
          Bp.pick(context, base: 24.0, sm: 32.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t('featured.title'),
              style: theme.textTheme.displaySmall?.copyWith(
                // `text-xl sm:text-2xl md:text-3xl lg:text-4xl`
                fontSize: Bp.pick(context, base: 20.0, sm: 24.0, md: 30.0, lg: 36.0),
                color: AppColors.dark,
              ),
            ),
            SizedBox(height: Bp.pick(context, base: 8.0, sm: 12.0)), // mb-2 sm:mb-3
            Text(
              t('featured.description'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.dark.withValues(alpha: 0.6),
              ),
            ),
            SizedBox(height: Bp.pick(context, base: 20.0, sm: 32.0)), // mb-5 sm:mb-8
            if (projects.isEmpty)
              // `featured.noResults` — saytda bo'lim yashirilmaydi, matn chiqadi.
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 64), // py-16
                child: Center(
                  child: Text(
                    t('featured.noResults'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 18, // text-lg
                      color: AppColors.dark.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              )
            else
              // Telefonda ikki ustun — foydalanuvchi so'rovi bo'yicha bitta ekranda 4 ta
              // karta ko'rinadi. Saytda mobilda `grid-cols-1`, bu ataylab chekinish.
              GridView.count(
                // Explicit zero: a nested GridView otherwise inherits the ambient padding.
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: Bp.pick(context, base: 2, lg: 3),
                mainAxisSpacing: Bp.pick(context, base: 16.0, sm: 24.0, lg: 32.0),
                crossAxisSpacing: Bp.pick(context, base: 16.0, sm: 24.0, lg: 32.0),
                childAspectRatio: PropertyCard.compactAspectRatio,
                children: [
                  for (final (i, project) in projects.indexed)
                    Entrance.fadeIn(
                      delay: Duration(milliseconds: i * 100),
                      child: PropertyCard(
                        property: PropertyView.fromProject(project),
                        compact: true,
                      ),
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
                child: Text(t('featured.viewAll')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
