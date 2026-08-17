import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../shared/widgets/app_image.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/site_icon.dart';
import '../../shared/widgets/specialist_bits.dart';
import 'cabinet_repository.dart';
import 'cabinet_texts.dart';

/// Kabinetning `reviews` bo'limi (dizayner/usta) — saytdagi `reviewsTpl`.
///
/// Har sharh: mijoz avatari, ismi, xizmat nomi va sanasi, besh yulduz, matn qo'shtirnoqda.
/// Javob bo'lsa zaytun chiziqli blokda; bo'lmasa "Javob berish" tugmasi forma ochadi.
class CabinetReviews extends StatefulWidget {
  const CabinetReviews({super.key, required this.future, required this.onChanged});

  final Future<List<CabinetReview>> future;
  final VoidCallback onChanged;

  @override
  State<CabinetReviews> createState() => _CabinetReviewsState();
}

class _CabinetReviewsState extends State<CabinetReviews> {
  final _repo = const CabinetRepository();

  /// Ayni damda javob yozilayotgan sharh — saytdagi `replyingTo`.
  int? _replyingTo;
  final _reply = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _submitReply(CabinetReview review) async {
    if (_reply.text.trim().isEmpty || _sending) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sending = true);
    try {
      await _repo.replyToReview(review.id, _reply.text.trim());
      if (mounted) {
        setState(() {
          _replyingTo = null;
          _reply.clear();
        });
      }
      widget.onChanged();
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text(CabinetTexts.reviewReplyError)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<CabinetReview>>(
      future: widget.future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.olive));
        }
        if (snapshot.hasError) {
          return ErrorView(message: CabinetTexts.reviewsLoadError, onRetry: widget.onChanged);
        }
        final reviews = snapshot.data ?? const <CabinetReview>[];

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              CabinetTexts.tabLabel('reviews'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 20, // text-xl
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 16), // space-y-4
            if (reviews.isEmpty)
              _emptyCard(theme)
            else
              for (final review in reviews) ...[
                _card(theme, review),
                const SizedBox(height: 12), // space-y-3
              ],
          ],
        );
      },
    );
  }

  Widget _card(ThemeData theme, CabinetReview review) => Container(
    padding: const EdgeInsets.all(20), // p-5
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.lg), // rounded-2xl
      border: Border.all(color: AppColors.borderLight),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _avatar(theme, review),
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
                          review.clientName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.dark,
                          ),
                        ),
                        const SizedBox(height: 2), // mt-0.5
                        Text(
                          [?review.serviceName, ?review.date].join(' • '),
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
                  Row(
                    children: [
                      for (var i = 1; i <= 5; i++)
                        Padding(
                          padding: const EdgeInsets.only(left: 2), // gap-0.5
                          child: SiteIcon(
                            i <= review.rating ? SiteIcons.ratingStar : SiteIcons.ratingStarOutline,
                            size: 14,
                            color: i <= review.rating
                                ? const Color(0xFFF59E0B)
                                : AppColors.dark.withValues(alpha: 0.2),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8), // mt-2
              Text(
                '"${review.comment}"',
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.6, // leading-relaxed
                  color: AppColors.dark.withValues(alpha: 0.7),
                ),
              ),
              if (review.replyText case final reply?)
                _replyBlock(theme, reply)
              else if (_replyingTo == review.id)
                _replyForm(theme, review)
              else ...[
                const SizedBox(height: 8), // mt-2
                GestureDetector(
                  onTap: () => setState(() {
                    _replyingTo = review.id;
                    _reply.clear();
                  }),
                  child: Text(
                    CabinetTexts.reviewReply,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 12, // text-xs
                      fontWeight: FontWeight.w600,
                      color: AppColors.olive,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );

  /// `pl-4 border-l-2 border-olive bg-olive/5 p-3 rounded-lg`
  Widget _replyBlock(ThemeData theme, String reply) => Container(
    margin: const EdgeInsets.only(top: 12), // mt-3
    padding: const EdgeInsets.all(12), // p-3
    decoration: BoxDecoration(
      color: AppColors.olive.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      border: const Border(left: BorderSide(color: AppColors.olive, width: 2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          CabinetTexts.reviewSpecialistReply,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.olive,
          ),
        ),
        const SizedBox(height: 4), // mb-1
        Text(
          reply,
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.dark.withValues(alpha: 0.7)),
        ),
      ],
    ),
  );

  Widget _replyForm(ThemeData theme, CabinetReview review) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      borderSide: BorderSide(color: color),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 12), // mt-3
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _reply,
            maxLines: 2,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.dark),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: AppColors.surfaceAltLight,
              hintText: CabinetTexts.reviewReplyPlaceholder,
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.dark.withValues(alpha: 0.4),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: border(AppColors.borderLight),
              enabledBorder: border(AppColors.borderLight),
              focusedBorder: border(AppColors.olive),
            ),
          ),
          const SizedBox(height: 8), // mt-2
          Row(
            children: [
              Pressable(
                onTap: _reply.text.trim().isEmpty || _sending ? null : () => _submitReply(review),
                child: Opacity(
                  opacity: _reply.text.trim().isEmpty || _sending ? 0.6 : 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.olive,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      CabinetTexts.reviewSendReply,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8), // gap-2
              Pressable(
                onTap: () => setState(() {
                  _replyingTo = null;
                  _reply.clear();
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMutedLight,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Text(
                    CabinetTexts.cancel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dark,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatar(ThemeData theme, CabinetReview review) {
    final avatar = review.clientAvatar;
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
                decoration: BoxDecoration(gradient: avatarGradient(review.clientName)),
                child: Center(
                  child: Text(
                    initialsOf(review.clientName),
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
        CabinetTexts.reviewsEmpty,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.dark.withValues(alpha: 0.5)),
      ),
    ),
  );
}
