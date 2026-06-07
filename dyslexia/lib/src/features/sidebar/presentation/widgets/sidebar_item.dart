import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/sidebar_section.dart';

class SidebarItem extends StatelessWidget {
  final SidebarSection section;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;
  final bool touchMode;

  const SidebarItem({
    super.key,
    required this.section,
    required this.selected,
    required this.onTap,
    this.compact = false,
    this.touchMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final isCupertino = _useCupertinoIcons();
    final icon = isCupertino ? section.cupertinoIcon : section.materialIcon;
    final theme = Theme.of(context);
    final accent = const Color(0xFF3D5A99);
    final idleFg = theme.colorScheme.onSurface.withValues(alpha: 0.75);
    final selectedFg = accent;
    final idleBg = Colors.transparent;
    final selectedBg = accent.withValues(alpha: 0.12);
    final fg = selected ? selectedFg : idleFg;
    final bg = selected ? selectedBg : idleBg;
    final itemSize = touchMode ? 56.0 : 72.0;

    return Tooltip(
      message: section.label,
      preferBelow: false,
      waitDuration: const Duration(milliseconds: 300),
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
              Icon(icon, size: compact ? 24 : 22, color: fg),
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
    );
  }

  bool _useCupertinoIcons() {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }
}
