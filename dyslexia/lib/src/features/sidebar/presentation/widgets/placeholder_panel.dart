import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/sidebar_section.dart';

/// Generic "Coming soon" view rendered for unimplemented sidebar sections.
///
/// The icon and copy come from [SidebarSection]; the accent rail and
/// centred layout match the rest of the desktop shell. Designed to be
/// drop-in compatible with the existing 2-column or 3-column shell --
/// it expands to fill whatever space the parent gives it.
class PlaceholderPanel extends StatelessWidget {
  final SidebarSection section;
  const PlaceholderPanel({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    final isCupertino = _useCupertinoIcons();
    final icon =
        isCupertino ? section.cupertinoIcon : section.materialIcon;
    final theme = Theme.of(context);
    final accent = const Color(0xFF3D5A99);
    final fg = theme.colorScheme.onSurface;
    final muted = fg.withValues(alpha: 0.55);
    final tile = fg.withValues(alpha: 0.06);

    return Container(
      color: theme.colorScheme.surface,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: ConstrainedBox(
        constraints: const ConstrainedBox.tightFor(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: tile,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: accent),
            ),
            const SizedBox(height: 20),
            Text(
              '${section.label}',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: fg,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Not Implemented',
              style: theme.textTheme.titleMedium?.copyWith(
                color: accent,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Text(
              'The ${section.label.toLowerCase()} feature is on the roadmap. '
              'For now, head back to Reader to keep using the app.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: muted,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
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
