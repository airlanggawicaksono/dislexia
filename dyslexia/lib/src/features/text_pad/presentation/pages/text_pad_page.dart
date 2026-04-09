import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/font_utils.dart';
import '../../../../features/display_settings/domain/entities/display_settings_entity.dart';
import '../../../../features/display_settings/presentation/bloc/display_settings/display_settings_bloc.dart';

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

        const neutralBg = Color(0xFFF5F0E8);
        const neutralFg = Colors.black87;

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: neutralBg,
            elevation: 0,
            iconTheme: const IconThemeData(color: neutralFg),
            title: Text(
              sourceName ?? 'Text Pad',
              style: const TextStyle(
                  color: neutralFg, fontWeight: FontWeight.w600),
            ),
            actions: [
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
              style: applyDyslexiaFont(
                font: s.font,
                baseStyle: TextStyle(
                  fontSize: s.fontSize,
                  color: fg,
                  height: s.lineSpacing,
                  letterSpacing: s.letterSpacing,
                  wordSpacing: s.wordSpacing,
                ),
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

}
