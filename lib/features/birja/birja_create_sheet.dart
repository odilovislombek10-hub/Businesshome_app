import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../core/models/region.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/site_icon.dart';
import 'birja_texts.dart';

/// Yangi birja buyurtmasi formasi — saytdagi "create" modalning ko'chirmasi.
///
/// Maydonlar va tartibi shablondagidek: mutaxassis turi, sarlavha, tafsilot, obyekt turi va
/// maydon, shahar va tuman, narx oralig'i, valyuta, muddat.
///
/// Yopilganda `POST /market/birja` uchun tayyor tanani qaytaradi (bekor qilinsa `null`).
class BirjaCreateSheet extends StatefulWidget {
  const BirjaCreateSheet({super.key, required this.regions});

  final List<Region> regions;

  @override
  State<BirjaCreateSheet> createState() => _BirjaCreateSheetState();
}

class _BirjaCreateSheetState extends State<BirjaCreateSheet> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _area = TextEditingController();
  final _budgetFrom = TextEditingController();
  final _budgetTo = TextEditingController();

  String _target = 'designer';
  String _projectType = '';
  String _city = '';
  String _district = '';
  String _currency = 'UZS';
  DateTime? _deadline;

  List<District> get _districts => widget.regions
      .firstWhere(
        (r) => r.value == _city,
        orElse: () => const Region(value: '', label: ''),
      )
      .districts;

  @override
  void dispose() {
    for (final c in [_title, _description, _area, _budgetFrom, _budgetTo]) {
      c.dispose();
    }
    super.dispose();
  }

  int? _int(TextEditingController c) => int.tryParse(c.text.trim());

  void _submit() {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    Navigator.of(context).pop(<String, dynamic>{
      'target': _target,
      'title': title,
      'description': _description.text.trim(),
      'project_type': _projectType.isEmpty ? null : _projectType,
      'city': _city.isEmpty ? null : _city,
      'district': _district.isEmpty ? null : _district,
      'area_m2': _int(_area),
      'budget_from': _int(_budgetFrom),
      'budget_to': _int(_budgetTo),
      // Saytda valyuta tanlanadi, lekin so'rov tanasiga **qo'shilmaydi** — natijada tanlov
      // yo'qoladi va byudjet doim UZS bo'lib saqlanadi. Backend `currency` ni qabul qiladi,
      // shuning uchun bu yerda yuboriladi.
      'currency': _currency,
      'deadline': _deadline == null ? null : _dateWire(_deadline!),
    });
  }

  static String _dateWire(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.92,
        child: Column(
          children: [
            // `sticky top-0 … px-6 py-4` sarlavha qatori.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.borderLight)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '📋 Yangi birja buyurtmasi',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                    ),
                  ),
                  Pressable(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.dark.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
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
                  _label(theme, 'Mutaxassis turi *'),
                  Row(
                    children: [
                      for (final (value, label) in const [
                        ('designer', 'Dizayner'),
                        ('master', 'Usta'),
                      ]) ...[
                        if (value != 'designer') const SizedBox(width: 8),
                        _Choice(
                          label: label,
                          selected: _target == value,
                          onTap: () => setState(() => _target = value),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16), // space-y-4

                  _label(theme, 'Sarlavha *'),
                  _Field(
                    controller: _title,
                    hint: 'Misol: 3-xonali kvartira uchun zamonaviy dizayn kerak',
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),

                  _label(theme, 'Tafsilot'),
                  _Field(
                    controller: _description,
                    maxLines: 4,
                    hint: "Loyiha haqida: maydoni, xohlagan uslub, talab, qo'shimcha shartlar...",
                  ),
                  const SizedBox(height: 16),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label(theme, BirjaTexts.propertyType),
                            _Select(
                              value: _projectType,
                              options: [
                                ('', '—'),
                                for (final (v, l) in BirjaTexts.typeOptions)
                                  if (v.isNotEmpty) (v, l),
                              ],
                              onChanged: (v) => setState(() => _projectType = v),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12), // gap-3
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label(theme, 'Maydon (m²)'),
                            _Field(controller: _area, numeric: true),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label(theme, BirjaTexts.city),
                            _Select(
                              value: _city,
                              options: [
                                ('', '—'),
                                for (final r in widget.regions) (r.value, r.label),
                              ],
                              // Shahar almashsa tuman tozalanadi — saytdagi `onCityChange`.
                              onChanged: (v) => setState(() {
                                _city = v;
                                _district = '';
                              }),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label(theme, 'Tuman'),
                            _Select(
                              value: _district,
                              enabled: _city.isNotEmpty,
                              options: [('', '—'), for (final d in _districts) (d.value, d.label)],
                              onChanged: (v) => setState(() => _district = v),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label(theme, 'Narx dan'),
                            _Field(
                              controller: _budgetFrom,
                              numeric: true,
                              hint: '0',
                              suffix: _currency == 'USD' ? '\$' : "so'm",
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label(theme, 'Narx gacha'),
                            _Field(
                              controller: _budgetTo,
                              numeric: true,
                              hint: '0',
                              suffix: _currency == 'USD' ? '\$' : "so'm",
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _label(theme, 'Valyuta'),
                  Row(
                    children: [
                      for (final (value, label) in const [
                        ('UZS', "so'm (UZS)"),
                        ('USD', '\$ (USD)'),
                      ]) ...[
                        if (value != 'UZS') const SizedBox(width: 8),
                        Expanded(
                          child: _Choice(
                            label: label,
                            selected: _currency == value,
                            onTap: () => setState(() => _currency = value),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  _label(theme, 'Muddati'),
                  Pressable(
                    scale: 1,
                    onTap: _pickDeadline,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAltLight,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Text(
                        _deadline == null ? '—' : _dateWire(_deadline!),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _deadline == null
                              ? AppColors.dark.withValues(alpha: 0.4)
                              : AppColors.dark,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // `sticky bottom-0 … border-t` amal qatori.
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.borderLight)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(BirjaTexts.cancel),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: AppColors.olive),
                      // Saytda ham tugma sarlavha bo'sh bo'lsa o'chiq turadi.
                      onPressed: _title.text.trim().isEmpty ? null : _submit,
                      child: const Text('Joylash'),
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

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Widget _label(ThemeData theme, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6), // mb-1.5
    child: Text(
      text,
      style: theme.textTheme.labelSmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.dark.withValues(alpha: 0.7),
      ),
    ),
  );
}

/// `px-4 py-2 rounded-xl text-sm font-semibold border` — tanlangan holatda olive.
class _Choice extends StatelessWidget {
  const _Choice({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.olive : AppColors.surfaceAltLight,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: selected ? AppColors.olive : AppColors.borderLight),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.dark,
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    this.hint,
    this.maxLines = 1,
    this.numeric = false,
    this.suffix,
    this.onChanged,
  });

  final TextEditingController controller;
  final String? hint;
  final int maxLines;
  final bool numeric;
  final String? suffix;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      // Saytda `updateFormNumber` raqam bo'lmagan belgilarni tashlab yuboradi.
      inputFormatters: numeric ? [FilteringTextInputFormatter.digitsOnly] : null,
      style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.dark),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: AppColors.surfaceAltLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        hintText: hint,
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.dark.withValues(alpha: 0.4),
        ),
        suffixText: suffix,
        suffixStyle: theme.textTheme.labelSmall?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w700,
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

class _Select extends StatelessWidget {
  const _Select({
    required this.value,
    required this.options,
    required this.onChanged,
    this.enabled = true,
  });

  final String value;
  final List<(String, String)> options;
  final ValueChanged<String> onChanged;

  /// Tuman ro'yxati shahar tanlanmaguncha o'chiq — saytdagi `[disabled]="!form().city"`.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceAltLight,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: options.any((o) => o.$1 == value) ? value : options.first.$1,
            isExpanded: true,
            padding: const EdgeInsets.symmetric(vertical: 2),
            icon: const SiteIcon(SiteIcons.chevronDown, size: 16),
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.dark),
            items: [
              for (final (v, label) in options)
                DropdownMenuItem(
                  value: v,
                  child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: enabled ? (v) => onChanged(v ?? '') : null,
          ),
        ),
      ),
    );
  }
}
