import 'package:flutter/material.dart';

/// Dizayner va usta sahifalari birga ishlatadigan mayda qismlar.
///
/// Ikkala shablon ham bir xil `getInitials` / `getAvatarGradient` funksiyalarini va bir xil
/// nuqtali naqsh fonini takrorlaydi — shuning uchun bu yerga chiqarildi.

/// `radial-gradient(rgba(255,255,255,α) 1px, transparent 1px)` — hero va karta muqovasidagi
/// nuqtali naqsh. [step] — `background-size` (dizaynerlarda 18px, usta kartasida 14px).
class DotPatternPainter extends CustomPainter {
  const DotPatternPainter({this.step = 18, this.alpha = 0.075});

  final double step;

  /// Naqsh ustidagi `opacity-*` bilan ko'paytirilgan yakuniy shaffoflik.
  final double alpha;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: alpha);
    for (var y = step / 2; y < size.height; y += step) {
      for (var x = step / 2; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(DotPatternPainter old) => old.step != step || old.alpha != alpha;
}

/// Ismdan birinchi (ko'pi bilan 2) harf — saytdagi `getInitials`.
String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts[0][0] + parts[1][0]).toUpperCase();
}

/// Ismdan deterministik gradient — saytdagi `getAvatarGradient` ning aynan o'zi.
LinearGradient avatarGradient(String name) {
  const palette = <List<Color>>[
    [Color(0xFF999966), Color(0xFF4F6E3A)],
    [Color(0xFF6366F1), Color(0xFF4338CA)],
    [Color(0xFFEC4899), Color(0xFFBE185D)],
    [Color(0xFF14B8A6), Color(0xFF0F766E)],
    [Color(0xFFF59E0B), Color(0xFFB45309)],
    [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
    [Color(0xFFEF4444), Color(0xFFB91C1C)],
    [Color(0xFF10B981), Color(0xFF047857)],
  ];
  var h = 0;
  for (final unit in name.codeUnits) {
    // JS `(h << 5) - h + code` 32 bitli — Dart'da int 64 bitli, shuning uchun qirqiladi.
    h = ((h << 5) - h + unit).toSigned(32);
  }
  final colors = palette[h.abs() % palette.length];
  return LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors);
}
