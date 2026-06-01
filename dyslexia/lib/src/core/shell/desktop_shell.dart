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
import '../../features/reader/presentation/bloc/reader/reader_event.dart';
import '../../features/reader/presentation/pages/reader_page.dart';
import 'display_settings_panel.dart';
import 'feature_canvas.dart';
import 'web_landing_content.dart';

/// 3-column desktop shell:
///   [ FeatureCanvas ] [ Main content (Reader) ] [ DisplaySettingsPanel ]
///
/// - Column 1: feature buttons (Reader, Upload PDF, Paste, Sample) + manual input
/// - Column 2: reader page (or landing) as the primary content area
/// - Column 3: typography/accessibility settings panel
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
          ],
          child: BlocBuilder<DisplaySettingsBloc, DisplaySettingsState>(
            builder: (context, displayState) {
              return BlocBuilder<ThemeBloc, ThemeState>(
                builder: (_, themeState) {
                  return MaterialApp(
                    debugShowCheckedModeBanner: false,
                    theme: AppTheme.data(themeState.isDarkMode),
                    home: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 1040),
                      child: const Scaffold(
                        body: Row(
                          children: [
                            _FeatureColumn(),
                            Expanded(child: _MainColumn()),
                            DisplaySettingsPanel(),
                          ],
                        ),
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

/// Column 1: feature canvas (Reader/Upload/Paste/Sample + text input).
/// All reader state is owned by [_MainColumn]; this widget is a thin
/// presentation wrapper that just delegates actions to its parent.
class _FeatureColumn extends StatelessWidget {
  const _FeatureColumn();

  @override
  Widget build(BuildContext context) {
    return _FeatureCanvasAdapter();
  }
}

/// Internal widget that locates the enclosing [_MainColumnState] and forwards
/// actions to it. Falls back to no-ops if the parent cannot be found (which
/// should not happen under normal use).
class _FeatureCanvasAdapter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final main = context.findAncestorStateOfType<_MainColumnState>();
    if (main == null) {
      return const FeatureCanvas(
        onTextExtracted: _noopText,
        onFeedback: _noopFeedback,
      );
    }
    return FeatureCanvas(
      onTextExtracted: main.setReaderText,
      onPdfProgress: main.onPdfProgress,
      onFeedback: main.showSnack,
    );
  }

  static void _noopText(String text, String? source) {}
  static void _noopFeedback(String message) {}
}

/// Column 2: main content area. The reader page is the default destination;
/// before any text is loaded we show the web landing content (paste/upload CTA).
class _MainColumn extends StatefulWidget {
  const _MainColumn();

  @override
  State<_MainColumn> createState() => _MainColumnState();
}

class _MainColumnState extends State<_MainColumn> {
  String _readerText = '';
  String? _readerSource;
  bool _showReader = false;
  ({int current, int total})? _pdfProgress;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Auto-load the dyslexia sample on first launch so users see content
      // immediately, matching the React web reference behaviour.
      setReaderText(kDyslexiaSampleText, 'Sample');
    });
  }

  void setReaderText(String text, String? source) {
    if (text.trim().isEmpty) {
      if (_showReader) {
        setState(() {
          _showReader = false;
          _readerText = '';
          _readerSource = null;
        });
      }
      return;
    }

    context.read<ReaderBloc>().add(SetTextEvent(text, sourceName: source));

    if (!_showReader || _readerSource != source) {
      setState(() {
        _readerText = text;
        _readerSource = source;
        _showReader = true;
      });
    } else {
      _readerText = text;
    }
  }

  void hideReader() {
    setState(() {
      _showReader = false;
      _readerText = '';
      _readerSource = null;
    });
  }

  void onPdfProgress(int current, int total) {
    if (current >= total) {
      setState(() => _pdfProgress = null);
    } else {
      setState(() => _pdfProgress = (current: current, total: total));
    }
  }

  void showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _showReader
            ? ReaderPage(
                text: _readerText,
                sourceName: _readerSource,
                onBack: hideReader,
              )
            : WebLandingContent(
                onUploadTap: () => showSnack(
                    'Use Upload PDF in the feature panel on the left'),
                onPasteTap: setReaderText,
                onCameraSnack: showSnack,
              ),
        if (_pdfProgress != null) _buildPdfProgressOverlay(),
      ],
    );
  }

  Widget _buildPdfProgressOverlay() {
    final progress = _pdfProgress!;
    final pct = progress.current / progress.total;
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
                    'Page ${progress.current} of ${progress.total}',
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
