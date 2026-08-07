import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../core/constants/city_labels.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/site_icon.dart';
import 'new_projects_texts.dart';
import 'project_filter.dart';

/// `/new-projects` filtr paneli.
///
/// Shablonda bu yon panel, mobilda "Filterlar" tugmasi bilan ochiladi-yopiladi
/// (`mobileFiltersOpen`) — ya'ni bu sahifada tugma bilan ochiladigan panel **saytning o'zida
/// ham** bor. Maydonlar: shahar, narx oralig'i, topshirish muddati (matn + yil tugmalari).
class NewProjectsFilterSheet extends StatefulWidget {
  const NewProjectsFilterSheet({super.key, required this.filter, required this.years});

  final ProjectFilter filter;

  /// Joriy yildan boshlab olti yil — saytdagi `completionYears`.
  final List<String> years;

  @override
  State<NewProjectsFilterSheet> createState() => _NewProjectsFilterSheetState();
}

class _NewProjectsFilterSheetState extends State<NewProjectsFilterSheet> {
  late ProjectFilter _draft = widget.filter;

  late final _priceMin = TextEditingController(text: _text(_draft.priceMin));
  late final _priceMax = TextEditingController(text: _text(_draft.priceMax));
  late final _completion = TextEditingController(text: _draft.completion);

  static String _text(num value) => value == 0 ? '' : '${value.toInt()}';
  static num _num(TextEditingController c) => num.tryParse(c.text.trim()) ?? 0;

  @override
  void dispose() {
    _priceMin.dispose();
    _priceMax.dispose();
    _completion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
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
                  SiteIcon(
                    SiteIcons.funnel,
                    size: 20,
                    color: AppColors.dark.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      NewProjectsTexts.filters,
                      style: theme.textTheme.titleMedium?.copyWith(color: AppColors.dark),
                    ),
                  ),
                  if (_draft.hasActive)
                    Pressable(
                      onTap: () => setState(() {
                        _draft = ProjectFilter(search: _draft.search, sort: _draft.sort);
                        _priceMin.clear();
                        _priceMax.clear();
                        _completion.clear();
                      }),
                      child: Text(
                        NewProjectsTexts.resetAll,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.olive,
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
                  _label(theme, NewProjectsTexts.city),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAltLight,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _draft.city,
                        isExpanded: true,
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        icon: const SiteIcon(SiteIcons.chevronDown, size: 16),
                        style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.dark),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text(NewProjectsTexts.allCities),
                          ),
                          for (final (value, label) in CityLabels.options)
                            DropdownMenuItem(value: value, child: Text(label)),
                        ],
                        onChanged: (v) => setState(() => _draft = _draft.copyWith(city: v ?? '')),
                      ),
                    ),
                  ),
                  const Divider(height: 32),

                  _label(theme, NewProjectsTexts.priceRange),
                  Row(
                    children: [
                      Expanded(
                        child: _NumberField(controller: _priceMin, hint: NewProjectsTexts.from),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '—',
                          style: TextStyle(color: AppColors.dark.withValues(alpha: 0.3)),
                        ),
                      ),
                      Expanded(
                        child: _NumberField(controller: _priceMax, hint: NewProjectsTexts.to),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      NewProjectsTexts.priceUnit,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 12,
                        color: AppColors.dark.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  const Divider(height: 32),

                  _label(theme, NewProjectsTexts.completion),
                  _NumberField(
                    controller: _completion,
                    hint: NewProjectsTexts.completionHint,
                    numeric: false,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final year in widget.years)
                        Pressable(
                          onTap: () => setState(() {
                            final next = _completion.text.trim() == year ? '' : year;
                            _completion.text = next;
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _completion.text.trim() == year
                                  ? AppColors.olive
                                  : AppColors.surfaceAltLight,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: _completion.text.trim() == year
                                    ? AppColors.olive
                                    : Colors.transparent,
                              ),
                            ),
                            child: Text(
                              year,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: _completion.text.trim() == year
                                    ? Colors.white
                                    : AppColors.dark.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ),
                    ],
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
                    onPressed: () => Navigator.of(context).pop(
                      _draft.copyWith(
                        priceMin: _num(_priceMin),
                        priceMax: _num(_priceMax),
                        completion: _completion.text.trim(),
                      ),
                    ),
                    child: const Text("Ko'rsatish"),
                  ),
                ),
              ),
            ),
          ],
        ),
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
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.hint,
    this.numeric = true,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final bool numeric;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      inputFormatters: numeric ? [FilteringTextInputFormatter.digitsOnly] : null,
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
