import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../configs/injector/injector_conf.dart';
import '../../../../core/utils/font_utils.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../display_settings/presentation/bloc/display_settings/display_settings_bloc.dart';
import '../../../display_settings/presentation/theme/display_colors.dart';
import '../../../upload/data/datasources/pdf_extractor_service.dart';
import '../bloc/summarize_bloc.dart';
import '../bloc/summarize_event.dart';
import '../bloc/summarize_state.dart';

class SummarizePage extends StatelessWidget {
  const SummarizePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SummarizeBloc>(),
      child: const _SummarizeBody(),
    );
  }
}

class _SummarizeBody extends StatefulWidget {
  const _SummarizeBody();
  @override
  State<_SummarizeBody> createState() => _SummarizeBodyState();
}

class _SummarizeBodyState extends State<_SummarizeBody> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickPdf(BuildContext context) async {
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
        if (!context.mounted) return;
        showAdaptiveFeedback(context, 'Could not read file data');
        return;
      }
      final text = await getIt<PdfExtractorService>().extractText(bytes);
      if (text.trim().isEmpty) {
        if (!context.mounted) return;
        showAdaptiveFeedback(
            context, 'PDF appears to be empty or contains only images');
        return;
      }
      _controller.text = text;
    } catch (e) {
      if (!context.mounted) return;
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
            title: Text('Summarize', style: TextStyle(color: fg)),
          ),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _controller,
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText: 'Type text to summarize…',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          final text = _controller.text.trim();
                          if (text.isNotEmpty) {
                            context
                                .read<SummarizeBloc>()
                                .add(SummarizeTextEvent(text));
                          }
                        },
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Summarize'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final data =
                            await Clipboard.getData(Clipboard.kTextPlain);
                        if (!context.mounted) return;
                        final text = data?.text?.trim() ?? '';
                        if (text.isEmpty) {
                          showAdaptiveFeedback(
                              context, 'Nothing found in clipboard');
                          return;
                        }
                        _controller.text = text;
                      },
                      icon: const Icon(Icons.content_paste_rounded, size: 18),
                      label: const Text('Paste'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _pickPdf(context),
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                      label: const Text('PDF'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: BlocBuilder<SummarizeBloc, SummarizeState>(
                    builder: (context, state) {
                      return switch (state) {
                        SummarizeInitial() => const SizedBox(),
                        SummarizeLoading() => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        SummarizeResultState(:final result) => _ResultCard(
                            text: result,
                            onClear: () => context
                                .read<SummarizeBloc>()
                                .add(ClearSummarizeEvent()),
                          ),
                        SummarizeErrorState(:final message) => Center(
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

class _ResultCard extends StatelessWidget {
  final String text;
  final VoidCallback onClear;
  const _ResultCard({required this.text, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DisplaySettingsBloc, DisplaySettingsState>(
      builder: (context, ds) {
        final s = ds.settings;
        final fg = fgColor(s.colorTheme);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, size: 18),
                    const SizedBox(width: 8),
                    const Text('Summary',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Copy to clipboard',
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: text));
                        showAdaptiveFeedback(context, 'Copied to clipboard');
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: onClear,
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        text,
                        style: applyDyslexiaFont(
                          font: s.font,
                          baseStyle: TextStyle(
                            fontSize: s.fontSize,
                            color: fg,
                            height: s.lineSpacing,
                            letterSpacing: s.letterSpacing,
                            wordSpacing: s.wordSpacing,
                          ),
                        ),
                      ),
                    ),
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
