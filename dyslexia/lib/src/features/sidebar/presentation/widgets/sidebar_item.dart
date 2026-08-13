import 'package:flutter/material.dart';

import '../../../../core/themes/feature_accent.dart';
import '../../domain/entities/sidebar_section.dart';

class SidebarItem extends StatelessWidget {
  final SidebarSection section;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;
  final bool touchMode;
  /// When the sidebar has a tinted background, pass the accent's onTint
  /// colour here so idle icons + labels stay dark and readable.
  final Color? foregroundColor;

  const SidebarItem({
    super.key,
    required this.section,
    required this.selected,
    required this.onTap,
    this.compact = false,
    this.touchMode = false,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = featureAccent(section).strong;
    final idleFg = foregroundColor ?? theme.colorScheme.onSurface.withValues(alpha: 0.75);
    final selectedFg = accent;
    final idleBg = Colors.transparent;
    final selectedBg = Colors.white;
    final fg = selected ? selectedFg : idleFg;
    final bg = selected ? selectedBg : idleBg;
    final itemSize = touchMode ? 56.0 : 72.0;
    final iconSize = compact ? 24.0 : 22.0;

    return Tooltip(
      message: section.label,
      preferBelow: false,
      waitDuration: const Duration(milliseconds: 300),
      child: Semantics(
        // Screen readers get a labelled, selectable button; the selected
        // state is announced too so colour is never the only signal.
        label: '${section.label} feature',
        button: true,
        selected: selected,
        child: InkResponse(
          onTap: onTap,
          radius: touchMode ? 28 : 32,
          highlightShape: BoxShape.circle,
          child: Container(
            width: itemSize,
            height: itemSize,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border(
                left: BorderSide(
                  color: selected ? accent : Colors.transparent,
                  width: 3,
                ),
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              
                _buildCustomIcon(section, iconSize, fg),
                if (!compact) ...[
                  const SizedBox(height: 4),
                  Text(
                    section.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: fg,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildCustomIcon(SidebarSection section, double size, Color color) {
    // Render the feature PNG inside a small tinted square so the white
    // glyph is always readable — matching the landing cards' look.
    final containerSize = compact ? 32.0 : 36.0;
    final iconSize = compact ? 18.0 : 20.0;
    final tintBg = featureAccent(section).tint;
    return Container(
      width: containerSize,
      height: containerSize,
      decoration: BoxDecoration(
        color: tintBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Image.asset(
          _iconPathFor(section),
          width: iconSize,
          height: iconSize,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  String _iconPathFor(SidebarSection section) {
    return switch (section) {
      SidebarSection.reader        => 'assets/images/reader.png',
      SidebarSection.summarize     => 'assets/images/summarize.png',
      SidebarSection.define        => 'assets/images/define.png',
      SidebarSection.professionalize => 'assets/images/profesionalize.png',
      SidebarSection.screening     => 'assets/images/screenings.png',
    };
  }


}