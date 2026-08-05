import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../core/api/media_url.dart';
import '../../core/models/homepage.dart';
import '../../core/models/page_content.dart';
import '../../core/models/project.dart';
import '../../shared/widgets/project_card.dart';
import '../../shared/widgets/site_header.dart';
import 'components/hero_section.dart';
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
  final _scroll = ScrollController();

  late Future<_HomeData> _future;

  /// Drives the header: translucent over the hero, solid once the page moves.
  bool _scrolled = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
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

  Future<_HomeData> _load() async {
    // One round trip per section, all in flight together — the page is as slow as its slowest
    // section rather than the sum of them.
    final results = await Future.wait([
      _repo.heroContent(),
      _repo.featured(),
      _repo.promoBanners(),
      _repo.categories(),
      _repo.stats(),
      _repo.services(),
    ]);
    return _HomeData(
      hero: results[0] as PageContent?,
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
    // The header is `fixed` on the site and floats over the hero, so the content is not inset by
    // it — a Stack, not an AppBar.
    return Scaffold(
      body: Stack(
        children: [
          RefreshIndicator(onRefresh: _refresh, child: _body(context)),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SiteHeader(
              transparent: true,
              scrolled: _scrolled,
              onSearch: (q) => context.go('/secondary?search=$q'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    return FutureBuilder<_HomeData>(
      future: _future,
      builder: (context, snapshot) {
        // No full-page spinner: the hero is static copy and renders straight away, exactly as on
        // the site. Sections below it simply appear once their data lands.
        final data = snapshot.data ?? const _HomeData.empty();
        return ListView(
          controller: _scroll,
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            HeroSection(content: data.hero),
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
    : hero = null,
      featured = const [],
      promos = const [],
      categories = const [],
      stats = null,
      services = const [];

  final PageContent? hero;
  final List<Project> featured;
  final List<PromoBanner> promos;
  final List<PropertyCategory> categories;
  final PlatformStats? stats;
  final List<ServiceCard> services;
}

/// Section wrapper: heading on the left, optional "see all" link on the right.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.actionLabel, this.onAction});

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
              if (actionLabel != null) TextButton(onPressed: onAction, child: Text(actionLabel!)),
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
      // Tall enough for the card's worst case: 16:9 image, two lines of meta and the chip row
      // wrapping onto a second line. A short card just leaves whitespace; too short clips.
      height: 348,
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
                          onPressed: banner.link == null ? null : () => context.go(banner.link!),
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
                Text(label, style: theme.textTheme.labelSmall?.copyWith(color: Colors.white70)),
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

  /// The admin panel stores Font Awesome class names (`fas fa-key`). Map the ones actually in
  /// use to their Material equivalents; anything new falls back to a neutral badge rather than
  /// rendering nothing.
  static IconData _icon(String name) => switch (name.split(' ').last) {
    'fa-home' => Icons.home_outlined,
    'fa-key' => Icons.vpn_key_outlined,
    'fa-building' => Icons.apartment_outlined,
    'fa-palette' => Icons.palette_outlined,
    'fa-tools' => Icons.handyman_outlined,
    'fa-bullhorn' => Icons.campaign_outlined,
    'fa-shield' || 'shield' => Icons.verified_user_outlined,
    _ => Icons.verified_outlined,
  };

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
                  child: Icon(_icon(service.icon), color: AppColors.olive),
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
          Text("O'zbekistondagi yangi binolar va kvartiralar", style: theme.textTheme.bodySmall),
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
