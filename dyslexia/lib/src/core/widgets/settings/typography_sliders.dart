import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/display_settings/presentation/bloc/display_settings/display_settings_bloc.dart';
import '../../widgets/adaptive/adaptive.dart';

class TypographySliders extends StatelessWidget {
  final bool compact;
  const TypographySliders({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DisplaySettingsBloc, DisplaySettingsState>(
      builder: (context, state) {
        final s = state.settings;
        final bloc = context.read<DisplaySettingsBloc>();

        if (compact) {
          return Column(
            children: [
              _miniSlider('Size', s.fontSize, 12, 32, (v) => bloc.add(UpdateFontSizeEvent(v)), s.fontSize.toStringAsFixed(0)),
              _miniSlider('Line', s.lineSpacing, 1.0, 3.0, (v) => bloc.add(UpdateLineSpacingEvent(v)), '${s.lineSpacing.toStringAsFixed(1)}x'),
              _miniSlider('Letter', s.letterSpacing, 0.0, 2.0, (v) => bloc.add(UpdateLetterSpacingEvent(v)), s.letterSpacing.toStringAsFixed(1)),
              _miniSlider('Word', s.wordSpacing, 0.0, 8.0, (v) => bloc.add(UpdateWordSpacingEvent(v)), s.wordSpacing.toStringAsFixed(1)),
            ],
          );
        }

        return Column(
          children: [
            _labeledSlider('Size', '${s.fontSize.toStringAsFixed(0)}px', s.fontSize, 12, 32, (v) => bloc.add(UpdateFontSizeEvent(v))),
            _labeledSlider('Line Height', '${s.lineSpacing.toStringAsFixed(1)}', s.lineSpacing, 1.0, 3.0, (v) => bloc.add(UpdateLineSpacingEvent(v))),
            _labeledSlider('Letter Spacing', '${s.letterSpacing.toStringAsFixed(1)}px', s.letterSpacing, 0.0, 2.0, (v) => bloc.add(UpdateLetterSpacingEvent(v))),
            _labeledSlider('Word Spacing', '${s.wordSpacing.toStringAsFixed(0)}px', s.wordSpacing, 0.0, 8.0, (v) => bloc.add(UpdateWordSpacingEvent(v))),
          ],
        );
      },
    );
  }
}

Widget _miniSlider(String label, double value, double min, double max, ValueChanged<double> onChanged, String displayValue) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        SizedBox(width: 36, child: Text(label, style: const TextStyle(fontSize: 10, color: Colors.black45))),
        Expanded(child: AdaptiveSlider(value: value.clamp(min, max), min: min, max: max, onChanged: onChanged, activeColor: Color(0xFF3D5A99))),
      ],
    ),
  );
}

Widget _labeledSlider(String label, String displayValue, double value, double min, double max, ValueChanged<double> onChanged) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: AdaptiveSlider(value: value, min: min, max: max, onChanged: onChanged, activeColor: const Color(0xFF3D5A99)),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 48,
              child: Text(
                displayValue,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF3D5A99)),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
