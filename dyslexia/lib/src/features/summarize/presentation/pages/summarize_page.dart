import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../configs/injector/injector_conf.dart';
import '../../../../core/utils/font_utils.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/ruler/reading_ruler.dart';
import '../../../display_settings/presentation/bloc/display_settings/display_settings_bloc.dart';
import '../../../display_settings/presentation/theme/display_colors.dart';
import '../../../reader/data/syllabifier.dart';
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
  bool _inputExpanded = true;

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
                icon: Icons.picture_as_pdf_rounded,
                label: 'PDF',
                color: fg,
                onTap: () => _pickPdf(context),
              ),
              const SizedBox(width: 4),
              _FeatureBarAction(
                icon: Icons.auto_awesome,
                label: 'Summarize',
                color: fg,
                onTap: () {
                  final text = _controller.text.trim();
                  if (text.isNotEmpty) {
                    context
                        .read<SummarizeBloc>()
                        .add(SummarizeTextEvent(text));
                  }
                },
              ),
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
                              decoration: InputDecoration(
                                hintText: 'Type text to summarize…',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
                Expanded(
                  child: BlocBuilder<SummarizeBloc, SummarizeState>(
                    builder: (context, state) {
                      return switch (state) {
                        SummarizeInitial() => const SizedBox(),
                        SummarizeLoading() => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        SummarizeResultState(:final result) =>
                          _ResultCard(
                            text: result,
                            inputExpanded: _inputExpanded,
                            rulerEnabled: s.rulerEnabled,
                            fgColor: fg,
                            onToggleInput: () => setState(
                                () => _inputExpanded = !_inputExpanded),
                          ),
                        SummarizeErrorState(:final message) => Center(
                            child: Text(message,
                                style:
                                    const TextStyle(color: Colors.red)),
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

class _FeatureBarAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _FeatureBarAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
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

class _ResultCard extends StatefulWidget {
  final String text;
  final VoidCallback onToggleInput;
  final bool inputExpanded;
  final bool rulerEnabled;
  final Color fgColor;
  const _ResultCard({
    required this.text,
    required this.onToggleInput,
    required this.inputExpanded,
    this.rulerEnabled = false,
    required this.fgColor,
  });

  @override
  State<_ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<_ResultCard> {
  double _rulerY = 120.0;

  @override
  Widget build(BuildContext context) {
    final body = BlocBuilder<DisplaySettingsBloc, DisplaySettingsState>(
      builder: (context, ds) {
        final s = ds.settings;
        final fg = widget.fgColor;
        final displayText = s.syllablesEnabled ? syllabify(widget.text) : widget.text;
        return Container(
          decoration: BoxDecoration(
            color: fg.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
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
                      tooltip: widget.inputExpanded
                          ? 'Hide input'
                          : 'Show input',
                      icon: Icon(
                        widget.inputExpanded
                            ? Icons.unfold_less_rounded
                            : Icons.unfold_more_rounded,
                        size: 18,
                      ),
                      onPressed: widget.onToggleInput,
                    ),
                    IconButton(
                      tooltip: 'Copy to clipboard',
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: widget.text));
                        showAdaptiveFeedback(context, 'Copied to clipboard');
                      },
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                        displayText,
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
              ],
            ),
          ),
        );
      },
    );

    if (!widget.rulerEnabled) return body;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: MouseRegion(
        onHover: (e) => setState(() => _rulerY = e.localPosition.dy),
        child: Stack(
          children: [
            body,
            if (widget.rulerEnabled)
              ReadingRuler(
                height: 48,
                foregroundColor: widget.fgColor,
                rulerY: _rulerY,
                onPositionChanged: (y) => setState(() => _rulerY = y),
              ),
          ],
        ),
      ),
    );
  }
}
