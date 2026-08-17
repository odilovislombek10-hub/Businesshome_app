import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/theme.dart';
import '../../core/models/market_user.dart';
import '../../shared/widgets/app_image.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/site_icon.dart';
import 'cabinet_repository.dart';
import 'cabinet_texts.dart';

/// Kabinetning `reels` bo'limi (dizayner/usta) — saytdagi `reelsTpl`.
///
/// Sarlavha va yuklash tugmasi, ko'k moderatsiya eslatmasi, ostida 9:16 kartalar to'ri.
/// Har kartada moderatsiya nishonchasi, o'chirish tugmasi, sarlavha, rad etilgan bo'lsa sabab
/// va "Qayta yuborish", pastda ko'rishlar va yoqtirishlar.
class CabinetReels extends StatefulWidget {
  const CabinetReels({
    super.key,
    required this.future,
    required this.role,
    required this.onChanged,
  });

  final Future<List<MyReel>> future;

  /// Yuklashda `kind` sifatida ketadi — saytda dizayner/usta uchun qo'shiladi.
  final MarketRole role;
  final VoidCallback onChanged;

  @override
  State<CabinetReels> createState() => _CabinetReelsState();
}

class _CabinetReelsState extends State<CabinetReels> {
  final _repo = const CabinetRepository();
  bool _uploading = false;

  Future<void> _upload() async {
    if (_uploading) return;
    final messenger = ScaffoldMessenger.of(context);
    final file = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (file == null) return;

    if (await file.length() > 100 * 1024 * 1024) {
      messenger.showSnackBar(const SnackBar(content: Text(CabinetTexts.reelTooBig)));
      return;
    }

    // Saytda sarlavha `prompt()` bilan so'raladi; standart qiymat — fayl nomi.
    final suggested = file.name.replaceAll(RegExp(r'\.[^.]+$'), '');
    if (!mounted) return;
    final title = await _askTitle(suggested);
    if (title == null || title.trim().isEmpty) return;

    setState(() => _uploading = true);
    try {
      await _repo.uploadReel(
        path: file.path,
        title: title.trim(),
        kind: widget.role == MarketRole.designer || widget.role == MarketRole.master
            ? widget.role.wire
            : null,
      );
      messenger.showSnackBar(const SnackBar(content: Text(CabinetTexts.reelSent)));
      widget.onChanged();
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text(CabinetTexts.reelUploadError)));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<String?> _askTitle(String suggested) {
    final controller = TextEditingController(text: suggested);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(CabinetTexts.reelTitlePrompt),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(CabinetTexts.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text(CabinetTexts.reelUpload),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(MyReel reel) async {
    final messenger = ScaffoldMessenger.of(context);
    final agreed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text('"${reel.title}" — reelni o\'chirmoqchimisiz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(CabinetTexts.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              CabinetTexts.deleteConfirmYes,
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (agreed != true) return;
    try {
      await _repo.deleteReel(reel.id);
      widget.onChanged();
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text(CabinetTexts.portfolioRemoveError)));
    }
  }

  Future<void> _resubmit(MyReel reel) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repo.resubmitReel(reel.id);
      widget.onChanged();
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text(CabinetTexts.reelUploadError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<MyReel>>(
      future: widget.future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.olive));
        }
        if (snapshot.hasError) {
          return ErrorView(message: CabinetTexts.reelsLoadError, onRetry: widget.onChanged);
        }
        final reels = snapshot.data ?? const <MyReel>[];

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        CabinetTexts.tabLabel('reels'),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 20, // text-xl
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark,
                        ),
                      ),
                      const SizedBox(height: 2), // mt-0.5
                      Text(
                        CabinetTexts.reelsSubtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.dark.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12), // gap-3
                _uploadButton(theme),
              ],
            ),
            const SizedBox(height: 16), // space-y-4
            _moderationNote(theme),
            const SizedBox(height: 16),
            if (reels.isEmpty)
              _emptyCard(theme)
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  // `grid-cols-2 gap-3`
                  final width = (constraints.maxWidth - 12) / 2;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final reel in reels) SizedBox(width: width, child: _card(theme, reel)),
                    ],
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _uploadButton(ThemeData theme) => Pressable(
    onTap: _uploading ? null : _upload,
    child: Opacity(
      opacity: _uploading ? 0.5 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // px-4 py-2
        decoration: BoxDecoration(
          color: AppColors.olive,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_uploading) ...[
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              const SizedBox(width: 8), // gap-2
            ],
            Text(
              _uploading ? CabinetTexts.reelUploading : '+ ${CabinetTexts.reelUpload}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  /// `border-blue-100 bg-blue-50 text-blue-800`
  Widget _moderationNote(ThemeData theme) => Container(
    padding: const EdgeInsets.all(16), // p-4
    decoration: BoxDecoration(
      color: const Color(0xFFEFF6FF), // bg-blue-50
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: const Color(0xFFDBEAFE)), // border-blue-100
    ),
    child: Text(
      CabinetTexts.reelsModerationNote,
      style: theme.textTheme.labelSmall?.copyWith(
        fontSize: 12, // text-xs
        height: 1.5,
        color: const Color(0xFF1E40AF), // text-blue-800
      ),
    ),
  );

  Widget _card(ThemeData theme, MyReel reel) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.lg), // rounded-2xl
      border: Border.all(color: AppColors.borderLight),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 9 / 16, // aspect-[9/16]
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: const Color(0xFF111827), // bg-gray-900
                child: reel.thumbnail == null
                    ? const Center(child: SiteIcon(SiteIcons.reel, size: 32, color: Colors.white24))
                    : AppImage(imageUrl: reel.thumbnail!, fit: BoxFit.cover),
              ),
              if (CabinetTexts.reelStatus(reel.moderationStatus) case final status?)
                Positioned(
                  top: 8, // top-2 left-2
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: status.$2,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      status.$1,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: 8,
                right: 8,
                child: Pressable(
                  onTap: () => _delete(reel),
                  child: Container(
                    width: 28, // w-7 h-7
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xE6FFFFFF), // bg-white/90
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Center(
                      child: SiteIcon(SiteIcons.trash, size: 14, color: Color(0xFFEF4444)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12), // p-3
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reel.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark,
                ),
              ),
              if (reel.rejectedReason case final reason?) ...[
                const SizedBox(height: 4), // mt-1
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${CabinetTexts.reelRejectReason}: ',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: reason),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 12,
                    color: const Color(0xFFDC2626), // text-red-600
                  ),
                ),
                const SizedBox(height: 8), // mt-2
                GestureDetector(
                  onTap: () => _resubmit(reel),
                  child: Text(
                    CabinetTexts.reelResubmit,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.olive,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 6), // mt-1.5
              Text(
                '${reel.playCount} ${CabinetTexts.reelViews} · ${reel.likeCount} ♥',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10, // text-[10px]
                  color: AppColors.dark.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _emptyCard(ThemeData theme) => Container(
    padding: const EdgeInsets.all(48), // p-12
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: AppColors.borderLight),
    ),
    child: Column(
      children: [
        SiteIcon(SiteIcons.reel, size: 64, color: AppColors.dark.withValues(alpha: 0.2)),
        const SizedBox(height: 12), // mb-3
        Text(
          CabinetTexts.reelsEmpty,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.dark.withValues(alpha: 0.5)),
        ),
      ],
    ),
  );
}
