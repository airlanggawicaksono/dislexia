import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../configs/injector/injector_conf.dart';
import '../blocs/theme/theme_bloc.dart';
import '../themes/app_theme.dart';
import '../../features/display_settings/presentation/bloc/display_settings/display_settings_bloc.dart';
import '../../features/display_settings/presentation/theme/display_colors.dart';
import '../../features/reader/presentation/bloc/reader/reader_bloc.dart';
import '../../features/reader/presentation/bloc/reader/reader_event.dart';
import '../../features/reader/presentation/pages/reader_page.dart';
import 'display_settings_panel.dart';
import 'dyslexia_topbar.dart';
import 'web_landing_content.dart';

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
                            DisplaySettingsPanel(),
                            _DesktopContent(),
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

class _DesktopContent extends StatefulWidget {
  const _DesktopContent();
  @override
  State<_DesktopContent> createState() => _DesktopContentState();
}

class _DesktopContentState extends State<_DesktopContent> {
  final _topbarKey = GlobalKey<DyslexiaTopbarState>();
  String _readerText = '';
  String? _readerSource;
  bool _showReader = false;
  ({int current, int total})? _pdfProgress;

  void _setReaderText(String text, String? source) {
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

  void _hideReader() {
    setState(() {
      _showReader = false;
      _readerText = '';
      _readerSource = null;
    });
  }

  void _onPdfProgress(int current, int total) {
    if (current >= total) {
      setState(() => _pdfProgress = null);
    } else {
      setState(() => _pdfProgress = (current: current, total: total));
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Stack(
        children: [
          Column(
            children: [
              DyslexiaTopbar(
                key: _topbarKey,
                onTextExtracted: _setReaderText,
                onPdfProgress: _onPdfProgress,
              ),
              Expanded(
                child: _showReader
                    ? ReaderPage(
                        text: _readerText,
                        sourceName: _readerSource,
                        onBack: _hideReader,
                      )
                    : WebLandingContent(
                        onUploadTap: () =>
                            _topbarKey.currentState?.triggerUploadPdf(),
                        onPasteTap: _setReaderText,
                        onCameraSnack: _showSnack,
                      ),
              ),
            ],
          ),
          if (_pdfProgress != null) _buildPdfProgressOverlay(),
        ],
      ),
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
