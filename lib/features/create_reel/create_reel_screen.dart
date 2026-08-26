import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail_plus/video_thumbnail_plus.dart';

import '../../app/theme.dart';
import '../../core/api/api_client.dart';
import '../../core/models/market_user.dart';
import '../../core/services/auth_service.dart';
import '../../core/api/media_url.dart';
import '../../shared/widgets/app_image.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/site_footer_section.dart';
import '../../shared/widgets/site_header.dart';
import '../../shared/widgets/site_icon.dart';

/// Saytning `/reels/create` sahifasi — `create-reel.component.ts`.
///
/// Uch bo'lim: video, e'lonni biriktirish, ma'lumotlar. Yuborilgan reel darrov chiqmaydi —
/// admin tekshiruvidan keyin e'lon qilinadi, shuning uchun oxirida "Reel yuborildi!" ekrani
/// ko'rsatiladi.
///
/// Backend `kind` ni biriktirilgan e'londan oladi (`entityId` saqlanmaydi) — saytdagi izohda
/// ham shunday yozilgan.
class CreateReelScreen extends StatefulWidget {
  const CreateReelScreen({super.key});

  @override
  State<CreateReelScreen> createState() => _CreateReelScreenState();
}

class _CreateReelScreenState extends State<CreateReelScreen> {
  final _scroll = ScrollController();
  final _title = TextEditingController();
  final _subtitle = TextEditingController();

  File? _video;
  VideoPlayerController? _player;
  int _videoDuration = 0;
  int _videoSize = 0;

  /// Videodan olingan kadr — saytda `thumbFile`, `POST` da `thumbnail` maydoni.
  File? _thumb;
  String? _videoName;
  List<_MyListing> _listings = const [];
  _MyListing? _attached;

  bool _scrolled = false;
  bool _listingsLoading = true;
  bool _submitting = false;
  bool _published = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final scrolled = _scroll.offset > 10;
      if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
    });
    _loadListings();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _title.dispose();
    _subtitle.dispose();
    super.dispose();
  }

  /// Biriktirish uchun ro'yxat: dizayner va ustada — o'z profili, qolganlarda
  /// e'lonlari (saytdagi `loadAttachables`).
  Future<void> _loadListings() async {
    final role = context.read<AuthService>().user?.role;
    if (role == MarketRole.designer || role == MarketRole.master) {
      await _loadOwnProfile(role == MarketRole.designer ? 'designer' : 'master');
      return;
    }
    try {
      final res = await ApiClient.instance.get<dynamic>('/market/my-listings/me');
      final data = res.data;
      final items = data is Map ? data['items'] : data;
      if (!mounted) return;
      setState(() {
        _listings = [
          for (final row in (items is List ? items : const []))
            if (row is Map) _MyListing.fromJson(row),
        ];
        _listingsLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _listingsLoading = false);
    }
  }

  Future<void> _loadOwnProfile(String kind) async {
    try {
      final res = await ApiClient.instance.get<dynamic>('/market/cabinet/specialist-profile');
      final data = res.data;
      if (!mounted) return;
      setState(() {
        _listings = data is Map
            ? [
                _MyListing(
                  id: (data['id'] as num?)?.toInt() ?? 0,
                  title:
                      (data['fullName'] ?? data['full_name'] ?? data['name'])?.toString() ??
                      CreateReelTexts.attachProfile,
                  kind: kind,
                  coverImage:
                      (data['avatar'] ??
                              (data['portfolio'] is List && (data['portfolio'] as List).isNotEmpty
                                  ? (data['portfolio'] as List).first
                                  : null))
                          ?.toString(),
                ),
              ]
            : const [];
        _listingsLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _listingsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAltLight,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scroll,
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 96 + MediaQuery.paddingOf(context).top, 16, 0),
                sliver: SliverList.list(children: _published ? _successView() : _form()),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 64)),
              const SliverToBoxAdapter(child: SiteFooterSection()),
            ],
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

  // ── muvaffaqiyat ekrani ────────────────────────────────────────────────────

  List<Widget> _successView() {
    final theme = Theme.of(context);
    return [
      Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: Color(0xFFD1FAE5), shape: BoxShape.circle),
              child: const Center(
                child: SiteIcon(
                  SiteIcons.check,
                  size: 28,
                  color: Color(0xFF059669),
                  strokeWidth: 3,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              CreateReelTexts.successTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              CreateReelTexts.successText,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                color: AppColors.dark.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            _primaryButton(CreateReelTexts.successView, () => context.go('/reels')),
            const SizedBox(height: 8),
            _secondaryButton(CreateReelTexts.successAgain, () {
              setState(() {
                _published = false;
                _video = null;
                _videoName = null;
                _attached = null;
                _title.clear();
                _subtitle.clear();
              });
            }),
          ],
        ),
      ),
    ];
  }

  // ── forma ──────────────────────────────────────────────────────────────────

  List<Widget> _form() {
    final theme = Theme.of(context);
    return [
      Text(
        CreateReelTexts.title,
        style: theme.textTheme.displaySmall?.copyWith(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: AppColors.dark,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        CreateReelTexts.subtitle,
        style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.dark.withValues(alpha: 0.6)),
      ),
      const SizedBox(height: 32),
      if (_error case final message?) ...[
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: const Color(0xFFFECACA)),
          ),
          child: Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              color: const Color(0xFFDC2626),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
      Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section(CreateReelTexts.sectionVideo, CreateReelTexts.required, _videoSection()),
            const Divider(height: 1, color: AppColors.borderLight),
            _section(CreateReelTexts.sectionAttach, CreateReelTexts.optional, _attachSection()),
            const Divider(height: 1, color: AppColors.borderLight),
            _section(CreateReelTexts.sectionDetails, CreateReelTexts.required, _detailsSection()),
            const Divider(height: 1, color: AppColors.borderLight),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _preview(),
                  const SizedBox(height: 16),
                  _hint(CreateReelTexts.moderationNote),
                  const SizedBox(height: 16),
                  _primaryButton(
                    _submitting ? CreateReelTexts.publishing : CreateReelTexts.publish,
                    _submitting ? null : _submit,
                  ),
                  const SizedBox(height: 8),
                  _secondaryButton(CreateReelTexts.cancel, () => context.go('/reels')),
                ],
              ),
            ),
          ],
        ),
      ),
    ];
  }

  /// Bo'lim sarlavhasi va "Majburiy/Ixtiyoriy" belgisi.
  Widget _section(String title, String badge, List<Widget> children) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: badge == CreateReelTexts.required
                      ? AppColors.olive.withValues(alpha: 0.1)
                      : AppColors.surfaceMutedLight,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  badge,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: badge == CreateReelTexts.required
                        ? AppColors.olive
                        : AppColors.dark.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  List<Widget> _videoSection() {
    final theme = Theme.of(context);
    if (_video == null || _player?.value.isInitialized != true) {
      return [
        // `border-2 border-dashed rounded-2xl p-10`
        Pressable(
          scale: 0.99,
          onTap: _pickVideo,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(40), // p-10
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.borderLight, width: 2),
            ),
            child: Column(
              children: [
                Container(
                  width: 64, // w-16
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.olive.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: SiteIcon(SiteIcons.video, size: 28, color: AppColors.olive),
                  ),
                ),
                const SizedBox(height: 12), // gap-3
                Text(
                  CreateReelTexts.videoDropHere,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 4), // mb-1
                Text(
                  '${CreateReelTexts.videoMaxDuration} · ${CreateReelTexts.videoFormat}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 12,
                    color: AppColors.dark.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 16), // mt-1 + gap-3
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.olive,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    CreateReelTexts.videoSelectFile,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return [
      ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: ColoredBox(
            color: Colors.black,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: AspectRatio(
                    aspectRatio: _player!.value.aspectRatio,
                    child: VideoPlayer(_player!),
                  ),
                ),
                Positioned(
                  top: 12, // top-3 left-3
                  left: 12,
                  child: Row(
                    children: [
                      _videoChip(theme, _formatDuration(_videoDuration)),
                      const SizedBox(width: 8),
                      _videoChip(theme, _formatSize(_videoSize)),
                    ],
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Pressable(
                    onTap: _removeVideo,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDC2626),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: SiteIcon(SiteIcons.close, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 12), // space-y-3
      // Muqova kadri
      Row(
        children: [
          if (_thumb case final thumb?) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Image.file(thumb, width: 48, height: 64, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12), // gap-3
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  CreateReelTexts.coverTitle,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark.withValues(alpha: 0.8),
                  ),
                ),
                Text(
                  CreateReelTexts.coverHint,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    color: AppColors.dark.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Pressable(
            onTap: _captureCover,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.olive.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                CreateReelTexts.captureCover,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.olive,
                ),
              ),
            ),
          ),
        ],
      ),
    ];
  }

  /// Saytdagi "LIVE PREVIEW" — 9:16 telefon ramkasi, ustida reels lentasidagi
  /// kabi qatlamlar. Mobilda formadan keyin turadi (`grid-cols-1`).
  Widget _preview() {
    final theme = Theme.of(context);
    final title = _title.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          CreateReelTexts.previewTitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.dark.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 12), // mb-3
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260), // max-w-[260px]
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32), // rounded-[2rem]
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: ColoredBox(
                  color: Colors.black,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_player?.value.isInitialized == true)
                        FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _player!.value.size.width,
                            height: _player!.value.size.height,
                            child: VideoPlayer(_player!),
                          ),
                        )
                      else
                        Center(
                          child: Text(
                            CreateReelTexts.previewEmpty,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      // `bg-gradient-to-t from-black via-black/50 to-transparent`
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 200,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black,
                                Colors.black.withValues(alpha: 0.5),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 12, // p-3
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_attached?.kindBadge case final badge?) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.olive.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(AppRadius.pill),
                                ),
                                child: Text(
                                  badge,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6), // mb-1.5
                            ],
                            Text(
                              title.isEmpty ? CreateReelTexts.previewTitlePlaceholder : title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8), // mt-2
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Text(
                                'Batafsil',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.dark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _videoChip(ThemeData theme, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(AppRadius.sm),
    ),
    child: Text(
      text,
      style: theme.textTheme.labelSmall?.copyWith(fontSize: 11, color: Colors.white),
    ),
  );

  static String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  static String _formatSize(int bytes) => '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';

  void _removeVideo() {
    setState(() {
      _player?.dispose();
      _player = null;
      _video = null;
      _videoName = null;
      _thumb = null;
    });
  }

  /// `captureCover()` — joriy kadrni muqova qilib oladi. Saytda kadr `canvas`
  /// ga chiziladi, bu yerda esa videodan kadr ajratuvchi paket bilan.
  Future<void> _captureCover() async {
    final video = _video;
    if (video == null) return;
    final position = _player?.value.position.inMilliseconds ?? 0;
    final path = await VideoThumbnailPlus.thumbnailFile(
      video: video.path,
      imageFormat: ImageFormat.JPEG,
      timeMs: position,
      quality: 80,
    );
    if (path == null || !mounted) return;
    setState(() => _thumb = File(path));
  }

  Future<void> _pickVideo() async {
    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked == null) return;
    final file = File(picked.path);
    final size = await file.length();
    if (size > 100 * 1024 * 1024) {
      setState(() => _error = CreateReelTexts.videoErrorSize);
      return;
    }
    final controller = VideoPlayerController.file(file);
    try {
      await controller.initialize();
    } catch (_) {
      await controller.dispose();
      if (!mounted) return;
      setState(() => _error = CreateReelTexts.videoErrorRead);
      return;
    }
    final duration = controller.value.duration.inSeconds;
    if (duration > 60) {
      await controller.dispose();
      if (!mounted) return;
      setState(() => _error = CreateReelTexts.videoErrorDuration(duration));
      return;
    }
    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() {
      _player?.dispose();
      _player = controller
        ..setLooping(true)
        ..setVolume(0)
        ..play();
      _video = file;
      _videoName = picked.name;
      _videoDuration = duration;
      _videoSize = size;
      _error = null;
    });
    // Saytda video yuklangach muqova o'zi olinadi (`if (!thumbFile()) captureCover()`).
    await _captureCover();
  }

  List<Widget> _attachSection() {
    final theme = Theme.of(context);
    if (_listingsLoading) {
      return [_hint(CreateReelTexts.attachLoading)];
    }
    if (_listings.isEmpty) {
      return [_hint(CreateReelTexts.attachEmpty)];
    }
    return [
      _hint(CreateReelTexts.attachHint),
      const SizedBox(height: 12),
      for (final listing in [null, ..._listings])
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Pressable(
            scale: 0.99,
            onTap: () => setState(() => _attached = listing),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _attached == listing
                    ? AppColors.olive.withValues(alpha: 0.08)
                    : AppColors.surfaceAltLight,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: _attached == listing ? AppColors.olive : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  if (listing != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: switch (absoluteMediaUrl(listing.coverImage)) {
                          final image? when image.isNotEmpty => AppImage(
                            imageUrl: image,
                            fit: BoxFit.cover,
                          ),
                          _ => const ColoredBox(color: AppColors.surfaceMutedLight),
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      listing?.title ?? CreateReelTexts.attachNone,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.dark,
                      ),
                    ),
                  ),
                  // Nishoncha faqat e'londa bo'ladi; mutaxassis profilida yo'q.
                  if (listing?.kindBadge case final badge?)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: listing!.kind == 'rent'
                            ? const Color(0xFFDBEAFE)
                            : AppColors.olive.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        badge,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: listing.kind == 'rent' ? const Color(0xFF1D4ED8) : AppColors.olive,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
    ];
  }

  List<Widget> _detailsSection() => [
    _label(CreateReelTexts.titleLabel),
    const SizedBox(height: 8),
    _input(_title, hint: CreateReelTexts.titlePlaceholder),
    const SizedBox(height: 20),
    _label(CreateReelTexts.subtitleLabel),
    const SizedBox(height: 8),
    _input(_subtitle, hint: CreateReelTexts.subtitlePlaceholder, lines: 3),
  ];

  Future<void> _submit() async {
    if (_video == null) {
      setState(() => _error = CreateReelTexts.needVideo);
      return;
    }
    if (_title.text.trim().length < 3) {
      setState(() => _error = CreateReelTexts.needTitle);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final form = FormData();
      form.fields.add(MapEntry('title', _title.text.trim()));
      final subtitle = _subtitle.text.trim();
      if (subtitle.isNotEmpty) form.fields.add(MapEntry('subtitle', subtitle));
      if (_attached?.kind case final kind?) form.fields.add(MapEntry('kind', kind));
      form.files.add(
        MapEntry(
          'video',
          await MultipartFile.fromFile(_video!.path, filename: _videoName ?? 'reel.mp4'),
        ),
      );
      // Saytda muqova kadri ham shu so'rovda ketadi (`thumbnail`).
      if (_thumb case final thumb?) {
        form.files.add(
          MapEntry('thumbnail', await MultipartFile.fromFile(thumb.path, filename: 'cover.jpg')),
        );
      }

      final res = await ApiClient.instance.post<dynamic>('/market/cabinet/reels', data: form);
      if (!mounted) return;
      if (res.statusCode != 200 && res.statusCode != 201) {
        final data = res.data;
        setState(() {
          _submitting = false;
          _error = data is Map && data['detail'] != null
              ? data['detail'].toString()
              : CreateReelTexts.errorGeneric;
        });
        return;
      }
      setState(() {
        _submitting = false;
        _published = true;
      });
      _scroll.jumpTo(0);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = CreateReelTexts.errorGeneric;
      });
    }
  }

  // ── umumiy bo'laklar ──────────────────────────────────────────────────────

  Widget _label(String text) => Text(
    text,
    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.dark,
    ),
  );

  Widget _hint(String text) => Text(
    text,
    style: Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(fontSize: 12, color: AppColors.dark.withValues(alpha: 0.4)),
  );

  Widget _input(TextEditingController controller, {required String hint, int lines = 1}) {
    final theme = Theme.of(context);
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: color),
    );
    return TextField(
      controller: controller,
      maxLines: lines,
      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15, color: AppColors.dark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          fontSize: 15,
          color: AppColors.dark.withValues(alpha: 0.3),
        ),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: border(AppColors.borderLight),
        enabledBorder: border(AppColors.borderLight),
        focusedBorder: border(AppColors.olive),
      ),
    );
  }

  Widget _primaryButton(String label, VoidCallback? onTap) {
    final theme = Theme.of(context);
    return Pressable(
      scale: 0.98,
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.6 : 1,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.olive,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _secondaryButton(String label, VoidCallback onTap) {
    final theme = Theme.of(context);
    return Pressable(
      scale: 0.98,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.dark.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

/// `uz.ts` dagi `createReel.*` kalitlari.
abstract final class CreateReelTexts {
  static const title = 'Reel yaratish';
  static const subtitle = "Ko'chmas mulk videongizni yuklang va e'lon qiling";
  static const sectionVideo = 'Video';
  static const sectionAttach = "E'lonni biriktirish";
  static const sectionDetails = "Ma'lumotlar";
  static const required = 'Majburiy';
  static const optional = 'Ixtiyoriy';
  static const titleLabel = 'Sarlavha';
  static const titlePlaceholder = 'Masalan: Markazda yangi kvartira';
  static const subtitleLabel = "Qo'shimcha matn";
  static const subtitlePlaceholder = 'Qisqa tavsif (ixtiyoriy)';
  static const attachHint = "Reelni o'z e'loningizga bog'lang (ixtiyoriy)";
  static const attachLoading = 'Yuklanmoqda...';
  static const attachEmpty = "Biriktiriladigan e'lon topilmadi";
  static const attachNone = 'Biriktirmaslik';
  static const badgeRent = 'Ijara';
  static const badgeSale = 'Sotuv';
  static const previewEmpty = 'Video yuklang';
  static const moderationNote = "Reel admin tekshiruvidan so'ng e'lon qilinadi";
  static const coverTitle = 'Muqova rasmi';
  static const coverHint = 'Videodan kadr oling yoki avtomatik tanlanadi';
  static const captureCover = 'Kadr olish';
  static const previewTitle = "Ko'rinishi";
  static const previewTitlePlaceholder = 'Reel sarlavhasi';
  static const attachProfile = 'Mening profilim';
  static const videoDropHere = 'Videoni bu yerga tashlang yoki bosing';
  static const videoSelectFile = 'Kompyuterdan tanlash';
  static const videoMaxDuration = 'Maksimal davomiylik: 60 sekund';
  static const videoFormat = 'Format: MP4, vertikal (9:16)';
  static const videoErrorSize = "Video hajmi 100 MB dan kam bo'lishi kerak";
  static const videoErrorRead = "Videoni o'qib bo'lmadi. Boshqa fayl sinab ko'ring";
  static String videoErrorDuration(int seconds) =>
      "Video $seconds sekund — 60 sekunddan ko'p bo'lmasligi kerak";
  static const needVideo = 'Avval video yuklang';
  static const needTitle = "Sarlavha kamida 3 ta belgi bo'lishi kerak";
  static const publish = "E'lon qilish";
  static const publishing = 'Yuklanmoqda...';
  static const cancel = 'Bekor qilish';
  static const errorGeneric = "Xatolik yuz berdi. Qayta urinib ko'ring";
  static const successTitle = 'Reel yuborildi!';
  static const successText = "Admin tekshiruvidan so'ng e'lon qilinadi";
  static const successView = "Reellarni ko'rish";
  static const successAgain = 'Yana yaratish';
}

/// Biriktirish uchun foydalanuvchining e'loni.
class _MyListing {
  const _MyListing({required this.id, required this.kind, required this.title, this.coverImage});

  final int id;
  final String kind;
  final String title;
  final String? coverImage;

  /// Ko'rinishdagi nishoncha — saytdagi `badge()`.
  String? get kindBadge => switch (kind) {
    'rent' => CreateReelTexts.badgeRent,
    'secondary' => CreateReelTexts.badgeSale,
    _ => null,
  };

  factory _MyListing.fromJson(Map row) => _MyListing(
    id: (row['id'] as num?)?.toInt() ?? 0,
    kind: row['kind']?.toString() ?? 'secondary',
    title: row['title']?.toString() ?? '',
    coverImage: row['cover_image']?.toString(),
  );
}
