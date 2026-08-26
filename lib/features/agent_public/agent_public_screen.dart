import '../../core/i18n/translate.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../core/api/api_client.dart';
import '../../core/api/media_url.dart';
import '../../core/constants/city_labels.dart';
import '../../core/utils/format.dart';
import '../../shared/widgets/app_image.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/site_footer_section.dart';
import '../../shared/widgets/site_header.dart';

/// Saytning `/agent/:id` sahifasi — `agent-public.component.ts`.
///
/// Prodda `market_agent_profiles` jadvali hozircha bo'sh, shuning uchun sahifani haqiqiy
/// ma'lumot bilan ko'rib bo'lmadi — agent kabinetdan profil to'ldirgach ishlaydi.
/// Endpoint javobi `snake_case` (dizayner/ustanikidan farqli).
class AgentPublicScreen extends StatefulWidget {
  const AgentPublicScreen({super.key, required this.id});

  final int id;

  @override
  State<AgentPublicScreen> createState() => _AgentPublicScreenState();
}

class _AgentPublicScreenState extends State<AgentPublicScreen> {
  final _scroll = ScrollController();
  late final Future<AgentPublic?> _future = _load();
  bool _scrolled = false;

  Future<AgentPublic?> _load() async {
    try {
      final res = await ApiClient.instance.get<dynamic>('/market/agent/${widget.id}');
      final data = res.data;
      if (res.statusCode != 200 || data is! Map<String, dynamic>) return null;
      return AgentPublic.fromJson(data);
    } catch (_) {
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
      backgroundColor: AppColors.surfaceAltLight,
      body: Stack(
        children: [
          FutureBuilder<AgentPublic?>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.olive));
              }
              final agent = snapshot.data;
              if (agent == null) return _notFound();
              return _body(agent);
            },
          ),
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

  Widget _notFound() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Agent topilmadi',
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 18, // text-lg
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.olive),
              onPressed: () => context.go('/'),
              child: Text(t('cabinet.tab.dashboard')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(AgentPublic a) => ListView(
    controller: _scroll,
    padding: EdgeInsets.fromLTRB(0, 96 + MediaQuery.paddingOf(context).top, 0, 0),
    children: [
      _header(a),
      const SizedBox(height: 20),
      if (a.bio case final bio?) ...[
        _section(
          'Haqida',
          Text(
            bio,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              height: 1.6,
              color: AppColors.dark.withValues(alpha: 0.7),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
      if (a.specialization.isNotEmpty) ...[
        _section(t('designers.specialization'), _chips(a.specialization.map(_specLabel).toList())),
        const SizedBox(height: 16),
      ],
      if (a.regions.isNotEmpty) ...[
        _section('Ishlaydigan hududlar', _chips(a.regions.map(CityLabels.label).toList())),
        const SizedBox(height: 16),
      ],
      if (a.sampleListings.isNotEmpty) ...[
        _section(
          "Agentning e'lonlari (${a.listingsTotal})",
          Column(
            children: [
              for (final listing in a.sampleListings) ...[
                _listingCard(listing),
                const SizedBox(height: 12), // gap-3
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
      _contact(a),
      const SizedBox(height: 48),
      const SiteFooterSection(),
    ],
  );

  /// Muqova rasmi, ustiga chiqib turgan avatar va ism/statistika.
  Widget _header(AgentPublic a) {
    final theme = Theme.of(context);
    final cover = absoluteMediaUrl(a.coverImage);
    final avatar = absoluteMediaUrl(a.avatar);
    final initials = a.displayName
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 120,
            width: double.infinity,
            child: cover != null && cover.isNotEmpty
                ? AppImage(imageUrl: cover, fit: BoxFit.cover)
                : DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.olive, AppColors.bronze]),
                    ),
                  ),
          ),
          Transform.translate(
            offset: const Offset(0, -28), // -mt-14
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0), // px-5
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: avatar != null && avatar.isNotEmpty
                          ? AppImage(imageUrl: avatar, fit: BoxFit.cover)
                          : ColoredBox(
                              color: AppColors.olive.withValues(alpha: 0.15),
                              child: Center(
                                child: Text(
                                  initials,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.olive,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    a.displayName,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontSize: 22,
                      color: AppColors.dark,
                    ),
                  ),
                  if (a.agencyName case final agency?) ...[
                    const SizedBox(height: 2),
                    Text(
                      agency,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: AppColors.dark.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.olive.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          t('cabinet.role.agent'),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.olive,
                          ),
                        ),
                      ),
                      if (a.rating > 0)
                        Text(
                          '⭐ ${a.rating.toStringAsFixed(1)} (${a.reviewsCount})',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 13,
                            color: AppColors.dark.withValues(alpha: 0.7),
                          ),
                        ),
                      if (a.experienceYears > 0)
                        Text(
                          '${a.experienceYears} ${t('designerDetail.years')}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 13,
                            color: AppColors.dark.withValues(alpha: 0.6),
                          ),
                        ),
                      Text(
                        "${a.listingsTotal} aktiv e'lon",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          color: AppColors.dark.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20), // pb-5
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, Widget child) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14, // text-sm
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 12), // mb-3
            child,
          ],
        ),
      ),
    );
  }

  Widget _chips(List<String> items) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceMutedLight,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              item,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.dark.withValues(alpha: 0.7),
              ),
            ),
          ),
      ],
    );
  }

  Widget _listingCard(AgentListing listing) {
    final theme = Theme.of(context);
    final image = absoluteMediaUrl(listing.coverImage);
    return Pressable(
      scale: 0.99,
      onTap: () => context.go('/property/${listing.kind}/${listing.id}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: SizedBox(
              width: 80,
              height: 64,
              child: image != null && image.isNotEmpty
                  ? AppImage(imageUrl: image, fit: BoxFit.cover)
                  : const ColoredBox(color: AppColors.surfaceMutedLight),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    CityLabels.label(listing.city),
                    if (listing.rooms > 0) '${listing.rooms} ${t('propertyCard.rooms')}',
                    if (listing.area > 0) '${formatNumber(listing.area)} m²',
                  ].join(' · '),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10, // text-[10px]
                    color: AppColors.dark.withValues(alpha: 0.5),
                  ),
                ),
                if (listing.price case final price? when price > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    listing.currency == 'usd'
                        ? '\$${formatNumber(price)}'
                        : "${formatNumber(price)} ${t('hero.currency')}",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.olive,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contact(AgentPublic a) {
    final theme = Theme.of(context);
    Widget link(String label, VoidCallback onTap) => Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Pressable(
        scale: 0.98,
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.dark.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );

    return _section(
      t('stats.contact'),
      Column(
        children: [
          Pressable(
            scale: 0.98,
            // Saytda bu chat ochadi; ilovada suhbat sahifasi tayyor bo'lgach shu yerga ulanadi.
            onTap: () => context.go('/cabinet/messages'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.olive,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                t('chat.write'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          if (a.phone case final phone? when phone.isNotEmpty)
            link('📞 $phone', () => launchUrl(Uri.parse('tel:$phone'))),
          if (a.telegram case final telegram? when telegram.isNotEmpty)
            link('💬 Telegram: $telegram', () {
              final handle = telegram.replaceAll('@', '');
              launchUrl(Uri.parse('https://t.me/$handle'), mode: LaunchMode.externalApplication);
            }),
          if (a.instagram case final instagram? when instagram.isNotEmpty)
            link('📷 Instagram: $instagram', () {
              final handle = instagram.replaceAll('@', '');
              launchUrl(
                Uri.parse('https://instagram.com/$handle'),
                mode: LaunchMode.externalApplication,
              );
            }),
          // Saytda bog'lanish blokining pastida uchta raqam turadi.
          const SizedBox(height: 16), // mt-4 pt-4
          Container(
            padding: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.surfaceMutedLight)),
            ),
            child: Column(
              children: [
                _statRow(theme, "E'lonlar:", '${a.listingsTotal}'),
                const SizedBox(height: 8), // space-y-2
                _statRow(theme, 'Sotilgan:', '${a.dealsClosed}'),
                const SizedBox(height: 8),
                _statRow(theme, "Ko'rishlar:", '${a.viewsCount}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(ThemeData theme, String label, String value) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: 12,
          color: AppColors.dark.withValues(alpha: 0.5),
        ),
      ),
      Text(
        value,
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.dark,
        ),
      ),
    ],
  );

  /// Saytdagi `specLabel`.
  static String _specLabel(String code) => switch (code) {
    'sale' => t('map.search.sell'),
    'rent' => t('header.nav.rent'),
    'commercial' => 'Tijoriy',
    _ => code,
  };
}

/// `/market/agent/{id}` javobi — bu endpoint `snake_case` qaytaradi.
class AgentPublic {
  const AgentPublic({
    required this.id,
    required this.displayName,
    this.agencyName,
    this.bio,
    this.avatar,
    this.coverImage,
    this.experienceYears = 0,
    this.specialization = const [],
    this.regions = const [],
    this.phone,
    this.telegram,
    this.instagram,
    this.rating = 0,
    this.reviewsCount = 0,
    this.listingsTotal = 0,
    this.dealsClosed = 0,
    this.viewsCount = 0,
    this.sampleListings = const [],
  });

  final int id;
  final String displayName;
  final String? agencyName;
  final String? bio;
  final String? avatar;
  final String? coverImage;
  final int experienceYears;
  final List<String> specialization;
  final List<String> regions;
  final String? phone;
  final String? telegram;
  final String? instagram;
  final double rating;
  final int reviewsCount;
  final int listingsTotal;
  final int dealsClosed;
  final int viewsCount;
  final List<AgentListing> sampleListings;

  static String? _text(Object? value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  static List<String> _strings(Object? raw) => [
    for (final item in (raw as List? ?? const [])) ?_text(item),
  ];

  factory AgentPublic.fromJson(Map<String, dynamic> json) => AgentPublic(
    id: (json['id'] as num?)?.toInt() ?? 0,
    displayName: _text(json['display_name']) ?? '',
    agencyName: _text(json['agency_name']),
    bio: _text(json['bio']),
    avatar: _text(json['avatar']),
    coverImage: _text(json['cover_image']),
    experienceYears: (json['experience_years'] as num?)?.toInt() ?? 0,
    specialization: _strings(json['specialization']),
    regions: _strings(json['regions']),
    phone: _text(json['phone']),
    telegram: _text(json['telegram']),
    instagram: _text(json['instagram']),
    rating: (json['rating'] as num?)?.toDouble() ?? 0,
    reviewsCount: (json['reviews_count'] as num?)?.toInt() ?? 0,
    dealsClosed: (json['deals_closed'] as num?)?.toInt() ?? 0,
    viewsCount: (json['views_count'] as num?)?.toInt() ?? 0,
    listingsTotal: (json['listings_total'] as num?)?.toInt() ?? 0,
    sampleListings: [
      for (final row in (json['sample_listings'] as List? ?? const []))
        if (row is Map) AgentListing.fromJson(row),
    ],
  );
}

class AgentListing {
  const AgentListing({
    required this.id,
    required this.kind,
    required this.title,
    this.price,
    this.currency = 'uzs',
    this.rooms = 0,
    this.area = 0,
    this.city,
    this.coverImage,
  });

  final int id;

  /// `secondary` yoki `rent`.
  final String kind;
  final String title;
  final num? price;
  final String currency;
  final int rooms;
  final num area;
  final String? city;
  final String? coverImage;

  factory AgentListing.fromJson(Map row) => AgentListing(
    id: (row['id'] as num?)?.toInt() ?? 0,
    kind: row['kind']?.toString() ?? 'secondary',
    title: row['title']?.toString() ?? '',
    price: row['price'] is num ? row['price'] as num : null,
    currency: row['currency']?.toString() ?? 'uzs',
    rooms: (row['rooms'] as num?)?.toInt() ?? 0,
    area: row['area'] is num ? row['area'] as num : 0,
    city: row['city']?.toString(),
    coverImage: row['cover_image']?.toString(),
  );
}
