import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../app/theme.dart';
import '../../core/api/api_client.dart';
import '../../core/api/media_url.dart';
import '../../core/services/auth_service.dart';
import '../../shared/widgets/ai_assistant.dart';
import '../../shared/widgets/app_image.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/presentation_mode.dart';
import '../../shared/widgets/site_footer_section.dart';
import '../../shared/utils/breakpoints.dart';
import '../../shared/widgets/site_icon.dart';
import 'project_detail_models.dart';
import 'project_detail_repository.dart';
import 'project_detail_texts.dart';

/// Saytning `/property/:id` va `/:dev/:project` sahifasi — `property-detail.component.ts`.
///
/// Ikkala yo'l bitta komponentga olib boradi, shuning uchun bu yerda ham bitta ekran.
/// Sahifa bo'limlardan yig'iladi va **har biri ma'lumot bo'lsagina chiziladi** — saytda ham
/// hammasi `@if (…length > 0)` bilan o'ralgan. Prodda hozircha bironta loyihada
/// `architecture`, `highlights`, `gallery_sections`, `smart_home`, `documents` to'ldirilmagan.
class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({
    super.key,
    this.id,
    this.developerCode,
    this.projectCode,
    this.presenting = false,
  });

  final int? id;
  final String? developerCode;
  final String? projectCode;

  /// `?present=1` — sahifa sekin o'zi suriladi, oxirida 3D ochiladi.
  final bool presenting;

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  static const _repo = ProjectDetailRepository();

  late final Future<ProjectDetail?> _future = _load();

  /// Saytda bu `FavoritesService` orqali serverda saqlanadi; ilovada hozircha faqat
  /// shu ekran ichida turadi.
  bool _favorite = false;

  final _scroll = ScrollController();
  final _viewer3dKey = GlobalKey<_Viewer3dSectionState>();
  late bool _presenting = widget.presenting;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<ProjectDetail?> _load() {
    final dev = widget.developerCode;
    final code = widget.projectCode;
    if (dev != null && code != null) return _repo.byCode(dev, code);
    return widget.id == null ? Future.value(null) : _repo.byId(widget.id!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: FutureBuilder<ProjectDetail?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.olive));
          }
          final project = snapshot.data;
          if (project == null) return _notFound();
          return Stack(
            children: [
              Positioned.fill(child: _body(project)),
              Positioned(top: 0, left: 0, right: 0, child: _header(project)),
              if (_presenting)
                PresentationMode(
                  scroll: _scroll,
                  onReveal: () => _viewer3dKey.currentState?.open(),
                  onExit: () => setState(() => _presenting = false),
                ),
            ],
          );
        },
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
              ProjectDetailTexts.notFound,
              style: theme.textTheme.displaySmall?.copyWith(fontSize: 24, color: AppColors.dark),
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.olive),
              onPressed: () => context.go('/'),
              child: const Text(ProjectDetailTexts.backHome),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(ProjectDetail project) {
    final settings = project.settings;
    return ListView(
      controller: _scroll,
      padding: EdgeInsets.zero,
      children: [
        _hero(project),
        if (settings.features.isNotEmpty) _features(project),
        if (settings.architectureTabs.isNotEmpty)
          _ArchitectureShowcase(architect: settings.architect, tabs: settings.architectureTabs),
        _Viewer3dSection(
          key: _viewer3dKey,
          url: _viewerUrl(project),
          poster: absoluteMediaUrl(settings.heroPosterUrl ?? project.coverImage),
        ),
        if (settings.highlightCategories.isNotEmpty)
          _Highlights(categories: settings.highlightCategories),
        if (settings.gallerySections.isNotEmpty)
          _ArchitectureGallery(sections: settings.gallerySections),
        if (settings.smartHomeTabs.isNotEmpty) _SmartHome(tabs: settings.smartHomeTabs),
        if (settings.documentCategories.isNotEmpty)
          _ProjectDocuments(categories: settings.documentCategories),
        const SiteFooterSection(),
      ],
    );
  }

  /// Saytdagi `<iframe src="https://3d.businesshome.uz/{dev}/{proj}/?autostart=1">`.
  /// Kod yoki slug bo'lmasa sayt `test/test` ga tushadi.
  String _viewerUrl(ProjectDetail project) {
    final dev = project.developerCode.trim();
    final code = project.slug.trim();
    final path = dev.isNotEmpty && code.isNotEmpty ? '$dev/$code' : 'test/test';
    return 'https://3d.businesshome.uz/$path/?autostart=1';
  }

  // ── yuqoridagi panel ───────────────────────────────────────────────────────

  /// `fixed top-0 … h-14 bg-cream/80 border-b border-dark/5`.
  Widget _header(ProjectDetail project) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.8),
        border: Border(bottom: BorderSide(color: AppColors.dark.withValues(alpha: 0.05))),
      ),
      child: SizedBox(
        height: 56, // h-14
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Pressable(
                onTap: () => context.go('/'),
                child: Row(
                  children: [
                    const SiteIcon(SiteIcons.arrowLeft, size: 20, color: AppColors.dark),
                    // `hidden sm:inline` — matn faqat kengroq ekranda.
                    if (Bp.isSm(context)) ...[
                      const SizedBox(width: 8),
                      Text(
                        ProjectDetailTexts.back,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.dark,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    project.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontSize: 18, // text-lg
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                    ),
                  ),
                ),
              ),
              _headerButton(
                SiteIcons.heart,
                filled: _favorite,
                onTap: () => setState(() => _favorite = !_favorite),
              ),
              const SizedBox(width: 8),
              _headerButton(SiteIcons.share, onTap: () {}),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerButton(SiteIconData icon, {required VoidCallback onTap, bool filled = false}) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: filled ? AppColors.olive : AppColors.dark.withValues(alpha: 0.05),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: SiteIcon(icon, size: 20, color: filled ? AppColors.cream : AppColors.dark),
        ),
      ),
    );
  }

  // ── hero ───────────────────────────────────────────────────────────────────

  Widget _hero(ProjectDetail project) {
    final settings = project.settings;
    final top = MediaQuery.paddingOf(context).top + 56; // pt-14 + tizim paneli
    return Padding(
      padding: EdgeInsets.only(top: top),
      child: SizedBox(
        // `h-[70vh] sm:h-[85vh]`
        height: MediaQuery.sizeOf(context).height * Bp.pick(context, base: 0.7, sm: 0.85),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _HeroMedia(
              videoUrl: absoluteMediaUrl(settings.heroVideoUrl),
              posterUrl: absoluteMediaUrl(settings.heroPosterUrl ?? project.coverImage),
            ),
            // `bg-gradient-to-t from-dark via-dark/50 to-dark/10`
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppColors.dark,
                    AppColors.dark.withValues(alpha: 0.5),
                    AppColors.dark.withValues(alpha: 0.1),
                  ],
                ),
              ),
            ),
            // `p-5 pb-14 sm:p-8 sm:pb-8 md:p-16`
            Positioned(
              left: Bp.pick(context, base: 20.0, sm: 32.0, md: 64.0),
              right: Bp.pick(context, base: 20.0, sm: 32.0, md: 64.0),
              bottom: Bp.pick(context, base: 56.0, sm: 32.0, md: 64.0),
              child: _heroContent(project),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroContent(ProjectDetail project) {
    final theme = Theme.of(context);
    final settings = project.settings;
    final developerLogo = absoluteMediaUrl(project.developerLogo);
    final projectLogo = absoluteMediaUrl(settings.projectLogo);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quruvchi
        Row(
          children: [
            Container(
              // `w-9 h-9 sm:w-12 sm:h-12`
              width: Bp.pick(context, base: 36.0, sm: 48.0),
              height: Bp.pick(context, base: 36.0, sm: 48.0),
              decoration: BoxDecoration(
                color: AppColors.cream.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              clipBehavior: Clip.antiAlias,
              child: developerLogo == null || developerLogo.isEmpty
                  ? null
                  : AppImage(
                      imageUrl: developerLogo,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => const SizedBox.shrink(),
                      placeholder: (_, _) => const SizedBox.shrink(),
                    ),
            ),
            SizedBox(width: Bp.pick(context, base: 8.0, sm: 12.0)), // gap-2 sm:gap-3
            Expanded(
              child: Text(
                project.developerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: Bp.pick(context, base: 14.0, sm: 18.0), // text-sm sm:text-lg
                  fontWeight: FontWeight.w500,
                  color: AppColors.cream.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: Bp.pick(context, base: 12.0, sm: 24.0)), // mb-3 sm:mb-6
        // Sarlavha (loyiha logotipi bo'lsa yonida)
        Row(
          children: [
            if (projectLogo != null && projectLogo.isNotEmpty) ...[
              Container(
                // `w-12 h-12 sm:w-16 sm:h-16 md:w-20 md:h-20`
                width: Bp.pick(context, base: 48.0, sm: 64.0, md: 80.0),
                height: Bp.pick(context, base: 48.0, sm: 64.0, md: 80.0),
                decoration: BoxDecoration(
                  color: AppColors.cream.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(
                    Bp.pick(context, base: AppRadius.md, sm: AppRadius.lg),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                // Adminkada yozuv bor-u fayl yo'q bo'lishi mumkin (prodda shunday holat
                // bor) — bunda logotip o'rniga sinig'i emas, hech nima ko'rinmasin.
                child: AppImage(
                  imageUrl: projectLogo,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => const SizedBox.shrink(),
                  placeholder: (_, _) => const SizedBox.shrink(),
                ),
              ),
              SizedBox(width: Bp.pick(context, base: 12.0, sm: 16.0)), // gap-3 sm:gap-4
            ],
            Expanded(
              child: Text(
                project.name,
                style: theme.textTheme.displaySmall?.copyWith(
                  // `text-3xl sm:text-5xl md:text-7xl lg:text-8xl`
                  fontSize: Bp.pick(context, base: 30.0, sm: 48.0, md: 72.0, lg: 96.0),
                  fontWeight: FontWeight.w700,
                  color: AppColors.cream,
                ),
              ),
            ),
          ],
        ),
        if (settings.pageSubtitle case final subtitle?) ...[
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              // `text-lg sm:text-2xl md:text-3xl`
              fontSize: Bp.pick(context, base: 18.0, sm: 24.0, md: 30.0),
              color: AppColors.cream.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4), // mb-4 (tepasidagi 12 bilan)
        ] else
          const SizedBox(height: 4),
        if (project.address case final address?) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              SiteIcon(
                SiteIcons.mapPin,
                size: Bp.pick(context, base: 20.0, sm: 24.0),
                color: AppColors.cream.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    // `text-sm sm:text-lg`
                    fontSize: Bp.pick(context, base: 14.0, sm: 18.0),
                    color: AppColors.cream.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8), // mb-5
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: Bp.pick(context, base: 8.0, sm: 12.0), // gap-2 sm:gap-3
          runSpacing: Bp.pick(context, base: 8.0, sm: 12.0),
          children: [
            if (settings.galleryImages.isNotEmpty)
              _heroChip(
                SiteIcons.image,
                ProjectDetailTexts.photos,
                background: AppColors.olive,
                onTap: () => _openGallery(settings.galleryImages),
              ),
            if (settings.brochureUrl case final brochure?)
              _heroChip(
                SiteIcons.download,
                ProjectDetailTexts.brochure,
                onTap: () {
                  final url = absoluteMediaUrl(brochure);
                  if (url != null) {
                    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                  }
                },
              ),
            for (final feature in _dynamicFeatures(project)) _heroChip(feature.icon, feature.label),
          ],
        ),
      ],
    );
  }

  /// `dynamicFeatures()` — loyiha raqamlaridan yig'iladigan belgilar.
  List<({SiteIconData icon, String label})> _dynamicFeatures(ProjectDetail project) {
    final features = <({SiteIconData icon, String label})>[];
    if (project.totalBlocks > 0) {
      features.add((
        icon: SiteIcons.building,
        label: '${project.totalBlocks} ${ProjectDetailTexts.blocks}',
      ));
    }
    if (project.totalApartments > 0) {
      features.add((
        icon: SiteIcons.house,
        label: '${project.totalApartments} ${ProjectDetailTexts.apartments}',
      ));
    }
    final year = (project.endDate ?? project.startDate)?.split('-').first;
    if (year != null && year.isNotEmpty) {
      features.add((icon: SiteIcons.calendar, label: '$year ${ProjectDetailTexts.year}'));
    }
    if (project.totalArea case final area? when area > 0) {
      // JS raqamni butun bo'lsa kasrsiz chiqaradi (`10000`, `10000.5` emas).
      final text = area is int || area == area.roundToDouble()
          ? area.round().toString()
          : area.toString();
      features.add((icon: SiteIcons.ruler, label: '$text m²'));
    }
    return features;
  }

  Widget _heroChip(SiteIconData icon, String label, {Color? background, VoidCallback? onTap}) {
    final theme = Theme.of(context);
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), // px-4 py-2.5
      decoration: BoxDecoration(
        color: background ?? AppColors.cream.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SiteIcon(icon, size: 16, color: AppColors.cream),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.cream,
            ),
          ),
        ],
      ),
    );
    return onTap == null ? chip : Pressable(scale: 0.97, onTap: onTap, child: chip);
  }

  void _openGallery(List<String> images) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: AppColors.dark,
        pageBuilder: (_, _, _) => _GalleryModal(images: images),
      ),
    );
  }

  // ── xususiyatlar ───────────────────────────────────────────────────────────

  Widget _features(ProjectDetail project) {
    final theme = Theme.of(context);
    final settings = project.settings;
    return Container(
      color: AppColors.cream,
      // `pt-10 sm:pt-16 md:pt-24 pb-8 sm:pb-10 md:pb-16`
      padding: EdgeInsets.fromLTRB(
        16,
        Bp.pick(context, base: 40.0, sm: 64.0, md: 96.0),
        16,
        Bp.pick(context, base: 32.0, sm: 40.0, md: 64.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (settings.pageDescription case final description?) ...[
            Text(
              description,
              style: theme.textTheme.displaySmall?.copyWith(
                // `text-lg sm:text-2xl md:text-3xl lg:text-4xl`
                fontSize: Bp.pick(context, base: 18.0, sm: 24.0, md: 30.0, lg: 36.0),
                height: 1.6,
                color: AppColors.dark,
              ),
            ),
            SizedBox(height: Bp.pick(context, base: 24.0, sm: 48.0)), // mb-6 sm:mb-12
          ],
          // Saytda bu tugmaga hech qanday amal ulanmagan (`(selectApartment)` hech
          // qayerda tinglanmaydi) — shuning uchun bu yerda ham bo'sh.
          Container(
            // `px-6 sm:px-8 py-3 sm:py-4`
            padding: EdgeInsets.symmetric(
              horizontal: Bp.pick(context, base: 24.0, sm: 32.0),
              vertical: Bp.pick(context, base: 12.0, sm: 16.0),
            ),
            decoration: BoxDecoration(
              color: AppColors.dark,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              ProjectDetailTexts.selectApartment,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: Bp.pick(context, base: 14.0, sm: 16.0),
                fontWeight: FontWeight.w600,
                color: AppColors.cream,
              ),
            ),
          ),
          SizedBox(height: Bp.pick(context, base: 32.0, sm: 64.0)), // mb-8 sm:mb-16
          _grid(
            // `grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6`
            columns: Bp.pick(context, base: 2, sm: 3, md: 4, lg: 6),
            spacing: Bp.pick(context, base: 16.0, sm: 24.0, lg: 32.0), // gap-4 sm:gap-6 lg:gap-8
            children: [for (final feature in settings.features) _featureCard(feature)],
          ),
        ],
      ),
    );
  }

  Widget _featureCard(ProjectFeature feature) {
    final theme = Theme.of(context);
    final image = absoluteMediaUrl(feature.image);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1, // aspect-square
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: image != null && image.isNotEmpty
                ? AppImage(imageUrl: image, fit: BoxFit.cover)
                : ColoredBox(color: AppColors.bronze.withValues(alpha: 0.2)),
          ),
        ),
        const SizedBox(height: 16), // mb-4
        Container(height: 1, color: AppColors.dark.withValues(alpha: 0.2)),
        const SizedBox(height: 16),
        Text(
          feature.title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 18, // text-lg
            fontWeight: FontWeight.w700,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(height: 4), // mb-1
        Text(
          feature.subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            color: AppColors.dark.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  /// Tailwind `grid-cols-N gap-*` ning qo'lda yig'ilgani.
  Widget _grid({required int columns, required List<Widget> children, double spacing = 8}) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final slice = children.sublist(i, (i + columns).clamp(0, children.length));
      rows.add(
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : spacing),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var c = 0; c < columns; c++) ...[
                if (c > 0) SizedBox(width: spacing),
                Expanded(child: c < slice.length ? slice[c] : const SizedBox.shrink()),
              ],
            ],
          ),
        ),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }
}

// ── hero medias ──────────────────────────────────────────────────────────────

/// Hero foni: video bo'lsa avtomatik o'ynaydi (saytda `autoplay loop muted playsinline`),
/// bo'lmasa poster rasmi turadi. Video ustidagi tugmalar ham saytdagidek.
class _HeroMedia extends StatefulWidget {
  const _HeroMedia({required this.videoUrl, required this.posterUrl});

  final String? videoUrl;
  final String? posterUrl;

  @override
  State<_HeroMedia> createState() => _HeroMediaState();
}

class _HeroMediaState extends State<_HeroMedia> {
  VideoPlayerController? _controller;
  bool _playing = true;
  bool _muted = true;

  @override
  void initState() {
    super.initState();
    final url = widget.videoUrl;
    if (url == null || url.isEmpty) return;
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _controller = controller;
    controller.initialize().then((_) {
      if (!mounted) return;
      controller
        ..setLooping(true)
        ..setVolume(0)
        ..play();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    setState(() {
      _playing = !_playing;
      _playing ? controller.play() : controller.pause();
    });
  }

  void _toggleMute() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    setState(() {
      _muted = !_muted;
      controller.setVolume(_muted ? 0 : 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final poster = widget.posterUrl;
    final ready = controller != null && controller.value.isInitialized;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (ready)
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          )
        else if (poster != null && poster.isNotEmpty)
          AppImage(imageUrl: poster, fit: BoxFit.cover)
        else
          const ColoredBox(color: AppColors.dark),
        if (ready)
          // `absolute top-4 right-4 w-10 h-10 bg-olive rounded-xl` — videoni
          // to'liq ekranda ochadi.
          Positioned(
            top: Bp.pick(context, base: 16.0, sm: 24.0),
            right: Bp.pick(context, base: 16.0, sm: 24.0),
            child: Pressable(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => _VideoFullscreen(controller: controller)),
              ),
              child: Container(
                width: Bp.pick(context, base: 40.0, sm: 48.0),
                height: Bp.pick(context, base: 40.0, sm: 48.0),
                decoration: BoxDecoration(
                  color: AppColors.olive,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Center(
                  child: SiteIcon(SiteIcons.fullscreen, size: 20, color: AppColors.cream),
                ),
              ),
            ),
          ),
        if (ready)
          // `right-4 bottom-4 sm:right-auto sm:left-8 sm:bottom-8`
          Positioned(
            right: Bp.isSm(context) ? null : 16,
            left: Bp.isSm(context) ? 32 : null,
            bottom: Bp.pick(context, base: 16.0, sm: 32.0),
            child: Row(
              children: [
                _control(_playing ? SiteIcons.pause : SiteIcons.play, _togglePlay),
                SizedBox(width: Bp.pick(context, base: 8.0, sm: 12.0)),
                _control(_muted ? SiteIcons.volumeOff : SiteIcons.volumeOn, _toggleMute),
              ],
            ),
          ),
      ],
    );
  }

  Widget _control(SiteIconData icon, VoidCallback onTap) {
    return Pressable(
      onTap: onTap,
      child: Container(
        // `w-9 h-9 sm:w-10 sm:h-10`
        width: Bp.pick(context, base: 36.0, sm: 40.0),
        height: Bp.pick(context, base: 36.0, sm: 40.0),
        decoration: BoxDecoration(
          color: AppColors.dark.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.cream.withValues(alpha: 0.2)),
        ),
        child: Center(child: SiteIcon(icon, size: 16, color: AppColors.cream)),
      ),
    );
  }
}

/// Hero videosi to'liq ekranda — saytda bu `h-screen` holati, ustidagi
/// qatlam va matn yashiriladi, tugma esa X ga aylanadi.
class _VideoFullscreen extends StatelessWidget {
  const _VideoFullscreen({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 16,
            right: 16,
            child: Pressable(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.olive,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Center(
                  child: SiteIcon(SiteIcons.close, size: 20, color: AppColors.cream),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── arxitektura ──────────────────────────────────────────────────────────────

/// `architecture-showcase.component.ts` — muallif, keng slayder va pastdagi yorliqlar.
class _ArchitectureShowcase extends StatefulWidget {
  const _ArchitectureShowcase({required this.architect, required this.tabs});

  final ProjectArchitect? architect;
  final List<ProjectTab> tabs;

  @override
  State<_ArchitectureShowcase> createState() => _ArchitectureShowcaseState();
}

class _ArchitectureShowcaseState extends State<_ArchitectureShowcase> {
  // `slides-per-view="1.1" centered-slides="true"`
  final _pager = PageController(viewportFraction: 1 / 1.1);
  int _tab = 0;

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  void _slide(int direction) {
    if (!_pager.hasClients) return;
    final page = (_pager.page ?? 0).round() + direction;
    final last = widget.tabs[_tab].slides.length - 1;
    _pager.animateToPage(
      page.clamp(0, last < 0 ? 0 : last),
      duration: const Duration(milliseconds: 600), // speed="600"
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final architect = widget.architect;
    final slides = widget.tabs[_tab.clamp(0, widget.tabs.length - 1)].slides;
    return Container(
      color: AppColors.cream,
      // `py-8 sm:py-10 md:py-16`
      padding: EdgeInsets.symmetric(vertical: Bp.pick(context, base: 32.0, sm: 40.0, md: 64.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (architect != null) ...[
                  Row(
                    children: [
                      ClipOval(
                        child: SizedBox(
                          width: 56, // w-14
                          height: 56,
                          child: _architectAvatar(architect),
                        ),
                      ),
                      const SizedBox(width: 16), // gap-4
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              architect.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.dark,
                              ),
                            ),
                            Text(
                              architect.role,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 14,
                                color: AppColors.dark.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: Bp.pick(context, base: 20.0, sm: 32.0)), // gap-5 sm:gap-8
                  Text(
                    architect.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                      height: 1.6,
                      color: AppColors.dark.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                Row(
                  children: [
                    _arrow(SiteIcons.chevronLeft, () => _slide(-1)),
                    const SizedBox(width: 8),
                    _arrow(SiteIcons.chevronRight, () => _slide(1)),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: Bp.pick(context, base: 24.0, sm: 40.0)), // mb-6 sm:mb-10
          AspectRatio(
            aspectRatio: Bp.pick(context, base: 16 / 9, md: 16 / 8),
            child: PageView.builder(
              controller: _pager,
              itemCount: slides.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8), // space-between 16
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: AppImage(
                    imageUrl: absoluteMediaUrl(slides[index]) ?? '',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          if (widget.tabs.length > 1) ...[
            const SizedBox(height: 40), // mt-10
            _TabSwitcher(
              labels: [for (final tab in widget.tabs) tab.label],
              active: _tab,
              onChanged: (index) {
                setState(() => _tab = index);
                if (_pager.hasClients) _pager.jumpToPage(0);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _architectAvatar(ProjectArchitect architect) {
    final avatar = absoluteMediaUrl(architect.avatar);
    if (avatar != null && avatar.isNotEmpty) {
      return AppImage(imageUrl: avatar, fit: BoxFit.cover);
    }
    // Saytda rasm bo'lmasa `ui-avatars.com` dan ikki harfli rasm olinadi.
    final theme = Theme.of(context);
    final initials = architect.name.isEmpty
        ? ''
        : architect.name.substring(0, architect.name.length < 2 ? 1 : 2).toUpperCase();
    return ColoredBox(
      color: const Color(0xFF999966),
      child: Center(
        child: Text(
          initials,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _arrow(SiteIconData icon, VoidCallback onTap) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 48, // w-12
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.dark.withValues(alpha: 0.2)),
        ),
        child: Center(child: SiteIcon(icon, size: 20, color: AppColors.dark)),
      ),
    );
  }
}

/// Saytdagi `bg-dark/10` doira ichida sirg'aluvchi oq ko'rsatkichli yorliqlar.
class _TabSwitcher extends StatelessWidget {
  const _TabSwitcher({required this.labels, required this.active, required this.onChanged});

  final List<String> labels;
  final int active;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(6), // p-1.5
        decoration: BoxDecoration(
          color: AppColors.dark.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++) ...[
              if (i > 0) const SizedBox(width: 4), // gap-1
              Pressable(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: i == active ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    labels[i],
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: i == active ? AppColors.dark : AppColors.dark.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── 3D ko'ruvchi ─────────────────────────────────────────────────────────────

/// Saytda iframe sahifa ochilishi bilan **fon rejimida** yuklanadi, ustida esa poster va
/// "3D'ni ko'rish" tugmasi turadi; yuklanib bo'lgach "Ko'rish uchun bosing" yoziladi.
/// Ilovada ham xuddi shunday: WebView darrov yuklanadi, lekin ko'rinmaydi.
class _Viewer3dSection extends StatefulWidget {
  const _Viewer3dSection({super.key, required this.url, required this.poster});

  final String url;
  final String? poster;

  @override
  State<_Viewer3dSection> createState() => _Viewer3dSectionState();
}

class _Viewer3dSectionState extends State<_Viewer3dSection> {
  late final WebViewController _controller;
  bool _ready = false;

  /// To'liq ekran ochilganda WebView o'sha yerga ko'chadi — bitta kontroller ikki
  /// joyda tura olmaydi.
  bool _movedToFullscreen = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.dark)
      // 3D ichidagi o'tish videolari brauzerdagi kabi o'zi o'ynashi kerak.
      // Busiz WebView ularni to'xtatib turadi va ekranda "play" belgisi chiqadi.
      ..addJavaScriptChannel('BHViewer', onMessageReceived: _onViewerMessage)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _ready = true);
            _installBridge();
            _sendAuth();
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));

    if (_controller.platform case final AndroidWebViewController android) {
      android.setMediaPlaybackRequiresUserGesture(false);
    }
  }

  /// Saytda 3D ko'ruvchi ota oynaga `postMessage` yuboradi. WebView ichida
  /// `window.parent` — o'zi, shuning uchun xabarni shu yerda tutib Dart tomonga
  /// uzatamiz (`viewer3d.component.ts` dagi `onChildMessage` ning o'rni).
  Future<void> _installBridge() async {
    try {
      await _controller.runJavaScript('''
        if (!window.__bhBridge) {
          window.__bhBridge = true;
          window.addEventListener('message', function (e) {
            var d = e && e.data;
            if (!d || typeof d !== 'object' || !d.type) return;
            try { BHViewer.postMessage(JSON.stringify(d)); } catch (err) {}
          });
        }
      ''');
    } catch (_) {}
  }

  void _onViewerMessage(JavaScriptMessage message) {
    Map<String, dynamic> data;
    try {
      final decoded = jsonDecode(message.message);
      if (decoded is! Map) return;
      data = decoded.cast<String, dynamic>();
    } catch (_) {
      return;
    }
    switch (data['type']) {
      case 'bh.exit3d':
        // Ko'ruvchi menyusidagi "3D dan chiqish".
        if (_movedToFullscreen && mounted) Navigator.of(context).pop();
      case 'bh:auth-request':
        // Saytdagi kabi 2 soniyada bir marta (halqa bo'lib qolmasligi uchun).
        final now = DateTime.now();
        if (_lastAuthRequest != null &&
            now.difference(_lastAuthRequest!) < const Duration(seconds: 2)) {
          return;
        }
        _lastAuthRequest = now;
        _sendAuth();
      case 'bh:request-login':
        if (mounted) context.push('/login');
    }
  }

  DateTime? _lastAuthRequest;

  /// Saytda token iframe'ga `postMessage({type:'bh:auth', …})` orqali beriladi — 3D ichidagi
  /// "Sevimlilar" tugmasi shuning hisobiga ishlaydi.
  Future<void> _sendAuth() async {
    if (!mounted) return;
    final user = context.read<AuthService>().user;
    final token = await ApiClient.instance.accessToken();
    final payload = jsonEncode({
      'type': 'bh:auth',
      'token': token,
      'apiUrl': ApiClient.baseUrl,
      'user': user == null
          ? null
          : {'id': user.id, 'fullName': user.fullName, 'phone': user.phone, 'role': user.role.name},
    });
    try {
      await _controller.runJavaScript('window.postMessage($payload, "*");');
    } catch (_) {
      // 3D sahifasi hali tayyor bo'lmasa — jim o'tamiz, saytda ham xatolik chiqmaydi.
    }
  }

  /// Prezentatsiya rejimi oxirida tashqaridan chaqiriladi (`reveal`).
  void open() => unawaited(_open());

  Future<void> _open() async {
    setState(() => _movedToFullscreen = true);
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => _Viewer3dPage(controller: _controller)));
    if (mounted) setState(() => _movedToFullscreen = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final poster = widget.poster;
    return Container(
      color: AppColors.cream,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg), // rounded-2xl
        child: SizedBox(
          // `clamp(340px, 68vh, 700px)`
          height: (MediaQuery.sizeOf(context).height * 0.68).clamp(340.0, 700.0),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Yuklanayotgan ko'ruvchi poster ostida turadi.
              if (!_movedToFullscreen)
                Opacity(opacity: 0, child: WebViewWidget(controller: _controller)),
              IgnorePointer(
                child: poster == null || poster.isEmpty
                    ? const ColoredBox(color: AppColors.dark)
                    : AppImage(imageUrl: poster, fit: BoxFit.cover),
              ),
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        AppColors.dark.withValues(alpha: 0.7),
                        AppColors.dark.withValues(alpha: 0.2),
                        AppColors.dark.withValues(alpha: 0.4),
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: Pressable(
                  scale: 0.97,
                  onTap: _open,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        // `w-16 h-16 md:w-20 md:h-20`
                        width: Bp.pick(context, base: 64.0, md: 80.0),
                        height: Bp.pick(context, base: 64.0, md: 80.0),
                        decoration: const BoxDecoration(
                          color: AppColors.olive,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4), // ml-1
                            child: SiteIcon(
                              SiteIcons.play,
                              size: Bp.pick(context, base: 32.0, md: 40.0),
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12), // gap-3
                      Text(
                        ProjectDetailTexts.viewer3dView,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: Bp.pick(context, base: 18.0, md: 20.0), // text-lg md:text-xl
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _ready
                                  ? const Color(0xFF34D399) // emerald-400
                                  : const Color(0xFFFBBF24), // amber-400
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6), // gap-1.5
                          Text(
                            _ready
                                ? ProjectDetailTexts.viewer3dReady
                                : ProjectDetailTexts.viewer3dPreloading,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: Bp.pick(context, base: 12.0, md: 14.0),
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Oldindan yuklangan ko'ruvchi to'liq ekranda — saytdagi `fixed inset-0 z-[9999]`.
///
/// Saytda bu holatda ekranga **hech narsa qo'shilmaydi**: yopish tugmasi ham,
/// "Aziza" tugmasi ham ko'rinmaydi (3D `z-[9999]`, Aziza `z-[9998]`). Chiqish
/// ko'ruvchining o'z menyusidagi "3D dan chiqish" orqali bo'ladi — u ota
/// oynaga `bh.exit3d` yuboradi.
class _Viewer3dPage extends StatefulWidget {
  const _Viewer3dPage({required this.controller});

  final WebViewController controller;

  @override
  State<_Viewer3dPage> createState() => _Viewer3dPageState();
}

class _Viewer3dPageState extends State<_Viewer3dPage> {
  @override
  void initState() {
    super.initState();
    // Qurilish paytida o'zgartirilsa `ValueListenableBuilder` qayta chizilmaydi,
    // shuning uchun kadr tugagach aytamiz.
    WidgetsBinding.instance.addPostFrameCallback((_) => AiAssistant.hidden.value++);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) => AiAssistant.hidden.value--);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.dark,
    body: WebViewWidget(controller: widget.controller),
  );
}

// ── xususiyatlar (aylanadigan kartalar) ──────────────────────────────────────

class _Highlights extends StatefulWidget {
  const _Highlights({required this.categories});

  final List<HighlightCategory> categories;

  @override
  State<_Highlights> createState() => _HighlightsState();
}

class _HighlightsState extends State<_Highlights> {
  int _category = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = widget.categories[_category.clamp(0, widget.categories.length - 1)].items;
    return Container(
      color: AppColors.cream,
      // `py-8 sm:py-10 md:py-16`
      padding: EdgeInsets.symmetric(vertical: Bp.pick(context, base: 32.0, sm: 40.0, md: 64.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    ProjectDetailTexts.highlightsTitle,
                    style: theme.textTheme.displaySmall?.copyWith(
                      // `text-2xl sm:text-3xl md:text-4xl`
                      fontSize: Bp.pick(context, base: 24.0, sm: 30.0, md: 36.0),
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                    ),
                  ),
                ),
                // Saytda bu strelkalar `grid` ni surmoqchi bo'ladi, lekin grid
                // gorizontal surilmaydi — ya'ni ular hech nima qilmaydi.
                _arrow(SiteIcons.chevronLeft, filled: false),
                const SizedBox(width: 8),
                _arrow(SiteIcons.chevronRight, filled: true),
              ],
            ),
          ),
          SizedBox(height: Bp.pick(context, base: 20.0, sm: 40.0)), // mb-5 sm:mb-10
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                for (var i = 0; i < items.length; i += 2) ...[
                  if (i > 0) const SizedBox(height: 16), // gap-4
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _FlipCard(item: items[i])),
                      const SizedBox(width: 16),
                      Expanded(
                        child: i + 1 < items.length
                            ? _FlipCard(item: items[i + 1])
                            : const SizedBox(height: 320),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (widget.categories.length > 1) ...[
            const SizedBox(height: 48), // mb-12
            _TabSwitcher(
              labels: [for (final category in widget.categories) category.label],
              active: _category,
              onChanged: (index) => setState(() => _category = index),
            ),
          ],
        ],
      ),
    );
  }

  Widget _arrow(SiteIconData icon, {required bool filled}) {
    return Container(
      // `w-10 h-10 sm:w-12 sm:h-12`
      width: Bp.pick(context, base: 40.0, sm: 48.0),
      height: Bp.pick(context, base: 40.0, sm: 48.0),
      decoration: BoxDecoration(
        color: filled ? AppColors.dark : Colors.transparent,
        shape: BoxShape.circle,
        border: filled ? null : Border.all(color: AppColors.dark.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: SiteIcon(icon, size: 20, color: filled ? AppColors.cream : AppColors.dark),
      ),
    );
  }
}

/// Bosilganda orqa tomoni (izohi) ko'rinadigan karta.
class _FlipCard extends StatefulWidget {
  const _FlipCard({required this.item});

  final HighlightItem item;

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard> {
  bool _flipped = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _flipped = !_flipped),
      child: SizedBox(
        // `h-[320px] md:h-[480px] lg:h-[520px]`
        height: Bp.pick(context, base: 320.0, md: 480.0, lg: 520.0),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 700), // duration-700
          child: _flipped ? _back() : _front(),
        ),
      ),
    );
  }

  Widget _front() {
    final theme = Theme.of(context);
    final image = absoluteMediaUrl(widget.item.image);
    return Stack(
      key: const ValueKey('front'),
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: image != null && image.isNotEmpty
              ? AppImage(imageUrl: image, fit: BoxFit.cover)
              : const ColoredBox(color: AppColors.surfaceMutedLight),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.dark.withValues(alpha: 0.4),
                  Colors.transparent,
                  AppColors.dark.withValues(alpha: 0.2),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 20, // top-5
          left: 20,
          right: 20,
          child: Text(
            widget.item.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: Bp.pick(context, base: 18.0, md: 20.0), // text-lg md:text-xl
              fontWeight: FontWeight.w600,
              height: 1.25, // leading-tight
              color: Colors.white,
            ),
          ),
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: Container(
            width: 44, // w-11
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: const Center(child: SiteIcon(SiteIcons.plus, size: 20, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _back() {
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey('back'),
      padding: const EdgeInsets.all(24), // p-6
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.dark.withValues(alpha: 0.1)),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.item.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: Bp.pick(context, base: 20.0, md: 24.0), // text-xl md:text-2xl
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 16), // mb-4
              Expanded(
                child: Text(
                  widget.item.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    height: 1.6,
                    color: AppColors.dark.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(color: AppColors.dark, shape: BoxShape.circle),
              child: const Center(child: SiteIcon(SiteIcons.close, size: 20, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── galereya (nuqtali) ───────────────────────────────────────────────────────

/// `architecture-gallery.component.ts` — katta rasm, ustidagi nuqtalar va pastdagi yorliqlar.
class _ArchitectureGallery extends StatefulWidget {
  const _ArchitectureGallery({required this.sections});

  final List<GallerySection> sections;

  @override
  State<_ArchitectureGallery> createState() => _ArchitectureGalleryState();
}

class _ArchitectureGalleryState extends State<_ArchitectureGallery> {
  final _pager = PageController();
  int _section = 0;
  int _image = 0;
  int? _hotspot;

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final images = widget.sections[_section.clamp(0, widget.sections.length - 1)].images;
    return Container(
      color: AppColors.cream,
      // `py-8 sm:py-10 md:py-16`
      padding: EdgeInsets.symmetric(vertical: Bp.pick(context, base: 32.0, sm: 40.0, md: 64.0)),
      child: Column(
        children: [
          Padding(
            // `px-3 sm:px-4 md:px-8 lg:px-16 xl:px-24`
            padding: EdgeInsets.symmetric(
              horizontal: Bp.pick(context, base: 12.0, sm: 16.0, md: 32.0, lg: 64.0, xl: 96.0),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xl), // rounded-3xl
              child: AspectRatio(
                // `aspect-[4/3] md:[16/10] lg:[16/9] xl:[21/9]`
                aspectRatio: Bp.pick(context, base: 4 / 3, md: 16 / 10, lg: 16 / 9, xl: 21 / 9),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PageView.builder(
                      controller: _pager,
                      itemCount: images.length,
                      onPageChanged: (index) => setState(() {
                        _image = index;
                        _hotspot = null;
                      }),
                      itemBuilder: (context, index) => _image_(images[index]),
                    ),
                    Positioned(
                      right: 24, // bottom-6 right-6
                      bottom: 24,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.dark.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          '${_image + 1} / ${images.length}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (widget.sections.length > 1) ...[
            SizedBox(height: Bp.pick(context, base: 24.0, sm: 40.0)), // mb-6 sm:mb-10
            _TabSwitcher(
              labels: [for (final section in widget.sections) section.label],
              active: _section,
              onChanged: (index) => setState(() {
                _section = index;
                _image = 0;
                _hotspot = null;
                if (_pager.hasClients) _pager.jumpToPage(0);
              }),
            ),
          ],
        ],
      ),
    );
  }

  Widget _image_(GalleryImage image) {
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: () => setState(() => _hotspot = null),
            child: AppImage(imageUrl: absoluteMediaUrl(image.url) ?? '', fit: BoxFit.cover),
          ),
          for (var i = 0; i < image.hotspots.length; i++)
            Positioned(
              left: constraints.maxWidth * image.hotspots[i].x / 100 - 20,
              top: constraints.maxHeight * image.hotspots[i].y / 100 - 20,
              child: _hotspotPin(image.hotspots[i], i),
            ),
        ],
      ),
    );
  }

  Widget _hotspotPin(GalleryHotspot hotspot, int index) {
    final theme = Theme.of(context);
    final active = _hotspot == index;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => setState(() => _hotspot = active ? null : index),
          child: Container(
            width: 40, // w-10
            height: 40,
            decoration: BoxDecoration(
              color: active ? Colors.white : Colors.white.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              border: active ? null : Border.all(color: Colors.white.withValues(alpha: 0.5)),
            ),
            child: Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: active ? AppColors.dark : Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
        if (active)
          Padding(
            padding: const EdgeInsets.only(left: 8), // left-12
            child: Container(
              constraints: const BoxConstraints(minWidth: 240, maxWidth: 280),
              padding: const EdgeInsets.all(20), // p-5
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hotspot.label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 8), // mb-2
                  Text(
                    hotspot.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      height: 1.6,
                      color: AppColors.dark.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ── aqlli uy ─────────────────────────────────────────────────────────────────

class _SmartHome extends StatefulWidget {
  const _SmartHome({required this.tabs});

  final List<SmartHomeTab> tabs;

  @override
  State<_SmartHome> createState() => _SmartHomeState();
}

class _SmartHomeState extends State<_SmartHome> {
  int _tab = 0;

  static SiteIconData _icon(String name) => switch (name) {
    'zap' => SiteIcons.zap,
    'droplets' => SiteIcons.droplets,
    'thermometer' => SiteIcons.thermometer,
    'wifi' => SiteIcons.wifi,
    _ => SiteIcons.zap,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = widget.tabs[_tab.clamp(0, widget.tabs.length - 1)];
    final image = absoluteMediaUrl(active.image);
    return Container(
      color: AppColors.cream,
      // `py-8 sm:py-10 md:py-16`
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: Bp.pick(context, base: 32.0, sm: 40.0, md: 64.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ProjectDetailTexts.smartTitle,
            style: theme.textTheme.displaySmall?.copyWith(
              // `text-2xl sm:text-3xl md:text-4xl`
              fontSize: Bp.pick(context, base: 24.0, sm: 30.0, md: 36.0),
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          SizedBox(height: Bp.pick(context, base: 16.0, sm: 24.0)), // gap-4 sm:gap-6
          Text(
            ProjectDetailTexts.smartMainDesc,
            style: theme.textTheme.bodyMedium?.copyWith(
              // `text-sm sm:text-base md:text-lg`
              fontSize: Bp.pick(context, base: 14.0, sm: 16.0, md: 18.0),
              height: 1.6,
              color: AppColors.dark.withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: Bp.pick(context, base: 16.0, sm: 24.0)), // mt-4 sm:mt-6
          Container(
            // `px-6 sm:px-8 py-2.5 sm:py-3.5`
            padding: EdgeInsets.symmetric(
              horizontal: Bp.pick(context, base: 24.0, sm: 32.0),
              vertical: Bp.pick(context, base: 10.0, sm: 14.0),
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.dark.withValues(alpha: 0.2)),
            ),
            child: Text(
              ProjectDetailTexts.smartDetails,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: Bp.pick(context, base: 14.0, sm: 16.0),
                fontWeight: FontWeight.w500,
                color: AppColors.dark,
              ),
            ),
          ),
          SizedBox(height: Bp.pick(context, base: 24.0, sm: 48.0)), // mb-6 sm:mb-12
          ClipRRect(
            // `rounded-[1.5rem] sm:rounded-[2rem]`
            borderRadius: BorderRadius.circular(Bp.pick(context, base: 24.0, sm: 32.0)),
            child: SizedBox(
              // `min-h-[480px] sm:min-h-[600px] lg:min-h-[800px]`
              height: Bp.pick(context, base: 480.0, sm: 600.0, lg: 800.0),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (image != null && image.isNotEmpty)
                    AppImage(imageUrl: image, fit: BoxFit.cover)
                  else
                    const ColoredBox(color: AppColors.dark),
                  // `bg-gradient-to-r from-[#4A3728]/70 via-[#4A3728]/25 to-transparent`
                  DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0xB34A3728), Color(0x404A3728), Color(0x004A3728)],
                      ),
                    ),
                  ),
                  Padding(
                    // `p-8 md:p-12 lg:p-16`
                    padding: EdgeInsets.all(Bp.pick(context, base: 32.0, md: 48.0, lg: 64.0)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            for (var i = 0; i < widget.tabs.length; i++) ...[
                              if (i > 0) const SizedBox(width: 12), // gap-3
                              Pressable(
                                onTap: () => setState(() => _tab = i),
                                child: Container(
                                  width: 56, // w-14
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: i == _tab
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: SiteIcon(
                                      _icon(widget.tabs[i].icon),
                                      size: 24,
                                      color: i == _tab
                                          ? const Color(0xFF4A3728)
                                          : Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 40), // mb-10
                        Text(
                          active.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            // `text-xl sm:text-2xl md:text-3xl`
                            fontSize: Bp.pick(context, base: 20.0, sm: 24.0, md: 30.0),
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: Bp.pick(context, base: 12.0, sm: 16.0)), // mb-3 sm:mb-4
                        Text(
                          active.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            // `text-sm sm:text-base md:text-lg`
                            fontSize: Bp.pick(context, base: 14.0, sm: 16.0, md: 18.0),
                            height: 1.6,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        const Spacer(), // mt-auto
                        if (active.products.isNotEmpty)
                          SizedBox(
                            height: 160,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: active.products.length,
                              separatorBuilder: (_, _) => const SizedBox(width: 16), // gap-4
                              itemBuilder: (context, index) =>
                                  _product(active.products[index], theme),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _product(({String name, String image}) product, ThemeData theme) {
    final image = absoluteMediaUrl(product.image);
    return Container(
      width: Bp.pick(context, base: 160.0, md: 180.0), // `w-[160px] md:w-[180px]`
      padding: const EdgeInsets.all(20), // p-5
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 40, // min-h-[40px]
            child: Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.25,
                color: AppColors.dark,
              ),
            ),
          ),
          const SizedBox(height: 16), // mb-4
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: image == null || image.isEmpty
                  ? const SizedBox.shrink()
                  : AppImage(imageUrl: image, fit: BoxFit.contain),
            ),
          ),
        ],
      ),
    );
  }
}

// ── hujjatlar ────────────────────────────────────────────────────────────────

/// Bitta bo'lim, ichida papka kartalari; karta bosilsa hujjatlar oynasi ochiladi.
class _ProjectDocuments extends StatelessWidget {
  const _ProjectDocuments({required this.categories});

  final List<DocumentCategory> categories;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: AppColors.cream,
      // `py-8 sm:py-10 md:py-16`
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: Bp.pick(context, base: 32.0, sm: 40.0, md: 64.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ProjectDetailTexts.docsTitle,
            style: theme.textTheme.displaySmall?.copyWith(
              // `text-2xl sm:text-3xl md:text-4xl`
              fontSize: Bp.pick(context, base: 24.0, sm: 30.0, md: 36.0),
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          SizedBox(height: Bp.pick(context, base: 20.0, sm: 40.0)), // mb-5 sm:mb-10
          // `grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6`
          _documentsGrid(context, theme),
        ],
      ),
    );
  }

  Widget _documentsGrid(BuildContext context, ThemeData theme) {
    final columns = Bp.pick(context, base: 1, sm: 2, lg: 3);
    final spacing = Bp.pick(context, base: 16.0, sm: 24.0);
    final rows = <Widget>[];
    for (var i = 0; i < categories.length; i += columns) {
      final slice = categories.sublist(i, (i + columns).clamp(0, categories.length));
      rows.add(
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : spacing),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var c = 0; c < columns; c++) ...[
                if (c > 0) SizedBox(width: spacing),
                Expanded(
                  child: c < slice.length
                      ? _folderCard(context, slice[c], theme)
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }

  Widget _folderCard(BuildContext context, DocumentCategory category, ThemeData theme) {
    return Pressable(
      scale: 0.99,
      onTap: () => showDialog<void>(
        context: context,
        barrierColor: AppColors.dark.withValues(alpha: 0.8),
        builder: (_) => _DocumentsModal(category: category),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24), // p-6
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _folderIcon(),
            const SizedBox(height: 16), // mb-4
            Text(
              category.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 16, // text-base
                fontWeight: FontWeight.w600,
                height: 1.375, // leading-snug
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 8), // mb-2
            Text(
              '${category.documents.length} ${ProjectDetailTexts.docsDocument}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                color: AppColors.dark.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Saytda papka uchta to'rtburchakdan yig'ilgan (ikonka emas).
  Widget _folderIcon() {
    return SizedBox(
      width: 56, // w-14
      height: 48, // h-12
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.olive.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
          ),
          Positioned(
            top: -8,
            left: 0,
            child: Container(
              width: 32, // w-8
              height: 12, // h-3
              decoration: BoxDecoration(
                color: AppColors.olive.withValues(alpha: 0.7),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 40, // h-10
              decoration: BoxDecoration(
                color: AppColors.olive,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentsModal extends StatelessWidget {
  const _DocumentsModal({required this.category});

  final DocumentCategory category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(16), // p-4
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(24), // p-6
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      category.label,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 20, // text-xl
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                    ),
                  ),
                  Pressable(
                    onTap: () => Navigator.of(context).pop(),
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Center(
                        child: SiteIcon(SiteIcons.close, size: 24, color: AppColors.dark),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: AppColors.dark.withValues(alpha: 0.1)),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.all(24),
                itemCount: category.documents.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12), // space-y-3
                itemBuilder: (context, index) => _documentRow(category.documents[index], theme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _documentRow(({String name, String url}) document, ThemeData theme) {
    return Pressable(
      scale: 0.99,
      onTap: () {
        final url = absoluteMediaUrl(document.url);
        if (url != null) launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      },
      child: Container(
        padding: const EdgeInsets.all(16), // p-4
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444), // bg-red-500
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Center(
                child: SiteIcon(SiteIcons.document, size: 20, color: Colors.white),
              ),
            ),
            const SizedBox(width: 16), // gap-4
            Expanded(
              child: Text(
                document.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.dark,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SiteIcon(SiteIcons.download, size: 20, color: AppColors.dark.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }
}

// ── galereya oynasi ──────────────────────────────────────────────────────────

/// Hero'dagi "Rasmlar" tugmasi ochadigan oyna — surib ko'riladi, pastda kichik rasmlar.
class _GalleryModal extends StatefulWidget {
  const _GalleryModal({required this.images});

  final List<String> images;

  @override
  State<_GalleryModal> createState() => _GalleryModalState();
}

class _GalleryModalState extends State<_GalleryModal> {
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
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (index) => setState(() => _index = index),
            itemBuilder: (context, index) => InteractiveViewer(
              child: Center(
                child: AppImage(
                  imageUrl: absoluteMediaUrl(widget.images[index]) ?? '',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Positioned(
            top: top + 24, // top-6
            right: 24,
            child: Pressable(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 48, // w-12
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.cream.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: SiteIcon(SiteIcons.close, size: 20, color: AppColors.cream),
                ),
              ),
            ),
          ),
          Positioned(
            top: top + 24,
            left: 24,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${_index + 1}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.cream,
                    ),
                  ),
                  TextSpan(
                    text: ' / ${widget.images.length}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.cream.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 32, // bottom-8
            left: 0,
            right: 0,
            child: Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    for (var i = 0; i < widget.images.length; i++) ...[
                      if (i > 0) const SizedBox(width: 12), // gap-3
                      Pressable(
                        onTap: () => _controller.jumpToPage(i),
                        child: Opacity(
                          opacity: i == _index ? 1 : 0.5,
                          child: Container(
                            width: 80, // w-20
                            height: 56, // h-14
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: i == _index
                                  ? Border.all(color: AppColors.olive, width: 2)
                                  : null,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: AppImage(
                              imageUrl: absoluteMediaUrl(widget.images[i]) ?? '',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
