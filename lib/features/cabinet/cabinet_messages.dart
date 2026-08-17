import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../shared/widgets/app_image.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/specialist_bits.dart';
import 'cabinet_repository.dart';
import 'cabinet_texts.dart';

/// Kabinetning `messages` bo'limi — saytdagi `messagesTpl`.
///
/// Bitta kartada suhbatlar ro'yxati: avatar (yo'q bo'lsa ismdan gradientli harflar), onlayn
/// nuqtasi, ism va nisbiy vaqt, e'lon sarlavhasi, oxirgi xabar va o'qilmaganlar soni.
class CabinetMessages extends StatelessWidget {
  const CabinetMessages({
    super.key,
    required this.future,
    required this.onOpen,
    required this.onRetry,
  });

  final Future<List<ChatConversation>> future;

  /// Saytda `routerLink="['/chat', conv.id]"`.
  final void Function(ChatConversation conversation) onOpen;

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          CabinetTexts.tabLabel('messages'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 20, // text-xl
            fontWeight: FontWeight.w700,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(height: 16), // space-y-4
        FutureBuilder<List<ChatConversation>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return _card(_spinner());
            if (snapshot.hasError) {
              return ErrorView(message: "Xabarlarni yuklab bo'lmadi", onRetry: onRetry);
            }
            final items = snapshot.data ?? const <ChatConversation>[];
            if (items.isEmpty) return _card(_empty(theme));
            return _card(
              Column(
                children: [
                  for (final (index, conv) in items.indexed) ...[
                    if (index > 0) const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    _Row(conversation: conv, onTap: () => onOpen(conv)),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _card(Widget child) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.lg), // rounded-2xl
      border: Border.all(color: AppColors.borderLight),
    ),
    clipBehavior: Clip.antiAlias,
    child: child,
  );

  /// `p-12 text-center` — yuklanish aylanasi.
  Widget _spinner() => const Padding(
    padding: EdgeInsets.all(48),
    child: Center(
      child: SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.olive),
      ),
    ),
  );

  Widget _empty(ThemeData theme) => Padding(
    padding: const EdgeInsets.all(48), // p-12
    child: Column(
      children: [
        Text(
          CabinetTexts.noMessages,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 18, // text-lg
            fontWeight: FontWeight.w700,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(height: 8), // mb-2
        Text(
          CabinetTexts.noMessagesDesc,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.dark.withValues(alpha: 0.5)),
        ),
      ],
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row({required this.conversation, required this.onTap});

  final ChatConversation conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unread = conversation.unreadCount > 0;
    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16), // p-4
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _avatar(theme),
            const SizedBox(width: 12), // gap-3
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.otherName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: unread ? AppColors.dark : AppColors.dark.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8), // gap-2
                      Text(
                        CabinetTexts.relativeTime(conversation.lastMessageAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 11, // text-[11px]
                          color: AppColors.dark.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2), // mb-0.5
                  if (conversation.propertyTitle case final title? when title.isNotEmpty) ...[
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
                    const SizedBox(height: 2),
                  ],
                  Text(
                    conversation.lastText?.isNotEmpty == true ? conversation.lastText! : '—',
                    maxLines: 1, // line-clamp-1
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: unread ? FontWeight.w500 : FontWeight.w400,
                      color: AppColors.dark.withValues(alpha: unread ? 0.8 : 0.5),
                    ),
                  ),
                ],
              ),
            ),
            if (unread) ...[
              const SizedBox(width: 8),
              Container(
                margin: const EdgeInsets.only(top: 8), // mt-2
                constraints: const BoxConstraints(minWidth: 20), // min-w-[20px]
                height: 20, // h-5
                padding: const EdgeInsets.symmetric(horizontal: 6), // px-1.5
                decoration: BoxDecoration(
                  color: AppColors.olive,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Center(
                  child: Text(
                    '${conversation.unreadCount}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10, // text-[10px]
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// `w-12 h-12 rounded-full ring-2 ring-white` + pastki o'ngda onlayn nuqtasi.
  Widget _avatar(ThemeData theme) {
    final avatar = conversation.otherAvatar;
    final hasAvatar = avatar != null && avatar.isNotEmpty;
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 48, // w-12 h-12
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2), // ring-2 ring-white
            ),
            child: ClipOval(
              child: hasAvatar
                  ? AppImage(imageUrl: avatar, fit: BoxFit.cover)
                  : DecoratedBox(
                      decoration: BoxDecoration(gradient: avatarGradient(conversation.otherName)),
                      child: Center(
                        child: Text(
                          initialsOf(conversation.otherName),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          if (conversation.otherIsOnline)
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                width: 12, // w-3 h-3
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981), // bg-emerald-500
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
