import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/api/media_url.dart';
import '../../../core/models/page_content.dart';

/// The site's `hero-section`: a full-viewport background with the eight "superapp" sector tiles
/// laid over it, and the platform stats underneath.
///
/// Mirrors `hero-section.component.html`: `min-h-screen`, a `from-dark/80 via-dark/70 to-dark/90`
/// scrim over the photo, `pt-32` so the fixed header clears the title, a two-column square grid
/// on phones (`grid-cols-2`), and the stats row at `mt-12`.
class HeroSection extends StatefulWidget {
  const HeroSection({super.key, this.content});

  final PageContent? content;

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection> {
  Timer? _timer;
  int _bgIndex = 0;

  /// The twelve stock photos the site cycles through when the admin has set no background.
  static const _backgrounds = [
    'https://images.unsplash.com/photo-1613490493576-7fde63acd811?w=1920&q=85',
    'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=1920&q=85',
    'https://images.unsplash.com/photo-1582407947304-fd86f028f716?w=1920&q=85',
    'https://images.unsplash.com/photo-1613977257363-707ba9348227?w=1920&q=85',
    'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=1920&q=85',
    'https://images.unsplash.com/photo-1600047509807-ba8f99d2cdde?w=1920&q=85',
    'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?w=1920&q=85',
  ];

  /// `sectors` from `hero-section.component.ts`, with the Uzbek strings from `i18n/uz.ts` and the
  /// two gradient stops each tile falls back to before its image loads.
  static const _sectors = <_Sector>[
    _Sector(
      'Novostroykalar',
      'Yangi qurilish loyihalari',
      '/new-projects',
      'new-projects',
      Color(0xFF999966),
      Color(0xFF7A7A52),
    ),
    _Sector(
      'Ikkilamchi bozor',
      'Tayyor uy va kvartiralar',
      '/secondary',
      'secondary',
      Color(0xFF0E9F6E),
      Color(0xFF057A55),
    ),
    _Sector(
      'Ijara',
      "Uy, ofis va do'konlar ijarasi",
      '/rent',
      'rent',
      Color(0xFF0EA5E9),
      Color(0xFF0369A1),
    ),
    _Sector(
      'Xarita',
      'Mulklarni xaritada toping',
      '/map',
      'map',
      Color(0xFFF472A6),
      Color(0xFFDB2777),
    ),
    _Sector(
      'Dizaynerlar',
      'Interyer dizayni ustalari',
      '/designers',
      'designers',
      Color(0xFF8B5CF6),
      Color(0xFF6D28D9),
    ),
    _Sector(
      'Ustalar',
      "Ta'mir va qurilish ustalari",
      '/masters',
      'masters',
      Color(0xFFF59E0B),
      Color(0xFFD97706),
    ),
    _Sector(
      'Birja',
      "Buyurtmalar va ish e'lonlari",
      '/birja',
      'birja',
      Color(0xFF475569),
      Color(0xFF1E293B),
    ),
    _Sector(
      'Jurnal',
      'Yangiliklar va tahlillar',
      '/news',
      'news',
      Color(0xFF06B6D4),
      Color(0xFF0E7490),
    ),
  ];

  @override
  void initState() {
    super.initState();
    // The site cross-fades every few seconds with a 2s transition.
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (mounted) setState(() => _bgIndex = (_bgIndex + 1) % _backgrounds.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = widget.content;
    final custom = absoluteMediaUrl(content?.heroBgUrl);
    final background = custom ?? _backgrounds[_bgIndex];

    final stats = content?.stats.isNotEmpty == true
        ? content!.stats
        : const [
            PageStat(value: '150+', label: 'Yangi loyihalar'),
            PageStat(value: '50+', label: 'Quruvchilar'),
            PageStat(value: '10K+', label: 'Baxtli oilalar'),
          ];

    return ConstrainedBox(
      // `min-h-screen` — the hero fills the viewport, and the header floats over its top.
      constraints: BoxConstraints(minHeight: MediaQuery.sizeOf(context).height),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 2000),
              child: CachedNetworkImage(
                key: ValueKey(background),
                imageUrl: background,
                fit: BoxFit.cover,
                // AnimatedSwitcher lays its child out at the child's own size, so without these
                // the photo is drawn at its intrinsic size and centred instead of covering.
                width: double.infinity,
                height: double.infinity,
                placeholder: (_, _) => const ColoredBox(color: AppColors.dark),
                errorWidget: (_, _, _) => const ColoredBox(color: AppColors.dark),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.dark.withValues(alpha: 0.80),
                    AppColors.dark.withValues(alpha: 0.70),
                    AppColors.dark.withValues(alpha: 0.90),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            // `pt-32 pb-16 px-4`. The site's 128px clears a header that starts at y=0; on a phone
            // the status bar sits above it, so add that inset or the title lands under the bar.
            padding: EdgeInsets.fromLTRB(16, 128 + MediaQuery.paddingOf(context).top, 16, 64),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  content?.heroTitle ?? 'Orzuingizdagi uyingizda yashang',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displayLarge?.copyWith(
                    color: AppColors.cream,
                    fontSize: 36, // text-4xl
                  ),
                ),
                const SizedBox(height: 32),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [for (final sector in _sectors) _SectorTile(sector: sector)],
                ),
                const SizedBox(height: 48),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 32,
                  runSpacing: 16,
                  children: [
                    for (final stat in stats)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            stat.value,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: AppColors.cream,
                              fontSize: 30, // text-3xl
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            stat.label,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.cream.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Sector {
  const _Sector(this.title, this.description, this.href, this.image, this.from, this.to);

  final String title;
  final String description;
  final String href;

  /// Basename under `assets/images/sectors/`, copied from the site's `/images/sectors/`.
  final String image;
  final Color from;
  final Color to;
}

class _SectorTile extends StatelessWidget {
  const _SectorTile({required this.sector});

  final _Sector sector;

  /// `drop-shadow-sm` — what keeps the caption legible where a tile's photo is bright.
  static const _textShadow = [Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1))];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // A plain Container, not `Ink`: `Ink` paints its decoration onto the nearest Material
    // ancestor, which here sits *behind* the hero photo — the gradient would never be seen.
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl), // rounded-3xl
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [sector.from, sector.to],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/sectors/${sector.image}.png',
            fit: BoxFit.cover,
            // The site hides a missing tile image and leaves the gradient showing.
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black54, Colors.black12, Colors.black26],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Align(
              alignment: Alignment.topLeft,
              child: FractionallySizedBox(
                widthFactor: 0.78, // max-w-[78%]
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sector.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                        shadows: _textShadow,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sector.description,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.3,
                        shadows: _textShadow,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Ripple on top of the artwork, transparent so the tile stays visible.
          Material(
            color: Colors.transparent,
            child: InkWell(onTap: () => context.go(sector.href)),
          ),
        ],
      ),
    );
  }
}
