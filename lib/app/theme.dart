import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens lifted verbatim from the website's `tailwind.config.js` so the app and
/// businesshome.uz stay visually identical — change one, change the other.
abstract final class AppColors {
  /// UYSOT brand palette — the four colours the whole site is built from.
  static const dark = Color(0xFF3D3D3D);
  static const olive = Color(0xFF87885C);
  static const cream = Color(0xFFFAF9F6);
  static const bronze = Color(0xFF8B8B6B);

  /// Tailwind `primary` maps onto olive, with the two shades the site uses for
  /// hover/active states.
  static const primary = olive;
  static const primaryLight = bronze;
  static const primaryDark = dark;

  /// Light surfaces: the site alternates `bg-white` / `bg-gray-50` / `bg-cream`.
  static const surfaceLight = Colors.white;
  static const surfaceAltLight = Color(0xFFF9FAFB); // gray-50
  static const surfaceMutedLight = Color(0xFFF3F4F6); // gray-100
  static const creamAlt = Color(0xFFF5F3EC);

  /// Dark surfaces: slate-800/900 for chrome, the olive-tinted darks for content blocks.
  static const surfaceDark = Color(0xFF1E293B); // slate-800
  static const surfaceAltDark = Color(0xFF334155); // slate-700
  static const scaffoldDark = Color(0xFF0F172A); // slate-900
  static const oliveDark = Color(0xFF2A2B20);
  static const oliveDarker = Color(0xFF222318);
  static const oliveDarkest = Color(0xFF17180F);
  static const oliveMuted = Color(0xFF41422F);

  static const borderLight = Color(0xFFE5E7EB); // gray-200
  static const borderDark = Color(0xFF475569); // slate-600

  static const textLight = Color(0xFF111827); // gray-900
  static const textMutedLight = Color(0xFF6B7280); // gray-500
  static const textDark = Color(0xFFF1F5F9); // slate-100
  static const textMutedDark = Color(0xFF94A3B8); // slate-400

  static const danger = Color(0xFFDC2626); // red-600
  static const success = Color(0xFF16A34A); // green-600
  static const warning = Color(0xFFCA8A04); // yellow-600
  static const terracotta = Color(0xFFB5694C);
}

/// Corner radii the site uses via Tailwind's `rounded-*` scale.
abstract final class AppRadius {
  static const sm = 8.0; // rounded-lg
  static const md = 12.0; // rounded-xl
  static const lg = 16.0; // rounded-2xl
  static const xl = 24.0; // rounded-3xl
  static const pill = 999.0;
}

abstract final class AppTheme {
  /// Inter for body copy, Playfair Display for headings — same pairing as the site's
  /// `fontFamily.sans` / `fontFamily.display`.
  static TextTheme _text(Color onSurface, Color muted) {
    final base = GoogleFonts.interTextTheme();
    return base
        .copyWith(
          // `font-display` on the site is only ever applied to large headings.
          displayLarge: GoogleFonts.playfairDisplay(fontSize: 44, fontWeight: FontWeight.w700),
          displayMedium: GoogleFonts.playfairDisplay(fontSize: 34, fontWeight: FontWeight.w700),
          displaySmall: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.w600),
          headlineMedium: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w600),
          titleLarge: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600),
          titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
          bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400),
          bodySmall: GoogleFonts.inter(fontSize: 13, color: muted),
          labelSmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500),
        )
        .apply(bodyColor: onSurface, displayColor: onSurface);
  }

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(seedColor: AppColors.olive, brightness: Brightness.light)
        .copyWith(
          primary: AppColors.olive,
          onPrimary: Colors.white,
          secondary: AppColors.bronze,
          surface: AppColors.surfaceLight,
          onSurface: AppColors.textLight,
          onSurfaceVariant: AppColors.textMutedLight,
          outlineVariant: AppColors.borderLight,
          error: AppColors.danger,
        );
    return _build(scheme, AppColors.cream, AppColors.textLight, AppColors.textMutedLight);
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(seedColor: AppColors.olive, brightness: Brightness.dark)
        .copyWith(
          primary: AppColors.olive,
          onPrimary: Colors.white,
          secondary: AppColors.bronze,
          surface: AppColors.surfaceDark,
          onSurface: AppColors.textDark,
          onSurfaceVariant: AppColors.textMutedDark,
          outlineVariant: AppColors.borderDark,
          error: AppColors.danger,
        );
    return _build(scheme, AppColors.scaffoldDark, AppColors.textDark, AppColors.textMutedDark);
  }

  static ThemeData _build(ColorScheme scheme, Color scaffold, Color onSurface, Color muted) {
    final text = _text(onSurface, muted);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          textStyle: text.titleMedium,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.brightness == Brightness.light
            ? AppColors.surfaceAltLight
            : AppColors.surfaceAltDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.olive, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.brightness == Brightness.light
            ? AppColors.surfaceMutedLight
            : AppColors.surfaceAltDark,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
        labelStyle: text.labelSmall,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: AppColors.olive.withValues(alpha: 0.15),
        elevation: 0,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStatePropertyAll(text.labelSmall),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1, space: 1),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),
    );
  }
}
