import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/services/ai_chat_service.dart';
import 'entrance.dart';
import 'site_icon.dart';

/// The site's floating `ai-assistant` — "Aziza".
///
/// A 56px olive gradient tile pinned bottom-right (`fixed bottom-6 right-6`, `rounded-2xl`) with
/// a red pulse dot, a hint bubble that fades after ten seconds, and a chat sheet that slides up
/// when tapped.
class AiAssistant extends StatefulWidget {
  const AiAssistant({super.key});

  @override
  State<AiAssistant> createState() => _AiAssistantState();
}

class _AiAssistantState extends State<AiAssistant> {
  bool _showHint = true;

  @override
  void initState() {
    super.initState();
    // The site drops the hint after ten seconds.
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) setState(() => _showHint = false);
    });
  }

  void _open() {
    setState(() => _showHint = false);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _ChatSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned(
      right: 24, // right-6
      bottom: 24, // bottom-6
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showHint)
            Container(
              constraints: const BoxConstraints(maxWidth: 260),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.surfaceMutedLight),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 4)),
                ],
              ),
              child: Text(
                'Salom! Men Aziza — uy tanlashda yordam beraman 👋',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 12,
                  color: AppColors.dark,
                  height: 1.4,
                ),
              ),
            ),
          Pressable(
            scale: 0.9, // active:scale-90
            onTap: _open,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 56, // w-14
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.olive, AppColors.oliveMuted],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.olive.withValues(alpha: 0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: SiteIcon(SiteIcons.sparkle, size: 26, color: Colors.white),
                  ),
                ),
                Positioned(
                  top: -2,
                  right: -2,
                  child: Pulse(
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444), // red-500
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatSheet extends StatefulWidget {
  const _ChatSheet();

  @override
  State<_ChatSheet> createState() => _ChatSheetState();
}

class _ChatSheetState extends State<_ChatSheet> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _service = AiChatService.instance;

  /// The quick prompts the site offers under the greeting.
  static const _suggestions = [
    'Toshkentda 2 xonali kvartira',
    'Arzon ijara variantlari',
    'Yangi qurilayotgan loyihalar',
    'Dizayner kerak',
  ];

  @override
  void initState() {
    super.initState();
    _service.addListener(_onChange);
  }

  @override
  void dispose() {
    _service.removeListener(_onChange);
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onChange() {
    if (!mounted) return;
    setState(() {});
    // Follow the newest message, as the site does after each render.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send([String? preset]) {
    final text = preset ?? _input.text;
    if (text.trim().isEmpty) return;
    _input.clear();
    _service.send(text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final messages = _service.messages;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.olive, AppColors.oliveMuted],
                ),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white24,
                    child: SiteIcon(SiteIcons.sparkle, size: 18, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Aziza — AI yordamchi',
                          style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
                        ),
                        Row(
                          children: [
                            const Pulse(
                              child: SizedBox(
                                width: 6,
                                height: 6,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Color(0xFF86EFAC), // green-300
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'onlayn',
                              style: theme.textTheme.labelSmall?.copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.all(16),
                children: [
                  if (messages.isEmpty) ...[
                    _Bubble(
                      text:
                          'Salom! Men Aziza — sizga uy tanlashda yordamchi 👋\n\n'
                          'Qanaqa joy izlayapsiz? Bir necha savol berib, sizga eng '
                          'moslarini topib beraman ✨',
                      isUser: false,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final suggestion in _suggestions)
                          Pressable(
                            scale: 0.95, // active:scale-95
                            onTap: () => _send(suggestion),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                                border: Border.all(color: AppColors.borderLight),
                              ),
                              child: Text(
                                suggestion,
                                style: theme.textTheme.labelSmall?.copyWith(fontSize: 12),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                  for (final message in messages) ...[
                    _Bubble(text: message.text, isUser: message.isUser),
                    const SizedBox(height: 12),
                  ],
                  if (_service.loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  if (_service.error case final error?)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Text(
                        error,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(hintText: 'Xabar yozing...', isDense: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: AppColors.olive),
                    onPressed: _service.loading ? null : () => _send(),
                    icon: const Icon(Icons.send, size: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.isUser});

  final String text;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? AppColors.olive : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isUser ? Colors.white : theme.colorScheme.onSurface,
            height: 1.45,
          ),
        ),
      ),
    );
  }
}
