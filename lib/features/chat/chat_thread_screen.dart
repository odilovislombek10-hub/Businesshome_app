import '../../core/i18n/translate.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/api/api_client.dart';
import '../../core/models/market_user.dart';
import '../../core/api/media_url.dart';
import '../../core/services/auth_service.dart';
import '../../shared/widgets/app_image.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/site_icon.dart';
import '../../shared/widgets/site_toast.dart';
import 'chat_order_sheet.dart';

/// Saytning `/chat/:id` sahifasi — `chat-thread.component.ts`.
///
/// Prodda suhbatlar hali yo'q (`cabinet/messages` ikkala test hisobda ham bo'sh), shuning
/// uchun ekran haqiqiy yozishmalar bilan ko'rilmagan.
///
/// Saytda bu sahifa to'liq ekranni egallaydi: tepada suhbatdosh, o'rtada xabarlar, pastda
/// yozish qatori. Umumiy sayt header'i yo'q — orqaga tugmasi bor. Xabarlar har besh
/// soniyada qayta so'raladi (saytda ham shunday interval bor).
class ChatThreadScreen extends StatefulWidget {
  const ChatThreadScreen({super.key, required this.id});

  final int id;

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final _scroll = ScrollController();
  final _input = TextEditingController();

  ConversationDetail? _conversation;
  bool _loading = true;
  bool _sending = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 5), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _poll?.cancel();
    _scroll.dispose();
    _input.dispose();
    super.dispose();
  }

  List<ChatOrder> _orders = const [];

  Future<void> _loadOrders() async {
    try {
      final res = await ApiClient.instance.get<dynamic>(
        '/market/chat/conversations/${widget.id}/orders',
        refresh: true,
      );
      final data = res.data;
      if (data is! List || !mounted) return;
      setState(() {
        _orders = [
          for (final row in data)
            if (row is Map) ChatOrder.fromJson(row),
        ];
      });
    } catch (_) {
      // Saytda ham xatolik jim yutiladi.
    }
  }

  Future<void> _load({bool silent = false}) async {
    try {
      // Saytdagi `/chat/:id` sahifasi `market/chat/...` xizmatini ishlatadi:
      // u onlayn holati, mulk turi va suhbatdagi buyurtmalarni ham beradi.
      // Suhbat va xabarlar alohida so'rov (backend shunday ajratgan).
      final responses = await Future.wait([
        ApiClient.instance.get<dynamic>('/market/chat/conversations/${widget.id}', refresh: true),
        ApiClient.instance.get<dynamic>(
          '/market/chat/conversations/${widget.id}/messages',
          query: {'limit': 200},
          refresh: true,
        ),
      ]);
      final data = responses[0].data;
      if (responses[0].statusCode != 200 || data is! Map<String, dynamic>) {
        if (!silent && mounted) setState(() => _loading = false);
        return;
      }
      final messagesData = responses[1].data;
      final conversation = ConversationDetail.fromJson(
        data,
        messages: messagesData is Map ? messagesData['items'] : messagesData,
      );
      if (!mounted) return;
      final grew = (_conversation?.messages.length ?? 0) < conversation.messages.length;
      setState(() {
        _conversation = conversation;
        _loading = false;
      });
      if (grew) _scrollToEnd();
      unawaited(_loadOrders());
    } catch (_) {
      if (!silent && mounted) setState(() => _loading = false);
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ApiClient.instance.post<dynamic>(
        '/market/chat/conversations/${widget.id}/messages',
        data: {'text': text},
      );
      _input.clear();
      await _load(silent: true);
      _scrollToEnd();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Xabar yuborilmadi')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthService>().user?.id;
    return Scaffold(
      backgroundColor: AppColors.surfaceAltLight,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.olive))
                  : _messages(me),
            ),
            _sendBox(),
          ],
        ),
      ),
    );
  }

  /// Tepadagi panel — orqaga, suhbatdosh nomi va holati.
  Widget _header() {
    final theme = Theme.of(context);
    final other = _conversation?.otherUser;
    final avatar = absoluteMediaUrl(other?.avatar);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/cabinet/messages'),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: SiteIcon(
                  SiteIcons.arrowLeft,
                  size: 20,
                  color: AppColors.dark.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
          ClipOval(
            child: SizedBox(
              width: 36,
              height: 36,
              child: avatar != null && avatar.isNotEmpty
                  ? AppImage(imageUrl: avatar, fit: BoxFit.cover)
                  : const ColoredBox(color: AppColors.surfaceMutedLight),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  other?.fullName ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
                ),
                // Saytda ism ostida onlayn holati turadi.
                Text(
                  other?.isOnline == true
                      ? ChatTexts.online
                      : (other?.lastSeenAt != null
                            ? '${ChatTexts.lastSeen} ${_relative(other!.lastSeenAt!)}'
                            : ChatTexts.offline),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    fontWeight: other?.isOnline == true ? FontWeight.w500 : FontWeight.w400,
                    color: other?.isOnline == true
                        ? const Color(0xFF059669)
                        : AppColors.dark.withValues(alpha: 0.5),
                  ),
                ),
                if (_conversation?.propertyTitle case final title?)
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.olive,
                    ),
                  ),
              ],
            ),
          ),
          if (_canCreateOrder)
            Pressable(
              onTap: _openOrderSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.olive,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  '+ ${ChatTexts.createOrderMobile}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// `canCreateOrder()` — suhbat mutaxassis profilidan boshlangan bo'lsa va
  /// men mutaxassis bo'lmasam.
  bool get _canCreateOrder {
    final type = _conversation?.propertyType;
    if (type != 'designer' && type != 'master' && type != 'agent') return false;
    final role = context.read<AuthService>().user?.role;
    return role != MarketRole.designer && role != MarketRole.master;
  }

  /// Saytdagi `formatRelative`.
  static String _relative(DateTime at) {
    final diff = DateTime.now().difference(at);
    if (diff.inMinutes < 1) return t('time.now');
    if (diff.inHours < 1) return '${diff.inMinutes} ${t('time.minAgo')}';
    if (diff.inDays < 1) return '${diff.inHours} ${t('time.hourAgo')}';
    return '${diff.inDays} ${t('time.dayAgo')}';
  }

  Future<void> _openOrderSheet() async {
    final created = await ChatOrderSheet.show(
      context,
      conversationId: widget.id,
      propertyType: _conversation?.propertyType ?? '',
    );
    if (created == true) _load();
  }

  Widget _messages(int? me) {
    final theme = Theme.of(context);
    final messages = _conversation?.messages ?? const <ConversationMessage>[];
    if (messages.isEmpty) {
      return Center(
        child: Text(
          ChatTexts.empty,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            color: AppColors.dark.withValues(alpha: 0.4),
          ),
        ),
      );
    }
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) =>
          _message(messages[index], mine: messages[index].senderId == me),
    );
  }

  /// O'z xabari o'ngda zaytun fonda, suhbatdoshniki chapda oq fonda.
  /// Saytdagi `🎯 Buyurtma yaratildi: {title} — {price}` xabari alohida
  /// kartochka bo'lib chiziladi.
  static const _orderPrefix = '🎯 Buyurtma yaratildi:';

  ChatOrder? _orderFor(ConversationMessage message) {
    if (!message.text.startsWith(_orderPrefix)) return null;
    final title = message.text.substring(_orderPrefix.length).split('—').first.trim();
    if (title.isEmpty) return null;
    for (final order in _orders) {
      if (order.title == title) return order;
    }
    return null;
  }

  Widget _orderCard(ConversationMessage message, ChatOrder? order, {required bool mine}) {
    final theme = Theme.of(context);
    final body = message.text.substring(_orderPrefix.length).split('—');
    final title = body.first.trim();
    final price = body.length > 1 ? body.sublist(1).join(' — ').trim() : '';
    final me = context.read<AuthService>().user?.id;
    final canAccept = order != null && order.providerId == me && order.status == 'pending';

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 448), // max-w-md
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.olive.withValues(alpha: 0.3)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // px-3 py-2
              color: AppColors.olive.withValues(alpha: 0.05),
              child: Text(
                'BUYURTMA',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w700,
                  color: AppColors.olive,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12), // p-3
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                    ),
                  ),
                  if (price.isNotEmpty)
                    Text(
                      price,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.olive,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    _time(message.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      color: AppColors.dark.withValues(alpha: 0.4),
                    ),
                  ),
                  if (canAccept) ...[
                    const SizedBox(height: 12), // mt-3
                    Row(
                      children: [
                        Expanded(
                          child: _orderButton(
                            theme,
                            t('orders.accept'),
                            background: const Color(0xFF10B981),
                            foreground: Colors.white,
                            onTap: () => _setOrderStatus(order, 'accepted'),
                          ),
                        ),
                        const SizedBox(width: 8), // gap-2
                        _orderButton(
                          theme,
                          t('common.reject'),
                          background: AppColors.surfaceAltLight,
                          foreground: AppColors.dark,
                          onTap: () => _rejectOrder(order),
                        ),
                      ],
                    ),
                  ],
                  if (order != null) ...[
                    const SizedBox(height: 8), // mt-2
                    _orderButton(
                      theme,
                      t('order.view'),
                      background: Colors.white,
                      foreground: AppColors.dark,
                      border: AppColors.borderLight,
                      full: true,
                      onTap: () => context.push('/cabinet/orders/${order.id}'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orderButton(
    ThemeData theme,
    String label, {
    required Color background,
    required Color foreground,
    required VoidCallback onTap,
    Color? border,
    bool full = false,
  }) {
    final button = Pressable(
      onTap: onTap,
      child: Container(
        width: full ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // px-3 py-2
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: border == null ? null : Border.all(color: border),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: foreground,
          ),
        ),
      ),
    );
    return button;
  }

  Future<void> _setOrderStatus(ChatOrder order, String status, {String? reason}) async {
    try {
      await ApiClient.instance.put<dynamic>(
        '/market/cabinet/orders/${order.id}/status',
        data: {'status': status, 'rejected_reason': ?reason},
      );
      await _loadOrders();
    } catch (_) {
      if (mounted) showSiteToast(context, 'Xatolik yuz berdi', kind: ToastKind.error);
    }
  }

  /// Saytda `prompt()` bilan sabab so'raladi.
  Future<void> _rejectOrder(ChatOrder order) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t('orders.rejectReasonPrompt')),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(t('common.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(t('chat.send')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null || reason.isEmpty) return;
    await _setOrderStatus(order, 'rejected', reason: reason);
  }

  /// Buyurtma xabari alohida kartochka, qolgani oddiy pufakcha.
  /// Saytdagi `formatTime` — soat:daqiqa.
  static String _time(DateTime? at) {
    if (at == null) return '';
    final local = at.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  Widget _message(ConversationMessage message, {required bool mine}) {
    if (message.text.startsWith(_orderPrefix)) {
      return _orderCard(message, _orderFor(message), mine: mine);
    }
    return _bubble(message, mine: mine);
  }

  Widget _bubble(ConversationMessage message, {required bool mine}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: mine ? AppColors.olive : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppRadius.md),
                  topRight: const Radius.circular(AppRadius.md),
                  bottomLeft: Radius.circular(mine ? AppRadius.md : 2),
                  bottomRight: Radius.circular(mine ? 2 : AppRadius.md),
                ),
                border: mine ? null : Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message.text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      height: 1.4,
                      color: mine ? Colors.white : AppColors.dark,
                    ),
                  ),
                  if (message.createdAt case final date?) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${date.hour.toString().padLeft(2, '0')}:'
                      '${date.minute.toString().padLeft(2, '0')}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: mine
                            ? Colors.white.withValues(alpha: 0.7)
                            : AppColors.dark.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sendBox() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _input,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15, color: AppColors.dark),
              decoration: InputDecoration(
                hintText: ChatTexts.typeMessage,
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 15,
                  color: AppColors.dark.withValues(alpha: 0.35),
                ),
                filled: true,
                fillColor: AppColors.surfaceAltLight,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Pressable(
            onTap: _sending ? null : _send,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _sending ? AppColors.olive.withValues(alpha: 0.6) : AppColors.olive,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: SiteIcon(SiteIcons.arrowRight, size: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

abstract final class ChatTexts {
  static String get empty => t('chat.empty');
  static String get typeMessage => t('chat.typeMessage');
  static String get send => t('chat.send');
  static String get online => t('chat.online');
  static String get offline => t('chat.offline');
  static String get lastSeen => t('chat.lastSeen');
  static String get createOrder => t('chat.createOrder');
  static String get createOrderMobile => t('chat.createOrderMobile');
}

/// `/market/cabinet/messages/{id}` javobi.
class ConversationDetail {
  const ConversationDetail({
    required this.id,
    required this.otherUser,
    this.propertyTitle,
    this.propertyType,
    this.messages = const [],
  });

  final int id;
  final ChatUser otherUser;
  final String? propertyTitle;

  /// `designer` | `master` | `agent` | `secondary` | `rent`
  final String? propertyType;
  final List<ConversationMessage> messages;

  /// `/market/chat/conversations/{id}` javobi `snake_case` — kabinetdagi
  /// `/cabinet/messages/{id}` esa camelCase. Ikkalasi ham qo'llab-quvvatlanadi.
  factory ConversationDetail.fromJson(Map<String, dynamic> json, {Object? messages}) {
    final other = json['other_user'] ?? json['otherUser'];
    final title = (json['property_title'] ?? json['propertyTitle'])?.toString().trim();
    return ConversationDetail(
      id: (json['id'] as num?)?.toInt() ?? 0,
      otherUser: other is Map ? ChatUser.fromJson(other) : const ChatUser(id: 0, fullName: ''),
      propertyTitle: (title == null || title.isEmpty) ? null : title,
      propertyType: json['property_type']?.toString(),
      messages: [
        for (final row in ((messages ?? json['messages']) as List? ?? const []))
          if (row is Map) ConversationMessage.fromJson(row),
      ],
    );
  }
}

class ChatUser {
  const ChatUser({
    required this.id,
    required this.fullName,
    this.avatar,
    this.isOnline = false,
    this.lastSeenAt,
  });

  final int id;
  final String fullName;
  final String? avatar;
  final bool isOnline;
  final DateTime? lastSeenAt;

  factory ChatUser.fromJson(Map row) => ChatUser(
    id: (row['id'] as num?)?.toInt() ?? 0,
    fullName: (row['name'] ?? row['fullName'])?.toString() ?? '',
    avatar: row['avatar']?.toString(),
    isOnline: row['is_online'] == true,
    lastSeenAt: DateTime.tryParse(row['last_seen_at']?.toString() ?? ''),
  );
}

class ConversationMessage {
  const ConversationMessage({
    required this.id,
    required this.senderId,
    required this.text,
    this.isRead = false,
    this.createdAt,
  });

  final int id;
  final int senderId;
  final String text;
  final bool isRead;
  final DateTime? createdAt;

  factory ConversationMessage.fromJson(Map row) => ConversationMessage(
    id: (row['id'] as num?)?.toInt() ?? 0,
    senderId: (row['sender_id'] ?? row['senderId']) is num
        ? ((row['sender_id'] ?? row['senderId']) as num).toInt()
        : 0,
    text: row['text']?.toString() ?? '',
    isRead: (row['is_read'] ?? row['isRead']) == true,
    createdAt: DateTime.tryParse((row['created_at'] ?? row['createdAt'])?.toString() ?? ''),
  );
}

/// Suhbatdagi buyurtma — `/market/chat/conversations/{id}/orders`.
class ChatOrder {
  const ChatOrder({
    required this.id,
    required this.title,
    required this.status,
    this.providerId,
    this.clientId,
  });

  final int id;
  final String title;
  final String status;
  final int? providerId;
  final int? clientId;

  factory ChatOrder.fromJson(Map row) => ChatOrder(
    id: (row['id'] as num?)?.toInt() ?? 0,
    title: row['title']?.toString() ?? '',
    status: row['status']?.toString() ?? '',
    providerId: (row['provider_id'] as num?)?.toInt(),
    clientId: (row['client_id'] as num?)?.toInt(),
  );
}
