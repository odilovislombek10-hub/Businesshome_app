import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

import '../../app/theme.dart';
import '../../shared/widgets/entrance.dart';

/// Saytdagi ijtimoiy tarmoq tugmasi: `w-full py-3 bg-white border border-gray-300 rounded-lg`,
/// ichida `gap-3` bilan belgi va matn, `active:scale-[0.99]`.
class SocialButton extends StatelessWidget {
  const SocialButton({
    super.key,
    required this.mark,
    required this.label,
    required this.onTap,
    this.busy = false,
    this.enabled = true,
  });

  final Widget mark;
  final String label;
  final VoidCallback onTap;
  final bool busy;

  /// Saytda mavjud bo'lmagan provayder tugmasi `disabled:opacity-40` bilan xiralashadi.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: enabled && !busy ? 1 : 0.4,
      child: Pressable(
        scale: 0.99,
        onTap: enabled && !busy ? onTap : null,
        child: Container(
          height: 48, // py-3 + 15px matn
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.sm), // rounded-lg
            border: Border.all(color: const Color(0xFFD1D5DB)), // border-gray-300
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: busy
                    ? const CircularProgressIndicator(strokeWidth: 2, color: AppColors.dark)
                    : mark,
              ),
              const SizedBox(width: 12), // gap-3
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 15, // text-[15px]
                  fontWeight: FontWeight.w500,
                  color: AppColors.dark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Google'ning to'rt rangli belgisi — [SiteIcon] bir rang bilan chizadi, shuning uchun alohida.
class GoogleMark extends StatelessWidget {
  const GoogleMark({super.key});

  static List<(String, Color)> get _paths => <(String, Color)>[
    (
      'M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z',
      Color(0xFF4285F4),
    ),
    (
      'M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z',
      Color(0xFF34A853),
    ),
    (
      'M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z',
      Color(0xFFFBBC05),
    ),
    (
      'M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z',
      Color(0xFFEA4335),
    ),
  ];

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _GooglePainter());
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    for (final (data, color) in GoogleMark._paths) {
      canvas.drawPath(parseSvgPathData(data), Paint()..color = color);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GooglePainter oldDelegate) => false;
}
