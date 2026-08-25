import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/api/api_client.dart';
import '../../core/api/media_url.dart';
import '../../core/services/auth_service.dart';
import '../../shared/widgets/app_image.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/site_icon.dart';

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

  Future<void> _load({bool silent = false}) async {
    try {
      final res = await ApiClient.instance.get<dynamic>(
        '/market/cabinet/messages/${widget.id}',
        refresh: true,
      );
      final data = res.data;
      if (res.statusCode != 200 || data is! Map<String, dynamic>) {
        if (!silent && mounted) setState(() => _loading = false);
        return;
      }
      final conversation = ConversationDetail.fromJson(data);
      if (!mounted) return;
      final grew = (_conversation?.messages.length ?? 0) < conversation.messages.length;
      setState(() {
        _conversation = conversation;
        _loading = false;
      });
      if (grew) _scrollToEnd();
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
        '/market/cabinet/messages/${widget.id}',
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
                if (_conversation?.propertyTitle case final title?)
                  Text(
                    title,
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
        ],
      ),
    );
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
          _bubble(messages[index], mine: messages[index].senderId == me),
    );
  }

  /// O'z xabari o'ngda zaytun fonda, suhbatdoshniki chapda oq fonda.
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
  static const empty = "Hozircha xabarlar yo'q";
  static const typeMessage = 'Xabar yozing...';
  static const send = 'Yuborish';
}

/// `/market/cabinet/messages/{id}` javobi.
class ConversationDetail {
  const ConversationDetail({
    required this.id,
    required this.otherUser,
    this.propertyTitle,
    this.messages = const [],
  });

  final int id;
  final ChatUser otherUser;
  final String? propertyTitle;
  final List<ConversationMessage> messages;

  factory ConversationDetail.fromJson(Map<String, dynamic> json) {
    final other = json['otherUser'];
    final title = json['propertyTitle']?.toString().trim();
    return ConversationDetail(
      id: (json['id'] as num?)?.toInt() ?? 0,
      otherUser: other is Map ? ChatUser.fromJson(other) : const ChatUser(id: 0, fullName: ''),
      propertyTitle: (title == null || title.isEmpty) ? null : title,
      messages: [
        for (final row in (json['messages'] as List? ?? const []))
          if (row is Map) ConversationMessage.fromJson(row),
      ],
    );
  }
}

class ChatUser {
  const ChatUser({required this.id, required this.fullName, this.avatar});

  final int id;
  final String fullName;
  final String? avatar;

  factory ChatUser.fromJson(Map row) => ChatUser(
    id: (row['id'] as num?)?.toInt() ?? 0,
    fullName: row['fullName']?.toString() ?? '',
    avatar: row['avatar']?.toString(),
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
    senderId: (row['senderId'] as num?)?.toInt() ?? 0,
    text: row['text']?.toString() ?? '',
    isRead: row['isRead'] == true,
    createdAt: DateTime.tryParse(row['createdAt']?.toString() ?? ''),
  );
}
