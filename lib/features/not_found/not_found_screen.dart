import '../../core/i18n/translate.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../shared/utils/breakpoints.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/site_icon.dart';

/// Saytning 404 sahifasi — `not-found.component.ts`.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16), // px-4
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 448), // max-w-md
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '404',
                  style: theme.textTheme.displayLarge?.copyWith(
                    // `text-[120px] md:text-[160px]`
                    fontSize: Bp.pick(context, base: 120.0, md: 160.0),
                    fontWeight: FontWeight.w700,
                    height: 1,
                    color: AppColors.olive.withValues(alpha: 0.2),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -24), // -mt-6
                  child: Column(
                    children: [
                      Text(
                        t('notFound.title'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.displaySmall?.copyWith(
                          // `text-2xl md:text-3xl`
                          fontSize: Bp.pick(context, base: 24.0, md: 30.0),
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark,
                        ),
                      ),
                      const SizedBox(height: 16), // mb-4
                      Text(
                        "Siz qidirayotgan sahifa mavjud emas yoki ko'chirilgan. "
                        'Iltimos, bosh sahifaga qayting.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: Bp.pick(context, base: 14.0, md: 16.0),
                          height: 1.6,
                          color: AppColors.dark.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 32), // mb-8
                      Pressable(
                        scale: 0.98,
                        onTap: () => context.go('/'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.olive,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SiteIcon(SiteIcons.arrowLeft, size: 18, color: AppColors.cream),
                              const SizedBox(width: 8), // gap-2
                              Text(
                                t('notFound.goHome'),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.cream,
                                ),
                              ),
                            ],
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
    );
  }
}
