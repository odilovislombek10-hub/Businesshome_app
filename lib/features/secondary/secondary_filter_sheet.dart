import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../core/models/region.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/site_icon.dart';
import 'secondary_repository.dart';
import 'secondary_texts.dart';

/// The `/secondary` filter panel.
///
/// On the site this is an aside that becomes a full-screen overlay below `lg` (`fixed inset-y-0
/// right-0 … animate-slide-up`); on a phone that is a sheet. Fields and their order are exactly
/// the site's: type, segment, rooms, bathrooms, price, area, floor, seller, payment, furnished,
/// repair, extras.
class SecondaryFilterSheet extends StatefulWidget {
  const SecondaryFilterSheet({super.key, required this.filter, required this.regions});

  final SecondaryFilter filter;
  final List<Region> regions;

  @override
  State<SecondaryFilterSheet> createState() => _SecondaryFilterSheetState();
}

class _SecondaryFilterSheetState extends State<SecondaryFilterSheet> {
  late SecondaryFilter _draft = widget.filter;

  late final _priceMin = TextEditingController(text: _text(_draft.priceMin));
  late final _priceMax = TextEditingController(text: _text(_draft.priceMax));
  late final _areaMin = TextEditingController(text: _text(_draft.areaMin));
  late final _areaMax = TextEditingController(text: _text(_draft.areaMax));
  late final _floorMin = TextEditingController(text: _text(_draft.floorMin));
  late final _floorMax = TextEditingController(text: _text(_draft.floorMax));

  static String _text(num? value) => value == null ? '' : '${value.toInt()}';
  static num? _num(TextEditingController c) => num.tryParse(c.text.trim());

  @override
  void dispose() {
    for (final c in [_priceMin, _priceMax, _areaMin, _areaMax, _floorMin, _floorMax]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(
      _draft.copyWith(
        priceMin: _num(_priceMin),
        priceMax: _num(_priceMax),
        areaMin: _num(_areaMin),
        areaMax: _num(_areaMax),
        floorMin: _num(_floorMin)?.toInt(),
        floorMax: _num(_floorMax)?.toInt(),
      ),
    );
  }

  void _reset() {
    setState(() {
      _draft = SecondaryFilter(sort: widget.filter.sort);
      for (final c in [_priceMin, _priceMax, _areaMin, _areaMax, _floorMin, _floorMax]) {
        c.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.92,
      child: Column(
        children: [
          // `px-6 py-4 border-b bg-gray-50/50` header row.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceAltLight,
              border: Border(bottom: BorderSide(color: AppColors.surfaceMutedLight)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    SecondaryTexts.filters,
                    style: theme.textTheme.titleMedium?.copyWith(color: AppColors.dark),
                  ),
                ),
                if (_draft.hasActive)
                  Pressable(
                    onTap: _reset,
                    child: Text(
                      SecondaryTexts.resetAll,
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
                _Select(
                  label: SecondaryTexts.propertyType,
                  value: _draft.types.isEmpty ? '' : _draft.types.first,
                  options: SecondaryTexts.propertyTypes,
                  onChanged: (v) =>
                      setState(() => _draft = _draft.copyWith(types: v.isEmpty ? const [] : [v])),
                ),
                _Select(
                  label: SecondaryTexts.segment,
                  value: _draft.segment,
                  options: [('', SecondaryTexts.allOption), ...SecondaryTexts.segments],
                  onChanged: (v) => setState(() => _draft = _draft.copyWith(segment: v)),
                ),
                const Divider(height: 32),

                _FieldLabel(SecondaryTexts.rooms),
                Row(
                  children: [
                    for (final room in SecondaryTexts.roomOptions)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8), // gap-2
                          child: _ToggleButton(
                            label: room == 5 ? '5+' : '$room',
                            selected: _draft.rooms.contains(room),
                            onTap: () => setState(() {
                              final rooms = [..._draft.rooms];
                              rooms.contains(room) ? rooms.remove(room) : rooms.add(room);
                              _draft = _draft.copyWith(rooms: rooms);
                            }),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                _Select(
                  label: SecondaryTexts.bathrooms,
                  value: '${_draft.bathrooms}',
                  options: [
                    ('0', SecondaryTexts.allOption),
                    for (final b in SecondaryTexts.bathroomOptions) ('$b', b == 4 ? '4+' : '$b'),
                  ],
                  onChanged: (v) =>
                      setState(() => _draft = _draft.copyWith(bathrooms: int.tryParse(v) ?? 0)),
                ),

                _RangeField(
                  label: SecondaryTexts.priceRange,
                  min: _priceMin,
                  max: _priceMax,
                  suffix: "so'm",
                ),
                _RangeField(label: 'Maydon', min: _areaMin, max: _areaMax, suffix: 'm²'),
                _RangeField(label: SecondaryTexts.floor, min: _floorMin, max: _floorMax),

                _Select(
                  label: SecondaryTexts.seller,
                  value: _draft.seller,
                  options: [('', SecondaryTexts.allOption), ...SecondaryTexts.sellers],
                  onChanged: (v) => setState(() => _draft = _draft.copyWith(seller: v)),
                ),
                _Select(
                  label: SecondaryTexts.payment,
                  value: _draft.payment,
                  options: [('', SecondaryTexts.allOption), ...SecondaryTexts.payments],
                  onChanged: (v) => setState(() => _draft = _draft.copyWith(payment: v)),
                ),
                _Select(
                  label: SecondaryTexts.furnished,
                  value: _draft.furnished,
                  options: const [('', SecondaryTexts.allOption), ('yes', 'Ha'), ('no', "Yo'q")],
                  onChanged: (v) => setState(() => _draft = _draft.copyWith(furnished: v)),
                ),
                _Select(
                  label: SecondaryTexts.repair,
                  value: _draft.repair,
                  options: const [('', SecondaryTexts.allOption), ('yes', 'Ha'), ('no', "Yo'q")],
                  onChanged: (v) => setState(() => _draft = _draft.copyWith(repair: v)),
                ),

                _FieldLabel(SecondaryTexts.extras),
                CheckboxListTile(
                  value: _draft.tour,
                  onChanged: (v) => setState(() => _draft = _draft.copyWith(tour: v ?? false)),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: AppColors.olive,
                  title: const Text('3D tur'),
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
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
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
}

class _Select extends StatelessWidget {
  const _Select({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<(String, String)> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24), // space-y-6
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label),
          Container(
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
                icon: const SiteIcon(SiteIcons.chevronDown, size: 16),
                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.dark),
                items: [for (final (v, l) in options) DropdownMenuItem(value: v, child: Text(l))],
                onChanged: (v) => onChanged(v ?? ''),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The site uses a two-handle range slider; on a phone a min/max pair is the same filter with a
/// keyboard that is easier to hit than a 4px handle.
class _RangeField extends StatelessWidget {
  const _RangeField({required this.label, required this.min, required this.max, this.suffix});

  final String label;
  final TextEditingController min;
  final TextEditingController max;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    InputDecoration decoration(String hint) => InputDecoration(
      hintText: hint,
      suffixText: suffix,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: min,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: decoration('dan'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: max,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: decoration('gacha'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.olive : AppColors.surfaceAltLight,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: selected ? AppColors.olive : Colors.transparent),
        ),
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: selected ? Colors.white : AppColors.dark.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }
}
