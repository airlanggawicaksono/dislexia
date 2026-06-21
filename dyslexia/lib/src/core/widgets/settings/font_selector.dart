import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/display_settings/domain/entities/display_settings_entity.dart';
import '../../../features/display_settings/presentation/bloc/display_settings/display_settings_bloc.dart';
import '../../utils/font_utils.dart';

class FontSelector extends StatelessWidget {
  const FontSelector({super.key});

  static const _fonts = <DyslexiaFont>[
    DyslexiaFont.openDyslexic,
    DyslexiaFont.lexend,
    DyslexiaFont.plusJakartaSans,
    DyslexiaFont.sassoonPrimary,
    DyslexiaFont.tahoma,
    DyslexiaFont.weezerFont,
    DyslexiaFont.verdana,
    DyslexiaFont.trebuchetMS,
    DyslexiaFont.helvetica,
    DyslexiaFont.arial,
    DyslexiaFont.comicSansMS,
    DyslexiaFont.calibri,
  ];

  static const _labels = {
    DyslexiaFont.openDyslexic: 'OpenDyslexic',
    DyslexiaFont.plusJakartaSans: 'Plus Jakarta Sans',
    DyslexiaFont.lexend: 'Lexend',
    DyslexiaFont.sassoonPrimary: 'Sassoon Primary',
    DyslexiaFont.tahoma: 'Tahoma',
    DyslexiaFont.weezerFont: 'WeezerFont',
    DyslexiaFont.verdana: 'Verdana',
    DyslexiaFont.trebuchetMS: 'Trebuchet MS',
    DyslexiaFont.helvetica: 'Helvetica',
    DyslexiaFont.arial: 'Arial',
    DyslexiaFont.comicSansMS: 'Comic Sans MS',
    DyslexiaFont.calibri: 'Calibri',
  };

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DisplaySettingsBloc, DisplaySettingsState>(
      builder: (context, state) {
        final bloc = context.read<DisplaySettingsBloc>();
        final selected = state.settings.font;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _fonts.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (_, i) {
            final font = _fonts[i];
            final label = _labels[font] ?? '';
            final isSelected = selected == font;
            final selectedBg = const Color(0xFF3D5A99);
            final idleBg = const Color(0xFFEFEADF);

            return GestureDetector(
              onTap: () => bloc.add(UpdateFontEvent(font)),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? selectedBg : idleBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? selectedBg : Colors.black12,
                    width: isSelected ? 2.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Aa',
                      style: applyDyslexiaFont(
                        font: font,
                        baseStyle: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 9,
                        color: isSelected ? Colors.white70 : Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
