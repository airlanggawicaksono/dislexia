import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
        final settings = state.settings;
        return Scaffold(
          backgroundColor: _bgColor(settings.colorTheme),
          appBar: AppBar(
            title: Text(sourceName ?? 'Text Pad'),
            actions: [
              IconButton(
                icon: const Icon(Icons.copy_rounded),
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
                fontSize: settings.fontSize,
                fontFamily: _fontFamily(settings.font),
                color: _textColor(settings.colorTheme),
                height: 1.6,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      },
    );
  }

  Color _bgColor(AppColorTheme theme) => switch (theme) {
        AppColorTheme.light => Colors.white,
        AppColorTheme.dark => const Color(0xFF1A1A1A),
        AppColorTheme.yellowOnBlack => Colors.black,
        AppColorTheme.creamOnBlue => const Color(0xFF1B3A6B),
      };

  Color _textColor(AppColorTheme theme) => switch (theme) {
        AppColorTheme.light => Colors.black87,
        AppColorTheme.dark => Colors.white70,
        AppColorTheme.yellowOnBlack => Colors.yellow,
        AppColorTheme.creamOnBlue => const Color(0xFFFFFDD0),
      };

  String _fontFamily(DyslexiaFont font) => switch (font) {
        DyslexiaFont.openDyslexic => 'OpenDyslexic',
        DyslexiaFont.lexend => 'Lexend',
        DyslexiaFont.arial => 'Arial',
        DyslexiaFont.verdana => 'Verdana',
      };
}
