import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/reader_text_display.dart';
import '../../../../features/display_settings/presentation/bloc/display_settings/display_settings_bloc.dart';
import '../../../../features/display_settings/presentation/theme/display_colors.dart';
import '../../../../routes/app_route_path.dart';

bool get _isCupertino =>
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;

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

        return AdaptiveScaffold(
          backgroundColor: bg,
          title: sourceName ?? 'Text Pad',
          titleColor: fg,
          iconColor: fg,
          actions: [
            AdaptiveIconButton(
              icon: Icon(
                _isCupertino
                    ? CupertinoIcons.settings
                    : Icons.settings_rounded,
                color: fg,
              ),
              tooltip: 'Display settings',
              onPressed: () =>
                  context.pushNamed(AppRoute.displaySettings.name),
            ),
            AdaptiveIconButton(
              icon: Icon(
                _isCupertino ? CupertinoIcons.doc_on_doc : Icons.copy_rounded,
                color: fg,
              ),
              tooltip: 'Copy all',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: text));
                showAdaptiveFeedback(context, 'Copied to clipboard');
              },
            ),
          ],
          // Reuse the shared reader so every display setting applies here too
          // (ruler, syllable dots, fonts, spacing, colour) — consistent with
          // the reader and feature outputs.
          body: ReaderTextDisplay(
            text: text,
            settings: s,
            fgColor: fg,
            bgColor: bg,
          ),
        );
      },
    );
  }
}
