import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/api/api_client.dart';
import '../../shared/utils/breakpoints.dart';
import '../../shared/widgets/entrance.dart';
import 'cabinet_texts.dart';

/// Kabinet profilidagi "Mavjudligim" bloki — faqat dizayner va usta uchun.
///
/// Saytdagi `cabinet.component.ts` → "BANDLIK HOLATI": sarlavha, hozirgi holat
/// nishonchasi, beshta holat tugmasi, band bo'lsa "qachondan boshlab" sanasi
/// va mijozlar uchun izoh. Har o'zgarishda `PUT
/// /market/cabinet/specialist-profile/availability` yuboriladi.
class CabinetAvailability extends StatefulWidget {
  const CabinetAvailability({super.key, this.initialStatus, this.initialNote, this.initialFrom});

  final String? initialStatus;
  final String? initialNote;
  final String? initialFrom;

  @override
  State<CabinetAvailability> createState() => _CabinetAvailabilityState();
}

class _CabinetAvailabilityState extends State<CabinetAvailability> {
  late String _status = widget.initialStatus ?? 'available';
  late final _note = TextEditingController(text: widget.initialNote ?? '');
  late String? _from = widget.initialFrom;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  /// `availabilityStatusInfo()` — nishoncha matni, izoh va joy tutuvchi.
  ({String label, String subtitle, String placeholder, Color color, Color background}) get _info =>
      switch (_status) {
        'busy' => (
          label: '🟡 Band',
          subtitle: "Hozir band — qisqa muddatda yana bo'shaysiz",
          placeholder: 'Masalan: 2 ta loyiha ustida ishlayapman',
          color: const Color(0xFFB45309),
          background: const Color(0xFFFEF3C7),
        ),
        'full' => (
          label: '🔴 Toʼliq band',
          subtitle: 'Yangi buyurtmalar qabul qilinmaydi',
          placeholder: "Masalan: dekabrgacha navbat to'la",
          color: const Color(0xFFB91C1C),
          background: const Color(0xFFFEE2E2),
        ),
        'vacation' => (
          label: '🏖️ Taʼtilda',
          subtitle: "Vaqtinchalik xizmat ko'rsatmaysiz",
          placeholder: "Masalan: Bali'ga ta'tilga ketdim",
          color: const Color(0xFF0369A1),
          background: const Color(0xFFE0F2FE),
        ),
        'offline' => (
          label: '⚪ Oflayn',
          subtitle: "Profilingiz qidiruvda ko'rinmaydi",
          placeholder: 'Izoh kiritish',
          color: const Color(0xFF475569),
          background: const Color(0xFFF1F5F9),
        ),
        _ => (
          label: '🟢 Mavjud',
          subtitle: 'Yangi buyurtmalarni qabul qilyapsiz',
          placeholder: 'Masalan: tezda javob beraman',
          color: const Color(0xFF047857),
          background: const Color(0xFFD1FAE5),
        ),
      };

  Future<void> _save({String? previous}) async {
    try {
      await ApiClient.instance.put<dynamic>(
        '/market/cabinet/specialist-profile/availability',
        data: {
          'availability_status': _status,
          'availability_note': _note.text.trim().isEmpty ? null : _note.text.trim(),
          'available_from': _from,
        },
      );
    } catch (_) {
      // Saytda xatolikda oldingi holat qaytariladi.
      if (previous != null && mounted) setState(() => _status = previous);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) return;
    setState(() {
      _from =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-'
          '${picked.day.toString().padLeft(2, '0')}';
    });
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final info = _info;
    final needsDate = _status == 'busy' || _status == 'full' || _status == 'vacation';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20), // p-5
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      CabinetTexts.availability,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 16, // text-base
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 2), // mt-0.5
                    Text(
                      info.subtitle,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 12,
                        color: AppColors.dark.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12), // gap-3
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: info.background,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  info.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: info.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16), // space-y-4
          // `grid-cols-2 sm:grid-cols-5 gap-2`
          _statusGrid(theme),
          if (needsDate) ...[
            const SizedBox(height: 16),
            Text(
              CabinetTexts.availableFromLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.dark.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 6), // mb-1.5
            Pressable(
              scale: 0.99,
              onTap: _pickDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAltLight,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Text(
                  _from ?? 'kk.oo.yyyy',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    color: _from == null ? AppColors.dark.withValues(alpha: 0.4) : AppColors.dark,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Izoh (mijozlar uchun ixtiyoriy)',
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.dark.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _note,
            maxLength: 255,
            onEditingComplete: _save,
            onTapOutside: (_) => _save(),
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
            decoration: InputDecoration(
              hintText: info.placeholder,
              counterText: '',
              filled: true,
              fillColor: AppColors.surfaceAltLight,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusGrid(ThemeData theme) {
    const options = CabinetTexts.availabilityOptions;
    final columns = Bp.pick(context, base: 2, sm: 5);
    final rows = <Widget>[];
    for (var i = 0; i < options.length; i += columns) {
      final slice = options.sublist(i, (i + columns).clamp(0, options.length));
      rows.add(
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : 8), // gap-2
          child: Row(
            children: [
              for (var c = 0; c < columns; c++) ...[
                if (c > 0) const SizedBox(width: 8),
                Expanded(
                  child: c < slice.length ? _chip(theme, slice[c]) : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _chip(ThemeData theme, ({String value, String label, String emoji, Color color}) option) {
    final active = _status == option.value;
    return Pressable(
      scale: 0.98,
      onTap: () {
        final previous = _status;
        setState(() => _status = option.value);
        _save(previous: previous);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10), // px-2 py-2.5
        decoration: BoxDecoration(
          color: active ? option.color : AppColors.surfaceAltLight,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: active ? option.color : AppColors.borderLight),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(option.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6), // gap-1.5
            Flexible(
              child: Text(
                option.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : AppColors.dark.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
