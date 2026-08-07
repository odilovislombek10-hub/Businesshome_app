import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/site_icon.dart';
import 'designers_repository.dart';
import 'designers_texts.dart';

/// `/designers` filtr paneli.
///
/// Saytda bu `aside` — katta ekranda yon ustunda yopishib turadi, telefonda esa kartalar ustida
/// to'liq kenglikda. Ilovada u ijara/ikkilamchidagi kabi qidiruv kartasidagi "Filterlar" tugmasi
/// bilan ochiladigan pastki oynaga olindi, chunki sahifada doim ochiq panel ekranning yarmini
/// egallab qolardi.
///
/// Maydonlar va tartibi shablondagidek: mutaxassislik, minimal reyting, narx oralig'i, tajriba.
class DesignersFilterSheet extends StatefulWidget {
  const DesignersFilterSheet({super.key, required this.filter});

  final DesignerFilter filter;

  @override
  State<DesignersFilterSheet> createState() => _DesignersFilterSheetState();
}

class _DesignersFilterSheetState extends State<DesignersFilterSheet> {
  late DesignerFilter _draft = widget.filter;

  late final _priceMin = TextEditingController(text: _text(_draft.priceMin));
  late final _priceMax = TextEditingController(text: _text(_draft.priceMax));

  /// Saytda narx signal'lari `0` — ya'ni "tanlanmagan", maydon bo'sh ko'rinadi.
  static String _text(num value) => value == 0 ? '' : '${value.toInt()}';
  static num _num(TextEditingController c) => num.tryParse(c.text.trim()) ?? 0;

  @override
  void dispose() {
    _priceMin.dispose();
    _priceMax.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(
      context,
    ).pop(_draft.copyWith(priceMin: _num(_priceMin), priceMax: _num(_priceMax)));
  }

  void _reset() {
    setState(() {
      // Saytdagi `resetFilters()` qidiruv va saralashni ham tozalaydi, lekin ular bu oynada emas
      // — hero'dagi maydonda va yuqoridagi ro'yxatda turadi, shuning uchun tegilmaydi.
      _draft = DesignerFilter(search: widget.filter.search, sort: widget.filter.sort);
      _priceMin.clear();
      _priceMax.clear();
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
          // `px-6 py-4 border-b bg-gray-50/50` — panel sarlavhasi.
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
                    DesignersTexts.filters,
                    style: theme.textTheme.titleMedium?.copyWith(color: AppColors.dark),
                  ),
                ),
                if (_draft.hasActive)
                  Pressable(
                    onTap: _reset,
                    child: Text(
                      DesignersTexts.resetAll,
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
              padding: const EdgeInsets.all(24), // p-6
              children: [
                _label(theme, DesignersTexts.specialization),
                // grid-cols-2 gap-2
                GridView.count(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 3.4,
                  children: [
                    for (final (value, text) in DesignersTexts.specializationOptions)
                      _Toggle(
                        label: text,
                        selected: _draft.specializations.contains(value),
                        onTap: () => _toggleSpec(value),
                      ),
                  ],
                ),
                const Divider(height: 32),

                _label(theme, DesignersTexts.minRating),
                Row(
                  children: [
                    for (final (i, value) in DesignersTexts.ratingOptions.indexed) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: _Toggle(
                          label: '${trimZero(value)}+',
                          selected: _draft.minRating == value,
                          solid: true,
                          onTap: () => setState(() {
                            _draft = _draft.copyWith(
                              minRating: _draft.minRating == value ? 0 : value,
                            );
                          }),
                        ),
                      ),
                    ],
                  ],
                ),
                const Divider(height: 32),

                _label(theme, DesignersTexts.priceRange),
                Row(
                  children: [
                    Expanded(
                      child: _NumberField(controller: _priceMin, hint: DesignersTexts.from),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '—',
                        style: TextStyle(color: AppColors.dark.withValues(alpha: 0.3)),
                      ),
                    ),
                    Expanded(
                      child: _NumberField(controller: _priceMax, hint: DesignersTexts.to),
                    ),
                  ],
                ),
                _hint(theme, DesignersTexts.priceUnit),
                const Divider(height: 32),

                _label(theme, DesignersTexts.experience),
                Row(
                  children: [
                    for (final (i, years) in DesignersTexts.experienceOptions.indexed) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: _Toggle(
                          label: '$years+',
                          selected: _draft.minExperience == years,
                          solid: true,
                          onTap: () => setState(() {
                            _draft = _draft.copyWith(
                              minExperience: _draft.minExperience == years ? 0 : years,
                            );
                          }),
                        ),
                      ),
                    ],
                  ],
                ),
                _hint(theme, DesignersTexts.yearsShort),
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
                  onPressed: _submit,
                  child: const Text("Ko'rsatish"),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(ThemeData theme, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12), // mb-3
    child: Text(
      text,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.dark.withValues(alpha: 0.8),
      ),
    ),
  );

  Widget _hint(ThemeData theme, String text) => Padding(
    padding: const EdgeInsets.only(top: 8), // mt-2
    child: Text(
      text,
      style: theme.textTheme.labelSmall?.copyWith(
        fontSize: 12,
        color: AppColors.dark.withValues(alpha: 0.3),
      ),
    ),
  );
}

/// `4.5` → `4.5`, `4.0` → `4` — saytda reyting shu ko'rinishda yoziladi.
String trimZero(double value) => value == value.roundToDouble() ? '${value.toInt()}' : '$value';

/// Panel tugmasi. `solid` — reyting va tajriba qatorlaridagi to'ldirilgan variant
/// (`bg-olive text-white`); qolgani `bg-olive/10 border-olive/30 text-olive`.
class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.label,
    required this.selected,
    required this.onTap,
    this.solid = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // px-3 py-2.5
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? (solid ? AppColors.olive : AppColors.olive.withValues(alpha: 0.1))
              : AppColors.surfaceAltLight,
          borderRadius: BorderRadius.circular(AppRadius.md), // rounded-xl
          border: Border.all(
            color: selected
                ? (solid ? AppColors.olive : AppColors.olive.withValues(alpha: 0.3))
                : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: selected
                ? (solid ? Colors.white : AppColors.olive)
                : AppColors.dark.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14, color: AppColors.dark),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: AppColors.surfaceAltLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        hintText: hint,
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          fontSize: 14,
          color: AppColors.dark.withValues(alpha: 0.4),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.olive),
        ),
      ),
    );
  }
}
