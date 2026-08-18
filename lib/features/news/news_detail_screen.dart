import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/api/media_url.dart';
import '../../core/utils/format.dart';
import '../../shared/widgets/app_image.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/site_footer_section.dart';
import '../../shared/widgets/site_header.dart';
import '../../shared/widgets/site_icon.dart';
import 'news_repository.dart';
import 'news_texts.dart';

/// Saytning `/news/:id` sahifasi — `news-detail.component.ts`.
///
/// Tepada balandligi 300px bo'lgan rasm (pastidan to'q gradient), so'ng orqaga havola, sana,
/// sarlavha va matn; oxirida — agar bog'langan loyiha bo'lsa — o'sha loyiha kartasi.
class NewsDetailScreen extends StatefulWidget {
  const NewsDetailScreen({super.key, required this.id});

  final int id;

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  final _repo = const NewsRepository();
  final _scroll = ScrollController();

  late final Future<NewsDetail?> _future = _load();
  bool _scrolled = false;

  Future<NewsDetail?> _load() async {
    try {
      return await _repo.byId(widget.id);
    } catch (_) {
      // Saytda ham xato "topilmadi" holatiga olib keladi.
      return null;
    }
  }

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
      backgroundColor: AppColors.surfaceAltLight, // main bg-gray-50
      body: Stack(
        children: [
          FutureBuilder<NewsDetail?>(
            future: _future,
            builder: (context, snapshot) {
              final loading = snapshot.connectionState == ConnectionState.waiting;
              final detail = snapshot.data;
              return CustomScrollView(
                controller: _scroll,
                slivers: [
                  if (loading)
                    SliverToBoxAdapter(child: _spinner())
                  else if (detail == null)
                    SliverToBoxAdapter(child: _notFound())
                  else
                    ..._content(detail),
                  const SliverToBoxAdapter(child: SizedBox(height: 48)),
                  const SliverToBoxAdapter(child: SiteFooterSection()),
                ],
              );
            },
          ),
          // Shablonda `[transparent]="false"`.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SiteHeader(scrolled: _scrolled, showSearch: false),
          ),
        ],
      ),
    );
  }

  Widget _spinner() => Padding(
    padding: EdgeInsets.only(top: 128 + MediaQuery.paddingOf(context).top, bottom: 128),
    child: Center(
      child: SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.olive),
      ),
    ),
  );

  Widget _notFound() {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 96 + MediaQuery.paddingOf(context).top, 16, 80),
      child: Column(
        children: [
          Container(
            width: 80, // w-20 h-20
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6), // bg-gray-100
              shape: BoxShape.circle,
            ),
            child: const Center(
              // `w-8 h-8 text-gray-400 stroke-width-1.5`
              child: SiteIcon(
                SiteIcons.alertCircle,
                size: 32,
                color: Color(0xFF9CA3AF),
                strokeWidth: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24), // mb-6
          Text(
            NewsTexts.notFound,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 20, // text-xl
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 8), // mb-2
          Text(
            NewsTexts.notFoundDesc,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              color: AppColors.dark.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24), // mb-6
          GestureDetector(
            onTap: () => context.go('/'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SiteIcon(SiteIcons.arrowLeft, size: 16, color: AppColors.olive),
                const SizedBox(width: 8), // gap-2
                Text(
                  NewsTexts.backHome,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.olive,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _content(NewsDetail detail) {
    final theme = Theme.of(context);
    final item = detail.item;
    final image = absoluteMediaUrl(item.image);
    final hasImage = image != null && image.isNotEmpty;

    return [
      if (hasImage)
        SliverToBoxAdapter(
          child: SizedBox(
            height: 300, // h-[300px]
            child: Stack(
              children: [
                Positioned.fill(
                  child: AppImage(imageUrl: image, fit: BoxFit.cover),
                ),
                // `bg-gradient-to-t from-dark/60 via-transparent to-transparent`
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [AppColors.dark.withValues(alpha: 0.6), Colors.transparent],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      SliverPadding(
        // `container-custom py-10`; rasm bo'lmasa qat'iy header uchun tepadan joy qoldiriladi.
        padding: EdgeInsets.fromLTRB(
          16,
          hasImage ? 40 : 96 + MediaQuery.paddingOf(context).top,
          16,
          0,
        ),
        sliver: SliverList.list(
          children: [
            GestureDetector(
              onTap: () => context.go('/news'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SiteIcon(
                    SiteIcons.arrowLeft,
                    size: 16,
                    color: AppColors.dark.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 8), // gap-2
                  Text(
                    NewsTexts.backToNews,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: AppColors.dark.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24), // mb-6
            if (item.dateLabel.isNotEmpty) ...[
              Text(
                item.dateLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  color: AppColors.dark.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 12), // mb-3
            ],
            Text(
              item.title,
              style: theme.textTheme.displaySmall?.copyWith(
                fontSize: 24, // text-2xl
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
                height: 1.2,
              ),
            ),
            if (item.description.isNotEmpty) ...[
              const SizedBox(height: 24), // mb-6
              Text(
                // `whitespace-pre-line` — matndagi qator uzilishlari saqlanadi.
                item.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 16, // text-base
                  height: 1.7, // leading-relaxed
                  color: AppColors.dark.withValues(alpha: 0.7),
                ),
              ),
            ],
            if (detail.project case final project?) ...[
              const SizedBox(height: 40), // mt-10
              const Divider(height: 1, color: AppColors.borderLight),
              const SizedBox(height: 32), // pt-8
              Text(
                NewsTexts.linkedProject.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1, // tracking-wider
                  color: AppColors.dark.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 16), // mb-4
              _projectCard(project),
            ],
          ],
        ),
      ),
    ];
  }

  /// Bog'langan loyiha kartasi. Mobilda `flex-col` — rasm tepada (160px), ma'lumot ostida.
  Widget _projectCard(NewsProject project) {
    final theme = Theme.of(context);
    final cover = absoluteMediaUrl(project.coverImage);
    final logo = absoluteMediaUrl(project.developerLogo);
    return Pressable.builder(
      onTap: () => context.go('/${project.developerCode}/${project.slug}'),
      builder: (context, pressed) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 160, // h-[160px]
              width: double.infinity,
              child: cover != null && cover.isNotEmpty
                  // `group-hover:scale-105`
                  ? ZoomOnPress(
                      pressed: pressed,
                      child: AppImage(imageUrl: cover, fit: BoxFit.cover),
                    )
                  : ColoredBox(
                      color: const Color(0xFFF3F4F6), // bg-gray-100
                      child: Center(
                        child: SiteIcon(
                          SiteIcons.house,
                          size: 32,
                          color: AppColors.dark.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(20), // p-5
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (logo != null && logo.isNotEmpty) ...[
                        ClipOval(
                          child: SizedBox(
                            width: 24, // w-6 h-6
                            height: 24,
                            child: AppImage(imageUrl: logo, fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(width: 8), // gap-2
                      ],
                      Text(
                        project.developerName,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 12,
                          color: AppColors.dark.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8), // mb-2
                  Text(
                    project.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 18, // text-lg
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                    ),
                  ),
                  if (project.address case final address? when address.isNotEmpty) ...[
                    const SizedBox(height: 4), // mb-1
                    Text(
                      address,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: AppColors.dark.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12), // mb-3
                  Row(
                    children: [
                      if (project.minPrice case final price? when price > 0) ...[
                        Text(
                          "${formatNumber(price)} so'm",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.olive,
                          ),
                        ),
                        const SizedBox(width: 16), // gap-4
                      ],
                      if (project.totalApartments > 0)
                        Text(
                          NewsTexts.apartments(project.totalApartments),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            color: AppColors.dark.withValues(alpha: 0.4),
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
    );
  }
}
