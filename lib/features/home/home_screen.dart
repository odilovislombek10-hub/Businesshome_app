import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/content.dart';
import '../../core/models/developer_summary.dart';
// PromoBanner nomi komponent bilan to'qnashadi — modeli bu sahifada kerak emas.
import '../../core/models/homepage.dart' hide PromoBanner;
import '../../core/models/page_content.dart';
import '../../core/models/project.dart';
import '../../core/models/property_listing.dart';
import '../../core/models/reel.dart';
import '../../core/models/region.dart';
import '../../core/models/specialist.dart';
import '../../shared/widgets/ai_assistant.dart';
import '../../shared/widgets/site_header.dart';
import 'components/featured_buildings.dart';
import 'components/developers_slider.dart';
import 'components/app_download.dart';
import 'components/features_section.dart';
import 'components/hero_section.dart';
import 'components/home_top_picks.dart';
import 'components/news_section.dart';
import 'components/promo_banner.dart';
import 'components/property_price_map.dart';
import 'components/reels_section.dart';
import 'components/site_footer.dart';
import 'components/property_categories.dart';
import 'components/stats_banner.dart';
import '../../core/services/regions_service.dart';
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
      _repo.categories(),
      _repo.stats(),
      _repo.developers(),
      _repo.features(),
      _repo.news(),
      _repo.reels(),
      _repo.topSecondary(),
      _repo.topRent(),
      _repo.topDesigners(),
      _repo.topMasters(),
      RegionsService.instance.regions(),
      _repo.settings(),
      _repo.priceMap(rent: true),
      _repo.priceMap(rent: false),
    ]);
    final categories = results[2] as List<PropertyCategory>;

    // Each category tile shows its cheapest listing; fetch them together once the categories
    // themselves are known, as the site does after its category request resolves.
    final tops = await Future.wait(categories.map(_repo.topListingForCategory));
    final topListings = <int, PropertyListing>{
      // `?` drops the entry for a category whose request found nothing.
      for (var i = 0; i < categories.length; i++) categories[i].id: ?tops[i],
    };

    return _HomeData(
      hero: results[0] as PageContent?,
      featured: results[1] as List<Project>,
      categories: categories,
      topListings: topListings,
      stats: results[3] as PlatformStats?,
      developers: results[4] as List<DeveloperSummary>,
      features: results[5] as List<FeatureItem>,
      news: results[6] as List<NewsItem>,
      reels: results[7] as List<Reel>,
      topSecondary: results[8] as List<PropertyListing>,
      topRent: results[9] as List<PropertyListing>,
      topDesigners: results[10] as List<Specialist>,
      topMasters: results[11] as List<Specialist>,
      regions: results[12] as List<Region>,
      settings: results[13] as Map<String, String>,
      rentPrices: results[14] as Map<String, RegionPrice>,
      buyPrices: results[15] as Map<String, RegionPrice>,
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
          // Aziza floats over everything, `fixed bottom-6 right-6` on the site.
          const AiAssistant(),
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
            // Section order is `home.component.ts` line for line.
            HeroSection(content: data.hero),
            if (data.featured.isNotEmpty) FeaturedBuildings(projects: data.featured),
            if (data.hero?.bannerEnabled ?? false) PromoBanner(content: data.hero!),
            if (data.developers.isNotEmpty) DevelopersSlider(developers: data.developers),
            PropertyPriceMap(rentPrices: data.rentPrices, buyPrices: data.buyPrices),
            if (data.categories.isNotEmpty)
              PropertyCategories(categories: data.categories, topListings: data.topListings),
            HomeTopPicks(
              secondary: data.topSecondary,
              rent: data.topRent,
              designers: data.topDesigners,
              masters: data.topMasters,
            ),
            ReelsSection(reels: data.reels),
            if (data.stats != null) StatsBanner(stats: data.stats!),
            if (data.features.isNotEmpty) FeaturesSection(features: data.features),
            if (data.news.isNotEmpty) NewsSection(news: data.news),
            AppDownload(
              appStoreUrl: data.settings['app_store_url'],
              googlePlayUrl: data.settings['google_play_url'],
            ),
            SiteFooter(regions: data.regions, contactPhone: data.settings['contact_phone']),
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
    required this.categories,
    required this.topListings,
    required this.stats,
    required this.developers,
    required this.features,
    required this.news,
    required this.reels,
    required this.topSecondary,
    required this.topRent,
    required this.topDesigners,
    required this.topMasters,
    required this.regions,
    required this.settings,
    required this.rentPrices,
    required this.buyPrices,
  });

  const _HomeData.empty()
    : hero = null,
      featured = const [],
      categories = const [],
      topListings = const {},
      stats = null,
      developers = const [],
      features = const [],
      news = const [],
      reels = const [],
      topSecondary = const [],
      topRent = const [],
      topDesigners = const [],
      topMasters = const [],
      regions = const [],
      settings = const {},
      rentPrices = const {},
      buyPrices = const {};

  final PageContent? hero;
  final List<Project> featured;
  final List<PropertyCategory> categories;
  final Map<int, PropertyListing> topListings;
  final PlatformStats? stats;
  final List<DeveloperSummary> developers;
  final List<FeatureItem> features;
  final List<NewsItem> news;
  final List<Reel> reels;
  final List<PropertyListing> topSecondary;
  final List<PropertyListing> topRent;
  final List<Specialist> topDesigners;
  final List<Specialist> topMasters;
  final List<Region> regions;

  /// Admin key/value pairs: `contact_phone`, `app_store_url`, `google_play_url`, …
  final Map<String, String> settings;

  /// Region price statistics behind the map's two tabs.
  final Map<String, RegionPrice> rentPrices;
  final Map<String, RegionPrice> buyPrices;
}
