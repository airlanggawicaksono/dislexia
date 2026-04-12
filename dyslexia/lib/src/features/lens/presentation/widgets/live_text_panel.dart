import 'package:flutter/material.dart';

import '../../../../core/utils/font_utils.dart';
import '../../../display_settings/domain/entities/display_settings_entity.dart';

class LiveTextPanel extends StatelessWidget {
  final String text;
  final DisplaySettingsEntity settings;

  const LiveTextPanel({super.key, required this.text, required this.settings});

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

  Color get _bg =>
      _themeColors[settings.colorTheme]?.$1 ?? const Color(0xFFFFF8EE);
  Color get _fg =>
      _themeColors[settings.colorTheme]?.$2 ?? const Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _bg.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: const [
          BoxShadow(
              color: Colors.black26, blurRadius: 8, offset: Offset(0, -2)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: _fg.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Flexible(
            child: text.isEmpty
                ? Center(
                    child: Text(
                      'Point camera at text...',
                      style: TextStyle(
                          color: _fg.withValues(alpha: 0.4), fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  )
                : SingleChildScrollView(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: Text(
                        text,
                        key: ValueKey(text),
                        style: applyDyslexiaFont(
                          font: settings.font,
                          baseStyle: TextStyle(
                            fontSize: settings.fontSize,
                            color: _fg,
                            height: settings.lineSpacing,
                            letterSpacing: settings.letterSpacing,
                            wordSpacing: settings.wordSpacing,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
