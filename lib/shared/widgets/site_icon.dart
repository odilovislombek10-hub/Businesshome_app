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

  /// PDF/hujjat fayli — "Shartnoma PDF" kartasida.
  static const document = SiteIconData([
    'M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z',
    'M14 2v6h6',
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

  /// Yangiliklar bo'sh holatidagi gazeta belgisi (heroicons `newspaper`).
  static const newspaper = SiteIconData([
    'M12 7.5h1.5',
    'M12 10.5h1.5',
    'M4.5 13.5h7.5',
    'M4.5 16.5h7.5',
    'M15 7.5h3.375c.621 0 1.125.504 1.125 1.125V18a2.25 2.25 0 0 1-2.25 2.25',
    'M16.5 7.5V18a2.25 2.25 0 0 0 2.25 2.25',
    'M16.5 7.5V4.875c0-.621-.504-1.125-1.125-1.125H4.125C3.504 3.75 3 4.254 3 4.875V18a2.25 2.25 0 0 0 2.25 2.25h13.5',
  ]);

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
  // ── login / register ──────────────────────────────────────────────────────
  /// Logotip kvadrati ichidagi uycha — `login.component.ts` dagi aynan shu chizma.
  static const logoHouse = SiteIconData([
    'M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z',
    'M9 22V12h6v10',
  ]);

  static const eye = SiteIconData([
    'M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z',
    'M12 12m-3 0a3 3 0 1 0 6 0a3 3 0 1 0 -6 0',
  ]);

  static const eyeOff = SiteIconData([
    'M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94',
    'M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19',
    'M14.12 14.12a3 3 0 1 1-4.24-4.24',
    'M1 1L23 23',
  ]);

  /// Xato satridagi nishoncha.
  static const xCircle = SiteIconData([
    'M12 12m-10 0a10 10 0 1 0 20 0a10 10 0 1 0 -20 0',
    'M15 9L9 15',
    'M9 9L15 15',
  ]);

  static const appleMark = SiteIconData([
    'M17.05 20.28c-.98.95-2.05.8-3.08.35-1.09-.46-2.09-.48-3.24 0-1.44.62-2.2.44-3.06-.35C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.12 1.87-2.38 5.98.48 7.13-.57 1.5-1.31 2.99-2.54 4.09zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z',
  ], filled: true);

  static const facebookMark = SiteIconData([
    'M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z',
  ], filled: true);

  /// Loyiha kartasidagi tahrirlash va o'chirish tugmalari.
  static const edit = SiteIconData(['M12 20h9', 'M16.5 3.5a2.121 2.121 0 0 1 3 3L7 19l-4 1 1-4Z']);

  static const trash = SiteIconData(['M3 6h18', 'M19 6l-2 14H7L5 6']);

  static const camera = SiteIconData([
    'M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z',
    'M12 13m-4 0a4 4 0 1 0 8 0a4 4 0 1 0 -8 0',
  ]);
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

  // ── dizaynerlar / ustalar ────────────────────────────────────────────────
  /// Reyting yulduzi. Kartada uchta holatda chiziladi: to'la (amber, `fill`), yarim (yarmigacha
  /// qirqilgan to'lasi) va bo'sh (`stroke`, kulrang) — shuning uchun bitta path ikki variantda.
  static const _starPolygon =
      'M12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26Z';
  static const ratingStar = SiteIconData([_starPolygon], filled: true);
  static const ratingStarOutline = SiteIconData([_starPolygon]);

  static const phone = SiteIconData([
    'M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z',
  ]);

  /// Yon paneldagi filtr voronkasi.
  static const funnel = SiteIconData(['M22 3 2 3 10 12.46 10 19 14 21 14 12.46Z']);

  /// Bo'sh holatdagi "odamlar" belgisi.
  static const users = SiteIconData([
    'M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2',
    'M9 7m-4 0a4 4 0 1 0 8 0a4 4 0 1 0 -8 0',
    'M22 21v-2a4 4 0 0 0-3-3.87',
    'M16 3.13a4 4 0 0 1 0 7.75',
  ]);

  /// Reels nishonchasidagi to'ldirilgan uchburchak.
  static const play = SiteIconData(['M6 3 20 12 6 21Z'], filled: true);

  /// Dizaynerlar hero'sining o'ng pastidagi suv belgisi — rassom palitrasi. Shablonda bitta
  /// `<svg>` ichida konturi chiziladi, uchta nuqtasi to'ldiriladi, shuning uchun ikki bo'lak.
  static const paletteOutline = SiteIconData([
    'M12 2a10 10 0 0 0 0 20c1.6 0 2-1.2 1.2-2-.8-.9-.3-2 .8-2H17a5 5 0 0 0 5-5c0-5-4.5-9-10-9z',
  ]);

  /// Ustalar hero'si va karta muqovasidagi suv belgisi — kalit (wrench).
  static const wrench = SiteIconData([
    'M14.7 6.3a4 4 0 0 0-5 5L3 18l3 3 6.7-6.7a4 4 0 0 0 5-5l-2.4 2.4-2.3-.6-.6-2.3 2.3-2.5z',
  ]);

  // ── kabinet yon paneli ───────────────────────────────────────────────────
  // Barchasi `cabinet.component.ts` dagi `getIconSvg()` dan.
  static const list = SiteIconData([
    'M8 6h13',
    'M8 12h13',
    'M8 18h13',
    'M3 6h.01',
    'M3 12h.01',
    'M3 18h.01',
  ]);

  static const clock = SiteIconData([
    'M12 12m-10 0a10 10 0 1 0 20 0a10 10 0 1 0 -20 0',
    'M12 6v6l4 2',
  ]);

  static const message = SiteIconData([
    'M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z',
  ]);

  static const image = SiteIconData([
    'M3 3m0 2a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z',
    'M9 9m-2 0a2 2 0 1 0 4 0a2 2 0 1 0 -4 0',
    'm21 15-3.086-3.086a2 2 0 0 0-2.828 0L6 21',
  ]);

  static const wallet = SiteIconData([
    'M21 12V7H5a2 2 0 0 1 0-4h14v4',
    'M3 5v14a2 2 0 0 0 2 2h16v-5',
    'M18 12a2 2 0 0 0 0 4h4v-4Z',
  ]);

  static const settings = SiteIconData([
    'M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z',
    'M12 12m-3 0a3 3 0 1 0 6 0a3 3 0 1 0 -6 0',
  ]);

  static const shield = SiteIconData(['M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z']);

  static const briefcase = SiteIconData([
    'M2 7m0 2a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2z',
    'M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16',
  ]);

  /// `/new-projects` dagi "Xaritadan qidirish" havolasi — qatlamlar belgisi.
  static const map = SiteIconData([
    'M3 6 9 3 15 6 21 3 21 18 15 21 9 18 3 21Z',
    'M9 3v15',
    'M15 6v15',
  ]);

  static const arrowLeft = SiteIconData(['M19 12H5', 'm12 19-7-7 7-7']);

  static const logout = SiteIconData([
    'M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4',
    'm16 17 5-5-5-5',
    'M21 12H9',
  ]);

  static const paletteDots = SiteIconData([
    'M7.5 11m-1.1 0a1.1 1.1 0 1 0 2.2 0a1.1 1.1 0 1 0 -2.2 0',
    'M11 7m-1.1 0a1.1 1.1 0 1 0 2.2 0a1.1 1.1 0 1 0 -2.2 0',
    'M15.5 8m-1.1 0a1.1 1.1 0 1 0 2.2 0a1.1 1.1 0 1 0 -2.2 0',
  ], filled: true);
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
