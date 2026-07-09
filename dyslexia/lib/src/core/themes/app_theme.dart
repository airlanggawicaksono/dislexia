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
    final base = data(isDark);
    // Keep the brand purple as the accent/primary (buttons, dialogs) — only
    // swap the surface/scaffold background + text colour to the chosen theme.
    return base.copyWith(
      scaffoldBackgroundColor: background,
      canvasColor: background,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColor.purple,
        surface: background,
        onSurface: foreground,
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
