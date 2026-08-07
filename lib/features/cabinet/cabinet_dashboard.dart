import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/models/market_user.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/site_icon.dart';
import 'cabinet_repository.dart';
import 'cabinet_texts.dart';

/// Kabinetning `dashboard` bo'limi.
///
/// Shablonda: salomlashuv, rolga qarab izoh va `/market/cabinet/role-stats` dan keladigan
/// ko'rsatkich kartalari — har birida yorliq, o'zgarish nishonchasi, raqam va mayda grafik
/// (sparkline). Yorliqqa mos bo'lim bo'lsa karta bosiladi.
///
/// Rolga xos qo'shimcha bloklar (agent uchun eng yaxshi e'lonlar, dizayner/usta uchun faol
/// buyurtmalar) keyingi bosqichda — ular alohida so'rovlarga tayanadi.
class CabinetDashboard extends StatelessWidget {
  const CabinetDashboard({
    super.key,
    required this.user,
    required this.stats,
    required this.onOpenTab,
    required this.onRetry,
  });

  final MarketUser user;
  final Future<List<RoleStat>> stats;
  final ValueChanged<String> onOpenTab;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstName = user.fullName.trim().split(RegExp(r'\s+')).firstOrNull ?? '';

    return ListView(
      padding: const EdgeInsets.all(20), // p-5
      children: [
        Text(
          '${CabinetTexts.greeting}, ${firstName.isEmpty ? user.fullName : firstName} 👋',
          style: theme.textTheme.displaySmall?.copyWith(
            fontSize: 24, // text-2xl
            fontWeight: FontWeight.w700,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(height: 6), // mt-1.5
        Text(
          CabinetTexts.dashSubtitle(user.role),
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.dark.withValues(alpha: 0.6)),
        ),
        const SizedBox(height: 16), // space-y-4
        FutureBuilder<List<RoleStat>>(
          future: stats,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Saytdagi `animate-pulse` skeletlari — to'rtta bo'sh karta.
              return _grid([
                for (var i = 0; i < 4; i++)
                  Pulse(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                    ),
                  ),
              ]);
            }
            final items = snapshot.data ?? const <RoleStat>[];
            if (items.isEmpty) {
              return Pressable(
                onTap: onRetry,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Text(
                    "Ko'rsatkichlarni yuklab bo'lmadi. Qayta urinish uchun bosing.",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.dark.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              );
            }
            return _grid([for (final stat in items) _StatCard(stat: stat, onOpenTab: onOpenTab)]);
          },
        ),
      ],
    );
  }

  /// `grid-cols-2 gap-3` — telefonda ikkita ustun.
  Widget _grid(List<Widget> children) => GridView.count(
    padding: EdgeInsets.zero,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 2,
    mainAxisSpacing: 12, // gap-3
    crossAxisSpacing: 12,
    childAspectRatio: 172 / 118,
    children: children,
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat, required this.onOpenTab});

  final RoleStat stat;
  final ValueChanged<String> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tab = CabinetTexts.statRoutes[stat.label];
    final trend = stat.trend;

    final card = Container(
      padding: const EdgeInsets.all(12), // p-3
      decoration: BoxDecoration(
        // Bosilmaydigan kartalar saytda kulrang fonda turadi.
        color: tab == null ? AppColors.surfaceAltLight : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg), // rounded-2xl
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  CabinetTexts.statLabel(stat.label).toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    height: 1.2,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.4, // tracking-wide
                    color: AppColors.dark.withValues(alpha: tab == null ? 0.4 : 0.5),
                  ),
                ),
              ),
              if (trend != null && trend != 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: trend > 0 ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '${trend > 0 ? '+' : ''}$trend%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: trend > 0 ? const Color(0xFF059669) : const Color(0xFFDC2626),
                    ),
                  ),
                ),
              ],
              if (tab != null) ...[
                const SizedBox(width: 4),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.olive.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: SiteIcon(
                      SiteIcons.arrowRight,
                      size: 10,
                      strokeWidth: 2.5,
                      color: AppColors.olive,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  stat.suffix != null ? _bigNumber(stat.value) : _statValue(stat.value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontSize: 22, // text-2xl
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
              ),
              if (stat.sparkline.length > 1)
                SizedBox(
                  width: 56,
                  height: 28,
                  child: CustomPaint(painter: _SparklinePainter(stat.sparkline)),
                ),
            ],
          ),
          if (stat.suffix case final suffix?)
            Text(
              suffix,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: AppColors.dark.withValues(alpha: 0.4),
              ),
            ),
        ],
      ),
    );

    if (tab == null) return card;
    return Pressable(scale: 0.98, onTap: () => onOpenTab(tab), child: card);
  }

  /// Saytdagi `formatStatValue` — kasrli qiymat (reyting) bitta xonagacha.
  static String _statValue(num value) {
    if (value < 10 && value % 1 != 0) return value.toStringAsFixed(1);
    return value.round().toString();
  }

  /// Saytdagi `formatBigNumber` — mingdan katta qiymatlar qisqartiriladi.
  static String _bigNumber(num value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)} mln';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return value.round().toString();
  }
}

/// Karta burchagidagi mayda grafik — saytdagi `sparklinePath` + `sparklineFill`.
class _SparklinePainter extends CustomPainter {
  const _SparklinePainter(this.values);

  final List<num> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final max = values.reduce((a, b) => a > b ? a : b);
    final min = values.reduce((a, b) => a < b ? a : b);
    final range = (max - min) == 0 ? 1 : (max - min);
    const padding = 3.0;

    final stepX = size.width / (values.length - 1);
    final path = Path();
    for (final (i, value) in values.indexed) {
      final x = i * stepX;
      final y = size.height - padding - ((value - min) / range) * (size.height - padding * 2);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }

    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fill, Paint()..color = const Color(0xFF999966).withValues(alpha: 0.1));

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF999966)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => old.values != values;
}
