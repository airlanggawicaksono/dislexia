import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../configs/injector/injector_conf.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/feature_result_card.dart';
import '../../../display_settings/presentation/bloc/display_settings/display_settings_bloc.dart';
import '../../../display_settings/presentation/theme/display_colors.dart';
import '../../../upload/data/datasources/pdf_extractor_service.dart';
import '../bloc/professionalize_bloc.dart';
import '../bloc/professionalize_event.dart';
import '../bloc/professionalize_state.dart';

class ProfessionalizePage extends StatelessWidget {
  const ProfessionalizePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProfessionalizeBloc>(),
      child: const _ProfessionalizeBody(),
    );
  }
}

class _ProfessionalizeBody extends StatefulWidget {
  const _ProfessionalizeBody();
  @override
  State<_ProfessionalizeBody> createState() => _ProfessionalizeBodyState();
}

class _ProfessionalizeBodyState extends State<_ProfessionalizeBody> {
  final _controller = TextEditingController();
  bool _inputExpanded = true;
  bool _isLoadingPdf = false;
  ({int current, int total})? _pdfProgress;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickPdf(BuildContext context) async {
    setState(() {
      _isLoadingPdf = true;
      _pdfProgress = null;
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        if (context.mounted) setState(() => _isLoadingPdf = false);
        return;
      }
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        if (!context.mounted) return;
        setState(() => _isLoadingPdf = false);
        showAdaptiveFeedback(context, 'Could not read file data');
        return;
      }
      final text = await getIt<PdfExtractorService>().extractText(
        bytes,
        onProgress: (current, total) {
          if (mounted) {
            setState(() => _pdfProgress = (current: current, total: total));
          }
        },
      );
      if (!mounted) return;
      setState(() {
        _isLoadingPdf = false;
        _pdfProgress = null;
      });
      if (text.trim().isEmpty) {
        showAdaptiveFeedback(
            context, 'PDF appears to be empty or contains only images');
        return;
      }
      _controller.text = text;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingPdf = false;
        _pdfProgress = null;
      });
      showAdaptiveFeedback(context, 'Failed to read PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DisplaySettingsBloc, DisplaySettingsState>(
      builder: (context, ds) {
        final s = ds.settings;
        final bg = bgColor(s.colorTheme);
        final fg = fgColor(s.colorTheme);
        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: bg,
            elevation: 0,
            title: Text('Professionalize', style: TextStyle(color: fg)),
            actions: [
              _FeatureBarAction(
                icon: Icons.content_paste_rounded,
                label: 'Paste',
                color: fg,
                onTap: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (!context.mounted) return;
                  final text = data?.text?.trim() ?? '';
                  if (text.isEmpty) {
                    showAdaptiveFeedback(
                        context, 'Nothing found in clipboard');
                    return;
                  }
                  _controller.text = text;
                },
              ),
              const SizedBox(width: 4),
              _FeatureBarAction(
                icon: Icons.upload_file_rounded,
                label: 'PDF',
                color: fg,
                onTap: () => _pickPdf(context),
              ),
              const SizedBox(width: 12),
              _FeatureBarAction(
                icon: Icons.auto_awesome,
                label: 'Professionalize',
                color: Colors.white,
                backgroundColor: const Color(0xFF3D5A99),
                onTap: () {
                  final text = _controller.text.trim();
                  if (text.isNotEmpty) {
                    context.read<ProfessionalizeBloc>().add(ProfessionalizeTextEvent(text));
                  }
                },
              ),
              const SizedBox(width: 24),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: _inputExpanded
                      ? Column(
                          children: [
                            TextField(
                              controller: _controller,
                              maxLines: 8,
                              style: TextStyle(color: fg),
                              decoration: InputDecoration(
                                hintText: 'Type text to professionalize…',
                                hintStyle:
                                    TextStyle(color: fg.withValues(alpha: 0.4)),
                                fillColor: fg.withValues(alpha: 0.06),
                                filled: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: fg.withValues(alpha: 0.2)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: fg.withValues(alpha: 0.2)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: fg, width: 1.5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
                Expanded(
                  child: BlocBuilder<ProfessionalizeBloc, ProfessionalizeState>(
                    builder: (context, state) {
                      return switch (state) {
                        ProfessionalizeInitial() => _PlaceholderCard(
                            icon: Icons.auto_awesome,
                            title: 'Professionalize',
                            description:
                                'Paste or type text above, then tap Professionalize to generate a concise Professionalized text.',
                            fgColor: fg,
                          ),
                        ProfessionalizeLoading() => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ProfessionalizeResultState(:final result) =>
                          FeatureResultCard(
                            text: result,
                            title: 'Summary',
                            inputExpanded: _inputExpanded,
                            onToggleInput: () => setState(
                                () => _inputExpanded = !_inputExpanded),
                          ),
                        ProfessionalizeErrorState(:final message) => Center(
                            child: Text(message,
                                style: const TextStyle(color: Colors.red)),
                          ),
                        _ => const SizedBox(),
                      };
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PlaceholderCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color fgColor;

  const _PlaceholderCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.fgColor,
  });

  @override
  Widget build(BuildContext context) {
    final fg = fgColor;
    return Container(
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: fg.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              Text(title,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: fg)),
              const SizedBox(height: 8),
              Text(description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13, color: fg.withValues(alpha: 0.6))),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureBarAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  const _FeatureBarAction({
    required this.icon,
    required this.label,
    required this.color,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
