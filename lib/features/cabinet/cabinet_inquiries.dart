import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../shared/widgets/app_image.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/specialist_bits.dart';
import 'cabinet_repository.dart';
import 'cabinet_texts.dart';

/// Kabinetning `inquiries` bo'limi (agent) — saytdagi `inquiriesTpl`.
///
/// Har so'rov: mijoz avatari, ismi va telefoni, holat nishonchasi, e'lon sarlavhasi, xabar
/// matni, pastda sana va uchta amal — javob berish (suhbat ochadi), WhatsApp, qo'ng'iroq.
class CabinetInquiries extends StatelessWidget {
  const CabinetInquiries({
    super.key,
    required this.future,
    required this.onOpenChat,
    required this.onRetry,
  });

  final Future<List<CabinetInquiry>> future;

  /// Saytdagi `openChatFromInquiry` — javobda kelgan suhbatga o'tiladi.
  final void Function(CabinetInquiry inquiry) onOpenChat;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<CabinetInquiry>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.olive));
        }
        if (snapshot.hasError) {
          return ErrorView(message: CabinetTexts.inquiriesLoadError, onRetry: onRetry);
        }
        final items = snapshot.data ?? const <CabinetInquiry>[];

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              CabinetTexts.tabLabel('inquiries'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 20, // text-xl
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 16), // space-y-4
            if (items.isEmpty)
              _emptyCard(theme)
            else
              for (final inquiry in items) ...[
                _card(context, theme, inquiry),
                const SizedBox(height: 12), // space-y-3
              ],
          ],
        );
      },
    );
  }

  Widget _card(BuildContext context, ThemeData theme, CabinetInquiry inquiry) {
    final (label, foreground, background) = CabinetTexts.inquiryStatusStyle(inquiry.status);
    return Container(
      padding: const EdgeInsets.all(20), // p-5
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg), // rounded-2xl
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _avatar(theme, inquiry),
          const SizedBox(width: 16), // gap-4
          Expanded(
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
                            inquiry.clientName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.dark,
                            ),
                          ),
                          Text(
                            inquiry.clientPhone,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 12, // text-xs
                              color: AppColors.dark.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8), // gap-2
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: background,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10, // text-[10px]
                          fontWeight: FontWeight.w700,
                          color: foreground,
                        ),
                      ),
                    ),
                  ],
                ),
                if (inquiry.propertyTitle case final title? when title.isNotEmpty) ...[
                  const SizedBox(height: 4), // mt-1
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.olive,
                    ),
                  ),
                ],
                const SizedBox(height: 8), // mt-2
                Text(
                  inquiry.message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.6, // leading-relaxed
                    color: AppColors.dark.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 12), // mt-3
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        inquiry.createdAt ?? '',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 11, // text-[11px]
                          color: AppColors.dark.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                    _action(
                      theme,
                      CabinetTexts.inquiryReply,
                      AppColors.olive,
                      Colors.white,
                      () => onOpenChat(inquiry),
                    ),
                    const SizedBox(width: 8), // gap-2
                    _action(
                      theme,
                      'WA',
                      const Color(0xFF10B981), // bg-emerald-500
                      Colors.white,
                      () => _open('https://wa.me/${inquiry.clientPhone.replaceAll('+', '')}'),
                    ),
                    const SizedBox(width: 8),
                    _action(
                      theme,
                      CabinetTexts.inquiryCall,
                      AppColors.surfaceMutedLight,
                      AppColors.dark.withValues(alpha: 0.7),
                      () => _open('tel:${inquiry.clientPhone}'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _open(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  /// `px-3 py-1.5 text-xs font-semibold rounded-lg`
  Widget _action(
    ThemeData theme,
    String label,
    Color background,
    Color foreground,
    VoidCallback onTap,
  ) => Pressable(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    ),
  );

  Widget _avatar(ThemeData theme, CabinetInquiry inquiry) {
    final avatar = inquiry.clientAvatar;
    final hasAvatar = avatar != null && avatar.isNotEmpty;
    return Container(
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
                decoration: BoxDecoration(gradient: avatarGradient(inquiry.clientName)),
                child: Center(
                  child: Text(
                    initialsOf(inquiry.clientName),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _emptyCard(ThemeData theme) => Container(
    padding: const EdgeInsets.all(48),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: AppColors.borderLight),
    ),
    child: Center(
      child: Text(
        CabinetTexts.inquiriesEmpty,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.dark.withValues(alpha: 0.5)),
      ),
    ),
  );
}
