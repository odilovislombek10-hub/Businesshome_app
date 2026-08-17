import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/utils/format.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/site_icon.dart';
import 'cabinet_repository.dart';
import 'cabinet_texts.dart';

/// Kabinetning `earnings` bo'limi — saytdagi `earningsTpl`.
///
/// Tepada davr filtri (tezkor tugmalar, sana oralig'i va guruhlash), so'ng zaytun gradientli
/// umumiy summa kartasi, pastida maydon grafigi va ustunlar bilan davrlar ro'yxati.
class CabinetEarnings extends StatefulWidget {
  const CabinetEarnings({super.key});

  @override
  State<CabinetEarnings> createState() => _CabinetEarningsState();
}

class _CabinetEarningsState extends State<CabinetEarnings> {
  final _repo = const CabinetRepository();

  String _range = 'month';
  String _granularity = 'day';
  String _from = '';
  String _to = '';

  late Future<List<Earning>> _future;

  @override
  void initState() {
    super.initState();
    _applyRange('month', reload: false);
    _future = _load();
  }

  Future<List<Earning>> _load() =>
      _repo.earnings(from: _from.isEmpty ? null : _from, to: _to, granularity: _granularity);

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Saytdagi `setEarningsRange` — har bir davr o'z guruhlashini ham belgilaydi.
  void _applyRange(String range, {bool reload = true}) {
    final today = DateTime.now();
    DateTime? from;
    var granularity = 'month';
    switch (range) {
      case 'week':
        from = today.subtract(const Duration(days: 7));
        granularity = 'day';
      case 'month':
        from = DateTime(today.year, today.month - 1, today.day);
        granularity = 'day';
      case 'quarter':
        from = DateTime(today.year, today.month - 3, today.day);
      case 'year':
        from = DateTime(today.year - 1, today.month, today.day);
      default:
        from = null;
        granularity = 'year';
    }
    _range = range;
    _granularity = granularity;
    _from = from == null ? '' : _fmt(from);
    _to = _fmt(today);
    if (reload) setState(() => _future = _load());
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final current = DateTime.tryParse(isFrom ? _from : _to) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(now.year - 10),
      lastDate: now,
    );
    if (picked == null) return;
    setState(() {
      // Sana qo'lda tanlansa tezkor tugma tanlovi bekor bo'ladi — saytda ham shunday.
      _range = 'custom';
      if (isFrom) {
        _from = _fmt(picked);
      } else {
        _to = _fmt(picked);
      }
      _future = _load();
    });
  }

  String get _rangeLabel {
    for (final (key, _, label) in CabinetTexts.earningRanges) {
      if (key == _range) return label;
    }
    return '${_from.isEmpty ? '...' : _from} → ${_to.isEmpty ? '...' : _to}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<Earning>>(
      future: _future,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState == ConnectionState.waiting;
        if (snapshot.hasError) {
          return ErrorView(
            message: CabinetTexts.earningsLoadError,
            onRetry: () => setState(() => _future = _load()),
          );
        }
        final items = snapshot.data ?? const <Earning>[];
        final total = items.fold<num>(0, (sum, e) => sum + e.amount);

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              CabinetTexts.tabLabel('earnings'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 20, // text-xl
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 16), // space-y-4
            _filterCard(theme),
            const SizedBox(height: 16),
            _totalCard(theme, total),
            const SizedBox(height: 16),
            _chartCard(theme, items, loading),
          ],
        );
      },
    );
  }

  Widget _filterCard(ThemeData theme) => Container(
    padding: const EdgeInsets.all(16), // p-4
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: AppColors.borderLight),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8, // gap-2
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              CabinetTexts.earningsQuick,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.dark.withValues(alpha: 0.6),
              ),
            ),
            for (final (key, label, _) in CabinetTexts.earningRanges)
              _chip(theme, label, active: _range == key, onTap: () => _applyRange(key)),
          ],
        ),
        const SizedBox(height: 12), // space-y-3
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _dateField(theme, CabinetTexts.earningsFrom, _from, isFrom: true)),
            const SizedBox(width: 8), // gap-2
            Expanded(child: _dateField(theme, CabinetTexts.earningsTo, _to, isFrom: false)),
          ],
        ),
        const SizedBox(height: 8),
        _label(theme, CabinetTexts.earningsGrouping),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceAltLight,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _granularity,
              isExpanded: true,
              icon: const SiteIcon(SiteIcons.chevronDown, size: 16),
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.dark),
              items: [
                for (final (value, label) in CabinetTexts.earningGranularities)
                  DropdownMenuItem(value: value, child: Text(label)),
              ],
              onChanged: (value) => setState(() {
                _granularity = value ?? 'month';
                _future = _load();
              }),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _chip(
    ThemeData theme,
    String label, {
    required bool active,
    required VoidCallback onTap,
  }) => Pressable(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // px-3 py-1.5
      decoration: BoxDecoration(
        color: active ? AppColors.olive : AppColors.surfaceMutedLight,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: active ? AppColors.olive : AppColors.borderLight),
        boxShadow: active
            ? const [BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 4))]
            : null,
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: 12, // text-xs
          fontWeight: FontWeight.w600,
          color: active ? Colors.white : AppColors.dark,
        ),
      ),
    ),
  );

  Widget _dateField(ThemeData theme, String label, String value, {required bool isFrom}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _label(theme, label),
      Pressable(
        onTap: () => _pickDate(isFrom: isFrom),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12), // px-3 py-2
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: AppColors.surfaceAltLight,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Text(
            value.isEmpty ? '—' : value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: value.isEmpty ? AppColors.dark.withValues(alpha: 0.4) : AppColors.dark,
            ),
          ),
        ),
      ),
    ],
  );

  Widget _label(ThemeData theme, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4), // mb-1
    child: Text(
      text,
      style: theme.textTheme.labelSmall?.copyWith(
        fontSize: 11, // text-[11px]
        fontWeight: FontWeight.w600,
        color: AppColors.dark.withValues(alpha: 0.6),
      ),
    ),
  );

  /// `bg-gradient-to-br from-olive to-olive/80 rounded-2xl p-6 text-white`
  Widget _totalCard(ThemeData theme, num total) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24), // p-6
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.olive, AppColors.olive.withValues(alpha: 0.8)],
      ),
      borderRadius: BorderRadius.circular(AppRadius.lg),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          CabinetTexts.totalEarnings,
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.8)),
        ),
        const SizedBox(height: 8), // mt-2
        Text(
          '${formatNumber(total)} ${CabinetTexts.soum}',
          style: theme.textTheme.displaySmall?.copyWith(
            fontSize: 36, // text-4xl
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8), // mt-2
        Text(
          _rangeLabel,
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.7)),
        ),
      ],
    ),
  );

  Widget _chartCard(ThemeData theme, List<Earning> items, bool loading) {
    final maxAmount = items.fold<num>(0, (m, e) => e.amount > m ? e.amount : m);
    return Container(
      padding: const EdgeInsets.all(24), // p-6
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  CabinetTexts.earningsChart,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
              ),
              Text(
                CabinetTexts.earningsUnit(_granularity),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 12,
                  color: AppColors.dark.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16), // mb-4
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator(color: AppColors.olive)),
            )
          else if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48), // py-12
              child: Center(
                child: Text(
                  CabinetTexts.earningsEmpty,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.dark.withValues(alpha: 0.5),
                  ),
                ),
              ),
            )
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Y o'qi yorliqlari — saytda grafik ustiga qo'yilgan.
                SizedBox(
                  width: 34,
                  height: 160,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _axisLabel(theme, CabinetTexts.earningAmount(maxAmount)),
                      _axisLabel(theme, CabinetTexts.earningAmount(maxAmount / 2)),
                      _axisLabel(theme, '0'),
                    ],
                  ),
                ),
                Expanded(
                  child: SizedBox(
                    height: 160,
                    child: CustomPaint(
                      painter: _EarningsChartPainter(items: items, maxAmount: maxAmount),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12), // mt-3
            Row(
              children: [
                for (final e in items)
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          CabinetTexts.earningAmount(e.amount),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.dark.withValues(alpha: 0.8),
                          ),
                        ),
                        Text(
                          CabinetTexts.earningPeriod(e.period),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10, // text-[10px]
                            color: AppColors.dark.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _axisLabel(ThemeData theme, String text) => Text(
    text,
    style: theme.textTheme.labelSmall?.copyWith(
      fontSize: 10,
      color: AppColors.dark.withValues(alpha: 0.4),
    ),
  );
}

/// Saytdagi SVG grafik: to'r chiziqlari, maydon to'ldirmasi, chiziq, ustunlar va nuqtalar.
class _EarningsChartPainter extends CustomPainter {
  _EarningsChartPainter({required this.items, required this.maxAmount});

  final List<Earning> items;
  final num maxAmount;

  @override
  void paint(Canvas canvas, Size size) {
    const padTop = 12.0;
    const padBottom = 8.0;
    final innerHeight = size.height - padTop - padBottom;
    if (innerHeight <= 0 || items.isEmpty) return;

    // To'r chiziqlari — 0%, 50%, 100%.
    final grid = Paint()
      ..color = AppColors.dark.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (final fraction in [0.0, 0.5, 1.0]) {
      final y = padTop + innerHeight * fraction;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final step = items.length == 1 ? size.width : size.width / (items.length - 1);
    double yFor(num amount) =>
        padTop + innerHeight - (maxAmount == 0 ? 0 : innerHeight * (amount / maxAmount));

    final points = <Offset>[
      for (final (index, e) in items.indexed)
        Offset(items.length == 1 ? size.width / 2 : index * step, yFor(e.amount)),
    ];

    // Ustunlar — chiziq ostidagi so'lik tayoqchalar.
    final barWidth = (size.width / items.length * 0.5).clamp(2.0, 18.0);
    final bar = Paint()..color = AppColors.olive.withValues(alpha: 0.12);
    for (final point in points) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(
            point.dx - barWidth / 2,
            point.dy,
            point.dx + barWidth / 2,
            padTop + innerHeight,
          ),
          const Radius.circular(2),
        ),
        bar,
      );
    }

    // Maydon to'ldirmasi.
    final area = Path()..moveTo(points.first.dx, padTop + innerHeight);
    for (final point in points) {
      area.lineTo(point.dx, point.dy);
    }
    area
      ..lineTo(points.last.dx, padTop + innerHeight)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.olive.withValues(alpha: 0.28),
            AppColors.olive.withValues(alpha: 0.02),
          ],
        ).createShader(Rect.fromLTWH(0, padTop, size.width, innerHeight)),
    );

    // Chiziq.
    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      line.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = AppColors.olive
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Nuqtalar.
    for (final point in points) {
      canvas.drawCircle(point, 3.5, Paint()..color = Colors.white);
      canvas.drawCircle(
        point,
        3.5,
        Paint()
          ..color = AppColors.olive
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_EarningsChartPainter old) => old.items != items || old.maxAmount != maxAmount;
}
