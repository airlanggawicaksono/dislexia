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
import 'display_settings_panel.dart';
import '../../features/sidebar/presentation/bloc/sidebar/sidebar_bloc.dart';
import '../../features/sidebar/presentation/bloc/sidebar/sidebar_state.dart';
import '../../features/sidebar/presentation/pages/sidebar_shell_page.dart';
import '../../features/sidebar/presentation/widgets/placeholder_panel.dart';
import '../../features/auth/presentation/widgets/auth_user_menu.dart';

/// Width below which the shell switches to its compact layout:
/// the typography/accessibility settings column is hidden and the
/// feature canvas collapses to an icon-only rail so the reader gets
/// the room it needs.
const double kShellCompactBreakpoint = 800;

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
  // Whether the right-hand DisplaySettingsPanel is shown. Toggled
  // from the gear button in the shell's top bar. Defaults to open
  // so users see the typography controls immediately on launch.
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
                          const _ShellHeaderBar(),
                          Expanded(
                            child: BlocBuilder<SidebarBloc, SidebarState>(
                              builder: (context, sidebar) {
                                return Row(
                                  children: [
                                    const SidebarShellPage(),
                                    Expanded(
                                      child: switch (sidebar.section) {
                                        SidebarSection.reader => MainColumn(
                                            settingsPanelOpen:
                                                _settingsPanelOpen,
                                            onToggleSettings: () =>
                                                setState(
                                              () => _settingsPanelOpen =
                                                  !_settingsPanelOpen,
                                            ),
                                          ),
                                        SidebarSection.summarize =>
                                          const SummarizePage(),
                                        _ => PlaceholderPanel(
                                            section: sidebar.section,
                                          ),
                                      },
                                    ),
                                  ],
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
  final bool settingsPanelOpen;
  final VoidCallback? onToggleSettings;
  const MainColumn({
    super.key,
    this.settingsPanelOpen = true,
    this.onToggleSettings,
  });

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
        return Row(
          children: [
            Expanded(
              child: Stack(
                children: [
                  if (state.showReader)
                    ReaderPage(
                      key: const ValueKey('reader'),
                      text: state.text,
                      sourceName: state.source,
                      onBack: _onBack,
                      settingsPanelOpen: widget.settingsPanelOpen,
                      onToggleSettings: widget.onToggleSettings,
                    )
                  else
                    const SizedBox.expand(),
                  if (state.pdfProgress != null)
                    _PdfProgressOverlay(
                      current: state.pdfProgress!.current,
                      total: state.pdfProgress!.total,
                    ),
                ],
              ),
            ),
            // The settings panel is rendered inside the reader column
            // so it only shows up when the Reader section is active.
            // Toggled via the gear button in the reader's top bar.
            if (widget.settingsPanelOpen)
              DisplaySettingsPanel(
                onClose: () => widget.onToggleSettings?.call(),
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
/// [AuthUserMenu] on the right edge. The reader's own AppBar
/// provides all input controls including the settings toggle.
class _ShellHeaderBar extends StatelessWidget {
  const _ShellHeaderBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerRight,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: const AuthUserMenu(),
    );
  }
}
