import '../../domain/entities/display_settings_entity.dart';

String fontFamily(DyslexiaFont font) => switch (font) {
      DyslexiaFont.openDyslexic => 'OpenDyslexic',
      DyslexiaFont.verdana => 'Verdana',
      DyslexiaFont.jakartaSans => 'Jakarta Sans',
      DyslexiaFont.arial => 'Arial',
      DyslexiaFont.calibri => 'Calibri',
      DyslexiaFont.lexend => 'Lexend',
    };
