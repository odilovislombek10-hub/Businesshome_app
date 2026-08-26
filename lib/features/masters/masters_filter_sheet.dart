import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/constants/city_labels.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/site_icon.dart';
import 'masters_repository.dart';
import 'masters_texts.dart';

/// `/masters` filtr paneli.
///
/// Saytda bu yon ustundagi `aside`, mobilda kartalar ustida ochiq turadi. Ilovada u qidiruv
/// qatoridagi "Filterlar" tugmasi bilan ochiladigan pastki oynaga olindi — ijara, ikkilamchi va
/// dizaynerlardagi kabi.
///
/// Maydonlar va tartibi shablondagidek: mutaxassislik, bandlik holati, shahar, minimal reyting,
/// "faqat tasdiqlangan". Dizaynerlardan farqli — bu yerda narx va tajriba filtri **yo'q**
/// (`priceMin`/`filterMinExp` signal'lari bor, lekin ularga tugma qo'yilmagan).
class MastersFilterSheet extends StatefulWidget {
  const MastersFilterSheet({super.key, required this.filter});

  final MasterFilter filter;

  @override
  State<MastersFilterSheet> createState() => _MastersFilterSheetState();
}

class _MastersFilterSheetState extends State<MastersFilterSheet> {
  late MasterFilter _draft = widget.filter;

  void _reset() {
    setState(() {
      // Qidiruv va saralash oynadan tashqarida — ularga tegilmaydi.
      _draft = MasterFilter(search: widget.filter.search, sort: widget.filter.sort);
    });
  }

  void _toggleSpec(String value) {
    setState(() {
      final next = [..._draft.specializations];
      if (!next.remove(value)) next.add(value);
      _draft = _draft.copyWith(specializations: next);
    });
  }

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
                    MastersTexts.filters,
                    style: theme.textTheme.titleMedium?.copyWith(color: AppColors.dark),
                  ),
                ),
                if (_draft.hasActive)
                  Pressable(
                    onTap: _reset,
                    child: Text(
                      MastersTexts.resetAll,
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
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18), // p-[18px]
              children: [
                _SectionLabel(MastersTexts.specialization),
                Wrap(
                  spacing: 7, // gap-[7px]
                  runSpacing: 7,
                  children: [
                    _Pill(
                      label: MastersTexts.allSpecs,
                      selected: _draft.specializations.isEmpty,
                      onTap: () =>
                          setState(() => _draft = _draft.copyWith(specializations: const [])),
                    ),
                    for (final (value, label) in MastersTexts.specializationOptions)
                      _Pill(
                        label: label,
                        selected: _draft.specializations.contains(value),
                        onTap: () => _toggleSpec(value),
                      ),
                  ],
                ),
                const SizedBox(height: 20), // mb-5

                _SectionLabel(MastersTexts.availability),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    for (final (value, label) in MastersTexts.availabilityOptions)
                      _Pill(
                        label: label,
                        selected: _draft.availability == value,
                        onTap: () => setState(() => _draft = _draft.copyWith(availability: value)),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                _SectionLabel(MastersTexts.city),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14), // px-3.5
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAltLight,
                    borderRadius: BorderRadius.circular(AppRadius.md), // rounded-xl
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _draft.city,
                      isExpanded: true,
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      icon: const SiteIcon(SiteIcons.chevronDown, size: 16),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dark,
                      ),
                      items: [
                        DropdownMenuItem(value: '', child: Text(MastersTexts.allCities)),
                        for (final (value, label) in CityLabels.options)
                          DropdownMenuItem(value: value, child: Text(label)),
                      ],
                      onChanged: (value) =>
                          setState(() => _draft = _draft.copyWith(city: value ?? '')),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                _SectionLabel(MastersTexts.minRating),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _Pill(
                      label: MastersTexts.allRatings,
                      selected: _draft.minRating == 0,
                      onTap: () => setState(() => _draft = _draft.copyWith(minRating: 0)),
                    ),
                    for (final value in MastersTexts.ratingOptions)
                      _Pill(
                        label: '${_trim(value)}+',
                        selected: _draft.minRating == value,
                        onTap: () => setState(() => _draft = _draft.copyWith(minRating: value)),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // "Faqat tasdiqlangan" — butun qator bosiladi, o'ngida kalit.
                Pressable(
                  scale: 1,
                  onTap: () =>
                      setState(() => _draft = _draft.copyWith(verifiedOnly: !_draft.verifiedOnly)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAltLight,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Row(
                      children: [
                        const Text('✔ ', style: TextStyle(color: Color(0xFF62633C))),
                        Expanded(
                          child: Text(
                            MastersTexts.verifiedOnly,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.dark,
                            ),
                          ),
                        ),
                        _Switch(on: _draft.verifiedOnly),
                      ],
                    ),
                  ),
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

String _trim(double value) => value == value.roundToDouble() ? '${value.toInt()}' : '$value';

/// `text-[12px] font-bold tracking-[0.05em] uppercase text-dark/40 mb-2.5`
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10), // mb-2.5
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6, // tracking-[0.05em]
          color: AppColors.dark.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

/// Yumaloq tanlov tugmasi — `px-3 py-[7px] rounded-full text-[13px] font-semibold border`.
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

/// `w-[38px] h-[22px]` kalit — shablondagi o'lchamlari bilan.
class _Switch extends StatelessWidget {
  const _Switch({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      height: 22,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: on ? AppColors.olive : const Color(0xFFD8D3C5),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 150),
            top: 2,
            left: on ? 18 : 2,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 3)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
