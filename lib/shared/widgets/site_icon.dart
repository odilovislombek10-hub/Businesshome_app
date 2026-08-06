import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

/// One icon from the site, as its literal SVG path data.
///
/// The site draws Lucide-style outlines by hand: a 24×24 viewBox, `stroke-width: 2`, round caps
/// and joins. Keeping the path strings means the shapes are the site's own, not a Material
/// look-alike; [filled] marks the few that are painted rather than stroked.
class SiteIconData {
  const SiteIconData(this.paths, {this.filled = false});

  final List<String> paths;
  final bool filled;
}

/// The icons the home page uses, copied from the templates they appear in.
abstract final class SiteIcons {
  // ── property-card ─────────────────────────────────────────────────────────
  static const box3d = SiteIconData([
    'M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z',
    'M3.27 6.96 12 12.01l8.73-5.05',
    'M12 22.08V12',
  ]);

  static const star = SiteIconData([
    'M12 2l2.39 7.36H22l-6.18 4.49L18.21 21 12 16.51 5.79 21l2.39-7.15L2 9.36h7.61z',
  ], filled: true);

  static const heart = SiteIconData([
    'M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z',
  ]);

  static const mapPin = SiteIconData([
    'M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z',
    'M12 10m-3 0a3 3 0 1 0 6 0a3 3 0 1 0 -6 0',
  ]);

  /// Apartments / rooms — the same house glyph in both stats.
  static const house = SiteIconData([
    'M15 21v-8a1 1 0 0 0-1-1h-4a1 1 0 0 0-1 1v8',
    'M3 10a2 2 0 0 1 .709-1.528l7-5.999a2 2 0 0 1 2.582 0l7 5.999A2 2 0 0 1 21 10v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z',
  ]);

  static const ruler = SiteIconData([
    'M21.3 15.3a2.4 2.4 0 0 1 0 3.4l-2.6 2.6a2.4 2.4 0 0 1-3.4 0L2.7 8.7a2.41 2.41 0 0 1 0-3.4l2.6-2.6a2.41 2.41 0 0 1 3.4 0Z',
    'm14.5 12.5 2-2',
    'm11.5 9.5 2-2',
    'm8.5 6.5 2-2',
    'm17.5 15.5 2-2',
  ]);

  static const building = SiteIconData([
    'M4 4m0 2a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v16a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2z',
    'M9 22v-4h6v4',
    'M8 6h.01',
    'M16 6h.01',
    'M12 6h.01',
  ]);

  static const floors = SiteIconData([
    'M6 22V4a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v18Z',
    'M6 12H4a2 2 0 0 0-2 2v6a2 2 0 0 0 2 2h2',
    'M18 9h2a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2h-2',
    'M10 6h4',
    'M10 10h4',
    'M10 14h4',
    'M10 18h4',
  ]);

  static const arrowRight = SiteIconData(['M5 12h14', 'm12 5 7 7-7 7']);

  // ── header / navigation ───────────────────────────────────────────────────
  static const search = SiteIconData([
    'M11 11m-8 0a8 8 0 1 0 16 0a8 8 0 1 0 -16 0',
    'm21 21-4.3-4.3',
  ]);

  /// The site's filter glyph: three rules with a dot on each.
  static const filters = SiteIconData([
    'M4 6h16',
    'M4 12h16',
    'M4 18h16',
    'M7 6m-1.5 0a1.5 1.5 0 1 0 3 0a1.5 1.5 0 1 0 -3 0',
    'M15 12m-1.5 0a1.5 1.5 0 1 0 3 0a1.5 1.5 0 1 0 -3 0',
    'M10 18m-1.5 0a1.5 1.5 0 1 0 3 0a1.5 1.5 0 1 0 -3 0',
  ]);

  static const menu = SiteIconData(['M4 12h16', 'M4 6h16', 'M4 18h16']);
  static const close = SiteIconData(['M18 6 6 18', 'm6 6 12 12']);
  static const chevronRight = SiteIconData(['m9 18 6-6-6-6']);
  static const chevronLeft = SiteIconData(['m15 18-6-6 6-6']);
  static const chevronDown = SiteIconData(['m6 9 6 6 6-6']);
  static const check = SiteIconData(['M20 6 9 17l-5-5']);
  static const user = SiteIconData([
    'M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2',
    'M12 7m-4 0a4 4 0 1 0 8 0a4 4 0 1 0 -8 0',
  ]);
  static const moon = SiteIconData(['M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9Z']);
  static const globe = SiteIconData([
    'M12 12m-10 0a10 10 0 1 0 20 0a10 10 0 1 0 -20 0',
    'M12 2a14.5 14.5 0 0 0 0 20 14.5 14.5 0 0 0 0-20',
    'M2 12h20',
  ]);
  static const sparkle = SiteIconData([
    'M12 0l2.4 9.6L24 12l-9.6 2.4L12 24l-2.4-9.6L0 12l9.6-2.4L12 0z',
  ], filled: true);

  /// `layout-dashboard` — the four panes the site draws beside "Mening kabinetim".
  static const dashboard = SiteIconData([
    'M3 3m0 1a1 1 0 0 1 1-1h5a1 1 0 0 1 1 1v7a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1z',
    'M14 3m0 1a1 1 0 0 1 1-1h5a1 1 0 0 1 1 1v3a1 1 0 0 1-1 1h-5a1 1 0 0 1-1-1z',
    'M14 12m0 1a1 1 0 0 1 1-1h5a1 1 0 0 1 1 1v7a1 1 0 0 1-1 1h-5a1 1 0 0 1-1-1z',
    'M3 16m0 1a1 1 0 0 1 1-1h5a1 1 0 0 1 1 1v3a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1z',
  ]);

  static const reel = SiteIconData([
    'M3 3m0 5a5 5 0 0 1 5-5h8a5 5 0 0 1 5 5v8a5 5 0 0 1-5 5H8a5 5 0 0 1-5-5z',
    'M10 9.5v5l4-2.5-4-2.5z',
  ]);
}

/// Draws a [SiteIconData] at [size], scaled from the 24×24 viewBox.
class SiteIcon extends StatelessWidget {
  const SiteIcon(this.icon, {super.key, this.size = 16, this.color, this.strokeWidth = 2});

  final SiteIconData icon;
  final double size;
  final Color? color;

  /// The site's outlines are all `stroke-width="2"`; a couple use 2.5 or 3.
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _IconPainter(
          icon: icon,
          color: color ?? IconTheme.of(context).color ?? Colors.black,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _IconPainter extends CustomPainter {
  _IconPainter({required this.icon, required this.color, required this.strokeWidth});

  final SiteIconData icon;
  final Color color;
  final double strokeWidth;

  /// Parsed once per path string — the same geometry is reused across every card.
  static final Map<String, Path> _cache = {};

  static Path _path(String data) => _cache.putIfAbsent(data, () => parseSvgPathData(data));

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    canvas.save();
    canvas.scale(scale);

    final paint = Paint()
      ..color = color
      ..style = icon.filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final data in icon.paths) {
      canvas.drawPath(_path(data), paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_IconPainter old) =>
      old.color != color || old.icon != icon || old.strokeWidth != strokeWidth;
}
