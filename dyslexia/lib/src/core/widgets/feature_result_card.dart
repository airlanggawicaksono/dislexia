import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/display_settings/presentation/bloc/display_settings/display_settings_bloc.dart';
import '../../features/reader/data/syllabifier.dart';
import '../utils/font_utils.dart';
import '../widgets/adaptive/adaptive.dart';
import '../widgets/ruler/reading_ruler.dart';

class FeatureResultCard extends StatefulWidget {
  final String text;
  final String title;
  final VoidCallback onToggleInput;
  final bool inputExpanded;
  final bool rulerEnabled;
  final Color fgColor;

  const FeatureResultCard({
    super.key,
    required this.text,
    required this.title,
    required this.onToggleInput,
    required this.inputExpanded,
    this.rulerEnabled = false,
    required this.fgColor,
  });

  @override
  State<FeatureResultCard> createState() => _FeatureResultCardState();
}

class _FeatureResultCardState extends State<FeatureResultCard> {
  double _rulerY = 120.0;

  @override
  Widget build(BuildContext context) {
    final body = BlocBuilder<DisplaySettingsBloc, DisplaySettingsState>(
      builder: (context, ds) {
        final s = ds.settings;
        final fg = widget.fgColor;
        final displayText =
            s.syllablesEnabled ? syllabify(widget.text) : widget.text;
        return Container(
          decoration: BoxDecoration(
            color: fg.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, size: 18),
                    const SizedBox(width: 8),
                    Text(widget.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    const Spacer(),
                    IconButton(
                      tooltip: widget.inputExpanded
                          ? 'Hide input'
                          : 'Show input',
                      icon: Icon(
                        widget.inputExpanded
                            ? Icons.unfold_less_rounded
                            : Icons.unfold_more_rounded,
                        size: 18,
                      ),
                      onPressed: widget.onToggleInput,
                    ),
                    IconButton(
                      tooltip: 'Copy to clipboard',
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: widget.text));
                        showAdaptiveFeedback(context, 'Copied to clipboard');
                      },
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      displayText,
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
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!widget.rulerEnabled) return body;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: MouseRegion(
        onHover: (e) => setState(() => _rulerY = e.localPosition.dy),
        child: Stack(
          children: [
            body,
            if (widget.rulerEnabled)
              ReadingRuler(
                height: 48,
                foregroundColor: widget.fgColor,
                rulerY: _rulerY,
                onPositionChanged: (y) => setState(() => _rulerY = y),
              ),
          ],
        ),
      ),
    );
  }
}
