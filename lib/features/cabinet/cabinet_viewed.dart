import '../../core/i18n/translate.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/app_image.dart';
import '../../app/theme.dart';
import '../../core/utils/format.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/site_icon.dart';
import 'cabinet_repository.dart';
import 'cabinet_texts.dart';

/// Kabinetning `viewed` bo'limi — `/market/cabinet/views?limit=20`.
///
/// Shablonda sevimlilarga o'xshash, lekin filtrsiz va nishonchasiz: sarlavha va 4:3 rasmli
/// kartalar to'ri, har birida nom va narx.
///
/// **Diqqat:** shablonda bo'sh holat uchun blok yo'q — ro'yxat bo'sh bo'lsa faqat sarlavha
/// qoladi. Telefonda bu tushunarsiz, shuning uchun qisqa izoh qo'shildi.
class CabinetViewed extends StatelessWidget {
  const CabinetViewed({super.key, required this.future});

  final Future<List<ViewedItem>> future;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<ViewedItem>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data ?? const <ViewedItem>[];
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              CabinetTexts.tabLabel('viewed'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 20, // text-xl
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 16), // space-y-4
            if (items.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  children: [
                    SiteIcon(
                      SiteIcons.clock,
                      size: 40,
                      strokeWidth: 1.5,
                      color: AppColors.dark.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Hali hech narsa ko'rilmagan",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.dark.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
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
                itemCount: items.length,
                itemBuilder: (context, i) => _ViewedCard(item: items[i]),
              ),
          ],
        );
      },
    );
  }
}

class _ViewedCard extends StatelessWidget {
  const _ViewedCard({required this.item});

  final ViewedItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Pressable(
      scale: 0.99,
      onTap: () => context.push(item.detailRoute),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.borderLight),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: item.image != null
                  ? AppImage(
                      imageUrl: item.image!,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => const ColoredBox(color: AppColors.surfaceAltLight),
                      errorWidget: (_, _, _) => const ColoredBox(color: AppColors.surfaceAltLight),
                    )
                  : const ColoredBox(color: AppColors.surfaceAltLight),
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
                      "${formatNumber(item.price)} ${t('hero.currency')}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 15,
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
