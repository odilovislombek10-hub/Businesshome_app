import 'package:flutter/widgets.dart';

/// Tailwind'ning ekran nuqtalari — saytdagi `sm:` `md:` `lg:` `xl:` prefikslari
/// aynan shu kengliklarda ishga tushadi (`tailwind.config.js` da o'zgartirilmagan).
///
/// Shu paytgacha ilova faqat mobil ko'rinishni (prefikssiz qiymatlarni) olardi.
/// Planshet va katta telefonlarda sayt kattaroq o'lchamga o'tadi — [pick] o'sha
/// zinapoyani takrorlaydi: joriy kenglikka mos eng oxirgi berilgan qiymat qaytadi.
///
/// ```dart
/// // text-2xl sm:text-3xl md:text-4xl
/// fontSize: Bp.pick(context, base: 24, sm: 30, md: 36)
/// ```
abstract final class Bp {
  static const double sm = 640;
  static const double md = 768;
  static const double lg = 1024;
  static const double xl = 1280;

  static T pick<T>(BuildContext context, {required T base, T? sm, T? md, T? lg, T? xl}) =>
      pickWidth(MediaQuery.sizeOf(context).width, base: base, sm: sm, md: md, lg: lg, xl: xl);

  /// Kengligi ma'lum bo'lgan joyda (`LayoutBuilder` ichida) ishlatiladi.
  static T pickWidth<T>(double width, {required T base, T? sm, T? md, T? lg, T? xl}) {
    var value = base;
    if (sm != null && width >= Bp.sm) value = sm;
    if (md != null && width >= Bp.md) value = md;
    if (lg != null && width >= Bp.lg) value = lg;
    if (xl != null && width >= Bp.xl) value = xl;
    return value;
  }

  static bool isSm(BuildContext context) => MediaQuery.sizeOf(context).width >= sm;
  static bool isMd(BuildContext context) => MediaQuery.sizeOf(context).width >= md;
  static bool isLg(BuildContext context) => MediaQuery.sizeOf(context).width >= lg;
}
