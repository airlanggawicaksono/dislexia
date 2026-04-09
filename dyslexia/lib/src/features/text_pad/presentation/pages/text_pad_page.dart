import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/display_settings/domain/entities/display_settings_entity.dart';
import '../../../../features/display_settings/presentation/bloc/display_settings/display_settings_bloc.dart';
import '../../../../routes/app_route_path.dart';

class TextPadPage extends StatelessWidget {
  final String text;
  final String? sourceName;

  const TextPadPage({super.key, required this.text, this.sourceName});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DisplaySettingsBloc, DisplaySettingsState>(
      builder: (context, state) {
        final s = state.settings;
        final bg = _bgColor(s.colorTheme);
        final fg = _textColor(s.colorTheme);

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: bg,
            elevation: 0,
            iconTheme: IconThemeData(color: fg),
            title: Text(
              sourceName ?? 'Text Pad',
              style: TextStyle(color: fg, fontWeight: FontWeight.w600),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.settings_rounded, color: fg),
                tooltip: 'Display settings',
                onPressed: () =>
                    context.pushNamed(AppRoute.displaySettings.name),
              ),
              IconButton(
                icon: Icon(Icons.copy_rounded, color: fg),
                tooltip: 'Copy all',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: SelectableText(
              text,
              style: TextStyle(
                fontSize: s.fontSize,
                fontFamily: _fontFamily(s.font),
                color: fg,
                height: s.lineSpacing,
                letterSpacing: s.letterSpacing,
                wordSpacing: s.wordSpacing,
              ),
            ),
          ),
        );
      },
    );
  }

  static const _themeColors = {
    AppColorTheme.white: (Color(0xFFFFFFFF), Color(0xFF1A1A1A)),
    AppColorTheme.cream: (Color(0xFFFFF8EE), Color(0xFF1A1A1A)),
    AppColorTheme.softYellow: (Color(0xFFFFFBCC), Color(0xFF1A1A1A)),
    AppColorTheme.mintGreen: (Color(0xFFE0F5E9), Color(0xFF1A1A1A)),
    AppColorTheme.lavender: (Color(0xFFEDE7F6), Color(0xFF1A1A1A)),
    AppColorTheme.skyBlue: (Color(0xFFE3F2FD), Color(0xFF1A1A1A)),
    AppColorTheme.peach: (Color(0xFFFFE8D6), Color(0xFF1A1A1A)),
    AppColorTheme.dark: (Color(0xFF1E1E1E), Color(0xFFE8E8E8)),
  };

  Color _bgColor(AppColorTheme theme) =>
      _themeColors[theme]?.$1 ?? const Color(0xFFFFF8EE);

  Color _textColor(AppColorTheme theme) =>
      _themeColors[theme]?.$2 ?? const Color(0xFF1A1A1A);

  String _fontFamily(DyslexiaFont font) => switch (font) {
        DyslexiaFont.openDyslexic => 'OpenDyslexic',
        DyslexiaFont.verdana => 'Verdana',
        DyslexiaFont.jakartaSans => 'Jakarta Sans',
        DyslexiaFont.arial => 'Arial',
        DyslexiaFont.calibri => 'Calibri',
        DyslexiaFont.lexend => 'Lexend',
      };
}
