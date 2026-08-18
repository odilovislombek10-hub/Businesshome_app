import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/api/media_url.dart';
import '../../core/models/content.dart';
import '../../shared/widgets/app_image.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/site_footer_section.dart';
import '../../shared/widgets/site_header.dart';
import '../../shared/widgets/site_icon.dart';
import 'news_repository.dart';
import 'news_texts.dart';

/// Saytning `/news` sahifasi — `news.component.ts`.
///
/// Mobil ko'rinish: to'q gradientli hero (fon rasmi ustida), keyin `bg-cream` tanada birinchi
/// yangilik "Tanlangan" kartasi (mobilda `grid-cols-1` — rasm tepada, matn ostida), qolganlari
/// bitta ustunli kartalar ro'yxati.
class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final _repo = const NewsRepository();
  final _scroll = ScrollController();

  late final Future<List<NewsItem>> _future = _repo.loadAll();
  bool _scrolled = false;

  /// Shablondagi hero fon rasmi (`unsplash`) — saytda ham qattiq yozilgan.
  static const _heroImage =
      'https://images.unsplash.com/photo-1585829365295-ab7cd400c167?w=1920&q=80';

  /// Rasmi yo'q yangilik uchun zaxira — saytdagi bilan bir xil.
  static const _fallbackImage =
      'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=800&q=80';

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final scrolled = _scroll.offset > 10;
      if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream, // main bg-cream
      body: Stack(
        children: [
          FutureBuilder<List<NewsItem>>(
            future: _future,
            builder: (context, snapshot) {
              final loading = snapshot.connectionState == ConnectionState.waiting;
              final news = snapshot.data ?? const <NewsItem>[];
              return CustomScrollView(
                controller: _scroll,
                slivers: [
                  SliverToBoxAdapter(child: _hero(news.length)),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 32, 16, 0), // container py-8
                    sliver: SliverList.list(
                      children: loading
                          ? [_stateBox(NewsTexts.loading, spinner: true)]
                          : news.isEmpty
                          ? [_emptyBox()]
                          : _cards(news),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 48)),
                  // Shablon `<app-footer />` bilan tugaydi.
                  const SliverToBoxAdapter(child: SiteFooterSection()),
                ],
              );
            },
          ),
          // Shablonda `[transparent]="true"` — hero ustida shaffof, surilgach to'qlashadi.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SiteHeader(transparent: true, scrolled: _scrolled, showSearch: false),
          ),
        ],
      ),
    );
  }

  // ── hero ────────────────────────────────────────────────────────────────────

  Widget _hero(int count) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        Positioned.fill(
          child: AppImage(imageUrl: _heroImage, fit: BoxFit.cover),
        ),
        // `bg-gradient-to-r from-dark/90 via-dark/70 to-dark/50`
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.dark.withValues(alpha: 0.9),
                  AppColors.dark.withValues(alpha: 0.7),
                  AppColors.dark.withValues(alpha: 0.5),
                ],
              ),
            ),
          ),
        ),
        Padding(
          // `pt-32` — qat'iy header ostidan; `py-8` mobilda.
          padding: EdgeInsets.fromLTRB(16, 96 + MediaQuery.paddingOf(context).top, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                NewsTexts.title,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontSize: 24, // text-2xl
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8), // mb-2
              Text(
                NewsTexts.heroDesc,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14, // text-sm
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              if (count > 0) ...[
                const SizedBox(height: 24), // mt-6
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF34D399), // bg-emerald-400
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8), // gap-2
                    Text(
                      '$count ${NewsTexts.totalCount}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── holatlar ────────────────────────────────────────────────────────────────

  Widget _stateBox(String label, {bool spinner = false}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 96), // py-24
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          if (spinner) ...[
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                color: AppColors.olive,
                backgroundColor: AppColors.olive.withValues(alpha: 0.2),
              ),
            ),
            const SizedBox(height: 16), // mb-4
          ],
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              color: AppColors.dark.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyBox() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 96, horizontal: 24), // py-24
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Container(
            width: 80, // w-20 h-20
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6), // bg-gray-100
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SiteIcon(
                SiteIcons.newspaper,
                size: 40,
                color: AppColors.dark.withValues(alpha: 0.2),
                strokeWidth: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20), // mb-5
          Text(
            NewsTexts.empty,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 20, // text-xl
              fontWeight: FontWeight.w600,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 8), // mb-2
          Text(
            NewsTexts.emptyDesc,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              color: AppColors.dark.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24), // mb-6
          Pressable(
            scale: 0.98,
            onTap: () => context.go('/'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10), // px-6 py-2.5
              decoration: BoxDecoration(
                color: AppColors.olive,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                NewsTexts.backHome,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
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

  // ── kartalar ────────────────────────────────────────────────────────────────

  List<Widget> _cards(List<NewsItem> news) => [
    _featuredCard(news.first),
    if (news.length > 1) ...[
      const SizedBox(height: 32), // mb-8
      for (final item in news.skip(1)) ...[
        _card(item),
        const SizedBox(height: 20), // gap-5
      ],
    ],
  ];

  String _imageOf(NewsItem item) {
    final url = absoluteMediaUrl(item.image);
    return (url == null || url.isEmpty) ? _fallbackImage : url;
  }

  /// Birinchi yangilik. Mobilda `grid-cols-1` — rasm tepada (`aspect-[16/10]`), matn ostida.
  Widget _featuredCard(NewsItem item) {
    final theme = Theme.of(context);
    return Pressable(
      scale: 0.99,
      onTap: () => context.go('/news/${item.id}'),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: AppImage(imageUrl: _imageOf(item), fit: BoxFit.cover),
                ),
                if (item.dateLabel.isNotEmpty)
                  Positioned(top: 16, left: 16, child: _dateBadge(item.dateLabel, size: 14)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24), // p-6
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // "Tanlangan" nishonchasi
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.olive.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SiteIcon(SiteIcons.sparkle, size: 12, color: AppColors.olive),
                        const SizedBox(width: 6), // gap-1.5
                        Text(
                          NewsTexts.featured,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.olive,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16), // mb-4
                  Text(
                    item.title,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontSize: 20, // text-xl
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    item.description,
                    maxLines: 3, // line-clamp-3
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      height: 1.6,
                      color: AppColors.dark.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 24), // mb-6
                  Row(
                    children: [
                      Text(
                        NewsTexts.readMore,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.olive,
                        ),
                      ),
                      const SizedBox(width: 8), // gap-2
                      const SiteIcon(SiteIcons.arrowRight, size: 16, color: AppColors.olive),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(NewsItem item) {
    final theme = Theme.of(context);
    return Pressable(
      scale: 0.99,
      onTap: () => context.go('/news/${item.id}'),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: AppImage(imageUrl: _imageOf(item), fit: BoxFit.cover),
                ),
                if (item.dateLabel.isNotEmpty)
                  Positioned(top: 12, left: 12, child: _dateBadge(item.dateLabel, size: 12)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20), // p-5
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 15, // text-[15px]
                      fontWeight: FontWeight.w600,
                      height: 1.35, // leading-snug
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 8), // mb-2
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      height: 1.6,
                      color: AppColors.dark.withValues(alpha: 0.45),
                    ),
                  ),
                  const SizedBox(height: 16), // mb-4
                  const Divider(height: 1, color: AppColors.borderLight),
                  const SizedBox(height: 16), // pt-4
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        NewsTexts.readMore,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.olive,
                        ),
                      ),
                      const SiteIcon(SiteIcons.arrowRight, size: 16, color: AppColors.olive),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Rasm ustidagi oq sana tabletkasi.
  Widget _dateBadge(String label, {required double size}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // px-3 py-1.5
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2))],
    ),
    child: Text(
      label,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontSize: size,
        fontWeight: FontWeight.w500,
        color: AppColors.dark,
      ),
    ),
  );
}
