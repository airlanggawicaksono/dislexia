import 'package:flutter/material.dart';

import 'adaptive/adaptive_slider.dart';

/// Reusable discrete slider for feature "level" knobs (summarize, define).
/// Self-managing: keeps its own index so it redraws correctly even inside a
/// modal bottom sheet (where the parent page's setState can't reach it).
/// Reports the chosen index up via [onChanged].
class LevelSlider extends StatefulWidget {
  final String label;
  final List<String> valueLabels;
  final int initialIndex;
  final ValueChanged<int> onChanged;

  const LevelSlider({
    super.key,
    required this.label,
    required this.valueLabels,
    required this.initialIndex,
    required this.onChanged,
  });

  @override
  State<LevelSlider> createState() => _LevelSliderState();
}

class _LevelSliderState extends State<LevelSlider> {
  late int _i = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.label,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500, color: fg)),
            Text(widget.valueLabels[_i],
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3D5A99))),
          ],
        ),
        AdaptiveSlider(
          value: _i.toDouble(),
          min: 0,
          max: (widget.valueLabels.length - 1).toDouble(),
          onChanged: (v) {
            final next = v.round();
            if (next == _i) return;
            setState(() => _i = next);
            widget.onChanged(next);
          },
        ),
      ],
    );
  }
}
