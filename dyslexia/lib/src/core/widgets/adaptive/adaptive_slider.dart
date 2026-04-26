import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

bool get _isCupertino =>
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;

class AdaptiveSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final Color? activeColor;

  const AdaptiveSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    if (_isCupertino) {
      return CupertinoSlider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        onChanged: onChanged,
        activeColor: activeColor ?? const Color(0xFF4C658A),
      );
    }

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: activeColor ?? const Color(0xFF4C658A),
        thumbColor: activeColor ?? const Color(0xFF4C658A),
        inactiveTrackColor: Colors.black12,
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      ),
      child: Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        onChanged: onChanged,
      ),
    );
  }
}
