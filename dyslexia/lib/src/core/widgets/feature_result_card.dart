import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/display_settings/presentation/bloc/display_settings/display_settings_bloc.dart';
import '../../features/display_settings/presentation/theme/display_colors.dart';
import '../widgets/adaptive/adaptive.dart';
import 'reader_text_display.dart';

class FeatureResultCard extends StatelessWidget {
  final String text;
  final String title;
  final VoidCallback onToggleInput;
  final bool inputExpanded;

  const FeatureResultCard({
    super.key,
    required this.text,
    required this.title,
    required this.onToggleInput,
    required this.inputExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final ds = context.watch<DisplaySettingsBloc>().state;
    final s = ds.settings;
    final bg = bgColor(s.colorTheme);
    final fg = fgColor(s.colorTheme);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, size: 18, color: fg),
                const SizedBox(width: 8),
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15, color: fg)),
                const Spacer(),
                IconButton(
                  tooltip: inputExpanded ? 'Hide input' : 'Show input',
                  icon: Icon(
                    inputExpanded
                        ? Icons.unfold_less_rounded
                        : Icons.unfold_more_rounded,
                    size: 18,
                    color: fg,
                  ),
                  onPressed: onToggleInput,
                ),
                IconButton(
                  tooltip: 'Copy to clipboard',
                  icon: Icon(Icons.copy_rounded, size: 18, color: fg),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: text));
                    showAdaptiveFeedback(context, 'Copied to clipboard');
                  },
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: ReaderTextDisplay(
                text: text,
                settings: s,
                fgColor: fg,
                bgColor: bg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
