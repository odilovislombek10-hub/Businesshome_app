import '../../core/i18n/translate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../core/api/api_client.dart';
import '../../core/api/media_url.dart';
import '../../core/models/property_listing.dart';
import 'entrance.dart';
import 'site_icon.dart';
import 'site_toast.dart';

/// `property-contact-card.component.ts` — e'lon egasi bilan bog'lanish kartasi.
///
/// Mobilda xaritadan keyin turadi. Tugmalar: qo'ng'iroq, "Yozish" (suhbat
/// ochadi), WhatsApp; pastda telefon raqami `+998 90 123 45 67` ko'rinishida.
class PropertyContactCard extends StatelessWidget {
  const PropertyContactCard({
    super.key,
    required this.owner,
    required this.propertyTitle,
    required this.propertyType,
    required this.propertyId,
    this.showChat = true,
  });

  final ListingOwner owner;
  final String propertyTitle;

  /// `secondary` yoki `rent` — suhbat shu nom bilan ochiladi.
  final String propertyType;
  final int propertyId;
  final bool showChat;

  static String formatPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 12 && digits.startsWith('998')) {
      return '+${digits.substring(0, 3)} ${digits.substring(3, 5)} ${digits.substring(5, 8)}'
          ' ${digits.substring(8, 10)} ${digits.substring(10, 12)}';
    }
    return phone;
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && uri.hasScheme) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// `startChat()` — kirmagan bo'lsa saytda login sahifasiga yuboriladi.
  Future<void> _startChat(BuildContext context) async {
    if (!await ApiClient.instance.isLoggedIn) {
      if (!context.mounted) return;
      context.push('/login');
      return;
    }
    try {
      final res = await ApiClient.instance.post<dynamic>(
        '/market/chat/start',
        data: {'property_type': propertyType, 'property_id': propertyId, 'initial_message': null},
      );
      final data = res.data;
      final id = data is Map ? (data['id'] as num?)?.toInt() : null;
      if (!context.mounted) return;
      if (id == null) {
        showSiteToast(context, 'Xatolik yuz berdi', kind: ToastKind.error);
        return;
      }
      context.push('/chat/$id');
    } catch (_) {
      if (!context.mounted) return;
      showSiteToast(context, 'Xatolik yuz berdi', kind: ToastKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phone = owner.phone ?? '';
    final name = (owner.name?.isNotEmpty ?? false) ? owner.name! : t('contact.owner');
    final avatar = absoluteMediaUrl(owner.avatar);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24), // p-6
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.surfaceMutedLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 64, // w-16
                height: 64,
                child: Stack(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.olive.withValues(alpha: 0.1),
                        border: Border.all(
                          color: AppColors.olive.withValues(alpha: 0.2),
                          width: 2, // ring-2 ring-olive/20
                        ),
                        image: avatar == null || avatar.isEmpty
                            ? null
                            : DecorationImage(
                                image: CachedNetworkImageProvider(avatar),
                                fit: BoxFit.cover,
                              ),
                      ),
                      child: avatar == null || avatar.isEmpty
                          ? Center(
                              child: Text(
                                name.characters.first.toUpperCase(),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.olive,
                                ),
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981), // emerald-500
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Center(
                          child: SiteIcon(SiteIcons.check, size: 10, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16), // gap-4
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 18, // text-lg
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                    ),
                    if (owner.type case final type?) ...[
                      const SizedBox(height: 4), // mt-1
                      _typeBadge(theme, type),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20), // mb-5
          Container(
            padding: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.surfaceMutedLight)),
            ),
            child: Row(
              children: [
                Expanded(child: _stat(theme, t('contact.responseTime'), t('contact.within1Hour'))),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('contact.availability'),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 12,
                          color: AppColors.dark.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            t('contact.online'),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF059669),
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
          const SizedBox(height: 20),
          if (phone.isNotEmpty)
            _button(
              theme,
              t('contact.call'),
              background: AppColors.olive,
              foreground: Colors.white,
              onTap: () => _open('tel:$phone'),
            ),
          if (showChat) ...[
            const SizedBox(height: 10), // space-y-2.5
            _button(
              theme,
              t('chat.write'),
              background: Colors.white,
              foreground: AppColors.olive,
              border: AppColors.olive,
              onTap: () => _startChat(context),
            ),
          ],
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 10),
            _button(
              theme,
              'WhatsApp',
              background: const Color(0xFF10B981),
              foreground: Colors.white,
              onTap: () {
                final digits = phone.replaceAll(RegExp(r'\D'), '');
                final message = Uri.encodeComponent(
                  "Salom, $propertyTitle e'loni haqida bilmoqchi edim",
                );
                _open('https://wa.me/$digits?text=$message');
              },
            ),
            const SizedBox(height: 12), // pt-3
            Center(
              child: Column(
                children: [
                  Text(
                    t('contact.phoneNumber'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 12,
                      color: AppColors.dark.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 4), // mb-1
                  Text(
                    formatPhone(phone),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1, // tracking-wider
                      color: AppColors.dark,
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

  Widget _typeBadge(ThemeData theme, String type) {
    final owner = type == 'owner';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: owner ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        owner ? t('contact.owner') : t('contact.agent'),
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: owner ? const Color(0xFF059669) : const Color(0xFF2563EB),
        ),
      ),
    );
  }

  Widget _stat(ThemeData theme, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 12,
            color: AppColors.dark.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 2), // mb-0.5
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.dark,
          ),
        ),
      ],
    );
  }

  Widget _button(
    ThemeData theme,
    String label, {
    required Color background,
    required Color foreground,
    required VoidCallback onTap,
    Color? border,
  }) {
    return Pressable(
      scale: 0.99,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14), // py-3.5
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: border == null ? null : Border.all(color: border, width: 2),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: foreground,
          ),
        ),
      ),
    );
  }
}
