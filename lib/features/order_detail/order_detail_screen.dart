import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/api/api_client.dart';
import '../../core/api/media_url.dart';
import '../../core/models/market_user.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/file_download.dart';
import '../../core/utils/format.dart';
import '../../shared/widgets/app_image.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/site_header.dart';
import '../../shared/widgets/site_icon.dart';

/// Saytning `/cabinet/orders/:id` sahifasi — `order-detail.component.ts`.
///
/// Prodda buyurtmalar hali yo'q (`cabinet/orders` ikkala test hisobda ham bo'sh), shuning
/// uchun ekran haqiqiy ma'lumot bilan ko'rilmagan — buyurtma paydo bo'lgach tekshiriladi.
///
/// Tugmalar rolga qarab: mutaxassis qabul qiladi/boshlaydi/tugatadi, mijoz esa tasdiqlaydi.
class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.id});

  final int id;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _scroll = ScrollController();
  OrderDetail? _order;
  bool _loading = true;
  bool _scrolled = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final scrolled = _scroll.offset > 10;
      if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
    });
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Saytda alohida "bitta buyurtma" endpointi yo'q — ro'yxat olinib, ichidan `id` topiladi.
  /// Rol ikkalasi ham sinaladi, chunki foydalanuvchi mijoz ham, mutaxassis ham bo'lishi mumkin.
  Future<void> _load() async {
    OrderDetail? found;
    for (final role in ['client', 'provider']) {
      try {
        final res = await ApiClient.instance.get<dynamic>(
          '/market/cabinet/orders',
          query: {'role': role},
          refresh: true,
        );
        final data = res.data;
        if (data is! List) continue;
        for (final row in data) {
          if (row is Map<String, dynamic> && row['id'] == widget.id) {
            found = OrderDetail.fromJson(row);
            break;
          }
        }
      } catch (_) {
        // Bir rol yiqilsa ikkinchisi sinaladi.
      }
      if (found != null) break;
    }
    if (!mounted) return;
    setState(() {
      _order = found;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAltLight,
      body: Stack(
        children: [
          if (_loading)
            const Center(child: CircularProgressIndicator(color: AppColors.olive))
          else if (_order == null)
            _notFound()
          else
            _body(_order!),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SiteHeader(scrolled: _scrolled, showSearch: false),
          ),
        ],
      ),
    );
  }

  Widget _notFound() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              OrderTexts.notFound,
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.olive),
              onPressed: () => context.go('/cabinet/orders'),
              child: const Text(OrderTexts.backToOrders),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(OrderDetail o) {
    final theme = Theme.of(context);
    return ListView(
      controller: _scroll,
      padding: EdgeInsets.fromLTRB(16, 96 + MediaQuery.paddingOf(context).top, 16, 32),
      children: [
        GestureDetector(
          onTap: () => context.go('/cabinet/orders'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SiteIcon(SiteIcons.arrowLeft, size: 16, color: AppColors.dark.withValues(alpha: 0.5)),
              const SizedBox(width: 8),
              Text(
                OrderTexts.backToOrders,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  color: AppColors.dark.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _headerCard(o),
        const SizedBox(height: 16),
        _parties(o),
        const SizedBox(height: 16),
        _details(o),
        const SizedBox(height: 16),
        _documents(o),
        const SizedBox(height: 16),
        _timeline(o),
        const SizedBox(height: 16),
        _actions(o),
      ],
    );
  }

  // ── sarlavha kartasi ───────────────────────────────────────────────────────

  Widget _headerCard(OrderDetail o) {
    final theme = Theme.of(context);
    final (label, foreground, background) = OrderTexts.status(o.status);
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  o.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
          if (o.serviceType.isNotEmpty) ...[
            const SizedBox(height: 8),
            _row(OrderTexts.project, o.serviceType),
          ],
          if (o.createdAt case final created?) ...[
            const SizedBox(height: 4),
            _row(OrderTexts.created, _date(created)),
          ],
        ],
      ),
    );
  }

  // ── tomonlar ───────────────────────────────────────────────────────────────

  Widget _parties(OrderDetail o) => _card(
    Row(
      children: [
        Expanded(child: _person(OrderTexts.client, o.clientName, o.clientAvatar)),
        const SizedBox(width: 12),
        Expanded(child: _person(OrderTexts.specialist, o.providerName, o.providerAvatar)),
      ],
    ),
  );

  Widget _person(String role, String name, String? avatar) {
    final theme = Theme.of(context);
    final image = absoluteMediaUrl(avatar);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          role,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 12,
            color: AppColors.dark.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ClipOval(
              child: SizedBox(
                width: 32,
                height: 32,
                child: image != null && image.isNotEmpty
                    ? AppImage(imageUrl: image, fit: BoxFit.cover)
                    : const ColoredBox(color: AppColors.surfaceMutedLight),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── tafsilot ───────────────────────────────────────────────────────────────

  Widget _details(OrderDetail o) {
    final theme = Theme.of(context);
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            OrderTexts.details,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 12),
          if (o.description.isNotEmpty) ...[
            Text(
              OrderTexts.description,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 12,
                color: AppColors.dark.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              o.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                height: 1.6,
                color: AppColors.dark.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
          ],
          _row(OrderTexts.amount, "${formatNumber(o.price)} so'm"),
          const SizedBox(height: 4),
          _row(
            OrderTexts.deadline,
            o.deadlineAt == null ? OrderTexts.deadlineNotSet : _date(o.deadlineAt!),
          ),
          const SizedBox(height: 12),
          // Saytdagi `cabinet.progress` chizig'i.
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: (o.progress / 100).clamp(0, 1),
                    minHeight: 8,
                    backgroundColor: AppColors.surfaceMutedLight,
                    valueColor: const AlwaysStoppedAnimation(AppColors.olive),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${o.progress}%',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          if (o.rejectedReason case final reason?) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    OrderTexts.rejectionReason,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reason,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── hujjatlar ──────────────────────────────────────────────────────────────

  Widget _documents(OrderDetail o) {
    final theme = Theme.of(context);
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            OrderTexts.documents,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 12),
          if (o.attachments.isEmpty)
            Text(
              OrderTexts.noDocuments,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                color: AppColors.dark.withValues(alpha: 0.4),
              ),
            )
          else
            for (final attachment in o.attachments) ...[
              Pressable(
                scale: 0.99,
                onTap: () =>
                    downloadAndOpen(attachment.url, attachment.name, saveToDownloads: true),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAltLight,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      const SiteIcon(SiteIcons.document, size: 18, color: AppColors.olive),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          attachment.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            color: AppColors.dark,
                          ),
                        ),
                      ),
                      Text(
                        OrderTexts.docDownload,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.olive,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }

  // ── tarix ──────────────────────────────────────────────────────────────────

  Widget _timeline(OrderDetail o) {
    final theme = Theme.of(context);
    final steps = <(String, DateTime?)>[
      (OrderTexts.timelineCreated, o.createdAt),
      (OrderTexts.timelineAccepted, o.acceptedAt),
      (OrderTexts.timelineStarted, o.startedAt),
      (OrderTexts.specialistCompleted, o.providerCompletedAt),
      (OrderTexts.clientConfirmed, o.clientCompletedAt),
    ];
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            OrderTexts.timeline,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 12),
          for (final (label, date) in steps)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: date == null
                          ? AppColors.dark.withValues(alpha: 0.15)
                          : AppColors.olive,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: date == null
                            ? AppColors.dark.withValues(alpha: 0.35)
                            : AppColors.dark,
                      ),
                    ),
                  ),
                  if (date != null)
                    Text(
                      _date(date),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 12,
                        color: AppColors.dark.withValues(alpha: 0.5),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── amallar ────────────────────────────────────────────────────────────────

  /// Saytdagi kabi rolga qarab: mutaxassis qabul → boshlash → tugatish, mijoz esa tasdiqlash.
  Widget _actions(OrderDetail o) {
    final user = context.watch<AuthService>().user;
    final isProvider = user != null && user.role != MarketRole.user;

    final buttons = <(String, String)>[
      if (isProvider) ...[
        if (o.status == 'pending') (OrderTexts.accept, 'accepted'),
        if (o.status == 'accepted') (OrderTexts.start, 'in_progress'),
        if (o.status == 'in_progress') (OrderTexts.complete, 'completed'),
      ] else if (o.providerCompletedAt != null && o.clientCompletedAt == null)
        (OrderTexts.confirm, 'confirmed'),
    ];

    if (buttons.isEmpty && o.conversationId == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return _card(
      Column(
        children: [
          for (final (label, status) in buttons) ...[
            Pressable(
              scale: 0.98,
              onTap: _busy ? null : () => _setStatus(o, status),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.olive,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (o.conversationId case final conversationId?)
            Pressable(
              scale: 0.98,
              onTap: () => context.go('/chat/$conversationId'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Text(
                  OrderTexts.messages,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _setStatus(OrderDetail o, String status) async {
    setState(() => _busy = true);
    try {
      await ApiClient.instance.put<dynamic>(
        '/market/cabinet/orders/${o.id}/status',
        data: {'status': status},
      );
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Holatni o\'zgartirib bo\'lmadi')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ── umumiy ─────────────────────────────────────────────────────────────────

  Widget _card(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: AppColors.borderLight),
    ),
    child: child,
  );

  Widget _row(String label, String value) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 12,
            color: AppColors.dark.withValues(alpha: 0.5),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.dark,
            ),
          ),
        ),
      ],
    );
  }

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}.'
      '${value.month.toString().padLeft(2, '0')}.${value.year}';
}

/// `uz.ts` dagi `order.*` kalitlari.
abstract final class OrderTexts {
  static const backToOrders = 'Buyurtmalarga qaytish';
  static const notFound = 'Buyurtma topilmadi';
  static const project = 'Loyiha';
  static const created = 'Yaratilgan';
  static const client = 'Mijoz';
  static const specialist = 'Mutaxassis';
  static const details = 'Tafsilot';
  static const description = 'Tavsif';
  static const amount = 'Summa';
  static const deadline = 'Muddat';
  static const deadlineNotSet = 'Belgilanmagan';
  static const rejectionReason = 'Rad etish sababi';
  static const specialistCompleted = 'Mutaxassis tugatildi deb belgiladi';
  static const clientConfirmed = 'Mijoz tasdiqladi';
  static const accept = 'Qabul qilish';
  static const start = 'Boshlash';
  static const complete = 'Tugatish';
  static const confirm = 'Tasdiqlash';
  static const documents = 'Hujjatlar';
  static const noDocuments = "Hujjat yo'q";
  static const docDownload = 'Yuklab olish';
  static const timeline = 'Tarix';
  static const timelineCreated = 'Yaratildi';
  static const timelineAccepted = 'Qabul qilindi';
  static const timelineStarted = 'Boshlandi';
  static const messages = 'Xabarlar';

  /// Kabinetdagi buyurtma holatlari bilan bir xil ranglar.
  static (String, Color, Color) status(String value) => switch (value) {
    'pending' => ('Kutilmoqda', const Color(0xFFB45309), const Color(0xFFFEF3C7)),
    'accepted' => ('Qabul qilindi', const Color(0xFF1D4ED8), const Color(0xFFDBEAFE)),
    'in_progress' => ('Jarayonda', const Color(0xFF1D4ED8), const Color(0xFFDBEAFE)),
    'completed' => ('Tugatildi', const Color(0xFF047857), const Color(0xFFD1FAE5)),
    'rejected' => ('Rad etildi', const Color(0xFFBE123C), const Color(0xFFFFE4E6)),
    'cancelled' => ('Bekor qilindi', const Color(0xFFBE123C), const Color(0xFFFFE4E6)),
    _ => (value, const Color(0xFF3D3D3D), const Color(0xFFF3F4F6)),
  };
}

/// `/market/cabinet/orders` ro'yxatidagi bitta buyurtma (javob `snake_case`).
class OrderDetail {
  const OrderDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.serviceType,
    required this.status,
    required this.progress,
    required this.clientName,
    required this.providerName,
    this.clientAvatar,
    this.providerAvatar,
    this.conversationId,
    this.rejectedReason,
    this.createdAt,
    this.acceptedAt,
    this.startedAt,
    this.providerCompletedAt,
    this.clientCompletedAt,
    this.deadlineAt,
    this.attachments = const [],
  });

  final int id;
  final String title;
  final String description;
  final num price;
  final String serviceType;
  final String status;
  final int progress;
  final String clientName;
  final String providerName;
  final String? clientAvatar;
  final String? providerAvatar;
  final int? conversationId;
  final String? rejectedReason;
  final DateTime? createdAt;
  final DateTime? acceptedAt;
  final DateTime? startedAt;
  final DateTime? providerCompletedAt;
  final DateTime? clientCompletedAt;
  final DateTime? deadlineAt;
  final List<OrderAttachment> attachments;

  static String? _text(Object? value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  static DateTime? _date(Object? value) => DateTime.tryParse(value?.toString() ?? '');

  factory OrderDetail.fromJson(Map<String, dynamic> json) => OrderDetail(
    id: (json['id'] as num?)?.toInt() ?? 0,
    title: _text(json['title']) ?? '',
    description: _text(json['description']) ?? '',
    price: json['price'] is num ? json['price'] as num : (json['amount'] as num? ?? 0),
    serviceType: _text(json['service_type']) ?? '',
    status: _text(json['status']) ?? '',
    progress: (json['progress'] as num?)?.toInt() ?? 0,
    clientName: _text(json['client_name']) ?? '',
    providerName: _text(json['provider_name']) ?? '',
    clientAvatar: _text(json['client_avatar']),
    providerAvatar: _text(json['provider_avatar']),
    conversationId: (json['conversation_id'] as num?)?.toInt(),
    rejectedReason: _text(json['rejected_reason']),
    createdAt: _date(json['created_at']),
    acceptedAt: _date(json['accepted_at']),
    startedAt: _date(json['started_at']),
    providerCompletedAt: _date(json['provider_completed_at']),
    clientCompletedAt: _date(json['client_completed_at']),
    deadlineAt: _date(json['deadline_at']),
    attachments: [
      for (final row in (json['attachments'] as List? ?? const []))
        if (row is Map) OrderAttachment.fromJson(row),
    ],
  );
}

class OrderAttachment {
  const OrderAttachment({required this.name, required this.url});

  final String name;
  final String url;

  factory OrderAttachment.fromJson(Map row) => OrderAttachment(
    name: row['name']?.toString() ?? row['filename']?.toString() ?? 'hujjat',
    url: row['url']?.toString() ?? '',
  );
}
