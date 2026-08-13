import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
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
    final selectedBg = accent.withValues(alpha: 0.12);
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
              border: Border(
                left: BorderSide(
                  color: selected ? accent : Colors.transparent,
                  width: 3,
                ),
              ),
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
    // Use Material/Cupertino icons so the colour parameter is respected.
    // PNG glyphs (white-on-colour) are only appropriate on the landing
    // cards; on the tinted sidebar they wash out.
    final isCupertino = _useCupertinoIcons();
    final icon = isCupertino ? section.cupertinoIcon : section.materialIcon;
    return Icon(icon, size: size, color: color);
  }

  bool _useCupertinoIcons() {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }
}