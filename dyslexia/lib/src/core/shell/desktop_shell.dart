import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../configs/injector/injector_conf.dart';
import '../blocs/theme/theme_bloc.dart';
import '../themes/app_theme.dart';
import '../../core/constants/sample_text.dart';
import '../../features/display_settings/presentation/bloc/display_settings/display_settings_bloc.dart';
import '../../features/display_settings/presentation/theme/display_colors.dart';
import '../../features/reader/presentation/bloc/reader/reader_bloc.dart';
import '../../features/reader/presentation/bloc/reader_shell/reader_shell_bloc.dart';
import '../../features/reader/presentation/bloc/reader_shell/reader_shell_event.dart';
import '../../features/reader/presentation/bloc/reader_shell/reader_shell_state.dart';
import '../../features/reader/presentation/pages/reader_page.dart';
import '../../features/sidebar/domain/entities/sidebar_section.dart';
import '../../features/summarize/presentation/pages/summarize_page.dart';
import '../../features/define/presentation/pages/define_page.dart';
import '../../features/professionalize/presentation/pages/professionalize_page.dart';
import 'display_settings_panel.dart';
import '../../features/sidebar/presentation/bloc/sidebar/sidebar_bloc.dart';
import '../../features/sidebar/presentation/bloc/sidebar/sidebar_event.dart';
import '../../features/sidebar/presentation/bloc/sidebar/sidebar_state.dart';
import '../../features/sidebar/presentation/pages/sidebar_shell_page.dart';
import '../../features/sidebar/presentation/widgets/placeholder_panel.dart';
import '../../features/auth/presentation/widgets/auth_user_menu.dart';

/// Width below which the sidebar collapses to icon-only.
const double kSidebarIconBreakpoint = 900;
/// Width below which the sidebar is completely hidden.
const double kSidebarHiddenBreakpoint = 700;

/// 3-column desktop shell driven by [SidebarBloc]:
///   [ SidebarShellPage ] [ Main content ] [ DisplaySettingsPanel? ]
///
/// - Column 1: sidebar rail (Reader, Summarize, Define, Personalize,
///   Screening). 96 px wide; selection state lives in [SidebarBloc].
/// - Column 2: the main content area. Switches on the active
///   [SidebarSection]. Reader renders the existing
///   [FeatureCanvas]+[MainColumn]+landing stack; the other 4 sections
///   render a [PlaceholderPanel].
/// - Column 3: typography/accessibility settings. Only shown when the
///   active section is implemented (currently just Reader) AND the
///   window is at least [kShellCompactBreakpoint] wide.
///
/// The reader main column's view-state (loaded text, source, PDF
/// progress) is owned by [ReaderShellBloc] so the column itself is a
/// pure stateless widget that BlocBuilder's the state. Children that
/// need to mutate the column (FeatureCanvas, ReaderPage) dispatch
/// events through `context.read<ReaderShellBloc>()` — no ancestor
/// state lookup is required.
class DesktopShell extends StatefulWidget {
  const DesktopShell({super.key});

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  bool _bottomSettings = false;
  bool _settingsPanelOpen = true;

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      useInheritedMediaQuery: true,
      designSize: const Size(1920, 1080),
      minTextAdapt: true,
      splitScreenMode: false,
      builder: (context, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => getIt<ThemeBloc>()),
            BlocProvider(create: (_) => getIt<DisplaySettingsBloc>()),
            BlocProvider(create: (_) => getIt<ReaderBloc>()),
            BlocProvider(create: (_) => SidebarBloc()),
            BlocProvider(create: (_) => ReaderShellBloc()),
          ],
          child: BlocBuilder<DisplaySettingsBloc, DisplaySettingsState>(
            builder: (context, displayState) {
              return BlocBuilder<ThemeBloc, ThemeState>(
                builder: (_, themeState) {
                  return MaterialApp(
                    debugShowCheckedModeBanner: false,
                    theme: AppTheme.data(themeState.isDarkMode),
                    home: Scaffold(
                      body: Column(
                        children: [
                          _ShellHeaderBar(
                            showGear: true,
                            onToggleSettings: () => setState(
                                () => _settingsPanelOpen = !_settingsPanelOpen),
                          ),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final compactSidebar = constraints.maxWidth <
                                    kSidebarIconBreakpoint;
                                final bottomNav = constraints.maxWidth <
                                    kSidebarHiddenBreakpoint;
                                final hiddenSidebar = bottomNav;
                                final touchMode = constraints.maxWidth < 800;
                                return BlocBuilder<SidebarBloc, SidebarState>(
                                  builder: (context, sidebar) {
                                    if (bottomNav) {
                                      return Column(
                                        children: [
                                          Expanded(
                                              child: _bottomSettings
                                                  ? const DisplaySettingsPanel()
                                                : switch (sidebar.section) {
                                                    SidebarSection.reader => const MainColumn(),
                                                    SidebarSection.summarize =>
                                                      const SummarizePage(),
                                                    SidebarSection.define =>
                                                      const DefinePage(),
                                                    SidebarSection.professionalize =>
                                                      const ProfessionalizePage(),
                                                    _ => PlaceholderPanel(section: sidebar.section),
                                                  },
                                          ),
                                          _BottomNavBar(
                                            currentSection: sidebar.section,
                                            showSettings: _bottomSettings,
                                            onSectionSelected: (s) {
                                              setState(() => _bottomSettings = false);
                                              context
                                                  .read<SidebarBloc>()
                                                  .add(SidebarSectionSelected(s));
                                            },
                                            onToggleSettings: () => setState(
                                                () => _bottomSettings = !_bottomSettings),
                                          ),
                                        ],
                                      );
                                    }
                                    if (_bottomSettings && hiddenSidebar) {
                                      return Row(
                                        children: [
                                          Expanded(
                                            child: const DisplaySettingsPanel(),
                                          ),
                                        ],
                                      );
                                    }
                                    return Row(
                                      children: [
                                        if (!hiddenSidebar)
                                          SidebarShellPage(
                                              compact: compactSidebar, touchMode: touchMode),
                                        Expanded(
                                          child: switch (sidebar.section) {
                                            SidebarSection.reader => const MainColumn(),
                                            SidebarSection.summarize =>
                                              const SummarizePage(),
                                            SidebarSection.define =>
                                              const DefinePage(),
                                            SidebarSection.professionalize =>
                                              const ProfessionalizePage(),
                                            _ => PlaceholderPanel(
                                                section: sidebar.section,
                                              ),
                                          },
                                        ),
                                        if (!hiddenSidebar && _settingsPanelOpen)
                                          const DisplaySettingsPanel(),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

/// Column 2: main content area. The reader page is the default destination;
/// before any text is loaded we show the web landing content (paste/upload CTA).
///
/// View-state is owned by [ReaderShellBloc] — the widget is stateless and
/// BlocBuilder's the state. The auto-load of the sample text is dispatched
/// on first frame.
class MainColumn extends StatefulWidget {
  const MainColumn({super.key});

  @override
  State<MainColumn> createState() => _MainColumnState();
}

class _MainColumnState extends State<MainColumn> {
  bool _autoLoadDispatched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _autoLoadDispatched) return;
      _autoLoadDispatched = true;
      // Auto-load the dyslexia sample on first launch so users see content
      // immediately, matching the React web reference behaviour.
      context
          .read<ReaderShellBloc>()
          .add(const LoadTextEvent(kDyslexiaSampleText, source: 'Sample'));
    });
  }

  void _onBack() {
    // Returning to landing always reloads the sample text so the user
    // sees the dyslexia sample in the reader (with ruler, syllabify,
    // display settings) instead of an empty column.
    context.read<ReaderShellBloc>().add(
          const LoadTextEvent(kDyslexiaSampleText, source: 'Sample'),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReaderShellBloc, ReaderShellState>(
      builder: (context, state) {
        return Stack(
          children: [
            if (state.showReader)
              ReaderPage(
                key: const ValueKey('reader'),
                text: state.text,
                sourceName: state.source,
                onBack: _onBack,
              )
            else
              const SizedBox.expand(),
            if (state.pdfProgress != null)
              _PdfProgressOverlay(
                current: state.pdfProgress!.current,
                total: state.pdfProgress!.total,
              ),
          ],
        );
      },
    );
  }
}

/// Translucent PDF processing overlay. Pulled out of [MainColumn] so the
/// state-building branch stays readable.
class _PdfProgressOverlay extends StatelessWidget {
  final int current;
  final int total;
  const _PdfProgressOverlay({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : current / total;
    final ds = context.read<DisplaySettingsBloc>().state.settings;
    final bg = bgColor(ds.colorTheme);
    final fg = fgColor(ds.colorTheme);
    return Positioned.fill(
      child: Container(
        color: fg.withValues(alpha: 0.4),
        child: Center(
          child: Card(
            color: bg,
            margin: const EdgeInsets.symmetric(horizontal: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.picture_as_pdf,
                      size: 40, color: fg.withValues(alpha: 0.6)),
                  const SizedBox(height: 16),
                  Text(
                    'Processing PDF...',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600, color: fg),
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 8,
                      backgroundColor: fg.withValues(alpha: 0.15),
                      valueColor:
                          const AlwaysStoppedAnimation(Color(0xFF3D5A99)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Page $current of $total',
                    style: TextStyle(
                        fontSize: 13, color: fg.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Slim top bar that sits above the 3-column body. Hosts the
/// [DisplaySettingsPanel] toggle (gear icon) and the [AuthUserMenu]
/// on the right edge. The gear button is only shown on wider screens
/// (>= 700px) — on narrow screens the settings toggle lives in the
/// bottom nav bar.
class _ShellHeaderBar extends StatelessWidget {
  final bool showGear;
  final VoidCallback? onToggleSettings;
  const _ShellHeaderBar({this.showGear = false, this.onToggleSettings});

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (showGear && screenW >= kSidebarHiddenBreakpoint)
            IconButton(
              tooltip: 'Toggle display settings',
              icon: Icon(Icons.tune_outlined, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), size: 20),
              onPressed: onToggleSettings,
            ),
          const SizedBox(width: 4),
          const AuthUserMenu(),
        ],
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final SidebarSection currentSection;
  final bool showSettings;
  final ValueChanged<SidebarSection> onSectionSelected;
  final VoidCallback onToggleSettings;
  const _BottomNavBar({
    required this.currentSection,
    required this.showSettings,
    required this.onSectionSelected,
    required this.onToggleSettings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = const Color(0xFF3D5A99);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          ...SidebarSection.values.map((section) {
            final selected = currentSection == section;
            final fg = selected ? accent : muted;
            return Expanded(
              child: InkWell(
                onTap: () => onSectionSelected(section),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(section.materialIcon, size: 20, color: fg),
                    const SizedBox(height: 2),
                    Text(section.label, style: TextStyle(fontSize: 9, fontWeight: selected ? FontWeight.w600 : FontWeight.w500, color: fg), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            );
          }),
          Expanded(
            child: InkWell(
              onTap: onToggleSettings,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(showSettings ? Icons.tune : Icons.tune_outlined, size: 20, color: showSettings ? accent : muted),
                  const SizedBox(height: 2),
                  Text('Settings', style: TextStyle(fontSize: 9, fontWeight: showSettings ? FontWeight.w600 : FontWeight.w500, color: showSettings ? accent : muted), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
