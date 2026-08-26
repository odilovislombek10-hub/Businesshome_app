import '../../core/i18n/translate.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/models/market_user.dart';
import '../../core/services/currency_service.dart';
import '../../shared/widgets/app_image.dart';
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
/// Ko'rsatkichlardan keyin rolga xos blok chiziladi: agentga eng yaxshi e'lonlari va bozor
/// ma'lumoti, dizayner/ustaga faol buyurtmalari va so'nggi sharhi, oddiy foydalanuvchiga
/// e'lonlari va "Xush kelibsiz" kartasi.
class CabinetDashboard extends StatelessWidget {
  const CabinetDashboard({
    super.key,
    required this.user,
    required this.stats,
    required this.onOpenTab,
    required this.onRetry,
    this.listings,
    this.providerOrders,
    this.reviews,
  });

  final MarketUser user;
  final Future<List<RoleStat>> stats;
  final ValueChanged<String> onOpenTab;
  final VoidCallback onRetry;

  /// Agent va oddiy foydalanuvchi paneli uchun.
  final Future<List<MyListing>>? listings;

  /// Dizayner/usta paneli uchun.
  final Future<List<ProviderOrder>>? providerOrders;
  final Future<List<CabinetReview>>? reviews;

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
        const SizedBox(height: 16),
        ..._roleBlocks(context, theme),
      ],
    );
  }

  /// Saytdagi "Role-specific dashboard content" — mobilda bloklar ustma-ust
  /// (`grid-cols-1`), oralig'i `gap-4`.
  List<Widget> _roleBlocks(BuildContext context, ThemeData theme) {
    switch (user.role) {
      case MarketRole.agent:
        return [
          _listingsCard(context, theme, CabinetTexts.topListings),
          const SizedBox(height: 16),
          _oliveCard(
            theme,
            title: CabinetTexts.marketInsight,
            description: CabinetTexts.marketDesc,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '+12.5%',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontSize: 30, // text-3xl
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4), // mt-1
                Text(
                  CabinetTexts.aboveMarket,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            actionLabel: CabinetTexts.newListing,
            onAction: () => context.go('/ads/create'),
          ),
        ];
      case MarketRole.designer || MarketRole.master:
        return [
          _ordersCard(context, theme),
          const SizedBox(height: 16),
          _reviewCard(context, theme),
        ];
      case MarketRole.user:
        return [
          _listingsCard(context, theme, t('cabinet.tab.listings')),
          const SizedBox(height: 16),
          _oliveCard(
            theme,
            title: CabinetTexts.welcomeUser,
            description: CabinetTexts.welcomeUserDesc,
            actionLabel: CabinetTexts.startSearch,
            onAction: () => context.go('/secondary'),
          ),
        ];
      case MarketRole.developer:
        return const [];
    }
  }

  Widget _cardShell(ThemeData theme, {required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16), // p-4
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
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 16, // text-base
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
              ),
              Pressable(
                onTap: () =>
                    onOpenTab(title == CabinetTexts.activeOrdersTitle ? 'orders' : 'listings'),
                child: Text(
                  CabinetTexts.viewAll,
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14, color: AppColors.olive),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12), // mb-3
          child,
        ],
      ),
    );
  }

  /// Uchta e'lon — rasm, sarlavha, narx, ko'rish va murojaat soni.
  Widget _listingsCard(BuildContext context, ThemeData theme, String title) {
    return FutureBuilder<List<MyListing>>(
      future: listings,
      builder: (context, snapshot) {
        final items = (snapshot.data ?? const <MyListing>[]).take(3).toList();
        return _cardShell(
          theme,
          title: title,
          child: items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32), // py-8
                  child: Center(
                    child: Text(
                      CabinetTexts.noListings,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: AppColors.dark.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0) const SizedBox(height: 12), // space-y-3
                      _listingRow(context, theme, items[i]),
                    ],
                  ],
                ),
        );
      },
    );
  }

  Widget _listingRow(BuildContext context, ThemeData theme, MyListing listing) {
    final image = listing.images.isEmpty ? null : listing.images.first;
    return Pressable(
      scale: 0.99,
      onTap: () => onOpenTab('listings'),
      child: Padding(
        padding: const EdgeInsets.all(12), // p-3
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: SizedBox(
                width: 64, // w-16
                height: 64,
                child: image == null || image.isEmpty
                    ? const ColoredBox(color: AppColors.surfaceMutedLight)
                    : AppImage(imageUrl: image, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12), // gap-3
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 2), // mt-0.5
                  Text(
                    CurrencyService.instance.formatWithSymbol(
                      listing.price,
                      from: listing.currency ?? 'uzs',
                    ),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 12,
                      color: AppColors.dark.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 6), // mt-1.5
                  Row(
                    children: [
                      SiteIcon(
                        SiteIcons.eye,
                        size: 12,
                        color: AppColors.dark.withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${listing.views}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                          color: AppColors.dark.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(width: 12), // gap-3
                      SiteIcon(
                        SiteIcons.message,
                        size: 12,
                        color: AppColors.dark.withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${listing.inquiries}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                          color: AppColors.dark.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Dizayner/usta paneli — uchta faol buyurtma.
  Widget _ordersCard(BuildContext context, ThemeData theme) {
    return FutureBuilder<List<ProviderOrder>>(
      future: providerOrders,
      builder: (context, snapshot) {
        final items = (snapshot.data ?? const <ProviderOrder>[]).take(3).toList();
        return _cardShell(
          theme,
          title: CabinetTexts.activeOrdersTitle,
          child: items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40), // py-10
                  child: Center(
                    child: Text(
                      CabinetTexts.noOrders,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: AppColors.dark.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0) const SizedBox(height: 12),
                      _orderRow(context, theme, items[i]),
                    ],
                  ],
                ),
        );
      },
    );
  }

  Widget _orderRow(BuildContext context, ThemeData theme, ProviderOrder order) {
    return Pressable(
      scale: 0.99,
      onTap: () => context.go('/cabinet/orders/${order.id}'),
      child: Container(
        padding: const EdgeInsets.all(16), // p-4
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20, // w-10
                  backgroundColor: AppColors.olive.withValues(alpha: 0.15),
                  backgroundImage: (order.clientAvatar?.isNotEmpty ?? false)
                      ? NetworkImage(order.clientAvatar!)
                      : null,
                  child: (order.clientAvatar?.isNotEmpty ?? false)
                      ? null
                      : Text(
                          order.clientName.isEmpty
                              ? '?'
                              : order.clientName.characters.first.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.olive,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.clientName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.dark,
                        ),
                      ),
                      Text(
                        order.serviceName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 12,
                          color: AppColors.dark.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.olive.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    CabinetTexts.orderStatusLabel(order.status),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.olive,
                    ),
                  ),
                ),
              ],
            ),
            if (order.status == 'in_progress') ...[
              const SizedBox(height: 12), // mt-3
              Row(
                children: [
                  Text(
                    CabinetTexts.progress,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 11,
                      color: AppColors.dark.withValues(alpha: 0.5),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${order.progress}%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.olive,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4), // mb-1
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: order.progress / 100,
                  minHeight: 6, // h-1.5
                  backgroundColor: AppColors.surfaceAltLight,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.olive),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// So'nggi sharh — zaytun rangli karta.
  Widget _reviewCard(BuildContext context, ThemeData theme) {
    return FutureBuilder<List<CabinetReview>>(
      future: reviews,
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <CabinetReview>[];
        // Saytda sharh bo'lmasa karta ichida faqat sarlavha qoladi.
        final review = items.isEmpty ? null : items.first;
        return _oliveCard(
          theme,
          title: CabinetTexts.latestReview,
          body: review == null
              ? null
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        for (var i = 0; i < 5; i++)
                          Padding(
                            padding: const EdgeInsets.only(right: 2),
                            child: SiteIcon(
                              i < review.rating
                                  ? SiteIcons.ratingStar
                                  : SiteIcons.ratingStarOutline,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8), // mb-2
                    Text(
                      '"${review.comment}"',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 12), // mb-3
                    Text(
                      '— ${review.clientName}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
          actionLabel: review == null ? null : CabinetTexts.allReviews,
          onAction: () => onOpenTab('reviews'),
        );
      },
    );
  }

  /// `bg-gradient-to-br from-olive to-olive/80 rounded-2xl p-6 text-white`.
  Widget _oliveCard(
    ThemeData theme, {
    required String title,
    String? description,
    Widget? body,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
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
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 18, // text-lg
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          if (description != null) ...[
            const SizedBox(height: 8), // mb-2
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
          if (body != null) ...[
            const SizedBox(height: 16), // mb-4 / mt-4
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16), // p-4
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: body,
            ),
          ],
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            Pressable(
              scale: 0.99,
              onTap: onAction ?? () {},
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12), // py-3
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  actionLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.olive,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
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
