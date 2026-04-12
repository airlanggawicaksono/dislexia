import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/display_settings/domain/entities/display_settings_entity.dart';

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
