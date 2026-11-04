import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Corner radius and sizes shared by the screens.
class AppRadius {
  AppRadius._();

  static const double card = 24;
  static const double thumb = 20;
  static const double pill = 999;
}

class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(AppPalette.light, Brightness.light);

  static ThemeData dark() => _build(AppPalette.dark, Brightness.dark);

  static ThemeData _build(AppPalette p, Brightness brightness) {
    final base = ThemeData(brightness: brightness, useMaterial3: true);
    final text = _textTheme(base.textTheme, p);

    return base.copyWith(
      scaffoldBackgroundColor: p.screen,
      canvasColor: p.screen,
      colorScheme: ColorScheme.fromSeed(
        seedColor: p.primary,
        brightness: brightness,
        primary: p.primary,
        surface: p.screen,
        onSurface: p.ink,
      ),
      textTheme: text,
      dividerColor: p.border,
      extensions: [p],
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: p.screen,
        foregroundColor: p.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: text.titleLarge,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.screen,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: p.border,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.primarySoft,
        hintStyle: text.bodyLarge?.copyWith(color: p.muted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.thumb),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.thumb),
          borderSide: BorderSide(color: p.primary, width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.ink,
        contentTextStyle: text.bodyMedium?.copyWith(color: p.screen),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.thumb),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? Colors.white : p.muted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? p.primary : p.primarySoft,
        ),
        trackOutlineColor: WidgetStatePropertyAll(p.border),
      ),
      textSelectionTheme: TextSelectionThemeData(cursorColor: p.primary),
    );
  }

  static TextTheme _textTheme(TextTheme base, AppPalette p) {
    final outfit = GoogleFonts.outfitTextTheme(base).apply(
      bodyColor: p.ink,
      displayColor: p.ink,
    );
    return outfit.copyWith(
      headlineLarge: outfit.headlineLarge?.copyWith(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        height: 1.1,
        letterSpacing: -0.5,
      ),
      headlineMedium: outfit.headlineMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.15,
        letterSpacing: -0.3,
      ),
      titleLarge: outfit.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
      titleMedium: outfit.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
      titleSmall: outfit.titleSmall?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
      bodyLarge: outfit.bodyLarge?.copyWith(fontSize: 16, height: 1.4),
      bodyMedium: outfit.bodyMedium?.copyWith(fontSize: 14, height: 1.4),
      bodySmall: outfit.bodySmall?.copyWith(fontSize: 12, color: p.muted),
      labelLarge: outfit.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
      ),
      labelMedium: outfit.labelMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
      labelSmall: outfit.labelSmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
    );
  }
}
