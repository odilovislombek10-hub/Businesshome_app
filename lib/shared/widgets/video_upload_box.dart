import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../app/theme.dart';
import 'entrance.dart';
import 'site_icon.dart';

/// Saytdagi "Video Upload (Optional)" bloki — e'lon yaratish va mutaxassis
/// profili sahifalarida bir xil ko'rinadi (`reels.video*` kalitlari).
///
/// Tekshiruvlar ham saytdagidek: faqat MP4/MOV/WebM, 100 MB dan kichik va
/// 60 sekunddan uzun emas.
class VideoUploadBox extends StatefulWidget {
  const VideoUploadBox({super.key, required this.onChanged});

  /// Tanlangan fayl (yoki olib tashlangani) haqida xabar beradi.
  final ValueChanged<File?> onChanged;

  @override
  State<VideoUploadBox> createState() => _VideoUploadBoxState();
}

class _VideoUploadBoxState extends State<VideoUploadBox> {
  static const _maxSize = 100 * 1024 * 1024;
  static const _maxDuration = 60;

  File? _video;
  VideoPlayerController? _controller;
  int _duration = 0;
  int _size = 0;
  bool _uploading = false;
  String? _error;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked == null) return;
    final name = picked.name.toLowerCase();
    if (!(name.endsWith('.mp4') || name.endsWith('.mov') || name.endsWith('.webm'))) {
      setState(() => _error = 'Faqat video fayl yuklash mumkin (MP4, MOV, WebM)');
      return;
    }
    final file = File(picked.path);
    final size = await file.length();
    if (size > _maxSize) {
      setState(() => _error = "Video hajmi 100 MB dan kam bo'lishi kerak");
      return;
    }
    setState(() {
      _uploading = true;
      _error = null;
    });

    final controller = VideoPlayerController.file(file);
    try {
      await controller.initialize();
    } catch (_) {
      await controller.dispose();
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _error = "Videoni o'qib bo'lmadi. Boshqa fayl sinab ko'ring";
      });
      return;
    }

    final duration = controller.value.duration.inSeconds;
    if (duration > _maxDuration) {
      await controller.dispose();
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _error = "Video $duration sekund — 60 sekunddan ko'p bo'lmasligi kerak";
      });
      return;
    }
    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() {
      _controller?.dispose();
      _controller = controller;
      _video = file;
      _duration = duration;
      _size = size;
      _uploading = false;
    });
    widget.onChanged(file);
  }

  void _remove() {
    setState(() {
      _controller?.dispose();
      _controller = null;
      _video = null;
      _error = null;
    });
    widget.onChanged(null);
  }

  static String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  static String _formatSize(int bytes) => '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20), // p-5
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2), // from-red-50
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: const Color(0xFFFEE2E2)), // border-red-100
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(theme),
          const SizedBox(height: 16), // mb-4
          if (_video == null && !_uploading) _dropZone(theme),
          if (_uploading) _uploadingBox(theme),
          if (_video != null && _controller?.value.isInitialized == true) ...[
            _preview(theme),
            const SizedBox(height: 8), // mt-2
            Text(
              'Video muvaffaqiyatli yuklandi',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 12,
                color: const Color(0xFF059669), // emerald-600
              ),
            ),
          ],
          if (_error case final error?) ...[
            const SizedBox(height: 12), // mt-3
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12), // p-3
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Text(
                error,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 12,
                  height: 1.5,
                  color: const Color(0xFFDC2626),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12), // mt-3
          Wrap(
            spacing: 16, // gap-4
            runSpacing: 4,
            children: [
              Text(
                'Maksimal davomiylik: 60 sekund',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  color: AppColors.dark.withValues(alpha: 0.5),
                ),
              ),
              Text(
                'Format: MP4, vertikal (9:16)',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  color: AppColors.dark.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _header(ThemeData theme) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 40, // w-10 h-10
        height: 40,
        decoration: const BoxDecoration(color: Color(0xFFDC2626), shape: BoxShape.circle),
        child: const Center(child: SiteIcon(SiteIcons.video, size: 20, color: Colors.white)),
      ),
      const SizedBox(width: 12), // gap-3
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    'Video yuklash (ixtiyoriy)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 15, // text-[15px]
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                    ),
                  ),
                ),
                const SizedBox(width: 8), // gap-2
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.olive.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    'Reels',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.olive,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4), // mt-1
            Text(
              "Mulkingizni 60 sekundlik video orqali ko'rsating — BusinessHome Reels "
              "bo'limida chiqadi",
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 12,
                height: 1.5,
                color: AppColors.dark.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _dropZone(ThemeData theme) => Pressable(
    scale: 0.99,
    onTap: _pick,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24), // p-6
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: const Color(0xFFFECACA), width: 2), // border-red-200
      ),
      child: Column(
        children: [
          Container(
            width: 48, // w-12
            height: 48,
            decoration: const BoxDecoration(color: Color(0xFFFEE2E2), shape: BoxShape.circle),
            child: const Center(
              child: SiteIcon(SiteIcons.video, size: 22, color: Color(0xFFDC2626)),
            ),
          ),
          const SizedBox(height: 8), // gap-2
          Text(
            'Videoni bu yerga tashlang yoki bosing',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              'Kompyuterdan tanlash',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _uploadingBox(ThemeData theme) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: const Color(0xFFFEE2E2)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFDC2626)),
        ),
        const SizedBox(width: 12), // gap-3
        Flexible(
          child: Text(
            'Video yuklanmoqda va tekshirilmoqda...',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              color: AppColors.dark.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _preview(ThemeData theme) => ClipRRect(
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
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            ),
            Positioned(
              top: 12, // top-3 left-3
              left: 12,
              child: Row(
                children: [
                  _chip(theme, _formatDuration(_duration)),
                  const SizedBox(width: 8), // gap-2
                  _chip(theme, _formatSize(_size)),
                ],
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Pressable(
                onTap: _remove,
                child: Container(
                  width: 32, // w-8
                  height: 32,
                  decoration: const BoxDecoration(color: Color(0xFFDC2626), shape: BoxShape.circle),
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
  );

  Widget _chip(ThemeData theme, String text) => Container(
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
}
