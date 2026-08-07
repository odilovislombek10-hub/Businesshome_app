import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/models/region.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/site_icon.dart';
import 'birja_repository.dart';
import 'birja_texts.dart';

/// `/birja` filtr paneli.
///
/// Shablonda bu yon ustundagi `aside`; ilovada boshqa ro'yxat sahifalaridagi kabi "Filterlar"
/// tugmasi bilan ochiladigan pastki oyna. Maydonlar va tartibi o'zgarmagan: mutaxassis turi
/// (tugmachalar), obyekt turi, shahar va saralash (ro'yxatlar).
class BirjaFilterSheet extends StatefulWidget {
  const BirjaFilterSheet({super.key, required this.filter, required this.regions});

  final BriefFilter filter;

  /// `/market/regions` dan — shablonda `regionsWithDistricts` ro'yxati ishlatiladi.
  final List<Region> regions;

  @override
  State<BirjaFilterSheet> createState() => _BirjaFilterSheetState();
}

class _BirjaFilterSheetState extends State<BirjaFilterSheet> {
  late BriefFilter _draft = widget.filter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.92,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: AppColors.surfaceAltLight,
              border: Border(bottom: BorderSide(color: AppColors.surfaceMutedLight)),
            ),
            child: Row(
              children: [
                SiteIcon(SiteIcons.funnel, size: 20, color: AppColors.dark.withValues(alpha: 0.5)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    BirjaTexts.filters,
                    style: theme.textTheme.titleMedium?.copyWith(color: AppColors.dark),
                  ),
                ),
                if (_draft.hasActive)
                  Pressable(
                    onTap: () => setState(() => _draft = BriefFilter(sort: _draft.sort)),
                    child: Text(
                      BirjaTexts.resetAll,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 12,
                        color: AppColors.olive,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                Pressable(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.dark.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: SiteIcon(SiteIcons.close, size: 16, color: AppColors.dark),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(18), // p-[18px]
              children: [
                _SectionLabel(BirjaTexts.specialistType),
                Wrap(
                  spacing: 7, // gap-[7px]
                  runSpacing: 7,
                  children: [
                    for (final (value, label) in BirjaTexts.targetOptions)
                      _Pill(
                        label: label,
                        selected: _draft.target == value,
                        onTap: () => setState(() => _draft = _draft.copyWith(target: value)),
                      ),
                  ],
                ),
                const SizedBox(height: 20), // mb-5

                _SectionLabel(BirjaTexts.propertyType),
                _Select(
                  value: _draft.projectType,
                  options: BirjaTexts.typeOptions,
                  onChanged: (v) => setState(() => _draft = _draft.copyWith(projectType: v)),
                ),
                const SizedBox(height: 20),

                _SectionLabel(BirjaTexts.city),
                _Select(
                  value: _draft.city,
                  options: [
                    ('', BirjaTexts.all),
                    for (final r in widget.regions) (r.value, r.label),
                  ],
                  onChanged: (v) => setState(() => _draft = _draft.copyWith(city: v)),
                ),
                const SizedBox(height: 20),

                _SectionLabel(BirjaTexts.sort),
                _Select(
                  value: _draft.sort,
                  options: BirjaTexts.sortOptions,
                  onChanged: (v) => setState(() => _draft = _draft.copyWith(sort: v)),
                ),
              ],
            ),
          ),

          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.olive),
                  onPressed: () => Navigator.of(context).pop(_draft),
                  child: const Text("Ko'rsatish"),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `text-[12px] font-bold tracking-[0.05em] uppercase text-dark/40 mb-2.5`
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: AppColors.dark.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

/// `px-3 py-[7px] rounded-full text-[13px] font-semibold border`
class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.olive : const Color(0xFFF5F3EC),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: selected ? AppColors.olive : const Color(0xFFE7E3D8)),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF6F6C5F),
          ),
        ),
      ),
    );
  }
}

/// `px-3.5 py-2.5 rounded-xl border bg-[#F5F3EC] text-[14px] font-semibold`
class _Select extends StatelessWidget {
  const _Select({required this.value, required this.options, required this.onChanged});

  final String value;
  final List<(String, String)> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3EC),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: const Color(0xFFE7E3D8)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: options.any((o) => o.$1 == value) ? value : options.first.$1,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(vertical: 2),
          icon: const SiteIcon(SiteIcons.chevronDown, size: 16),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.dark,
          ),
          items: [for (final (v, label) in options) DropdownMenuItem(value: v, child: Text(label))],
          onChanged: (v) => onChanged(v ?? ''),
        ),
      ),
    );
  }
}
