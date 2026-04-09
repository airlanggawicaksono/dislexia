import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/display_settings/domain/entities/display_settings_entity.dart';

/// Returns a [TextStyle] with the correct font family applied.
/// - Lexend uses google_fonts (auto-downloads / cached)
/// - OpenDyslexic uses bundled asset font
/// - Arial / Verdana are system fonts (available on Android & iOS)
TextStyle applyDyslexiaFont({
  required DyslexiaFont font,
  required TextStyle baseStyle,
}) {
  return switch (font) {
    DyslexiaFont.openDyslexic =>
      baseStyle.copyWith(fontFamily: 'OpenDyslexic'),
    DyslexiaFont.jakartaSans =>
      GoogleFonts.plusJakartaSans(textStyle: baseStyle),
    DyslexiaFont.arial => baseStyle.copyWith(fontFamily: 'Arial'),
    DyslexiaFont.calibri => baseStyle.copyWith(fontFamily: 'Calibri'),
  };
}
