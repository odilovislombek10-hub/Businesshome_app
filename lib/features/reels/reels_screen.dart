import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../app/theme.dart';
import '../../core/api/api_client.dart';
import '../../core/api/media_url.dart';
import '../../core/models/reel.dart';
import '../../core/utils/format.dart';
import '../../shared/widgets/app_image.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/site_icon.dart';

/// Saytning `/reels` va `/reels/:id` sahifasi — `reels.component.ts`.
///
/// Prodda hozircha birorta reel yo'q (`/market/reels` bo'sh ro'yxat qaytaradi), shuning
/// uchun faqat bo'sh holat ko'rilgan. Video paydo bo'lgach tekshiriladi.
///
/// Sayt bu sahifani TikTok uslubida qiladi: to'liq ekran, vertikal "snap" scroll, har bir
/// videoning tepasida to'q gradient va ustida ma'lumot. Faqat joriy ± 1 reel yuklanadi
/// (`shouldRender`), tovush esa boshida o'chiq (`muted = true`).
class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key, this.startId});

  /// `/reels/:id` — shu reeldan boshlanadi.
  final String? startId;

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final _controller = PageController();
  final _players = <int, VideoPlayerController>{};
  final _liked = <String>{};

  List<Reel> _reels = const [];
  bool _loading = true;
  bool _muted = true;
  int _index = 0;
  bool _hintVisible = true;

  @override
  void initState() {
    super.initState();
    // Saytda `document.body.style.overflow = 'hidden'` — mobil ilovada esa to'liq ekran.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _load();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    for (final player in _players.values) {
      player.dispose();
    }
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await ApiClient.instance.get<dynamic>('/market/reels', query: {'limit': 50});
      final data = res.data;
      final reels = <Reel>[
        for (final row in (data is List ? data : const []))
          if (row is Map<String, dynamic>) Reel.fromJson(row),
      ];
      if (!mounted) return;

      // `/reels/:id` — saytdagidek avval to'liq `id` bo'yicha, keyin raqam bo'yicha izlaydi.
      var start = 0;
      if (widget.startId case final startId?) {
        final index = reels.indexWhere(
          (reel) => '${reel.kind}-${reel.id}' == startId || '${reel.id}' == startId,
        );
        if (index >= 0) start = index;
      }

      setState(() {
        _reels = reels;
        _index = start;
        _loading = false;
      });
      if (start > 0) _controller.jumpToPage(start);
      _prepare(start);
      await Future<void>.delayed(const Duration(milliseconds: 3500));
      if (mounted) setState(() => _hintVisible = false);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Joriy va qo'shni videolarni tayyorlaydi, uzoqdagilarni bo'shatadi.
  void _prepare(int index) {
    for (var i = index - 1; i <= index + 1; i++) {
      if (i < 0 || i >= _reels.length || _players.containsKey(i)) continue;
      final url = absoluteMediaUrl(_reels[i].videoUrl);
      if (url == null || url.isEmpty) continue;
      final player = VideoPlayerController.networkUrl(Uri.parse(url));
      _players[i] = player;
      player.initialize().then((_) {
        if (!mounted) return;
        player
          ..setLooping(true)
          ..setVolume(_muted ? 0 : 1);
        if (i == _index) player.play();
        setState(() {});
      });
    }
    for (final key in _players.keys.toList()) {
      if ((key - index).abs() > 1) {
        _players.remove(key)?.dispose();
      }
    }
  }

  void _onPageChanged(int index) {
    _players[_index]?.pause();
    setState(() {
      _index = index;
      _hintVisible = false;
    });
    _prepare(index);
    final player = _players[index];
    if (player != null && player.value.isInitialized) {
      player
        ..seekTo(Duration.zero)
        ..play();
    }
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    for (final player in _players.values) {
      player.setVolume(_muted ? 0 : 1);
    }
  }

  void _togglePlay() {
    final player = _players[_index];
    if (player == null || !player.value.isInitialized) return;
    setState(() => player.value.isPlaying ? player.pause() : player.play());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_loading)
            const Center(child: CircularProgressIndicator(color: Colors.white))
          else if (_reels.isEmpty)
            _empty()
          else
            PageView.builder(
              controller: _controller,
              scrollDirection: Axis.vertical, // `snap-y snap-mandatory`
              itemCount: _reels.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) => _reelPage(_reels[index], index),
            ),
          _topBar(),
        ],
      ),
    );
  }

  Widget _empty() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SiteIcon(
              SiteIcons.video,
              size: 64,
              color: Colors.white.withValues(alpha: 0.6),
              strokeWidth: 1.5,
            ),
            const SizedBox(height: 16), // mb-4
            Text(
              ReelsTexts.empty,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tepadagi qatorda orqaga, "Reels" va tovush tugmasi.
  Widget _topBar() {
    final theme = Theme.of(context);
    return Positioned(
      top: MediaQuery.paddingOf(context).top,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // px-4 py-3
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => context.go('/'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SiteIcon(SiteIcons.chevronLeft, size: 20, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    ReelsTexts.back,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Text(
                'REELS',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5, // tracking-wider
                  color: Colors.white,
                ),
              ),
            ),
            GestureDetector(
              onTap: _toggleMute,
              child: Container(
                width: 36, // w-9 h-9
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SiteIcon(
                    _muted ? SiteIcons.volumeOff : SiteIcons.volumeOn,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reelPage(Reel reel, int index) {
    final player = _players[index];
    final poster = absoluteMediaUrl(reel.thumbnail);

    return GestureDetector(
      onTap: _togglePlay,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Poster har doim video ostida turadi (saytdagidek).
          if (poster != null && poster.isNotEmpty)
            AppImage(imageUrl: poster, fit: BoxFit.cover)
          else
            const ColoredBox(color: Colors.black),
          if (player != null && player.value.isInitialized)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: player.value.size.width,
                height: player.value.size.height,
                child: VideoPlayer(player),
              ),
            ),
          // Pastdagi to'q gradient — matn o'qilishi uchun.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black, Colors.black.withValues(alpha: 0.6), Colors.transparent],
                stops: const [0, 0.25, 0.5],
              ),
            ),
          ),
          if (player != null && player.value.isInitialized && !player.value.isPlaying)
            Center(
              child: Container(
                width: 80, // w-20 h-20
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: const Center(child: SiteIcon(SiteIcons.play, size: 40, color: Colors.white)),
              ),
            ),
          _actions(reel),
          _info(reel),
          if (index == 0 && _hintVisible) _swipeHint(),
        ],
      ),
    );
  }

  /// O'ng tomondagi tugmalar ustuni: yoqtirish, ulashish, chat, info.
  Widget _actions(Reel reel) {
    final theme = Theme.of(context);
    final id = '${reel.kind}-${reel.id}';
    final liked = _liked.contains(id);

    Widget button(SiteIconData icon, String label, VoidCallback onTap, {Color? background}) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 20), // gap-5
          child: GestureDetector(
            onTap: onTap,
            child: Column(
              children: [
                Container(
                  width: 48, // w-12 h-12
                  height: 48,
                  decoration: BoxDecoration(
                    color: background ?? Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: SiteIcon(icon, size: 24, color: Colors.white)),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 11, // text-[11px]
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );

    return Positioned(
      right: 12, // right-3
      bottom: 128, // bottom-32
      child: Column(
        children: [
          button(
            SiteIcons.heart,
            '${_likeCount(id) + (liked ? 1 : 0)}',
            () => setState(() => liked ? _liked.remove(id) : _liked.add(id)),
            background: liked ? const Color(0xFFEF4444) : null,
          ),
          button(SiteIcons.share, ReelsTexts.share, () {
            launchUrl(
              Uri.parse('https://businesshome.uz/reels/$id'),
              mode: LaunchMode.externalApplication,
            );
          }),
          button(
            SiteIcons.chat,
            'Chat',
            () => launchUrl(
              Uri.parse('https://wa.me/998901234567'),
              mode: LaunchMode.externalApplication,
            ),
            background: const Color(0xFF10B981), // bg-emerald-500
          ),
          button(SiteIcons.info, ReelsTexts.info, () => _openTarget(reel)),
        ],
      ),
    );
  }

  /// Saytda yoqtirishlar soni `id` dan hisoblanadi (backendda maydon yo'q).
  int _likeCount(String id) {
    var hash = 0;
    for (final code in id.codeUnits) {
      hash = (hash << 5) - hash + code;
    }
    return hash.abs() % 900 + 100;
  }

  Widget _info(Reel reel) {
    final theme = Theme.of(context);
    final avatar = absoluteMediaUrl(reel.authorAvatar);
    return Positioned(
      left: 0,
      right: 64, // right-16
      bottom: 0,
      child: Padding(
        padding: const EdgeInsets.all(16), // p-4
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (reel.badge case final badge? when badge.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.olive.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  badge,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10, // text-[10px]
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8), // mb-2
            ],
            Row(
              children: [
                ClipOval(
                  child: SizedBox(
                    width: 32, // w-8 h-8
                    height: 32,
                    child: avatar != null && avatar.isNotEmpty
                        ? AppImage(imageUrl: avatar, fit: BoxFit.cover)
                        : ColoredBox(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  reel.author ?? '',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              reel.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 16, // text-base
                fontWeight: FontWeight.w700,
                height: 1.2,
                color: Colors.white,
              ),
            ),
            if (reel.price case final price? when price.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                formatNumber(num.tryParse(price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 18, // text-lg
                  fontWeight: FontWeight.w700,
                  color: AppColors.olive,
                ),
              ),
            ],
            if (reel.location case final location? when location.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  SiteIcon(SiteIcons.mapPin, size: 12, color: Colors.white.withValues(alpha: 0.7)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12), // mb-3
            Pressable(
              scale: 0.98,
              onTap: () => _openTarget(reel),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ReelsTexts.viewDetails,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const SiteIcon(SiteIcons.arrowRight, size: 16, color: AppColors.dark),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _swipeHint() {
    final theme = Theme.of(context);
    return Positioned(
      left: 0,
      right: 0,
      bottom: 16,
      child: Column(
        children: [
          SiteIcon(SiteIcons.chevronUp, size: 24, color: Colors.white.withValues(alpha: 0.6)),
          const SizedBox(height: 4),
          Text(
            ReelsTexts.swipeUp,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  /// Saytdagi `buildRouterLink` — reel turi bo'yicha manzil.
  void _openTarget(Reel reel) {
    final target = switch (reel.kind) {
      'secondary' => '/property/secondary/${reel.entityId}',
      'rent' => '/property/rent/${reel.entityId}',
      'new-project' => '/new-projects',
      'designer' => '/designers',
      'master' => '/masters',
      _ => '/',
    };
    context.go(target);
  }
}

abstract final class ReelsTexts {
  static const empty = "Hozircha videolar yo'q";
  static const back = 'Ortga';
  static const share = 'Ulash';
  static const info = 'Info';
  static const viewDetails = 'Batafsil';
  static const swipeUp = 'Yuqoriga suring';
}
