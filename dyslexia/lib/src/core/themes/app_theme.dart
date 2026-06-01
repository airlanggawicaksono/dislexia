import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_color.dart';
import 'app_font.dart';

class AppTheme {
  AppTheme._();

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
