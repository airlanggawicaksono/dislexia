import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_color.dart';
import 'app_font.dart';

class AppTheme {
  AppTheme._();

  /// Off-white surface used for the pre-login experience (splash + auth).
  static const authSurface = AppColor.cream; // #FFF8EE
  static const authForeground = Color(0xFF1A1A1A);

  /// Build a theme whose surface/scaffold background is [background] and
  /// text colour [foreground]. Reuses [data] for fonts/buttons, then swaps
  /// the colours. Used to make the whole app follow either the off-white
  /// auth palette (logged out) or the user's display-settings colour
  /// (logged in) — see MyApp.
  static ThemeData fromColors({
    required Color background,
    required Color foreground,
    required bool isDark,
  }) {
    final brightness = isDark ? Brightness.dark : Brightness.light;
    // Derive a full palette from the background so accents (buttons,
    // dialogs, snackbars) harmonise with the theme instead of falling back
    // to Material's default purple. Pin surface/onSurface to the exact
    // chosen colours.
    final scheme = ColorScheme.fromSeed(
      seedColor: background,
      brightness: brightness,
    ).copyWith(
      surface: background,
      onSurface: foreground,
    );

    final base = data(isDark);
    return base.copyWith(
      brightness: brightness,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      colorScheme: scheme,
      // Kill the hardcoded purple from data() — make these follow the scheme.
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      floatingActionButtonTheme: base.floatingActionButtonTheme.copyWith(
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 2.0,
          textStyle: AppFont.normal.copyWith(fontSize: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.0),
          ),
        ),
      ),
      // "Notifications"/alerts — snackbars + dialogs follow the palette.
      snackBarTheme: base.snackBarTheme.copyWith(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: AppFont.normal.copyWith(
          fontSize: 14,
          color: scheme.onInverseSurface,
        ),
        actionTextColor: scheme.inversePrimary,
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: base.dialogTheme.copyWith(
        backgroundColor: scheme.surface,
      ),
    );
  }

  static ThemeData data(bool isDark) {
    return ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColor.navy : AppColor.purple,
        centerTitle: true,
        elevation: 2.0,
        titleTextStyle: AppFont.bold.copyWith(fontSize: 16),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: isDark ? AppColor.blue : AppColor.lightPurple,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 2.0,
        extendedTextStyle: AppFont.normal.copyWith(fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? AppColor.blue : AppColor.lightPurple,
          elevation: 2.0,
          textStyle: AppFont.normal.copyWith(fontSize: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.0),
          ),
        ),
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      fontFamily: GoogleFonts.poppins().fontFamily,
      textTheme: TextTheme(
        bodySmall: AppFont.normal.copyWith(fontSize: 12),
        bodyMedium: AppFont.normal.copyWith(fontSize: 14),
        bodyLarge: AppFont.normal.copyWith(fontSize: 16),
      ),
      cupertinoOverrideTheme: CupertinoThemeData(
        primaryColor: isDark ? AppColor.blue : AppColor.purple,
        brightness: isDark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: isDark
            ? const Color(0xFF1C1C1E)
            : CupertinoColors.systemGroupedBackground,
        textTheme: CupertinoTextThemeData(
          textStyle: AppFont.normal.copyWith(fontSize: 14),
          navTitleTextStyle: AppFont.bold.copyWith(fontSize: 16, color: Colors.white),
          actionTextStyle: AppFont.normal.copyWith(fontSize: 14,
            color: isDark ? AppColor.blue : AppColor.purple,
          ),
        ),
      ),
    );
  }
}
