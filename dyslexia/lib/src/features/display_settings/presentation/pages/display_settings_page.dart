import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/display_settings/display_settings_bloc.dart';
import '../../domain/entities/display_settings_entity.dart';

class DisplaySettingsPage extends StatelessWidget {
  const DisplaySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DisplaySettingsBloc, DisplaySettingsState>(
      builder: (context, state) {
        final settings = state.settings;
        return Scaffold(
          appBar: AppBar(title: const Text('Display Settings')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionTitle('Font Size'),
              Slider(
                value: settings.fontSize,
                min: 12,
                max: 32,
                divisions: 10,
                label: '${settings.fontSize.toInt()}',
                onChanged: (val) => context
                    .read<DisplaySettingsBloc>()
                    .add(UpdateFontSizeEvent(val)),
              ),
              const SizedBox(height: 16),
              _SectionTitle('Font'),
              ...DyslexiaFont.values.map(
                (f) => RadioListTile<DyslexiaFont>(
                  title: Text(_fontLabel(f)),
                  value: f,
                  // ignore: deprecated_member_use
                  groupValue: settings.font,
                  // ignore: deprecated_member_use
                  onChanged: (val) {
                    if (val != null) {
                      context
                          .read<DisplaySettingsBloc>()
                          .add(UpdateFontEvent(val));
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              _SectionTitle('Color Theme'),
              ...AppColorTheme.values.map(
                (t) => RadioListTile<AppColorTheme>(
                  title: Text(_themeLabel(t)),
                  value: t,
                  // ignore: deprecated_member_use
                  groupValue: settings.colorTheme,
                  // ignore: deprecated_member_use
                  onChanged: (val) {
                    if (val != null) {
                      context
                          .read<DisplaySettingsBloc>()
                          .add(UpdateColorThemeEvent(val));
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              _SectionTitle('Presets'),
              Wrap(
                spacing: 8,
                children: DisplayPreset.values
                    .map(
                      (p) => ChoiceChip(
                        label: Text(_presetLabel(p)),
                        selected: settings.preset == p,
                        onSelected: (_) => context
                            .read<DisplaySettingsBloc>()
                            .add(ApplyPresetEvent(p)),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  String _fontLabel(DyslexiaFont f) => switch (f) {
        DyslexiaFont.openDyslexic => 'OpenDyslexic',
        DyslexiaFont.lexend => 'Lexend',
        DyslexiaFont.arial => 'Arial',
        DyslexiaFont.verdana => 'Verdana',
      };

  String _themeLabel(AppColorTheme t) => switch (t) {
        AppColorTheme.light => 'Light',
        AppColorTheme.dark => 'Dark',
        AppColorTheme.yellowOnBlack => 'Yellow on Black',
        AppColorTheme.creamOnBlue => 'Cream on Blue',
      };

  String _presetLabel(DisplayPreset p) => switch (p) {
        DisplayPreset.defaultPreset => 'Default',
        DisplayPreset.dyslexiaFriendly => 'Dyslexia Friendly',
        DisplayPreset.highContrast => 'High Contrast',
        DisplayPreset.nightMode => 'Night Mode',
      };
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold)),
    );
  }
}
