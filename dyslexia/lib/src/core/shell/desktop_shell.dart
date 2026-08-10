import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../configs/injector/injector_conf.dart';
import '../blocs/theme/theme_bloc.dart';
import '../../core/api/api_helper.dart';
import '../../features/display_settings/presentation/bloc/display_settings/display_settings_bloc.dart';
import '../../features/reader/presentation/bloc/reader/reader_bloc.dart';
import '../../features/reader/presentation/bloc/reader_shell/reader_shell_bloc.dart';
import '../../features/reader/presentation/bloc/reader_shell/reader_shell_event.dart';
import '../../features/reader/presentation/bloc/reader_shell/reader_shell_state.dart';
import '../../features/reader/presentation/pages/reader_page.dart';
import '../../features/sidebar/domain/entities/sidebar_section.dart';
import '../../features/summarize/presentation/bloc/summarize_bloc.dart';
import '../../features/summarize/presentation/pages/summarize_page.dart';
import '../../features/define/presentation/bloc/define_bloc.dart';
import '../../features/define/presentation/pages/define_page.dart';
import '../../features/professionalize/presentation/bloc/professionalize_bloc.dart';
import '../../features/professionalize/presentation/pages/professionalize_page.dart';
import '../../features/screening/presentation/bloc/screening_bloc.dart';
import '../../features/screening/presentation/pages/screening_page.dart';
import '../themes/feature_accent.dart';
import 'display_settings_panel.dart';
import '../../features/sidebar/presentation/bloc/sidebar/sidebar_bloc.dart';
import '../../features/sidebar/presentation/bloc/sidebar/sidebar_event.dart';
import '../../features/sidebar/presentation/bloc/sidebar/sidebar_state.dart';
import '../../features/sidebar/presentation/pages/sidebar_shell_page.dart';
import '../../features/auth/presentation/widgets/auth_user_menu.dart';
import '../widgets/reader_landing_view.dart';

const Color _headerColorStart = Color(0xFFC9B8F0);
const Color _headerColorEnd = Color(0xFFB596E5);
const Color _headerBottomLayer = Color(0xFFD7C8FC);

const double kSidebarIconBreakpoint = 900;
const double kSidebarHiddenBreakpoint = 700;

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
    // ✅ KUNCI UTAMA: Memaksa DesktopShell untuk rebuild setiap kali font berubah.
    final _ = context.watch<DisplaySettingsBloc>().state.settings.font;

    final screenHeight = MediaQuery.of(context).size.height;

    return ScreenUtilInit(
      useInheritedMediaQuery: true,
      designSize: const Size(1920, 1080),
      minTextAdapt: true,
      splitScreenMode: false,
      builder: (context, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: getIt<ThemeBloc>()),
            BlocProvider.value(value: getIt<DisplaySettingsBloc>()),
            BlocProvider.value(value: getIt<SummarizeBloc>()),
            BlocProvider.value(value: getIt<DefineBloc>()),
            BlocProvider.value(value: getIt<ProfessionalizeBloc>()),
            BlocProvider.value(value: getIt<ScreeningBloc>()),
            BlocProvider.value(value: getIt<ReaderBloc>()),
            // NOTE: NO shell-scoped SidebarBloc here — the shell must bind to
            // the ROOT SidebarBloc provided by main.dart. The landing page
            // dispatches SidebarSectionSelected to that same root instance
            // before navigating here; a fresh per-shell SidebarBloc would
            // reset the section to the reader default and ignore the card the
            // user tapped.
            BlocProvider(create: (_) => ReaderShellBloc()),
            Provider.value(value: getIt<ApiHelper>()),
          ],
          child: Scaffold(
            // ✅ PERUBAHAN DI SINI: Mengganti background dari Colors.white ke #EFEEFE
            backgroundColor: const Color(0xFFEFEEFE),
            body: Stack(
              children: [
                // ==========================================
                // BACKGROUND 2 LAPIS UNGU (SAMPAI TENGAH)
                // ==========================================
                // Decorative background layers: Positioned is a
                // ParentDataWidget and MUST be a direct child of the Stack.
                // ExcludeSemantics wraps the painted Container inside it, so
                // the purple wash stays invisible to screen readers without
                // breaking the Stack parent-data contract (a Positioned
                // nested under ExcludeSemantics throws "Incorrect use of
                // ParentDataWidget" and blanks the whole shell).
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: ExcludeSemantics(
                    child: Container(
                      height: screenHeight * 0.55,
                      decoration: const BoxDecoration(
                        color: _headerBottomLayer,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(48),
                          bottomRight: Radius.circular(48),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: ExcludeSemantics(
                    child: Container(
                      height: screenHeight * 0.50,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_headerColorStart, _headerColorEnd],
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                      ),
                    ),
                  ),
                ),

                // ==========================================
                // KONTEN UTAMA (DITUMPANGKAN DI ATAS BACKGROUND)
                // ==========================================
                Column(
                  children: [
                    _ShellHeaderBar(
                      showGear: true,
                      onToggleSettings: () => setState(() => _settingsPanelOpen = !_settingsPanelOpen),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final compactSidebar = constraints.maxWidth < kSidebarIconBreakpoint;
                          final bottomNav = constraints.maxWidth < kSidebarHiddenBreakpoint;
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
                                              SidebarSection.summarize => const SummarizePage(),
                                              SidebarSection.define => const DefinePage(),
                                              SidebarSection.professionalize => const ProfessionalizePage(),
                                              SidebarSection.screening => const ScreeningPage(),
                                            },
                                    ),
                                    _BottomNavBar(
                                      currentSection: sidebar.section,
                                      showSettings: _bottomSettings,
                                      onSectionSelected: (s) {
                                        setState(() => _bottomSettings = false);
                                        context.read<SidebarBloc>().add(SidebarSectionSelected(s));
                                      },
                                      onToggleSettings: () => setState(() => _bottomSettings = !_settingsPanelOpen),
                                    ),
                                  ],
                                );
                              }
                              if (_bottomSettings && hiddenSidebar) {
                                return const Row(
                                  children: [
                                    Expanded(child: DisplaySettingsPanel()),
                                  ],
                                );
                              }
                              return Row(
                                children: [
                                  if (!hiddenSidebar)
                                    SidebarShellPage(compact: compactSidebar, touchMode: touchMode),
                                  Expanded(
                                    child: switch (sidebar.section) {
                                      SidebarSection.reader => const MainColumn(),
                                      SidebarSection.summarize => const SummarizePage(),
                                      SidebarSection.define => const DefinePage(),
                                      SidebarSection.professionalize => const ProfessionalizePage(),
                                      SidebarSection.screening => const ScreeningPage(),
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
              ],
            ),
          ),
        );
      },
    );
  }
}

// ==========================================
// WIDGET PENDUKUNG (DIPERTAHANKAN 100% UTUH)
// ==========================================

class MainColumn extends StatefulWidget {
  const MainColumn({super.key});

  @override
  State<MainColumn> createState() => _MainColumnState();
}

class _MainColumnState extends State<MainColumn> {
  void _onBack() {
    context.read<ReaderShellBloc>().add(const ClearTextEvent());
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
              const ReaderLandingView(),
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

class _PdfProgressOverlay extends StatelessWidget {
  final int current;
  final int total;
  const _PdfProgressOverlay({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : current / total;
    final theme = Theme.of(context);
    final fg = theme.colorScheme.onSurface;
    return Positioned.fill(
      child: Container(
        color: fg.withValues(alpha: 0.9),
        child: Center(
          child: Card(
            color: theme.colorScheme.surface,
            margin: const EdgeInsets.symmetric(horizontal: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.picture_as_pdf, size: 40, color: fg.withValues(alpha: 0.6)),
                  const SizedBox(height: 16),
                  Text(
                    'Processing PDF...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 8,
                      backgroundColor: fg.withValues(alpha: 0.15),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF3D5A99)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Page $current of $total',
                    style: TextStyle(fontSize: 13, color: fg.withValues(alpha: 0.6)),
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

class _ShellHeaderBar extends StatelessWidget {
  final bool showGear;
  final VoidCallback? onToggleSettings;
  const _ShellHeaderBar({this.showGear = false, this.onToggleSettings});

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (showGear && screenW >= kSidebarHiddenBreakpoint)
            IconButton(
              tooltip: 'Toggle display settings',
              icon: Icon(
                Icons.tune_outlined,
                color: Colors.white.withValues(alpha: 0.9),
                size: 24,
              ),
              onPressed: onToggleSettings,
            ),
          const SizedBox(width: 8),
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
            final selected = !showSettings && currentSection == section;
            // Each feature gets its own accent so tabs are distinguishable
            // by colour in addition to icon + label (never colour alone).
            final fg = selected ? featureAccent(section).strong : muted;
            return Expanded(
              child: Semantics(
                label: '${section.label} feature',
                button: true,
                selected: selected,
                child: InkWell(
                  onTap: () => onSectionSelected(section),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(section.materialIcon, size: 20, color: fg),
                      const SizedBox(height: 2),
                      Text(
                        section.label,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                          color: fg,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          Expanded(
            child: Semantics(
              label: 'Settings',
              button: true,
              selected: showSettings,
              toggled: showSettings,
              child: InkWell(
                onTap: onToggleSettings,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      showSettings ? Icons.tune : Icons.tune_outlined,
                      size: 20,
                      color: showSettings ? const Color(0xFF3D5A99) : muted,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: showSettings ? FontWeight.w600 : FontWeight.w500,
                        color: showSettings ? const Color(0xFF3D5A99) : muted,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}