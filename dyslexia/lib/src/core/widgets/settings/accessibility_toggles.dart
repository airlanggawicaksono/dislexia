import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/display_settings/presentation/bloc/display_settings/display_settings_bloc.dart';

class AccessibilityToggles extends StatelessWidget {
  const AccessibilityToggles({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DisplaySettingsBloc, DisplaySettingsState>(
      builder: (context, state) {
        final s = state.settings;
        final bloc = context.read<DisplaySettingsBloc>();
        final fg = const Color(0xFF3D5A99);

        return Column(
          children: [
            _toggleRow('Reading Ruler', s.rulerEnabled, () => bloc.add(ToggleRulerEvent()), fg),
            const SizedBox(height: 4),
            _toggleRow('Syllable Dots', s.syllablesEnabled, () => bloc.add(ToggleSyllablesEvent()), fg),
          ],
        );
      },
    );
  }
}

Widget _toggleRow(String label, bool value, VoidCallback onToggle, Color accent) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: Colors.black87.withValues(alpha: 0.7))),
            const Spacer(),
            Container(
              width: 32, height: 18,
              decoration: BoxDecoration(
                color: value ? accent : Colors.black87.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(9),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(margin: const EdgeInsets.all(2), width: 14, height: 14, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
