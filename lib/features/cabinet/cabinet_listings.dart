import '../../core/i18n/translate.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/app_image.dart';
import '../../app/theme.dart';
import '../../core/constants/city_labels.dart';
import '../../core/utils/format.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/site_icon.dart';
import 'cabinet_repository.dart';
import 'cabinet_texts.dart';

/// Kabinetning `listings` bo'limi — `/market/cabinet/my-listings`.
///
/// Shablonda karta 3:4 rasm ustiga qurilgan (`from-dark via-dark/40 to-transparent` pardasi
/// bilan): tepada moderatsiya va bitim turi nishonchalari, rad etilgan bo'lsa sabab, pastda
/// nom, shahar | maydon, narx, ko'rish/so'rov sanog'i, sana va ikki tugma — "Tahrirlash" va
/// o'chirish.
class CabinetListings extends StatelessWidget {
  const CabinetListings({
    super.key,
    required this.future,
    required this.canCreate,
    required this.onDelete,
  });

  final Future<List<MyListing>> future;

  /// Saytda "Mulk e'lonlari faqat user/agent uchun" — tugma shu shartga bog'liq.
  final bool canCreate;
  final Future<void> Function(MyListing) onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<MyListing>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data ?? const <MyListing>[];

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    CabinetTexts.tabLabel('listings'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 20, // text-xl
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                    ),
                  ),
                ),
                if (canCreate)
                  Pressable(
                    onTap: () => context.push('/ads/create'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.olive,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Text(
                        '+ ${CabinetTexts.newListing}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16), // space-y-4
            if (items.isEmpty)
              _empty(context)
            else
              GridView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20, // gap-5
                  crossAxisSpacing: 20,
                  // `aspect-ratio: 3/4`
                  childAspectRatio: 3 / 4,
                ),
                itemCount: items.length,
                itemBuilder: (context, i) => _ListingCard(listing: items[i], onDelete: onDelete),
              ),
          ],
        );
      },
    );
  }

  Widget _empty(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(48), // p-12
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.surfaceAltLight,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SiteIcon(
                SiteIcons.list,
                size: 28,
                color: AppColors.dark.withValues(alpha: 0.3),
              ),
            ),
          ),
          const SizedBox(height: 16), // mb-4
          Text(
            CabinetTexts.noListings,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 18, // text-lg
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 8), // mb-2
          Text(
            CabinetTexts.noListingsDesc,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.dark.withValues(alpha: 0.5),
            ),
          ),
          if (canCreate) ...[
            const SizedBox(height: 16), // mb-4
            Pressable(
              onTap: () => context.push('/ads/create'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.olive,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  '+ ${CabinetTexts.createListing}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.listing, required this.onDelete});

  final MyListing listing;
  final Future<void> Function(MyListing) onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mod = listing.moderationStatus;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg), // rounded-2xl
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (listing.images.isNotEmpty)
            AppImage(
              imageUrl: listing.images.first,
              fit: BoxFit.cover,
              placeholder: (_, _) => const ColoredBox(color: AppColors.surfaceAltLight),
              errorWidget: (_, _, _) => const ColoredBox(color: AppColors.surfaceMutedLight),
            )
          else
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE2E8F0), Color(0xFF94A3B8)],
                ),
              ),
            ),

          // `from-dark via-dark/40 to-transparent`, pastdan yuqoriga.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppColors.dark,
                    AppColors.dark.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12), // p-4
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (mod != null)
                      _badge(theme, CabinetTexts.modLabel(mod), CabinetTexts.modColor(mod)),
                    if (listing.dealType case final deal?)
                      _badge(
                        theme,
                        CabinetTexts.dealTypeLabel(deal),
                        AppColors.dark.withValues(alpha: 0.6),
                      ),
                  ],
                ),
                if (mod == 'rejected' && listing.rejectedReason != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xD9EF4444),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      listing.rejectedReason!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],

                const Spacer(),

                Text(
                  listing.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _location(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10.5,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatNumber(listing.price)} ${_currencyLabel()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 15, // text-lg → yarim kenglikda 15
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '👁 ${listing.views}   💬 ${listing.inquiries}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 9.5,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    const Spacer(),
                    if (listing.createdAt case final created?)
                      Text(
                        _date(created),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 9.5,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Pressable(
                        onTap: () => context.push('/ads/${listing.id}/edit?kind=${listing.source}'),
                        child: Container(
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Text(
                            CabinetTexts.edit,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.olive,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Pressable(
                      onTap: () => _confirmDelete(context),
                      child: Container(
                        width: 34,
                        height: 30,
                        decoration: BoxDecoration(
                          color: const Color(0x33EF4444),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: const Center(
                          child: SiteIcon(SiteIcons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _location() => [
    if (listing.city case final city?) CityLabels.label(city),
    if (listing.area case final area?) '${formatNumber(area)} m²',
  ].join(' | ');

  /// Saytdagi `getCurrencyLabel` — e'lonning o'z valyutasi.
  String _currencyLabel() => listing.currency?.toLowerCase() == 'usd' ? '\$' : t('hero.currency');

  /// `formatListingDate()` — bugun, kecha, N kun oldin, keyin esa sana.
  static String _date(DateTime value) {
    final days = DateTime.now().difference(value).inDays;
    if (days == 0) return CabinetTexts.today;
    if (days == 1) return CabinetTexts.yesterday;
    if (days < 30) return '$days ${CabinetTexts.daysAgo}';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(value.day)}.${two(value.month)}.${value.year}';
  }

  Widget _badge(ThemeData theme, String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppRadius.pill)),
    child: Text(
      text,
      style: theme.textTheme.labelSmall?.copyWith(
        fontSize: 9.5,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
  );

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(CabinetTexts.deleteConfirmTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(CabinetTexts.deleteConfirmMessage),
            const SizedBox(height: 8),
            Text('"${listing.title}"', style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(CabinetTexts.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(CabinetTexts.deleteConfirmYes),
          ),
        ],
      ),
    );
    if (confirmed == true) await onDelete(listing);
  }
}
