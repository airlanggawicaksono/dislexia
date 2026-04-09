import 'package:flutter/material.dart';

import '../../domain/entities/display_settings_entity.dart';

const _appColors = {
  AppColorTheme.white: (Color(0xFFFFFFFF), Color(0xFF1A1A1A), 'White'),
  AppColorTheme.cream: (Color(0xFFFFF8EE), Color(0xFF1A1A1A), 'Cream'),
  AppColorTheme.softYellow: (
    Color(0xFFFFFBCC),
    Color(0xFF1A1A1A),
    'Soft Yellow'
  ),
  AppColorTheme.mintGreen: (Color(0xFFE0F5E9), Color(0xFF1A1A1A), 'Mint Green'),
  AppColorTheme.lavender: (Color(0xFFEDE7F6), Color(0xFF1A1A1A), 'Lavender'),
  AppColorTheme.skyBlue: (Color(0xFFE3F2FD), Color(0xFF1A1A1A), 'Sky Blue'),
  AppColorTheme.peach: (Color(0xFFFFE8D6), Color(0xFF1A1A1A), 'Peach'),
  AppColorTheme.dark: (Color(0xFF1E1E1E), Color(0xFFE8E8E8), 'Dark Mode'),
};

Color bgColor(AppColorTheme theme) => _appColors[theme]!.$1;
Color fgColor(AppColorTheme theme) => _appColors[theme]!.$2;
String colorLabel(AppColorTheme theme) => _appColors[theme]!.$3;
