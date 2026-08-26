import '../../core/i18n/translate.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../app/theme.dart';
import '../../core/api/media_url.dart';
import 'entrance.dart';
import 'site_icon.dart';

/// `property-tours.component.ts` — video va 360° tur.
///
/// Yorliqlar faqat mavjud turlar uchun chiqadi; hech biri bo'lmasa karta umuman
/// chizilmaydi (saytda ham `@if (hasAnyTour())`).
class PropertyToursCard extends StatefulWidget {
  const PropertyToursCard({
    super.key,
    required this.propertyId,
    required this.propertyTitle,
    this.videoUrl,
    this.videoThumbnail,
    this.has360Tour = false,
  });

  final int propertyId;
  final String propertyTitle;
  final String? videoUrl;
  final String? videoThumbnail;
  final bool has360Tour;

  bool get hasAnyTour => (videoUrl?.isNotEmpty ?? false) || has360Tour;

  @override
  State<PropertyToursCard> createState() => _PropertyToursCardState();
}

class _PropertyToursCardState extends State<PropertyToursCard> {
  late String _tab = (widget.videoUrl?.isNotEmpty ?? false) ? 'video' : '360';

  @override
  Widget build(BuildContext context) {
    if (!widget.hasAnyTour) return const SizedBox.shrink();
    final tabs = <({String type, String label, String icon})>[
      if (widget.videoUrl?.isNotEmpty ?? false)
        (type: 'video', label: t('tours.video'), icon: '🎬'),
      if (widget.has360Tour) (type: '360', label: t('tours.360'), icon: '🌐'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.surfaceMutedLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Row(children: [for (final tab in tabs) Expanded(child: _tabButton(tab))]),
          Padding(
            padding: const EdgeInsets.all(20), // p-5
            child: _tab == 'video' ? _video() : _tour360(),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(({String type, String label, String icon}) tab) {
    final theme = Theme.of(context);
    final active = _tab == tab.type;
    return Pressable(
      onTap: () => setState(() => _tab = tab.type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14), // py-3.5
        decoration: BoxDecoration(
          color: active ? Colors.white : AppColors.surfaceAltLight.withValues(alpha: 0.3),
          border: Border(
            bottom: BorderSide(color: active ? AppColors.olive : Colors.transparent, width: 2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(tab.icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 8), // gap-2
            Text(
              tab.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: active ? AppColors.olive : AppColors.dark.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _video() {
    final url = absoluteMediaUrl(widget.videoUrl);
    if (url == null || url.isEmpty) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ColoredBox(
          color: Colors.black,
          child: _TourVideo(url: url, poster: absoluteMediaUrl(widget.videoThumbnail)),
        ),
      ),
    );
  }

  Widget _tour360() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32), // py-8
      child: Column(
        children: [
          Container(
            width: 80, // w-20
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.olive.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(child: SiteIcon(SiteIcons.globe, size: 32, color: AppColors.olive)),
          ),
          const SizedBox(height: 16), // mb-4
          Text(
            t('tours.360Title'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 8), // mb-2
          Text(
            t('tours.360Desc'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              color: AppColors.dark.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16), // mb-4
          Pressable(
            scale: 0.98,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    _PanoramaPage(propertyId: widget.propertyId, title: widget.propertyTitle),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), // px-6 py-3
              decoration: BoxDecoration(
                color: AppColors.olive,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                t('tours.start360'),
                style: theme.textTheme.bodyMedium?.copyWith(
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
}

class _TourVideo extends StatefulWidget {
  const _TourVideo({required this.url, this.poster});

  final String url;
  final String? poster;

  @override
  State<_TourVideo> createState() => _TourVideoState();
}

class _TourVideoState extends State<_TourVideo> {
  late final VideoPlayerController _controller = VideoPlayerController.networkUrl(
    Uri.parse(widget.url),
  );
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller.initialize().then((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Center(child: CircularProgressIndicator(color: AppColors.olive));
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
        ),
        // Saytdagi `controls` atributining o'rni — bosilganda o'ynaydi/to'xtaydi.
        GestureDetector(
          onTap: () => setState(() {
            _controller.value.isPlaying ? _controller.pause() : _controller.play();
          }),
          child: ColoredBox(
            color: Colors.transparent,
            child: _controller.value.isPlaying
                ? const SizedBox.expand()
                : const Center(child: SiteIcon(SiteIcons.play, size: 48, color: Colors.white)),
          ),
        ),
      ],
    );
  }
}

/// 360° tur — saytda bu o'z panorama ko'ruvchisi bilan ochiladi. Ilovada shu
/// sahifaning o'zi WebView ichida ko'rsatiladi, chunki panoramalar va ularning
/// nuqtalari saytning ichida turadi.
class _PanoramaPage extends StatefulWidget {
  const _PanoramaPage({required this.propertyId, required this.title});

  final int propertyId;
  final String title;

  @override
  State<_PanoramaPage> createState() => _PanoramaPageState();
}

class _PanoramaPageState extends State<_PanoramaPage> {
  late final WebViewController _controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setBackgroundColor(AppColors.dark)
    ..loadRequest(Uri.parse('https://businesshome.uz/property/secondary/${widget.propertyId}'));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28, // w-7
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.olive.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Center(
                      child: SiteIcon(SiteIcons.globe, size: 16, color: AppColors.olive),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.cream,
                          ),
                        ),
                        Text(
                          t('tours.360Title'),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            color: AppColors.cream.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Pressable(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: SiteIcon(SiteIcons.close, size: 16, color: AppColors.cream),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: WebViewWidget(controller: _controller)),
          ],
        ),
      ),
    );
  }
}
