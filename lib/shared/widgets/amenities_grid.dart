import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../features/create_listing/create_listing_data.dart';
import '../utils/breakpoints.dart';

/// `amenities-grid.component.ts` — mulk turiga mos qulayliklar.
///
/// E'londa kelgan kalitlar mulk turining ro'yxati bilan solishtiriladi; mos
/// kelmagani ko'rsatilmaydi (saytda ham shunday). Ro'yxatning o'zi e'lon
/// yaratish sahifasidagi bilan bir xil (`getAmenitiesForType`).
class AmenitiesGrid extends StatelessWidget {
  const AmenitiesGrid({super.key, required this.amenities, required this.propertyType});

  final List<String> amenities;
  final String? propertyType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catalogue = ListingOptions.amenitiesFor(propertyType ?? 'apartment');
    final matched = [
      for (final option in catalogue)
        if (amenities.contains(option.value)) option,
    ];
    if (matched.isEmpty) return const SizedBox.shrink();

    final columns = Bp.pick(context, base: 2, md: 3);
    final rows = <Widget>[];
    for (var i = 0; i < matched.length; i += columns) {
      final slice = matched.sublist(i, (i + columns).clamp(0, matched.length));
      rows.add(
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : 12), // gap-3
          child: Row(
            children: [
              for (var c = 0; c < columns; c++) ...[
                if (c > 0) const SizedBox(width: 12),
                Expanded(
                  child: c < slice.length ? _tile(theme, slice[c]) : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24), // p-6
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.surfaceMutedLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Xususiyatlar va qulayliklar',
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 16), // mb-4
          ...rows,
        ],
      ),
    );
  }

  Widget _tile(ThemeData theme, ListingOption option) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // px-3 py-2.5
      decoration: BoxDecoration(
        color: AppColors.olive.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Text(option.icon ?? '', style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10), // gap-2.5
          Expanded(
            child: Text(
              option.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.dark.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
