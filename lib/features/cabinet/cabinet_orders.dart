import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/utils/format.dart';
import '../../shared/widgets/app_image.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/site_icon.dart';
import '../../shared/widgets/specialist_bits.dart';
import 'cabinet_repository.dart';
import 'cabinet_texts.dart';

/// Kabinetning `orders` bo'limi (dizayner/usta) — saytdagi `ordersTpl`.
///
/// Ikki qism: tepada **faol buyurtmalar** (muddati yaqinlari birinchi, vaqt progressi bilan),
/// pastda holat bo'yicha filtrlanadigan to'liq ro'yxat. Saytdagi jadval `hidden md:block` —
/// mobil ko'rinishda faqat kompakt kartalar qoladi.
class CabinetOrders extends StatefulWidget {
  const CabinetOrders({
    super.key,
    required this.future,
    required this.onOpen,
    required this.onRetry,
  });

  final Future<List<ProviderOrder>> future;

  /// Saytda `/cabinet/orders/:id`.
  final void Function(ProviderOrder order) onOpen;
  final VoidCallback onRetry;

  @override
  State<CabinetOrders> createState() => _CabinetOrdersState();
}

class _CabinetOrdersState extends State<CabinetOrders> {
  String _filter = 'all';

  /// Saytdagi `filteredOrders` — `in_progress` filtri `accepted` ni ham oladi.
  List<ProviderOrder> _filtered(List<ProviderOrder> orders) => switch (_filter) {
    'pending' => orders.where((o) => o.status == 'pending').toList(),
    'in_progress' =>
      orders.where((o) => o.status == 'in_progress' || o.status == 'accepted').toList(),
    'completed' => orders.where((o) => o.status == 'completed').toList(),
    _ => orders,
  };

  int _count(List<ProviderOrder> orders, String status) => switch (status) {
    'all' => orders.length,
    'in_progress' =>
      orders.where((o) => o.status == 'in_progress' || o.status == 'accepted').length,
    _ => orders.where((o) => o.status == status).length,
  };

  /// Saytdagi `activeOrdersSorted` — muddatsizlari oxirida.
  List<ProviderOrder> _activeSorted(List<ProviderOrder> orders) {
    final list = orders.where((o) => o.isActive).toList();
    list.sort((a, b) {
      final ad = a.daysLeft ?? 1 << 30;
      final bd = b.daysLeft ?? 1 << 30;
      return ad.compareTo(bd);
    });
    return list;
  }

  /// Saytdagi `order.startDate` — qabul qilingan yoki yaratilgan sana.
  static String? _startDate(ProviderOrder order) {
    final iso = order.acceptedAt ?? order.createdAt;
    if (iso == null || iso.length < 10) return null;
    final at = DateTime.tryParse(iso);
    if (at == null) return null;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(at.day)}.${two(at.month)}.${at.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<ProviderOrder>>(
      future: widget.future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.olive));
        }
        if (snapshot.hasError) {
          return ErrorView(message: "Buyurtmalarni yuklab bo'lmadi", onRetry: widget.onRetry);
        }
        final orders = snapshot.data ?? const <ProviderOrder>[];
        final active = _activeSorted(orders);
        final filtered = _filtered(orders);

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (active.isNotEmpty) ...[
              _activeSection(theme, active),
              const SizedBox(height: 16), // space-y-4
            ],
            _header(theme, orders),
            const SizedBox(height: 16),
            if (filtered.isEmpty)
              _emptyCard(theme)
            else
              for (final order in filtered) ...[
                _compactCard(theme, order),
                const SizedBox(height: 8), // space-y-2
              ],
          ],
        );
      },
    );
  }

  /// `bg-gradient-to-br from-olive/5 via-white to-sky-50/30` + `border-olive/20`.
  Widget _activeSection(ThemeData theme, List<ProviderOrder> active) => Container(
    padding: const EdgeInsets.all(16), // p-4
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.olive.withValues(alpha: 0.05),
          Colors.white,
          const Color(0xFFF0F9FF).withValues(alpha: 0.3), // sky-50/30
        ],
      ),
      borderRadius: BorderRadius.circular(AppRadius.lg), // rounded-2xl
      border: Border.all(color: AppColors.olive.withValues(alpha: 0.2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32, // w-8 h-8
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.olive,
                borderRadius: BorderRadius.circular(AppRadius.sm), // rounded-lg
              ),
              child: const Center(child: SiteIcon(SiteIcons.clock, size: 18, color: Colors.white)),
            ),
            const SizedBox(width: 8), // gap-2
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    CabinetTexts.activeOrders,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 16, // text-base
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                    ),
                  ),
                  Text(
                    '${active.length} · ${CabinetTexts.activeOrdersHint}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 11, // text-[11px]
                      color: AppColors.dark.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12), // mb-3
        for (final (index, order) in active.indexed) ...[
          if (index > 0) const SizedBox(height: 12), // gap-3
          _activeCard(theme, order),
        ],
      ],
    ),
  );

  Widget _activeCard(ThemeData theme, ProviderOrder order) {
    final (percent, tone, label) = order.timeProgress;
    return Pressable(
      scale: 0.99,
      onTap: () => widget.onOpen(order),
      child: Container(
        padding: const EdgeInsets.all(12), // p-3
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md), // rounded-xl
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _avatar(theme, order, 40),
                const SizedBox(width: 12), // gap-3
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.serviceName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark,
                        ),
                      ),
                      Text(
                        order.clientName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                          color: AppColors.dark.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _statusBadge(theme, order.status),
              ],
            ),
            const SizedBox(height: 8), // mb-2
            // Summa satri — pastida chegara chizig'i.
            Padding(
              padding: const EdgeInsets.only(bottom: 8), // pb-2
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    CabinetTexts.amountLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 12, // text-xs
                      color: AppColors.dark.withValues(alpha: 0.5),
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: formatNumber(order.amount)),
                        TextSpan(
                          text: ' ${CabinetTexts.soum}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.dark.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 16, // text-base
                      fontWeight: FontWeight.w800,
                      color: AppColors.olive,
                    ),
                  ),
                  // Saytda o'ng tomonda buyurtma boshlangan sana turadi.
                  if (_startDate(order) case final started?)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CabinetTexts.startDate,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 12,
                            color: AppColors.dark.withValues(alpha: 0.4),
                          ),
                        ),
                        Text(
                          started,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            color: AppColors.dark.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            const SizedBox(height: 12), // mb-3
            if (order.deadlineAt != null)
              _deadlineProgress(theme, order, percent, tone, label)
            else
              _plainProgress(theme, order),
          ],
        ),
      ),
    );
  }

  Widget _deadlineProgress(
    ThemeData theme,
    ProviderOrder order,
    int percent,
    String tone,
    String label,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '${CabinetTexts.deadlineLabel} '),
                  TextSpan(
                    text: CabinetTexts.formatDeadline(order.deadlineAt),
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.dark),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 11,
                color: AppColors.dark.withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: CabinetTexts.deadlineBackground(tone),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: CabinetTexts.deadlineForeground(tone),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 6), // mb-1.5
      _bar(percent / 100, CabinetTexts.progressBarColor(tone)),
      const SizedBox(height: 4), // mt-1
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${CabinetTexts.timeLabel} $percent%',
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              color: AppColors.dark.withValues(alpha: 0.4),
            ),
          ),
          if (order.status == 'in_progress')
            Text(
              '${CabinetTexts.doneLabel} ${order.progress}%',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: AppColors.dark.withValues(alpha: 0.4),
              ),
            ),
        ],
      ),
    ],
  );

  /// Muddat yo'q — saytda qo'lda kiritilgan progress ko'rsatiladi.
  Widget _plainProgress(ThemeData theme, ProviderOrder order) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            CabinetTexts.doneShort,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 11,
              color: AppColors.dark.withValues(alpha: 0.6),
            ),
          ),
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
      const SizedBox(height: 6),
      _bar(order.progress / 100, AppColors.olive),
      const SizedBox(height: 4),
      Text(
        CabinetTexts.noDeadline,
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: 10,
          color: AppColors.dark.withValues(alpha: 0.4),
        ),
      ),
    ],
  );

  /// `h-2 bg-gray-100 rounded-full`
  Widget _bar(double value, Color color) => ClipRRect(
    borderRadius: BorderRadius.circular(AppRadius.pill),
    child: LinearProgressIndicator(
      value: value.clamp(0, 1),
      minHeight: 8, // h-2
      backgroundColor: AppColors.surfaceMutedLight,
      valueColor: AlwaysStoppedAnimation(color),
    ),
  );

  Widget _header(ThemeData theme, List<ProviderOrder> orders) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        CabinetTexts.tabLabel('orders'),
        style: theme.textTheme.titleLarge?.copyWith(
          fontSize: 20, // text-xl
          fontWeight: FontWeight.w700,
          color: AppColors.dark,
        ),
      ),
      const SizedBox(height: 12), // gap-3
      Wrap(
        spacing: 8, // gap-2
        runSpacing: 8,
        children: [
          for (final (key, label, color) in CabinetTexts.orderFilters)
            _filterChip(theme, key, '$label (${_count(orders, key)})', color),
        ],
      ),
    ],
  );

  Widget _filterChip(ThemeData theme, String key, String label, Color activeColor) {
    final active = _filter == key;
    return Pressable(
      onTap: () => setState(() => _filter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // px-3 py-1.5
        decoration: BoxDecoration(
          color: active ? activeColor : AppColors.surfaceMutedLight,
          borderRadius: BorderRadius.circular(AppRadius.sm), // rounded-lg
          border: Border.all(color: active ? activeColor : AppColors.borderLight),
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
  }

  Widget _emptyCard(ThemeData theme) => Container(
    padding: const EdgeInsets.all(48), // p-12
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: AppColors.borderLight),
    ),
    child: Center(
      child: Text(
        CabinetTexts.noOrdersInCategory,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.dark.withValues(alpha: 0.5)),
      ),
    ),
  );

  /// `md:hidden` kompakt karta.
  Widget _compactCard(ThemeData theme, ProviderOrder order) => Pressable(
    scale: 0.99,
    onTap: () => widget.onOpen(order),
    child: Container(
      padding: const EdgeInsets.all(12), // p-3
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
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
                      order.serviceName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 2), // mt-0.5
                    Text(
                      order.clientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 12, // text-xs
                        color: AppColors.dark.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8), // gap-2
              _statusBadge(theme, order.status),
            ],
          ),
          const SizedBox(height: 8), // mb-2 + pt-2
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 8),
          Text(
            '${formatNumber(order.amount)} ${CabinetTexts.soum}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.olive,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _statusBadge(ThemeData theme, String status) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), // px-2 py-0.5
    decoration: BoxDecoration(
      color: CabinetTexts.orderStatusBackground(status),
      borderRadius: BorderRadius.circular(AppRadius.pill),
    ),
    child: Text(
      CabinetTexts.orderStatusLabel(status),
      style: theme.textTheme.labelSmall?.copyWith(
        fontSize: 10, // text-[10px]
        fontWeight: FontWeight.w700,
        color: CabinetTexts.orderStatusForeground(status),
      ),
    ),
  );

  /// Mijoz avatari — rasm yo'q bo'lsa ismdan gradient va harflar.
  Widget _avatar(ThemeData theme, ProviderOrder order, double size) {
    final avatar = order.clientAvatar;
    final hasAvatar = avatar != null && avatar.isNotEmpty;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2), // ring-2 ring-white
      ),
      child: ClipOval(
        child: hasAvatar
            ? AppImage(imageUrl: avatar, fit: BoxFit.cover)
            : DecoratedBox(
                decoration: BoxDecoration(gradient: avatarGradient(order.clientName)),
                child: Center(
                  child: Text(
                    initialsOf(order.clientName),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 12, // text-xs
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
