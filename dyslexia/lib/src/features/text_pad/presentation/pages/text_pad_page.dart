import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../display_settings/presentation/theme/display_colors.dart';
import '../../../display_settings/presentation/theme/display_fonts.dart';
import '../../../display_settings/presentation/bloc/display_settings/display_settings_bloc.dart';
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
        final bg = bgColor(s.colorTheme);
        final fg = fgColor(s.colorTheme);

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
                fontFamily: fontFamily(s.font),
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
}
