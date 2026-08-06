import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../core/api/media_url.dart';
import '../../core/models/property_listing.dart';
import '../../core/services/currency_service.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/site_header.dart';
import '../../shared/widgets/site_icon.dart';
import 'secondary_repository.dart';

/// `/property/secondary/:id` — the site's `secondary-detail` page.
///
/// Order from the template: breadcrumb, title with address, the badge row, the three action
/// buttons, the photo gallery, the olive gradient price card with its three stat boxes, key
/// facts, description, amenities, and the owner's contact card.
class SecondaryDetailScreen extends StatefulWidget {
  const SecondaryDetailScreen({super.key, required this.id});

  final int id;

  @override
  State<SecondaryDetailScreen> createState() => _SecondaryDetailScreenState();
}

class _SecondaryDetailScreenState extends State<SecondaryDetailScreen> {
  final _repo = SecondaryRepository();
  final _scroll = ScrollController();

  late final Future<PropertyListing?> _future = _repo.byId(widget.id);
  bool _scrolled = false;
  bool _favorite = false;

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
      backgroundColor: AppColors.surfaceAltLight, // bg-gray-50
      body: Stack(
        children: [
          FutureBuilder<PropertyListing?>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final property = snapshot.data;
              if (property == null) return _notFound(context);
              return _body(context, property);
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

  Widget _notFound(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Mulk topilmadi',
              style: theme.textTheme.displaySmall?.copyWith(fontSize: 24, color: AppColors.dark),
            ),
            const SizedBox(height: 8),
            Text(
              "Bu e'lon mavjud emas yoki olib tashlangan",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.dark.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.olive),
              onPressed: () => context.go('/secondary'),
              child: const Text("Ro'yxatga qaytish"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, PropertyListing p) {
    final theme = Theme.of(context);
    return ListView(
      controller: _scroll,
      padding: EdgeInsets.fromLTRB(
        16,
        80 + MediaQuery.paddingOf(context).top, // pt-20 under the fixed header
        16,
        48,
      ),
      children: [
        _breadcrumb(context, p),
        const SizedBox(height: 16), // mb-4

        Text(
          p.title,
          style: theme.textTheme.displaySmall?.copyWith(
            fontSize: 24, // text-2xl
            color: AppColors.dark,
          ),
        ),
        const SizedBox(height: 8), // mb-2
        Row(
          children: [
            SiteIcon(SiteIcons.mapPin, size: 14, color: AppColors.dark.withValues(alpha: 0.6)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                [p.district, p.address].where((s) => s?.isNotEmpty ?? false).join(', '),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.dark.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12), // mt-3
        _badges(context, p),
        const SizedBox(height: 16),
        _actions(context, p),
        const SizedBox(height: 24), // mb-6

        _Gallery(images: p.images),
        const SizedBox(height: 16), // mt-4

        _priceCard(context, p),
        const SizedBox(height: 16),

        _card(context, 'Asosiy ma\'lumot', _keyFacts(context, p)),
        if (p.description?.isNotEmpty ?? false) ...[
          const SizedBox(height: 16),
          _card(
            context,
            'Tavsif',
            Text(
              p.description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.dark.withValues(alpha: 0.7),
                height: 1.6,
              ),
            ),
          ),
        ],
        if (p.amenities.isNotEmpty) ...[
          const SizedBox(height: 16),
          _card(context, 'Qulayliklar', _amenities(context, p)),
        ],
        if (p.owner != null) ...[const SizedBox(height: 16), _contactCard(context, p)],
      ],
    );
  }

  Widget _breadcrumb(BuildContext context, PropertyListing p) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: AppColors.dark.withValues(alpha: 0.5),
    );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Pressable(
            onTap: () => context.go('/'),
            child: Text('Bosh sahifa', style: muted),
          ),
          const SizedBox(width: 8),
          const SiteIcon(SiteIcons.chevronRight, size: 12),
          const SizedBox(width: 8),
          Pressable(
            onTap: () => context.go('/secondary'),
            child: Text('Ikkilamchi', style: muted),
          ),
          const SizedBox(width: 8),
          const SiteIcon(SiteIcons.chevronRight, size: 12),
          const SizedBox(width: 8),
          Text(
            p.title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.dark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Type, 360° tour, balcony and the id — the site's badge row, colours included.
  Widget _badges(BuildContext context, PropertyListing p) {
    final theme = Theme.of(context);
    Widget badge(String label, Color background, Color foreground, {VoidCallback? onTap}) {
      final chip = Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      return onTap == null ? chip : Pressable(scale: 0.97, onTap: onTap, child: chip);
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (p.type case final type?)
          badge(
            _typeLabel(type).toUpperCase(),
            AppColors.olive.withValues(alpha: 0.1),
            AppColors.olive,
          ),
        if (p.hasVirtualTour)
          badge(
            '360° Virtual tur',
            const Color(0xFFEFF6FF), // blue-50
            const Color(0xFF2563EB),
            onTap: () => _open(p.videoUrl),
          ),
        badge('ID: ${p.id}', AppColors.surfaceMutedLight, AppColors.dark.withValues(alpha: 0.6)),
      ],
    );
  }

  /// Favourite, share and report — three 44×44 `rounded-xl` buttons.
  Widget _actions(BuildContext context, PropertyListing p) {
    Widget button(SiteIconData icon, Color color, VoidCallback onTap, {Color? background}) =>
        Pressable(
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: background ?? Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Center(child: SiteIcon(icon, size: 18, color: color)),
          ),
        );

    return Row(
      children: [
        button(
          SiteIcons.heart,
          _favorite ? const Color(0xFFEF4444) : AppColors.dark.withValues(alpha: 0.6),
          () => setState(() => _favorite = !_favorite),
          background: _favorite ? const Color(0xFFFEF2F2) : null,
        ),
        button(
          SiteIcons.arrowRight,
          AppColors.dark.withValues(alpha: 0.6),
          () => _open('https://businesshome.uz/property/secondary/${p.id}'),
        ),
      ],
    );
  }

  /// `from-olive to-olive/80 rounded-2xl` card: the price, then rooms / area / floor boxes.
  Widget _priceCard(BuildContext context, PropertyListing p) {
    final theme = Theme.of(context);
    final currency = CurrencyService.instance;

    Widget stat(String value, String label) => Container(
      constraints: const BoxConstraints(minWidth: 80),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: theme.textTheme.titleMedium?.copyWith(color: Colors.white)),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(16), // p-4
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.olive, AppColors.olive.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Narxi',
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            p.price == null ? '—' : currency.formatWithSymbol(p.price!, from: p.currency ?? 'uzs'),
            style: theme.textTheme.displaySmall?.copyWith(fontSize: 28, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (p.rooms != null) stat('${p.rooms}', 'Xonalar'),
              if (p.area != null) stat('${p.area!.round()} m²', 'Maydon'),
              if (p.floor != null)
                stat('${p.floor}${p.totalFloors == null ? '' : '/${p.totalFloors}'}', 'Qavat'),
            ],
          ),
        ],
      ),
    );
  }

  /// `bg-white rounded-2xl border p-6` block with a bold heading.
  Widget _card(BuildContext context, String title, Widget child) {
    final theme = Theme.of(context);
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
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 16), // mb-4
          child,
        ],
      ),
    );
  }

  Widget _keyFacts(BuildContext context, PropertyListing p) {
    final theme = Theme.of(context);
    final facts = <(String, String)>[
      if (p.type case final type?) ('Turi', _typeLabel(type)),
      if (p.rooms != null) ('Xonalar', '${p.rooms}'),
      if (p.bathrooms != null) ('Sanuzellar', '${p.bathrooms}'),
      if (p.area != null) ('Maydon', '${p.area!.round()} m²'),
      if (p.floor != null)
        ('Qavat', '${p.floor}${p.totalFloors == null ? '' : '/${p.totalFloors}'}'),
      if (p.status case final status?) ('Holat', _statusLabel(status)),
    ];

    return Column(
      children: [
        for (final (label, value) in facts)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    label.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 12,
                      color: AppColors.dark.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.dark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _amenities(BuildContext context, PropertyListing p) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final amenity in p.amenities)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceAltLight,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SiteIcon(SiteIcons.check, size: 12, color: AppColors.olive),
                const SizedBox(width: 6),
                Text(amenity, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
      ],
    );
  }

  Widget _contactCard(BuildContext context, PropertyListing p) {
    final theme = Theme.of(context);
    final owner = p.owner!;
    final avatar = absoluteMediaUrl(owner.avatar);
    return _card(
      context,
      "Bog'lanish",
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.olive.withValues(alpha: 0.1),
                backgroundImage: avatar == null ? null : CachedNetworkImageProvider(avatar),
                child: avatar != null
                    ? null
                    : const SiteIcon(SiteIcons.user, size: 20, color: AppColors.olive),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      owner.name?.isNotEmpty == true ? owner.name! : 'Egasi',
                      style: theme.textTheme.titleMedium?.copyWith(color: AppColors.dark),
                    ),
                    if (owner.type case final type?)
                      Text(
                        type == 'agent' ? 'Reltor' : 'Uy egasi',
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (owner.phone?.isNotEmpty ?? false) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.olive),
                onPressed: () => _open('tel:${owner.phone}'),
                child: Text(owner.phone!),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _typeLabel(String type) => switch (type) {
    'apartment' => 'Kvartira',
    'house' => 'Hovli uy',
    'office' => 'Ofis',
    'shop' => "Do'kon",
    'building' => 'Bino',
    'land' => 'Yer',
    _ => type,
  };

  static String _statusLabel(String status) => switch (status) {
    'available' => 'Mavjud',
    'reserved' => 'Band qilingan',
    'sold' => 'Sotilgan',
    _ => status,
  };

  static Future<void> _open(String? url) async {
    final uri = Uri.tryParse(url ?? '');
    if (uri != null && uri.hasScheme) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// The site's `app-property-gallery`: a swipeable 4:3 strip with a counter.
class _Gallery extends StatefulWidget {
  const _Gallery({required this.images});

  final List<String> images;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final images = [for (final image in widget.images) ?absoluteMediaUrl(image)];
    if (images.isEmpty) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: images.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => CachedNetworkImage(
                imageUrl: images[i],
                fit: BoxFit.cover,
                placeholder: (_, _) => const ColoredBox(color: AppColors.surfaceMutedLight),
                errorWidget: (_, _, _) => const ColoredBox(color: AppColors.surfaceMutedLight),
              ),
            ),
            if (images.length > 1)
              Positioned(
                right: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.dark.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '${_index + 1}/${images.length}',
                    style: theme.textTheme.labelSmall?.copyWith(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
