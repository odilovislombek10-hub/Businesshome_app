import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/theme.dart';
import '../../shared/widgets/app_image.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/error_view.dart';
import 'cabinet_repository.dart';
import 'cabinet_texts.dart';

/// Kabinetning `portfolio` bo'limi (dizayner/usta) — saytdagi `portfolioTpl`.
///
/// Sarlavha va "+ Loyiha qo'shish" tugmasi, ostida kvadrat rasmlar to'ri. Saytda o'chirish
/// tugmasi faqat sichqoncha ustiga kelganda chiqadi; telefonda hover yo'q, shuning uchun u
/// doim ko'rinadi.
class CabinetPortfolio extends StatefulWidget {
  const CabinetPortfolio({super.key, required this.future, required this.onRetry});

  final Future<List<String>> future;
  final VoidCallback onRetry;

  @override
  State<CabinetPortfolio> createState() => _CabinetPortfolioState();
}

class _CabinetPortfolioState extends State<CabinetPortfolio> {
  final _repo = const CabinetRepository();

  /// Yuklangandan keyin ro'yxat shu yerda turadi — API har amaldan so'ng to'liq ro'yxat qaytaradi.
  List<String>? _images;
  bool _busy = false;

  Future<void> _add() async {
    if (_busy) return;
    final messenger = ScaffoldMessenger.of(context);
    final picked = await ImagePicker().pickMultiImage();
    if (picked.isEmpty) return;

    // Saytdagi filtr: 5 MB dan katta fayllar tashlab yuboriladi.
    final paths = <String>[];
    for (final file in picked) {
      if (await file.length() <= 5 * 1024 * 1024) paths.add(file.path);
    }
    if (paths.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text(CabinetTexts.avatarTooBig)));
      return;
    }

    setState(() => _busy = true);
    try {
      final list = await _repo.addPortfolio(paths);
      if (mounted) setState(() => _images = list);
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text(CabinetTexts.portfolioUploadError)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(String url) async {
    final messenger = ScaffoldMessenger.of(context);
    final agreed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text(CabinetTexts.portfolioRemoveConfirm),
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
      final list = await _repo.removePortfolio(url);
      if (mounted) setState(() => _images = list);
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text(CabinetTexts.portfolioRemoveError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<String>>(
      future: widget.future,
      builder: (context, snapshot) {
        if (_images == null && snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.olive));
        }
        if (_images == null && snapshot.hasError) {
          return ErrorView(message: CabinetTexts.portfolioLoadError, onRetry: widget.onRetry);
        }
        final images = _images ?? snapshot.data ?? const <String>[];

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    CabinetTexts.tabLabel('portfolio'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 20, // text-xl
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                    ),
                  ),
                ),
                _addButton(theme),
              ],
            ),
            const SizedBox(height: 16), // space-y-4
            if (images.isEmpty)
              _emptyCard(theme)
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  // `grid-cols-2 gap-3`
                  final size = (constraints.maxWidth - 12) / 2;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [for (final url in images) SizedBox(width: size, child: _tile(url))],
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _addButton(ThemeData theme) => Pressable(
    onTap: _busy ? null : _add,
    child: Opacity(
      opacity: _busy ? 0.5 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // px-4 py-2
        decoration: BoxDecoration(
          color: AppColors.olive,
          borderRadius: BorderRadius.circular(AppRadius.md), // rounded-xl
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_busy) ...[
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              const SizedBox(width: 8), // gap-2
            ],
            Text(
              '+ ${CabinetTexts.addProject}',
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

  /// `aspect-square rounded-xl` — ustida qizil o'chirish tugmasi.
  Widget _tile(String url) => AspectRatio(
    aspectRatio: 1,
    child: Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: ColoredBox(
              color: AppColors.surfaceMutedLight,
              child: AppImage(imageUrl: url, fit: BoxFit.cover),
            ),
          ),
        ),
        Positioned(
          top: 8, // top-2
          right: 8,
          child: Pressable(
            onTap: () => _remove(url),
            child: Container(
              width: 28, // w-7 h-7
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xE6EF4444), // bg-red-500/90
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  '×',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
            ),
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
    child: Center(
      child: Text(
        CabinetTexts.noPortfolio,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.dark.withValues(alpha: 0.5)),
      ),
    ),
  );
}
