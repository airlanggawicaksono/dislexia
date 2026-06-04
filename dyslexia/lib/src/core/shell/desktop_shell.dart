import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../features/upload/data/datasources/pdf_extractor_service.dart';
import 'display_settings_panel.dart';
import 'feature_canvas.dart';
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
class DesktopShell extends StatelessWidget {
  const DesktopShell({super.key});

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
                          Builder(
                            builder: (ctx) => _ShellHeaderBar(
                              onTextExtracted: (text, source) {
                                ctx
                                    .read<ReaderShellBloc>()
                                    .add(LoadTextEvent(text, source: source));
                              },
                              onPdfProgress: (current, total) {
                                ctx.read<ReaderShellBloc>().add(
                                      SetPdfProgressEvent(
                                          current: current, total: total),
                                    );
                              },
                              onFeedback: (message) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(content: Text(message)),
                                );
                              },
                            ),
                          ),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final compact = constraints.maxWidth <
                                    kShellCompactBreakpoint;
                                return BlocBuilder<SidebarBloc, SidebarState>(
                                  builder: (context, sidebar) {
                                    final isImplemented =
                                        sidebar.section.isImplemented;
                                    return Row(
                                      children: [
                                        const SidebarShellPage(),
                                        Expanded(
                                          child: isImplemented
                                              ? const MainColumn()
                                              : PlaceholderPanel(
                                                  section: sidebar.section,
                                                ),
                                        ),
                                        if (isImplemented && !compact)
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
        return Row(
          children: [
            FeatureCanvas(
              onTextExtracted: (text, source) {
                context
                    .read<ReaderShellBloc>()
                    .add(LoadTextEvent(text, source: source));
              },
              onPdfProgress: (current, total) {
                context.read<ReaderShellBloc>().add(
                      SetPdfProgressEvent(current: current, total: total),
                    );
              },
              onFeedback: (message) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message)),
                );
              },
            ),
            Expanded(
              child: Stack(
                children: [
                  if (state.showReader)
                    ReaderPage(
                      key: const ValueKey('reader'),
                      text: state.text,
                      sourceName: state.source,
                      onBack: _onBack,
                    )
                  else
                    // Empty state — no text loaded. FeatureCanvas on the
                    // left is the only entry point (Paste / Upload PDF /
                    // Sample / manual input).
                    const SizedBox.expand(),
                  if (state.pdfProgress != null)
                    _PdfProgressOverlay(
                      current: state.pdfProgress!.current,
                      total: state.pdfProgress!.total,
                    ),
                ],
              ),
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

/// Top bar that sits above the 3-column body. Mirrors the layout of
/// the React web reference (dyslexia-web/src/components/Topbar.jsx):
/// logo on the left, paste/type row in the middle, sample + auth on
/// the right. The text input, Format/PDF/Sample buttons and the
/// auth user menu all live here. The FeatureCanvas on the left side
/// is kept for sidebar navigation; this bar is the primary input
/// surface.
class _ShellHeaderBar extends StatefulWidget {
  final void Function(String text, String? source) onTextExtracted;
  final void Function(int current, int total)? onPdfProgress;
  final void Function(String message) onFeedback;

  const _ShellHeaderBar({
    required this.onTextExtracted,
    this.onPdfProgress,
    required this.onFeedback,
  });

  @override
  State<_ShellHeaderBar> createState() => _ShellHeaderBarState();
}

class _ShellHeaderBarState extends State<_ShellHeaderBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isLoadingPdf = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged(String text) {
    if (text.trim().isEmpty) {
      widget.onTextExtracted(kDyslexiaSampleText, 'Sample');
    } else {
      widget.onTextExtracted(text, 'Manual Input');
    }
  }

  void _onFormat() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      widget.onFeedback('Type or paste some text first');
      return;
    }
    widget.onTextExtracted(text, 'Manual Input');
  }

  Future<void> _onPaste() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (!mounted) return;
      final text = data?.text?.trim() ?? '';
      if (text.isEmpty) {
        widget.onFeedback('Nothing found in clipboard');
        return;
      }
      _controller.text = text;
      widget.onTextExtracted(text, 'Clipboard');
    } catch (_) {
      if (!mounted) return;
      _focusNode.requestFocus();
      widget.onFeedback('Press Ctrl+V (or Cmd+V) to paste');
    }
  }

  Future<void> _onPdf() async {
    setState(() => _isLoadingPdf = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        if (mounted) widget.onFeedback('Could not read file data');
        return;
      }
      widget.onPdfProgress?.call(0, 1);
      final text = await getIt<PdfExtractorService>().extractText(
        bytes,
        onProgress: widget.onPdfProgress,
      );
      if (text.trim().isEmpty) {
        if (mounted) {
          widget.onFeedback('PDF appears to be empty or contains only images');
        }
        return;
      }
      widget.onTextExtracted(text, file.name);
    } catch (e) {
      if (mounted) widget.onFeedback('Failed to read PDF: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoadingPdf = false);
        widget.onPdfProgress?.call(1, 1);
      }
    }
  }

  void _onSample() {
    _controller.clear();
    widget.onTextExtracted(kDyslexiaSampleText, 'Sample');
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.watch<DisplaySettingsBloc>().state.settings;
    final bg = bgColor(ds.colorTheme);
    final fg = fgColor(ds.colorTheme);
    final accent = const Color(0xFF3D5A99);
    final muted = fg.withValues(alpha: 0.6);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          bottom: BorderSide(color: fg.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          // Left: logo / brand
          Row(
            children: [
              const Icon(Icons.menu_book_rounded,
                  color: Color(0xFF3D5A99), size: 20),
              const SizedBox(width: 6),
              Text('Dyslexia',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: fg)),
            ],
          ),
          const SizedBox(width: 20),
          // Middle: text input + Format / PDF / Paste
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      onChanged: _onTextChanged,
                      onSubmitted: (_) => _onFormat(),
                      style: TextStyle(fontSize: 13, color: fg),
                      decoration: InputDecoration(
                        hintText: 'Type or paste text, then press Format…',
                        hintStyle: TextStyle(fontSize: 13, color: muted),
                        filled: true,
                        fillColor: fg.withValues(alpha: 0.06),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: accent, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _TopbarButton(
                  label: 'Format',
                  icon: Icons.check_rounded,
                  color: accent,
                  onTap: _onFormat,
                ),
                const SizedBox(width: 6),
                _TopbarButton(
                  label: 'PDF',
                  icon: Icons.upload_file_rounded,
                  color: accent,
                  busy: _isLoadingPdf,
                  onTap: _onPdf,
                ),
                const SizedBox(width: 6),
                _TopbarButton(
                  label: 'Paste',
                  icon: Icons.content_paste_rounded,
                  color: accent,
                  onTap: _onPaste,
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Right: Sample + auth menu
          _TopbarButton(
            label: 'Sample',
            icon: Icons.menu_book_rounded,
            color: accent,
            onTap: _onSample,
          ),
          const SizedBox(width: 16),
          const AuthUserMenu(),
        ],
      ),
    );
  }
}

class _TopbarButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool busy;

  const _TopbarButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              busy
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    )
                  : Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
