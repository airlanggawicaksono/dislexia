import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/display_settings/domain/entities/display_settings_entity.dart';
import '../../features/display_settings/presentation/bloc/display_settings/display_settings_bloc.dart';
import '../widgets/settings/accessibility_toggles.dart';
import '../widgets/settings/color_selector.dart';
import '../widgets/settings/font_selector.dart';
import '../widgets/settings/live_preview.dart';
import '../widgets/settings/typography_sliders.dart';

class DisplaySettingsPanel extends StatefulWidget {
  const DisplaySettingsPanel({super.key});

  @override
  State<DisplaySettingsPanel> createState() => _DisplaySettingsPanelState();
}

class _DisplaySettingsPanelState extends State<DisplaySettingsPanel> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  void _scrollBy(double delta) {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final target =
        (_scrollController.offset + delta).clamp(pos.minScrollExtent, pos.maxScrollExtent);
    _scrollController.jumpTo(target);
  }

  /// Makes the panel scrollable from the keyboard. When the panel region
  /// itself is focused, arrows move through the panel; otherwise arrow keys
  /// stay with inner controls (sliders, switches) and only PageUp/PageDown/
  /// Home/End scroll.
  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    const step = 56.0;
    const page = 400.0;

    if (key == LogicalKeyboardKey.home) {
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.end) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.pageUp) {
      _scrollBy(-page);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.pageDown) {
      _scrollBy(page);
      return KeyEventResult.handled;
    }
    if (node.hasPrimaryFocus) {
      if (key == LogicalKeyboardKey.arrowUp) {
        _scrollBy(-step);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowDown) {
        _scrollBy(step);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  static const _presetLabels = {
    DisplayPreset.defaultPreset: 'Default',
    DisplayPreset.dyslexiaFriendly: 'Dyslexia Friendly',
    DisplayPreset.highContrast: 'High Contrast',
    DisplayPreset.lightBlueTheme: 'Light Blue',
    DisplayPreset.greyTheme: 'Grey',
    DisplayPreset.lavenderTheme: 'Lavender',
    DisplayPreset.whiteTheme: 'White',
    DisplayPreset.skyBlueTheme: 'Sky Blue',
    DisplayPreset.mintGreenTheme: 'Mint Green',
    DisplayPreset.peachTheme: 'Peach',
  };

  static const _presetSubtitles = {
    DisplayPreset.defaultPreset: 'OpenDyslexic - Cream - 18pt',
    DisplayPreset.dyslexiaFriendly: 'OpenDyslexic - Cream - 20pt - 2.0x',
    DisplayPreset.highContrast: 'Plus Jakarta Sans - White - 22pt',
    DisplayPreset.lightBlueTheme: 'Sassoon Primary - Light Blue - 18pt',
    DisplayPreset.greyTheme: 'Tahoma - Grey - 18pt',
    DisplayPreset.lavenderTheme: 'Sassoon Primary - Lavender - 18pt',
    DisplayPreset.whiteTheme: 'OpenDyslexic - White - 18pt',
    DisplayPreset.skyBlueTheme: 'Plus Jakarta Sans - Sky Blue - 18pt',
    DisplayPreset.mintGreenTheme: 'Lexend - Mint Green - 18pt',
    DisplayPreset.peachTheme: 'Sassoon Primary - Peach - 18pt',
  };

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DisplaySettingsBloc, DisplaySettingsState>(
      builder: (context, state) {
        final s = state.settings;
        final theme = Theme.of(context);
        final bloc = context.read<DisplaySettingsBloc>();
        final focused = _focusNode.hasPrimaryFocus;

        return LayoutBuilder(
          builder: (context, constraints) {
            final fullWidth = constraints.maxWidth < 720;
            return Container(
              width: fullWidth ? double.infinity : 248,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(right: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5))),
              ),
              child: SafeArea(
                child: Semantics(
                  container: true,
                  label: 'Display settings panel',
                  child: Focus(
                    focusNode: _focusNode,
                    onKeyEvent: _onKeyEvent,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: focused
                              ? const Color(0xFF3D5A99)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ListView(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Settings',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
                            ],
                          ),
                          if (fullWidth) ...[
                            const SizedBox(height: 12),
                            _CollapsibleSection(
                              title: 'LIVE PREVIEW',
                              initiallyExpanded: true,
                              child: const LivePreview(),
                            ),
                          ],
                          _CollapsibleSection(
                            title: 'FONT',
                            initiallyExpanded: true,
                            child: FontSelector(compact: !fullWidth),
                          ),
                          const SizedBox(height: 12),
                          _CollapsibleSection(
                            title: 'BACKGROUND COLOR',
                            initiallyExpanded: true,
                            child: ColorSelector(compact: !fullWidth),
                          ),
                          const SizedBox(height: 12),
                          _CollapsibleSection(
                            title: 'TYPOGRAPHY',
                            initiallyExpanded: true,
                            child: TypographySliders(compact: !fullWidth),
                          ),
                          const SizedBox(height: 8),
                          _CollapsibleSection(
                            title: 'ACCESSIBILITY',
                            initiallyExpanded: true,
                            child: const AccessibilityToggles(),
                          ),
                          const SizedBox(height: 12),
                          // Presets are collapsed by default so the panel
                          // doesn't force the user through a long scroll.
                          _CollapsibleSection(
                            title: 'PRESETS',
                            initiallyExpanded: false,
                            child: Column(
                              children: [
                                ...DisplayPreset.values.map((p) => _PresetChip(
                                    label: _presetLabels[p] ?? '',
                                    subtitle: _presetSubtitles[p] ?? '',
                                    selected: s.preset == p,
                                    onTap: () => bloc.add(ApplyPresetEvent(p)),
                                    surfaceColor: theme.colorScheme.onSurface.withValues(alpha: 0.08))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Section header that can be collapsed/expanded to keep the panel compact.
/// Keyboard accessible (InkWell) with an announced expanded state.
class _CollapsibleSection extends StatefulWidget {
  final String title;
  final bool initiallyExpanded;
  final Widget child;

  const _CollapsibleSection({
    required this.title,
    required this.initiallyExpanded,
    required this.child,
  });

  @override
  State<_CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<_CollapsibleSection> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Outer Semantics must not exclude the subtree: that would drop the
        // InkWell's tap action and the section could never be expanded from a
        // screen reader. Only the visual content below the InkWell is hidden.
        Semantics(
          label: widget.title,
          toggled: _expanded,
          expanded: _expanded,
          button: true,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(6),
              child: ExcludeSemantics(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    Icon(
                      _expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ],
                  ),
                ),
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 180),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox(width: double.infinity),
          secondChild: widget.child,
          sizeCurve: Curves.easeOut,
        ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Color surfaceColor;
  const _PresetChip({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    required this.surfaceColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF3D5A99).withValues(alpha: 0.15) : surfaceColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? const Color(0xFF3D5A99) : Colors.transparent, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? const Color(0xFF3D5A99) : surfaceColor.withValues(alpha: 1))),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 9,
                      color: selected ? const Color(0xFF3D5A99).withValues(alpha: 0.7) : Colors.black45),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
