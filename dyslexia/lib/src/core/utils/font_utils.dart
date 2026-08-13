import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/display_settings/domain/entities/display_settings_entity.dart';

/// 1. Helper untuk mengubah Enum menjadi String nama font yang 100% AKURAT
String getGlobalFontFamily(DyslexiaFont font) {
  switch (font) {
    case DyslexiaFont.openDyslexic:   return 'OpenDyslexic'; // Pastikan ada di pubspec.yaml
    case DyslexiaFont.lexend:         return GoogleFonts.lexend().fontFamily!;
    case DyslexiaFont.plusJakartaSans:return GoogleFonts.plusJakartaSans().fontFamily!;
    case DyslexiaFont.sassoonPrimary: return 'SassoonPrimary'; // Pastikan ada di pubspec.yaml
    case DyslexiaFont.tahoma:         return 'Tahoma'; // Pastikan ada di pubspec.yaml
    case DyslexiaFont.weezerFont:     return 'WeezerFont'; // Pastikan ada di pubspec.yaml
    case DyslexiaFont.arial:          return GoogleFonts.arimo().fontFamily!;
    case DyslexiaFont.calibri:        return GoogleFonts.lato().fontFamily!;
    case DyslexiaFont.verdana:        return GoogleFonts.cabin().fontFamily!;
    case DyslexiaFont.trebuchetMS:    return GoogleFonts.titilliumWeb().fontFamily!;
    case DyslexiaFont.helvetica:      return GoogleFonts.inter().fontFamily!;
    case DyslexiaFont.comicSansMS:    return GoogleFonts.comicNeue().fontFamily!;
  }
}

/// 2. Style untuk ukuran, spasi, dan warna (untuk input text spesifik)
TextStyle dyslexiaTextStyle(DisplaySettingsEntity s, Color color) {
  return applyDyslexiaFont(
    font: s.font,
    baseStyle: TextStyle(
      fontSize: s.fontSize,
      color: color,
      height: s.lineSpacing,
      letterSpacing: s.letterSpacing,
      wordSpacing: s.wordSpacing,
    ),
  );
}

/// 3. FUNGSI INI WAJIB ADA untuk widget yang butuh override spesifik
TextStyle applyDyslexiaFont({
  required DyslexiaFont font,
  required TextStyle baseStyle,
}) {
  return switch (font) {
    DyslexiaFont.openDyslexic   => baseStyle.copyWith(fontFamily: 'OpenDyslexic'),
    DyslexiaFont.lexend         => GoogleFonts.lexend(textStyle: baseStyle),
    DyslexiaFont.plusJakartaSans => GoogleFonts.plusJakartaSans(textStyle: baseStyle),
    DyslexiaFont.sassoonPrimary => baseStyle.copyWith(fontFamily: 'SassoonPrimary'),
    DyslexiaFont.tahoma         => baseStyle.copyWith(fontFamily: 'Tahoma'),
    DyslexiaFont.weezerFont     => baseStyle.copyWith(fontFamily: 'WeezerFont'),
    DyslexiaFont.arial          => GoogleFonts.arimo(textStyle: baseStyle),
    DyslexiaFont.calibri        => GoogleFonts.lato(textStyle: baseStyle),
    DyslexiaFont.verdana        => GoogleFonts.cabin(textStyle: baseStyle),
    DyslexiaFont.trebuchetMS    => GoogleFonts.titilliumWeb(textStyle: baseStyle),
    DyslexiaFont.helvetica      => GoogleFonts.inter(textStyle: baseStyle),
    DyslexiaFont.comicSansMS    => GoogleFonts.comicNeue(textStyle: baseStyle),
  };
}

/// Applies [applyDyslexiaFont] to every style in a [TextTheme].
///
/// On web, this routes through `GoogleFonts.<family>(textStyle:)` for
/// Google-hosted fonts, which registers the async font load and triggers
/// a rebuild when the webfont arrives — unlike a bare `fontFamily` string
/// passed to `textTheme.apply(fontFamily:)` which does not.
TextTheme applyDyslexiaFontToTextTheme({
  required DyslexiaFont font,
  required TextTheme textTheme,
}) {
  TextStyle applyTo(TextStyle? s) =>
      s == null ? const TextStyle() : applyDyslexiaFont(font: font, baseStyle: s);

  return TextTheme(
    displayLarge:  applyTo(textTheme.displayLarge),
    displayMedium: applyTo(textTheme.displayMedium),
    displaySmall:  applyTo(textTheme.displaySmall),
    headlineLarge:  applyTo(textTheme.headlineLarge),
    headlineMedium: applyTo(textTheme.headlineMedium),
    headlineSmall:  applyTo(textTheme.headlineSmall),
    titleLarge:  applyTo(textTheme.titleLarge),
    titleMedium: applyTo(textTheme.titleMedium),
    titleSmall:  applyTo(textTheme.titleSmall),
    bodyLarge:  applyTo(textTheme.bodyLarge),
    bodyMedium: applyTo(textTheme.bodyMedium),
    bodySmall:  applyTo(textTheme.bodySmall),
    labelLarge:  applyTo(textTheme.labelLarge),
    labelMedium: applyTo(textTheme.labelMedium),
    labelSmall:  applyTo(textTheme.labelSmall),
  );
}