import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'site_icon.dart';

/// Saytdagi `toast.service.ts` + `toast.component.ts` ning o'rni.
///
/// Xabar ekranning yuqori o'ng burchagida chiqadi, 5 soniyadan keyin o'zi yo'qoladi
/// (`duration ?? 5000`), rangi turiga qarab: yashil, qizil, sariq yoki ko'k.
enum ToastKind { success, error, warning, info }

void showSiteToast(BuildContext context, String message, {ToastKind kind = ToastKind.success}) {
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _ToastCard(
      message: message,
      kind: kind,
      onClose: () {
        if (entry.mounted) entry.remove();
      },
    ),
  );
  overlay.insert(entry);
  Future<void>.delayed(const Duration(seconds: 5), () {
    if (entry.mounted) entry.remove();
  });
}

class _ToastCard extends StatefulWidget {
  const _ToastCard({required this.message, required this.kind, required this.onClose});

  final String message;
  final ToastKind kind;
  final VoidCallback onClose;

  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// `typeClasses()` — fon, matn va chegara ranglari.
  (Color, Color, Color, SiteIconData) get _palette => switch (widget.kind) {
    ToastKind.success => (
      const Color(0xFFECFDF5), // emerald-50
      const Color(0xFF065F46), // emerald-800
      const Color(0xFFA7F3D0), // emerald-200
      SiteIcons.check,
    ),
    ToastKind.error => (
      const Color(0xFFFEF2F2),
      const Color(0xFF991B1B),
      const Color(0xFFFECACA),
      SiteIcons.xCircle,
    ),
    ToastKind.warning => (
      const Color(0xFFFFFBEB),
      const Color(0xFF92400E),
      const Color(0xFFFDE68A),
      SiteIcons.alertCircle,
    ),
    ToastKind.info => (
      const Color(0xFFEFF6FF),
      const Color(0xFF1E40AF),
      const Color(0xFFBFDBFE),
      SiteIcons.info,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (background, foreground, border, icon) = _palette;
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 16, // top-4
      right: 16,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.3, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut)),
        child: FadeTransition(
          opacity: _controller,
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 384), // max-w-sm
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: border),
                boxShadow: const [
                  BoxShadow(color: Color(0x1A000000), blurRadius: 15, offset: Offset(0, 10)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2), // mt-0.5
                    child: SiteIcon(icon, size: 20, color: foreground),
                  ),
                  const SizedBox(width: 12), // gap-3
                  Flexible(
                    child: Text(
                      widget.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: foreground,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: widget.onClose,
                    child: Opacity(
                      opacity: 0.6,
                      child: SiteIcon(SiteIcons.close, size: 16, color: foreground),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
