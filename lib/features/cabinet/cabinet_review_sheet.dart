import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/api/api_client.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/site_icon.dart';
import '../../shared/widgets/site_toast.dart';
import 'cabinet_repository.dart';
import 'cabinet_texts.dart';

/// Saytdagi "REVIEW MODAL" — tugagan buyurtmaga sharh yozish.
///
/// Beshta yulduz, matn, "Anonim qoldirish" belgisi va kechikish haqidagi izoh.
/// Yuborish `POST /market/cabinet/reviews`.
class ReviewSheet extends StatefulWidget {
  const ReviewSheet({super.key, required this.order});

  final ClientOrder order;

  static Future<bool?> show(BuildContext context, {required ClientOrder order}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => ReviewSheet(order: order),
    );
  }

  @override
  State<ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<ReviewSheet> {
  final _text = TextEditingController();
  int _rating = 0;
  bool _anonymous = false;
  bool _sending = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  /// `openReviewModal()` — xizmat turiga qarab kimga sharh yozilishi.
  String get _targetType => switch (widget.order.serviceType) {
    'design' => 'designer',
    'master_work' => 'master',
    _ => 'agent',
  };

  Future<void> _submit() async {
    if (_rating == 0 || _sending) return;
    setState(() => _sending = true);
    try {
      await ApiClient.instance.post<dynamic>(
        '/market/cabinet/reviews',
        data: {
          'target_type': _targetType,
          'target_id': widget.order.providerId,
          'order_id': widget.order.id,
          'rating': _rating,
          'text': _text.text.trim(),
          'is_anonymous': _anonymous,
        },
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
      showSiteToast(context, "Sharhni yuborib bo'lmadi", kind: ToastKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        padding: const EdgeInsets.all(24), // p-6
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              CabinetTexts.writeReview,
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 18, // text-lg
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 16), // mb-4
            Row(
              children: [
                for (var i = 1; i <= 5; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 4), // gap-1
                    child: Pressable(
                      onTap: () => setState(() => _rating = i),
                      child: SiteIcon(
                        i <= _rating ? SiteIcons.ratingStar : SiteIcons.ratingStarOutline,
                        size: 28,
                        color: i <= _rating
                            ? const Color(0xFFF59E0B)
                            : AppColors.dark.withValues(alpha: 0.25),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _text,
              maxLines: 4,
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
              decoration: InputDecoration(
                hintText: CabinetTexts.reviewPlaceholder,
                filled: true,
                fillColor: AppColors.surfaceAltLight,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
              ),
            ),
            const SizedBox(height: 12), // mb-3
            Pressable(
              scale: 0.995,
              onTap: () => setState(() => _anonymous = !_anonymous),
              child: Container(
                padding: const EdgeInsets.all(12), // p-3
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB), // amber-50
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: const Color(0xFFFEF3C7)), // amber-100
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: _anonymous,
                        activeColor: AppColors.olive,
                        onChanged: (value) => setState(() => _anonymous = value ?? false),
                      ),
                    ),
                    const SizedBox(width: 10), // gap-2.5
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Anonim qoldirish',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.dark,
                            ),
                          ),
                          const SizedBox(height: 2), // mt-0.5
                          Text(
                            'Ismingiz va avataringiz "Anonim foydalanuvchi" deb '
                            "ko'rsatiladi. Mutaxassis ham, boshqalar ham kim yozganini "
                            'bilmaydi.',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 11,
                              color: AppColors.dark.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8), // mb-2
            Text(
              "Sharh sizning ma'lumotlaringizni himoya qilish uchun 1 soatdan keyin "
              'omma uchun chiqadi.',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 11,
                color: AppColors.dark.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Pressable(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAltLight,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Text(
                        CabinetTexts.cancel,
                        style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.dark),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8), // gap-2
                Expanded(
                  child: Pressable(
                    scale: _rating == 0 ? 1 : 0.98,
                    onTap: _submit,
                    child: Opacity(
                      opacity: _rating == 0 || _sending ? 0.6 : 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.olive,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Text(
                          'Yuborish',
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
                        ),
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
