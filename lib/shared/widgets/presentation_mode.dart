import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../app/theme.dart';
import '../../features/project_detail/project_detail_texts.dart';
import 'entrance.dart';
import 'site_icon.dart';

/// `presentation-mode.component.ts` — sahifani sekin o'zi suradi, oxirida 3D ochadi.
///
/// Saytda `?present=1` bilan yoqiladi. Pastda boshqaruv paneli turadi:
/// foiz, pauza/davom, "3D ko'rinish" va chiqish.
class PresentationMode extends StatefulWidget {
  const PresentationMode({
    super.key,
    required this.scroll,
    required this.onReveal,
    required this.onExit,
    this.speed = 70, // px/sekund — saytdagi `speed` ning o'zi
  });

  final ScrollController scroll;
  final VoidCallback onReveal;
  final VoidCallback onExit;
  final double speed;

  @override
  State<PresentationMode> createState() => _PresentationModeState();
}

class _PresentationModeState extends State<PresentationMode> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_step);
  Duration? _last;
  bool _paused = false;
  bool _revealed = false;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    // Saytda avval tepaga qaytadi, 0.6 soniyadan keyin suriladi.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.scroll.hasClients) return;
      widget.scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
      Future<void>.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _ticker.start();
      });
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _step(Duration elapsed) {
    if (_paused || !widget.scroll.hasClients) return;
    final last = _last ?? elapsed;
    _last = elapsed;
    final dt = ((elapsed - last).inMicroseconds / 1000000).clamp(0.0, 0.05);

    final max = widget.scroll.position.maxScrollExtent;
    final next = (widget.scroll.offset + widget.speed * dt).clamp(0.0, max);
    widget.scroll.jumpTo(next);

    final percent = max > 0 ? ((next / max) * 100).round() : 100;
    if (percent != _progress) setState(() => _progress = percent);

    if (next >= max - 2 && !_revealed) {
      _revealed = true;
      _ticker.stop();
      widget.onReveal();
    }
  }

  void _togglePause() {
    setState(() => _paused = !_paused);
    _last = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16, // bottom-4
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 448), // max-w-md
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // px-4 py-3
            decoration: BoxDecoration(
              color: AppColors.dark.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Pulse(
                      child: SizedBox(
                        width: 8,
                        height: 8,
                        child: DecoratedBox(
                          decoration: BoxDecoration(color: AppColors.olive, shape: BoxShape.circle),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8), // gap-2
                    Text(
                      ProjectDetailTexts.presentLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$_progress%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10), // mb-2.5
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: _progress / 100,
                    minHeight: 4, // h-1
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.olive),
                  ),
                ),
                const SizedBox(height: 12), // mb-3
                Row(
                  children: [
                    Expanded(
                      child: _button(
                        theme,
                        _paused
                            ? ProjectDetailTexts.presentResume
                            : ProjectDetailTexts.presentPause,
                        background: Colors.white.withValues(alpha: 0.1),
                        onTap: _togglePause,
                      ),
                    ),
                    const SizedBox(width: 8), // gap-2
                    Expanded(
                      child: _button(
                        theme,
                        ProjectDetailTexts.presentView3d,
                        background: AppColors.olive,
                        bold: true,
                        onTap: widget.onReveal,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Pressable(
                      onTap: widget.onExit,
                      child: Container(
                        width: 40, // w-10
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: const Center(
                          child: SiteIcon(SiteIcons.close, size: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _button(
    ThemeData theme,
    String label, {
    required Color background,
    required VoidCallback onTap,
    bool bold = false,
  }) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8), // py-2
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
