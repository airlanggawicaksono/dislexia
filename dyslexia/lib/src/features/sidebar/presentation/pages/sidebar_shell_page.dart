import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/sidebar/sidebar_bloc.dart';
import '../bloc/sidebar/sidebar_event.dart';
import '../bloc/sidebar/sidebar_state.dart';
import '../../domain/entities/sidebar_section.dart';
import '../widgets/sidebar_item.dart';

/// Vertical rail widget that lists all 5 sidebar sections.
///
/// Rendered as Column 1 of the desktop 3-column shell. Stateless on its
/// own: selection state lives in [SidebarBloc]. The rail is always
/// narrow (96px) so the rest of the window is reserved for content.
class SidebarShellPage extends StatelessWidget {
  final bool compact;
  const SidebarShellPage({super.key, this.compact = false});

  static const _fullWidth = 96.0;
  static const _compactWidth = 56.0;

  double get width => compact ? _compactWidth : _fullWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final borderColor = theme.dividerColor.withValues(alpha: 0.5);

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: surface,
        border: Border(right: BorderSide(color: borderColor)),
      ),
      child: SafeArea(
        child: BlocBuilder<SidebarBloc, SidebarState>(
          builder: (context, state) {
            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                for (final section in SidebarSection.values) ...[
                  SidebarItem(
                    section: section,
                    compact: compact,
                    selected: state.section == section,
                    onTap: () => context
                        .read<SidebarBloc>()
                        .add(SidebarSectionSelected(section)),
                  ),
                  const SizedBox(height: 4),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
