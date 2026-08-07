import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/app_image.dart';
import '../../app/theme.dart';
import '../../core/utils/format.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/site_icon.dart';
import 'cabinet_repository.dart';
import 'cabinet_texts.dart';

/// Kabinetning `favorites` bo'limi — `/market/cabinet/favorites/detailed`.
///
/// Shablonda: sarlavha, manba bo'yicha filtr tugmalari (ikkitadan ko'p manba bo'lsagina),
/// 4:3 rasmli kartalar to'ri. Har bir kartada manba nishonchasi (3D, Yangi loyiha, Ijara,
/// Ikkilamchi, Dizayner, Usta), o'ng yuqorida tur, pastida nom va narx.
class CabinetFavorites extends StatefulWidget {
  const CabinetFavorites({super.key, required this.future, required this.onRetry});

  final Future<List<FavoriteItem>> future;
  final VoidCallback onRetry;

  @override
  State<CabinetFavorites> createState() => _CabinetFavoritesState();
}

class _CabinetFavoritesState extends State<CabinetFavorites> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<FavoriteItem>>(
      future: widget.future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data ?? const <FavoriteItem>[];
        if (items.isEmpty) return _empty(context);

        // Manbalar ikkitadan ko'p bo'lsagina filtr chiqadi — shablondagi `length > 2`.
        final tabs = CabinetTexts.favoriteTabsFor(items.map((f) => f.source).toSet());
        final shown = _filter == 'all'
            ? items
            : [
                for (final item in items)
                  if (item.source == _filter) item,
              ];

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              CabinetTexts.tabLabel('favorites'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 20, // text-xl
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 16), // space-y-4
            if (tabs.length > 2) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (key, label) in tabs)
                    Pressable(
                      onTap: () => setState(() => _filter = key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _filter == key ? AppColors.olive : Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: _filter == key ? AppColors.olive : AppColors.borderLight,
                          ),
                        ),
                        child: Text(
                          label,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: _filter == key
                                ? Colors.white
                                : AppColors.dark.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            if (shown.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Text(
                  CabinetTexts.noFavoritesInCategory,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.dark.withValues(alpha: 0.5),
                  ),
                ),
              )
            else
              GridView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16, // gap-4
                  crossAxisSpacing: 16,
                  mainAxisExtent: 210,
                ),
                itemCount: shown.length,
                itemBuilder: (context, i) => _FavoriteCard(item: shown[i]),
              ),
          ],
        );
      },
    );
  }

  Widget _empty(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(48), // p-12
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SiteIcon(
                SiteIcons.heart,
                size: 64,
                strokeWidth: 1.5,
                color: AppColors.dark.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 16), // mb-4
              Text(
                CabinetTexts.noFavorites,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 18, // text-lg
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 8), // mb-2
              Text(
                CabinetTexts.noFavoritesDesc,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.dark.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 24), // mb-6
              Pressable(
                onTap: () => context.push('/secondary'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.olive,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    CabinetTexts.startSearch,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({required this.item});

  final FavoriteItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badge = CabinetTexts.favoriteBadge(item.source);

    return Pressable(
      scale: 0.99,
      onTap: () {
        final route = item.detailRoute;
        if (route != null) context.push(route);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg), // rounded-2xl
          border: Border.all(color: AppColors.borderLight),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (item.image != null)
                    AppImage(
                      imageUrl: item.image!,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => const ColoredBox(color: AppColors.surfaceAltLight),
                      errorWidget: (_, _, _) => const ColoredBox(color: AppColors.surfaceAltLight),
                    )
                  else
                    const ColoredBox(color: AppColors.surfaceAltLight),
                  if (badge != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: badge.$2,
                          borderRadius: BorderRadius.circular(6), // rounded-md
                        ),
                        child: Text(
                          badge.$1,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  if (item.type != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.type!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppColors.dark.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12), // p-4
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1, // line-clamp-1
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dark,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      // Mutaxassislarda narx "…dan", mulkda oddiy narx.
                      item.isSpecialist
                          ? '${formatNumber(item.price)} so\'m dan'
                          : '${formatNumber(item.price)} so\'m',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 15, // text-lg → yarim kenglikda 15
                        fontWeight: FontWeight.w700,
                        color: AppColors.olive,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
