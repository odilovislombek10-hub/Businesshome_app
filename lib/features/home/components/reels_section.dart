import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../shared/widgets/entrance.dart';
import '../../../core/api/media_url.dart';
import '../../../core/models/reel.dart';

/// The site's `reels-section`: a heading with a "Barchasini ko'rish" link and two circular
/// arrows, then a horizontal strip of 180px-wide 9:16 video thumbnails.
///
/// Each card carries a category pill top-right, the author top-left, a centred play button, and
/// the caption, price and location along the bottom over a `from-dark/70 … to-dark/90` scrim.
class ReelsSection extends StatefulWidget {
  const ReelsSection({super.key, required this.reels});

  final List<Reel> reels;

  @override
  State<ReelsSection> createState() => _ReelsSectionState();
}

class _ReelsSectionState extends State<ReelsSection> {
  final _scroll = ScrollController();

  static const _cardWidth = 180.0;
  static const _gap = 16.0;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollBy(double delta) {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      (_scroll.offset + delta).clamp(0.0, _scroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: AppColors.cream,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40), // py-10
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BusinessHome Reels',
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontSize: 24,
                            color: AppColors.dark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => context.go('/reels'),
                          child: Text(
                            "Barchasini ko'rish",
                            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.olive),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _RoundArrow(
                    icon: Icons.chevron_left,
                    onPressed: () => _scrollBy(-(_cardWidth + _gap)),
                  ),
                  const SizedBox(width: 8),
                  _RoundArrow(
                    icon: Icons.chevron_right,
                    onPressed: () => _scrollBy(_cardWidth + _gap),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24), // mb-6
            if (widget.reels.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Text(
                    "Hozircha videolar yo'q",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.dark.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                height: _cardWidth * 16 / 9, // aspect-[9/16]
                child: ListView.separated(
                  controller: _scroll,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: widget.reels.length,
                  separatorBuilder: (_, _) => const SizedBox(width: _gap),
                  itemBuilder: (context, i) => _ReelCard(reel: widget.reels[i], width: _cardWidth),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RoundArrow extends StatelessWidget {
  const _RoundArrow({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      customBorder: const CircleBorder(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.dark.withValues(alpha: 0.2), width: 2),
        ),
        child: Icon(icon, size: 20, color: AppColors.dark.withValues(alpha: 0.6)),
      ),
    );
  }
}

class _ReelCard extends StatelessWidget {
  const _ReelCard({required this.reel, required this.width});

  final Reel reel;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thumbnail = absoluteMediaUrl(reel.thumbnail);
    final avatar = absoluteMediaUrl(reel.authorAvatar);

    return Pressable.builder(
      onTap: () => context.go('/reels/${reel.id}'),
      builder: (context, pressed) => SizedBox(
        width: width,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg), // rounded-2xl
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (thumbnail != null)
                ZoomOnPress(
                  pressed: pressed,
                  child: CachedNetworkImage(
                    imageUrl: thumbnail,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => const ColoredBox(color: AppColors.dark),
                    errorWidget: (_, _, _) => const ColoredBox(color: AppColors.dark),
                  ),
                )
              else
                const ColoredBox(color: AppColors.dark),

              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.dark.withValues(alpha: 0.7),
                      Colors.transparent,
                      AppColors.dark.withValues(alpha: 0.9),
                    ],
                  ),
                ),
              ),

              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.olive.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
                ),
              ),

              if (reel.badge case final badge?)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.olive.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      badge,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              if (reel.author != null)
                Positioned(
                  top: 12,
                  left: 12,
                  right: 64,
                  child: Row(
                    children: [
                      if (avatar != null)
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                            image: DecorationImage(
                              image: CachedNetworkImageProvider(avatar),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          reel.authorFirstName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      reel.shortTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                    if (reel.price case final price?) ...[
                      const SizedBox(height: 4),
                      Text(
                        price,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                          color: AppColors.olive.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    if (reel.location case final location?) ...[
                      const SizedBox(height: 2),
                      Text(
                        location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
