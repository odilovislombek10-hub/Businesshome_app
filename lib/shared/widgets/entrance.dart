import 'package:flutter/material.dart';

/// The site's `animate-fade-in` and `animate-slide-up`, both 0.5s ease-out.
///
/// `fadeIn` goes 0→1 opacity; `slideUp` adds a 20px rise. Cards in a list stagger with
/// `animation-delay: (i * 100)ms`, which [delay] reproduces.
class Entrance extends StatefulWidget {
  const Entrance.fadeIn({super.key, required this.child, this.delay = Duration.zero})
    : slide = false;

  const Entrance.slideUp({super.key, required this.child, this.delay = Duration.zero})
    : slide = true;

  final Widget child;
  final Duration delay;

  /// True for `slide-up`, false for the plain fade.
  final bool slide;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  late final Animation<double> _curve = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) {
        final content = Opacity(opacity: _curve.value, child: child);
        if (!widget.slide) return content;
        // `translateY(20px)` easing back to zero.
        return Transform.translate(offset: Offset(0, 20 * (1 - _curve.value)), child: content);
      },
      child: widget.child,
    );
  }
}

/// The site's `active:scale-*` press feedback.
///
/// Tailwind applies the shrink only while the pointer is down; [scale] is the value the element
/// drops to (0.95, 0.9 or 0.98 depending on the button).
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = 0.95,
    this.onTapDown,
  }) : builder = null;

  /// Variant that hands the press state to its child, for cards whose artwork zooms on touch
  /// (`group-hover:scale-105` on the site) rather than the card itself shrinking.
  const Pressable.builder({super.key, required this.builder, required this.onTap, this.onTapDown})
    : child = const SizedBox.shrink(),
      scale = 1;

  final Widget child;
  final Widget Function(BuildContext context, bool pressed)? builder;
  final VoidCallback? onTap;
  final double scale;

  /// Extra hook for widgets that also need the raw press (image-switching zones).
  final VoidCallback? onTapDown;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        setState(() => _down = true);
        widget.onTapDown?.call();
      },
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: widget.builder != null
          ? widget.builder!(context, _down)
          : AnimatedScale(
              scale: _down ? widget.scale : 1,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              child: widget.child,
            ),
    );
  }
}

/// The site's `animate-pulse` — a 2s opacity breathe, used on the assistant's unread dot and the
/// "online" indicator.
class Pulse extends StatefulWidget {
  const Pulse({super.key, required this.child});

  final Widget child;

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      // Tailwind eases between full and half opacity rather than fading out entirely.
      opacity: Tween<double>(
        begin: 1,
        end: 0.5,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: widget.child,
    );
  }
}

/// The `group-hover:scale-105` / `scale-110` zoom the site applies to card artwork.
///
/// There is no hover on a phone, so the same emphasis is given on touch: the image grows while
/// the card is held down.
class ZoomOnPress extends StatelessWidget {
  const ZoomOnPress({super.key, required this.child, required this.pressed, this.scale = 1.05});

  final Widget child;
  final bool pressed;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: pressed ? scale : 1,
      duration: const Duration(milliseconds: 500), // duration-500
      curve: Curves.easeOut,
      child: child,
    );
  }
}
