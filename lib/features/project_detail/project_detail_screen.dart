import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../app/theme.dart';
import '../../core/api/media_url.dart';
import '../../shared/widgets/app_image.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/site_footer_section.dart';
import '../../shared/widgets/site_icon.dart';
import 'project_detail_models.dart';
import 'project_detail_repository.dart';
import 'project_detail_texts.dart';

/// Saytning `/property/:id` va `/:dev/:project` sahifasi — `property-detail.component.ts`.
///
/// Ikkala yo'l bitta komponentga olib boradi, shuning uchun bu yerda ham bitta ekran.
/// Sahifa bo'limlardan yig'iladi va **har biri ma'lumot bo'lsagina chiziladi** — saytda ham
/// hammasi `@if (…length > 0)` bilan o'ralgan. Prodda hozircha `smart_home` va `documents`
/// hech qaysi loyihada to'ldirilmagan.
class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({super.key, this.id, this.developerCode, this.projectCode});

  final int? id;
  final String? developerCode;
  final String? projectCode;

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  static const _repo = ProjectDetailRepository();

  late final Future<ProjectDetail?> _future = _load();

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
          return _body(project);
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
      padding: EdgeInsets.zero,
      children: [
        _hero(project),
        if (settings.features.isNotEmpty || (settings.pageDescription?.isNotEmpty ?? false))
          _features(project),
        if (settings.architectureTabs.isNotEmpty)
          _TabbedSlides(tabs: settings.architectureTabs, background: Colors.white),
        _viewer3d(project),
        if (settings.highlightCategories.isNotEmpty) _highlights(settings.highlightCategories),
        for (final section in settings.gallerySections)
          if (section.images.isNotEmpty) _gallerySection(section),
        if (settings.smartHomeTabs.isNotEmpty)
          _TabbedSlides(tabs: settings.smartHomeTabs, background: AppColors.cream),
        for (final category in settings.documentCategories)
          if (category.documents.isNotEmpty) _documents(category),
        const SiteFooterSection(),
      ],
    );
  }

  // ── hero ───────────────────────────────────────────────────────────────────

  /// Fon — video posteri yoki muqova rasmi, ustida to'q qatlam va loyiha ma'lumoti.
  Widget _hero(ProjectDetail project) {
    final theme = Theme.of(context);
    final settings = project.settings;
    final background = absoluteMediaUrl(settings.heroPosterUrl ?? project.coverImage);
    final logo = absoluteMediaUrl(settings.projectLogo);

    return SizedBox(
      height: 560,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (background != null && background.isNotEmpty)
            AppImage(imageUrl: background, fit: BoxFit.cover)
          else
            const ColoredBox(color: AppColors.dark),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.dark.withValues(alpha: 0.3),
                  AppColors.dark.withValues(alpha: 0.85),
                ],
              ),
            ),
          ),
          // Orqaga tugmasi — saytda hero ustida turadi.
          Positioned(
            top: MediaQuery.paddingOf(context).top + 12,
            left: 16,
            child: Pressable(
              onTap: () => context.go('/new-projects'),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Center(
                  child: SiteIcon(SiteIcons.arrowLeft, size: 18, color: Colors.white),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 32,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (project.developerName.isNotEmpty)
                  Text(
                    project.developerName.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 12,
                      letterSpacing: 1.5, // tracking-widest
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (logo != null && logo.isNotEmpty) ...[
                      SizedBox(
                        height: 40,
                        width: 40,
                        child: AppImage(
                          imageUrl: logo,
                          fit: BoxFit.contain,
                          // Adminkada yozuv bor-u fayl yo'q bo'lishi mumkin (prodda shunday
                          // holat bor) — bunda logotip o'rniga sinig'i emas, hech nima
                          // ko'rinmasin.
                          errorWidget: (_, _, _) => const SizedBox.shrink(),
                          placeholder: (_, _) => const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        project.name,
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontSize: 32, // text-3xl mobilda
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                if (settings.pageSubtitle case final subtitle?) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
                if (project.address case final address?) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SiteIcon(
                        SiteIcons.mapPin,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          address,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    if (settings.galleryImages.isNotEmpty)
                      _heroButton(
                        SiteIcons.camera,
                        '${ProjectDetailTexts.gallery} (${settings.galleryImages.length})',
                        () => _openGallery(settings.galleryImages),
                      ),
                    if (settings.brochureUrl case final brochure?) ...[
                      const SizedBox(width: 8),
                      _heroButton(SiteIcons.document, ProjectDetailTexts.brochure, () {
                        final url = absoluteMediaUrl(brochure);
                        if (url != null) {
                          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                        }
                      }),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroButton(SiteIconData icon, String label, VoidCallback onTap) {
    final theme = Theme.of(context);
    return Pressable(
      scale: 0.97,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SiteIcon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openGallery(List<String> images) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.95),
      builder: (dialogContext) => _GalleryModal(images: images),
    );
  }

  // ── qulayliklar ────────────────────────────────────────────────────────────

  Widget _features(ProjectDetail project) {
    final theme = Theme.of(context);
    final settings = project.settings;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 32), // py-8
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (settings.pageDescription case final description?) ...[
            Text(
              description,
              style: theme.textTheme.displaySmall?.copyWith(
                fontSize: 18, // mobilda `text-lg`
                height: 1.6,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 24), // mb-6
          ],
          Pressable(
            scale: 0.98,
            onTap: () => context.go('/new-projects'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.dark,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                ProjectDetailTexts.selectApartment,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          if (settings.features.isNotEmpty) ...[
            const SizedBox(height: 32), // mb-8
            // Mobilda `grid-cols-2 gap-4`.
            _grid(
              columns: 2,
              spacing: 16,
              children: [for (final feature in settings.features) _featureCard(feature)],
            ),
          ],
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

  // ── 3D ko'ruvchi ───────────────────────────────────────────────────────────

  /// Saytda bu `<iframe src="https://3d.businesshome.uz/{dev}/{proj}/?autostart=1">`.
  /// Ilovada ham xuddi shu sahifa, faqat WebView ichida va to'liq ekranda ochiladi.
  Widget _viewer3d(ProjectDetail project) {
    final theme = Theme.of(context);
    final poster = absoluteMediaUrl(project.settings.heroPosterUrl ?? project.coverImage);
    final path = project.developerCode.isEmpty || project.slug.isEmpty
        ? 'test/test'
        : '${project.developerCode}/${project.slug}';
    final url = 'https://3d.businesshome.uz/$path/?autostart=1';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: SizedBox(
          height: 340, // clamp(340px, …)
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (poster != null && poster.isNotEmpty)
                AppImage(imageUrl: poster, fit: BoxFit.cover)
              else
                const ColoredBox(color: AppColors.dark),
              DecoratedBox(
                decoration: BoxDecoration(color: AppColors.dark.withValues(alpha: 0.45)),
              ),
              Center(
                child: Pressable(
                  scale: 0.97,
                  onTap: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute<void>(builder: (_) => _Viewer3dPage(url: url))),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                        ),
                        child: const Center(
                          child: SiteIcon(SiteIcons.box3d, size: 28, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        ProjectDetailTexts.viewer3dView,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 18, // text-lg
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
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

  // ── xususiyatlar (flip kartalar) ───────────────────────────────────────────

  Widget _highlights(List<HighlightCategory> categories) {
    final theme = Theme.of(context);
    return Container(
      color: AppColors.cream,
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 32), // py-8
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ProjectDetailTexts.highlightsTitle,
            style: theme.textTheme.displaySmall?.copyWith(fontSize: 24, color: AppColors.dark),
          ),
          const SizedBox(height: 24),
          for (final category in categories) ...[
            if (category.label.isNotEmpty) ...[
              Text(
                category.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 12),
            ],
            _grid(
              columns: 2,
              spacing: 16, // gap-4
              children: [for (final item in category.items) _FlipCard(item: item)],
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  // ── galereya bo'limlari ────────────────────────────────────────────────────

  Widget _gallerySection(GallerySection section) {
    final theme = Theme.of(context);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (section.label.isNotEmpty) ...[
            Text(
              section.label,
              style: theme.textTheme.displaySmall?.copyWith(fontSize: 24, color: AppColors.dark),
            ),
            const SizedBox(height: 16),
          ],
          for (final image in section.images) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: AppImage(imageUrl: absoluteMediaUrl(image) ?? '', fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  // ── hujjatlar ──────────────────────────────────────────────────────────────

  Widget _documents(DocumentCategory category) {
    final theme = Theme.of(context);
    return Container(
      color: AppColors.cream,
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category.label,
            style: theme.textTheme.displaySmall?.copyWith(fontSize: 24, color: AppColors.dark),
          ),
          const SizedBox(height: 16),
          for (final document in category.documents) ...[
            Pressable(
              scale: 0.99,
              onTap: () {
                final url = absoluteMediaUrl(document.url);
                if (url != null) {
                  launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    const SiteIcon(SiteIcons.document, size: 20, color: AppColors.olive),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        document.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          color: AppColors.dark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  /// Tailwind `grid-cols-N gap-*` ning qo'lda yig'ilgani.
  Widget _grid({required int columns, required List<Widget> children, double spacing = 8}) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final slice = children.sublist(i, (i + columns).clamp(0, children.length));
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: i + columns < children.length ? spacing : 0),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var j = 0; j < columns; j++) ...[
                  Expanded(child: j < slice.length ? slice[j] : const SizedBox.shrink()),
                  if (j < columns - 1) SizedBox(width: spacing),
                ],
              ],
            ),
          ),
        ),
      );
    }
    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }
}

/// Arxitektura va "Smart Home" bo'limlari — yorliqlar va ular ostidagi slaydlar.
class _TabbedSlides extends StatefulWidget {
  const _TabbedSlides({required this.tabs, required this.background});

  final List<ProjectTab> tabs;
  final Color background;

  @override
  State<_TabbedSlides> createState() => _TabbedSlidesState();
}

class _TabbedSlidesState extends State<_TabbedSlides> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = widget.tabs[_tab.clamp(0, widget.tabs.length - 1)];
    return Container(
      color: widget.background,
      padding: const EdgeInsets.fromLTRB(0, 32, 0, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (var i = 0; i < widget.tabs.length; i++) ...[
                  Pressable(
                    scale: 0.98,
                    onTap: () => setState(() => _tab = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: i == _tab ? AppColors.dark : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: i == _tab ? AppColors.dark : AppColors.borderLight,
                        ),
                      ),
                      child: Text(
                        widget.tabs[i].label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: i == _tab ? Colors.white : AppColors.dark.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: current.slides.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) => ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: SizedBox(
                  width: 300,
                  child: AppImage(
                    imageUrl: absoluteMediaUrl(current.slides[index]) ?? '',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Saytdagi "flip" karta — bosilganda orqa tomoni (matn) ko'rinadi.
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
    final theme = Theme.of(context);
    final image = absoluteMediaUrl(widget.item.image);
    return GestureDetector(
      onTap: () => setState(() => _flipped = !_flipped),
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _flipped
              ? Container(
                  key: const ValueKey('back'),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.dark,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Flexible(
                        child: Text(
                          widget.item.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 13,
                            height: 1.5,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Stack(
                  key: const ValueKey('front'),
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      child: image != null && image.isNotEmpty
                          ? AppImage(imageUrl: image, fit: BoxFit.cover)
                          : const ColoredBox(color: AppColors.surfaceMutedLight),
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: Text(
                        widget.item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          shadows: const [Shadow(color: Colors.black54, blurRadius: 6)],
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

/// 3D ko'ruvchi — saytdagi iframe bilan bir xil manzil, to'liq ekranda.
class _Viewer3dPage extends StatefulWidget {
  const _Viewer3dPage({required this.url});

  final String url;

  @override
  State<_Viewer3dPage> createState() => _Viewer3dPageState();
}

class _Viewer3dPageState extends State<_Viewer3dPage> {
  late final WebViewController _controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setBackgroundColor(AppColors.dark)
    ..loadRequest(Uri.parse(widget.url));

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.dark,
    body: Stack(
      children: [
        Positioned.fill(child: WebViewWidget(controller: _controller)),
        Positioned(
          top: MediaQuery.paddingOf(context).top + 12,
          right: 16,
          child: Pressable(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Center(child: SiteIcon(SiteIcons.close, size: 20, color: Colors.white)),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Galereya oynasi — surib ko'riladi, tepada sanoq.
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
    return Stack(
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
          top: MediaQuery.paddingOf(context).top + 12,
          right: 16,
          child: Pressable(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Center(child: SiteIcon(SiteIcons.close, size: 20, color: Colors.white)),
            ),
          ),
        ),
        Positioned(
          bottom: 32,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              '${_index + 1} / ${widget.images.length}',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
