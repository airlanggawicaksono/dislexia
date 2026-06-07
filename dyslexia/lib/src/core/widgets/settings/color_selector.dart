import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/display_settings/domain/entities/display_settings_entity.dart';
import '../../../features/display_settings/presentation/bloc/display_settings/display_settings_bloc.dart';
import '../../../features/display_settings/presentation/theme/display_colors.dart';

bool get _cupertinoCheck =>
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;

class ColorSelector extends StatelessWidget {
  final bool compact;
  const ColorSelector({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DisplaySettingsBloc, DisplaySettingsState>(
      builder: (context, state) {
        final bloc = context.read<DisplaySettingsBloc>();
        final selected = state.settings.colorTheme;
        final entries = AppColorTheme.values;

        if (compact) {
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: entries.map((theme) {
              final isSelected = selected == theme;
              return GestureDetector(
                onTap: () => bloc.add(UpdateColorThemeEvent(theme)),
                child: Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    color: bgColor(theme),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF3D5A99) : Colors.black12,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: isSelected
                      ? const Center(child: Icon(Icons.check, size: 10, color: Color(0xFF3D5A99)))
                      : null,
                ),
              );
            }).toList(),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: entries.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (_, i) {
            final theme = entries[i];
            final color = bgColor(theme);
            final label = colorLabel(theme);
            final isSelected = selected == theme;
            return GestureDetector(
              onTap: () => bloc.add(UpdateColorThemeEvent(theme)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF3D5A99) : Colors.black12,
                          width: isSelected ? 2.5 : 1,
                        ),
                      ),
                      child: isSelected
                          ? Center(
                              child: Container(
                                width: 24, height: 24,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3D5A99).withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _cupertinoCheck ? CupertinoIcons.checkmark : Icons.check_rounded,
                                  size: 16, color: const Color(0xFF3D5A99),
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(label,
                      style: const TextStyle(fontSize: 9, color: Colors.black54),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
