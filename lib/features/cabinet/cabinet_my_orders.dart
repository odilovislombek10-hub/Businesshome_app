import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/utils/format.dart';
import '../../shared/widgets/entrance.dart';
import 'cabinet_repository.dart';
import 'cabinet_review_sheet.dart';
import 'cabinet_texts.dart';

/// Kabinetning `my-orders` bo'limi — `/market/cabinet/orders?role=client`.
///
/// Shablonda ikki ko'rinish bor: kattaroq ekranda jadval (`hidden md:block`), telefonda esa
/// **ixcham kartalar** (`md:hidden`) — bu yerda faqat mobil ko'rinish olingan.
///
/// Kartada: nom, mutaxassis, holat nishonchasi, muddat va uning ogohlantirishi (kechikdi /
/// bugun / N kun qoldi), pastida narx. Kartani bosish buyurtma sahifasiga olib boradi.
class CabinetMyOrders extends StatelessWidget {
  const CabinetMyOrders({super.key, required this.future});

  final Future<List<ClientOrder>> future;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<ClientOrder>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data ?? const <ClientOrder>[];

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              CabinetTexts.tabLabel('my-orders'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 20, // text-xl
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 16), // space-y-4
            if (items.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(48), // p-12
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Text(
                  CabinetTexts.myOrdersEmpty,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.dark.withValues(alpha: 0.5),
                  ),
                ),
              )
            else
              for (final (i, order) in items.indexed) ...[
                if (i > 0) const SizedBox(height: 8), // space-y-2
                _OrderCard(order: order),
              ],
          ],
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final ClientOrder order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deadline = CabinetTexts.deadlineState(order);

    return Pressable(
      scale: 0.99, // active:scale-[0.99]
      onTap: () => context.push('/cabinet/orders/${order.id}'),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.dark,
                        ),
                      ),
                      if (order.providerName case final name?) ...[
                        const SizedBox(height: 2), // mt-0.5
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 12,
                            color: AppColors.dark.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(status: order.status),
              ],
            ),
            if (order.deadlineAt != null) ...[
              const SizedBox(height: 8), // mb-2
              Row(
                children: [
                  Text(
                    'Muddat: ${CabinetTexts.formatDeadline(order.deadlineAt)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      color: AppColors.dark.withValues(alpha: 0.6),
                    ),
                  ),
                  const Spacer(),
                  if (deadline.$2.isNotEmpty && deadline.$1 != 'closed')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: CabinetTexts.deadlineBackground(deadline.$1),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        deadline.$2,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: CabinetTexts.deadlineForeground(deadline.$1),
                        ),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 8), // pt-2
            const Divider(height: 1, color: AppColors.borderLight),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    "${formatNumber(order.price)} so'm",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.olive,
                    ),
                  ),
                ),
                // Saytda tugma faqat tugagan va hali sharh yozilmagan buyurtmada.
                if (order.status == 'completed' && !order.hasReview)
                  Pressable(
                    scale: 0.98,
                    onTap: () => ReviewSheet.show(context, order: order),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.olive,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Text(
                        CabinetTexts.writeReview,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: CabinetTexts.orderStatusBackground(status),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        CabinetTexts.orderStatusLabel(status),
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: CabinetTexts.orderStatusForeground(status),
        ),
      ),
    );
  }
}
