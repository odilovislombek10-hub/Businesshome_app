import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../core/api/media_url.dart';
import '../../core/models/homepage.dart';
import '../../core/models/project.dart';
import '../../shared/widgets/project_card.dart';
import 'home_repository.dart';

/// The front page, section for section in the order `home.component.ts` renders them:
/// hero → featured buildings → promo banner → developers → price map → categories → top picks →
/// reels → stats → features → news → app download → footer.
///
/// Sections load independently (see [HomeRepository]) and a section with no data renders nothing,
/// exactly as on the site — so a quiet endpoint leaves a shorter page rather than an error.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repo = HomeRepository();

  late Future<_HomeData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_HomeData> _load() async {
    // One round trip per section, all in flight together — the page is as slow as its slowest
    // section rather than the sum of them.
    final results = await Future.wait([
      _repo.heroSlides(),
      _repo.featured(),
      _repo.promoBanners(),
      _repo.categories(),
      _repo.stats(),
      _repo.services(),
    ]);
    return _HomeData(
      hero: results[0] as List<HeroSlide>,
      featured: results[1] as List<Project>,
      promos: results[2] as List<PromoBanner>,
      categories: results[3] as List<PropertyCategory>,
      stats: results[4] as PlatformStats?,
      services: results[5] as List<ServiceCard>,
    );
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() => _future = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BusinessHome'),
        actions: [
          IconButton(
            onPressed: () => context.go('/map'),
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Xaritada qidirish',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<_HomeData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data ?? const _HomeData.empty();
            return ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                if (data.hero.isNotEmpty) _HeroCarousel(slides: data.hero),
                if (data.featured.isNotEmpty)
                  _Section(
                    title: 'Tanlangan binolar',
                    actionLabel: 'Barchasi',
                    onAction: () => context.go('/new-projects'),
                    child: _HorizontalProjects(projects: data.featured),
                  ),
                for (final promo in data.promos) _PromoCard(banner: promo),
                if (data.categories.isNotEmpty)
                  _Section(
                    title: 'Kategoriyalar',
                    child: _CategoryGrid(categories: data.categories),
                  ),
                if (data.stats != null) _StatsBanner(stats: data.stats!),
                if (data.services.isNotEmpty)
                  _Section(
                    title: 'Nega BusinessHome?',
                    child: _ServicesList(services: data.services),
                  ),
                const _Footer(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HomeData {
  const _HomeData({
    required this.hero,
    required this.featured,
    required this.promos,
    required this.categories,
    required this.stats,
    required this.services,
  });

  const _HomeData.empty()
      : hero = const [],
        featured = const [],
        promos = const [],
        categories = const [],
        stats = null,
        services = const [];

  final List<HeroSlide> hero;
  final List<Project> featured;
  final List<PromoBanner> promos;
  final List<PropertyCategory> categories;
  final PlatformStats? stats;
  final List<ServiceCard> services;
}

/// Auto-advancing hero slider — the site's `hero-section`.
class _HeroCarousel extends StatefulWidget {
  const _HeroCarousel({required this.slides});
  final List<HeroSlide> slides;

  @override
  State<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<_HeroCarousel> {
  final _controller = PageController();
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    if (widget.slides.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!mounted || !_controller.hasClients) return;
        _controller.animateToPage(
          (_index + 1) % widget.slides.length,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.slides.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final slide = widget.slides[i];
              final url = absoluteMediaUrl(slide.image);
              return GestureDetector(
                onTap: slide.link == null ? null : () => context.go(slide.link!),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (url != null)
                      CachedNetworkImage(imageUrl: url, fit: BoxFit.cover)
                    else
                      Container(color: AppColors.olive),
                    if (slide.title != null)
                      // Scrim so the caption stays readable over any photo.
                      DecoratedBox(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.center,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black54],
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              slide.title!,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          if (widget.slides.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < widget.slides.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _index ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _index ? Colors.white : Colors.white54,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
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

/// Section wrapper: heading on the left, optional "see all" link on the right.
class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 8, 12),
          child: Row(
            children: [
              Expanded(child: Text(title, style: theme.textTheme.displaySmall)),
              if (actionLabel != null)
                TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ),
        ),
        child,
      ],
    );
  }
}

class _HorizontalProjects extends StatelessWidget {
  const _HorizontalProjects({required this.projects});
  final List<Project> projects;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: projects.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) => ProjectCard(
          project: projects[i],
          width: 260,
          onTap: () => context.go('/property/${projects[i].id}'),
        ),
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.banner});
  final PromoBanner banner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = absoluteMediaUrl(banner.bestImage);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Card(
        child: InkWell(
          onTap: banner.link == null ? null : () => context.go(banner.link!),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (url != null)
                AspectRatio(
                  aspectRatio: 2,
                  child: CachedNetworkImage(imageUrl: url, fit: BoxFit.cover),
                ),
              if (banner.title != null || banner.description != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (banner.title != null)
                        Text(banner.title!, style: theme.textTheme.titleMedium),
                      if (banner.description != null) ...[
                        const SizedBox(height: 6),
                        Text(banner.description!, style: theme.textTheme.bodySmall),
                      ],
                      if (banner.buttonText != null) ...[
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed:
                              banner.link == null ? null : () => context.go(banner.link!),
                          child: Text(banner.buttonText!),
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

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.categories});
  final List<PropertyCategory> categories;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: categories.length,
      itemBuilder: (context, i) {
        final category = categories[i];
        final url = absoluteMediaUrl(category.image);
        return InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: () => context.go(category.link),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (url != null)
                  CachedNetworkImage(imageUrl: url, fit: BoxFit.cover)
                else
                  Container(color: theme.colorScheme.surfaceContainerHighest),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black54],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      category.name,
                      style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatsBanner extends StatelessWidget {
  const _StatsBanner({required this.stats});
  final PlatformStats stats;

  static final _n = NumberFormat.decimalPattern('uz');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = <(String, int)>[
      ('Loyihalar', stats.totalProjects),
      ('Mulklar', stats.totalProperties),
      ('Quruvchilar', stats.totalDevelopers),
      ('Shaharlar', stats.citiesCount),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.olive,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (final (label, value) in items)
            Column(
              children: [
                Text(
                  _n.format(value),
                  style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(color: Colors.white70),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ServicesList extends StatelessWidget {
  const _ServicesList({required this.services});
  final List<ServiceCard> services;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (final service in services)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: AppColors.olive.withValues(alpha: 0.15),
                  child: const Icon(Icons.verified_outlined, color: AppColors.olive),
                ),
                title: Text(service.title, style: theme.textTheme.titleMedium),
                subtitle: Text(service.description, style: theme.textTheme.bodySmall),
                onTap: service.link == null ? null : () => context.go(service.link!),
              ),
            ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 16),
          Text('BusinessHome', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            "O'zbekistondagi yangi binolar va kvartiralar",
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            children: [
              TextButton(onPressed: () => context.go('/privacy'), child: const Text('Maxfiylik')),
              TextButton(onPressed: () => context.go('/terms'), child: const Text('Shartlar')),
              TextButton(onPressed: () => context.go('/news'), child: const Text('Yangiliklar')),
            ],
          ),
        ],
      ),
    );
  }
}
