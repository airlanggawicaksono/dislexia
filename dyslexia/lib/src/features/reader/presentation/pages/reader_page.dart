import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../configs/injector/injector_conf.dart';
import '../../../../core/constants/sample_text.dart';
import '../../../../core/utils/font_utils.dart';
import '../../../display_settings/presentation/bloc/display_settings/display_settings_bloc.dart';
import '../../../display_settings/presentation/theme/display_colors.dart';
import '../../../upload/data/datasources/pdf_extractor_service.dart';
import '../../data/syllabifier.dart';
import '../bloc/reader/reader_bloc.dart';
import '../bloc/reader/reader_event.dart';
import '../bloc/reader_shell/reader_shell_bloc.dart';
import '../bloc/reader_shell/reader_shell_event.dart';

class _WordHighlightText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final double maxWidth;

  const _WordHighlightText({
    required this.text,
    required this.style,
    required this.maxWidth,
  });

  @override
  State<_WordHighlightText> createState() => _WordHighlightTextState();
}

class _WordHighlightTextState extends State<_WordHighlightText> {
  TextSelection _selection = const TextSelection.collapsed(offset: -1);

  void _updateSelection(Offset localPosition) {
    final painter = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      textDirection: TextDirection.ltr,
    );
    painter.layout(maxWidth: widget.maxWidth);

    final index = painter.getPositionForOffset(localPosition).offset;

    if (index >= widget.text.length ||
        RegExp(r'\s').hasMatch(widget.text[index])) {
      if (_selection.isValid) {
        setState(() => _selection = const TextSelection.collapsed(offset: -1));
      }
      return;
    }

    int start = index;
    while (start > 0 && !RegExp(r'\s').hasMatch(widget.text[start - 1])) {
      start--;
    }

    int end = index;
    while (
        end < widget.text.length && !RegExp(r'\s').hasMatch(widget.text[end])) {
      end++;
    }

    final newSelection = TextSelection(baseOffset: start, extentOffset: end);
    if (newSelection != _selection) {
      setState(() {
        _selection = newSelection;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) => _updateSelection(event.localPosition),
      onExit: (event) {
        if (_selection.isValid) {
          setState(() {
            _selection = const TextSelection.collapsed(offset: -1);
          });
        }
      },
      child: Builder(builder: (context) {
        if (!_selection.isValid) {
          return RichText(
              text: TextSpan(text: widget.text, style: widget.style));
        }

        final beforeText = widget.text.substring(0, _selection.start);
        final selectedText =
            widget.text.substring(_selection.start, _selection.end);
        final afterText = widget.text.substring(_selection.end);

        return RichText(
          text: TextSpan(
            style: widget.style,
            children: [
              TextSpan(text: beforeText),
              TextSpan(
                text: selectedText,
                style: TextStyle(
                  backgroundColor: widget.style.color!.withOpacity(0.12),
                ),
              ),
              TextSpan(text: afterText),
            ],
          ),
        );
      }),
    );
  }
}

class ReaderPage extends StatefulWidget {
  final String text;
  final String? sourceName;
  final VoidCallback? onBack;
  const ReaderPage({
    super.key,
    required this.text,
    this.sourceName,
    this.onBack,
  });

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  double _rulerY = 120.0;
  final _topbarController = TextEditingController();
  final _topbarFocusNode = FocusNode();

  @override
  void dispose() {
    _topbarController.dispose();
    _topbarFocusNode.dispose();
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
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not read file data')),
          );
        }
        return;
      }
      if (!context.mounted) return;
      context
          .read<ReaderShellBloc>()
          .add(const SetPdfProgressEvent(current: 0, total: 1));
      final text = await getIt<PdfExtractorService>().extractText(
        bytes,
        onProgress: (current, total) {
          if (!context.mounted) return;
          context
              .read<ReaderShellBloc>()
              .add(SetPdfProgressEvent(current: current, total: total));
        },
      );
      if (text.trim().isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('PDF appears to be empty or contains only images')),
          );
          context
              .read<ReaderShellBloc>()
              .add(const SetPdfProgressEvent(current: 1, total: 1));
        }
        return;
      }
      if (!context.mounted) return;
      context
          .read<ReaderShellBloc>()
          .add(LoadTextEvent(text, source: file.name));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to read PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DisplaySettingsBloc, DisplaySettingsState>(
      listenWhen: (prev, curr) =>
          prev.settings.syllablesEnabled != curr.settings.syllablesEnabled,
      listener: (context, state) {
        context.read<ReaderBloc>().add(ToggleSyllabifyEvent());
      },
      child: BlocBuilder<DisplaySettingsBloc, DisplaySettingsState>(
        builder: (context, displayState) {
          final s = displayState.settings;
          final bg = bgColor(s.colorTheme);
          final fg = fgColor(s.colorTheme);
          const rulerH = 48.0;

          return Scaffold(
            backgroundColor: bg,
            // Top bar mirrors dyslexia-web's Topbar.jsx: back/leading
            // on the left, a type-or-paste input in the middle, action
            // buttons (Format, PDF, Sample) on the right, and a
            // syllabification toggle at the far right.
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Container(
                decoration: BoxDecoration(
                  color: bg,
                  border: Border(
                    bottom: BorderSide(color: fg.withValues(alpha: 0.08)),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    // Leading: back button (hidden for sample source)
                    if (widget.sourceName != 'Sample')
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: fg),
                        tooltip: 'Back',
                        onPressed: widget.onBack ??
                            () => Navigator.of(context).maybePop(),
                      )
                    else
                      const SizedBox(width: 8),
                    // Source name
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        widget.sourceName ?? 'Reader',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: fg),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Type-or-paste input
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: TextField(
                          controller: _topbarController,
                          focusNode: _topbarFocusNode,
                          style: TextStyle(fontSize: 13, color: fg),
                          decoration: InputDecoration(
                            hintText: 'Type or paste text, then press Format…',
                            hintStyle: TextStyle(
                                fontSize: 13, color: fg.withValues(alpha: 0.5)),
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
                              borderSide: const BorderSide(
                                  color: Color(0xFF3D5A99), width: 1.5),
                            ),
                          ),
                          onChanged: (text) {
                            // Live-format: every keystroke dispatches
                            // a LoadTextEvent so the reader body
                            // updates immediately, no Format button
                            // required. Empty input → reload the
                            // sample so the reader never sits empty.
                            final trimmed = text.trim();
                            if (trimmed.isEmpty) {
                              context.read<ReaderShellBloc>().add(
                                    const LoadTextEvent(kDyslexiaSampleText,
                                        source: 'Sample'),
                                  );
                            } else {
                              context.read<ReaderShellBloc>().add(
                                    LoadTextEvent(trimmed,
                                        source: 'Manual Input'),
                                  );
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Action buttons
                    const SizedBox(width: 4),
                    _AppBarAction(
                      icon: Icons.content_paste_rounded,
                      label: 'Paste',
                      color: fg,
                      onTap: () async {
                        try {
                          final data =
                              await Clipboard.getData(Clipboard.kTextPlain);
                          if (!context.mounted) return;
                          final text = data?.text?.trim() ?? '';
                          if (text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Nothing found in clipboard')),
                            );
                            return;
                          }
                          _topbarController.text = text;
                          context.read<ReaderShellBloc>().add(
                                LoadTextEvent(text, source: 'Clipboard'),
                              );
                        } catch (_) {
                          if (!context.mounted) return;
                          _topbarFocusNode.requestFocus();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Press Ctrl+V (or Cmd+V) to paste')),
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 4),
                    _AppBarAction(
                      icon: Icons.upload_file_rounded,
                      label: 'PDF',
                      color: fg,
                      onTap: () => _pickPdf(context),
                    ),
                    const SizedBox(width: 4),
                    _AppBarAction(
                      icon: Icons.menu_book_rounded,
                      label: 'Sample',
                      color: fg,
                      onTap: () {
                        _topbarController.clear();
                        context.read<ReaderShellBloc>().add(
                              const LoadTextEvent(kDyslexiaSampleText,
                                  source: 'Sample'),
                            );
                      },
                    ),
                  ],
                ),
              ),
            ),
            body: Stack(
              children: [
                MouseRegion(
                  onHover: s.rulerEnabled
                      ? (e) => setState(
                          () => _rulerY = e.localPosition.dy - rulerH / 2)
                      : null,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Center(
                      child: SizedBox(
                        width: 740,
                        // Use DisplaySettingsBloc.syllablesEnabled directly
                        // to recompute the display text on the fly. The
                        // ReaderBloc used to own a separate toggle that
                        // drifted out of sync with the panel switch.
                        child: Builder(
                          builder: (context) {
                            final displayText = s.syllablesEnabled
                                ? syllabify(widget.text)
                                : widget.text;
                            final paragraphs = displayText
                                .split('\n\n')
                                .where((p) => p.trim().isNotEmpty)
                                .toList();
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: paragraphs
                                  .map((para) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 20),
                                        child: _WordHighlightText(
                                          text: para.trim(),
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
                                          maxWidth: 740,
                                        ),
                                      ))
                                  .toList(),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                if (s.rulerEnabled)
                  _ReadingRuler(
                    height: rulerH,
                    foregroundColor: fg,
                    rulerY: _rulerY,
                    onPositionChanged: (y) => setState(() => _rulerY = y),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ReadingRuler extends StatelessWidget {
  final double height;
  final Color foregroundColor;
  final double rulerY;
  final ValueChanged<double> onPositionChanged;
  const _ReadingRuler({
    required this.height,
    required this.foregroundColor,
    required this.rulerY,
    required this.onPositionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height;
    return Positioned(
      top: rulerY.clamp(0.0, maxH - height),
      left: 0,
      right: 0,
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            IgnorePointer(
              child: Container(
                width: double.infinity,
                height: height,
                decoration: BoxDecoration(
                  color: foregroundColor.withValues(alpha: 0.06),
                  border: Border(
                    top: BorderSide(
                        color: foregroundColor.withValues(alpha: 0.4),
                        width: 1.5),
                    bottom: BorderSide(
                        color: foregroundColor.withValues(alpha: 0.4),
                        width: 1.5),
                  ),
                ),
              ),
            ),
            Center(
              child: GestureDetector(
                onVerticalDragStart: (d) =>
                    onPositionChanged(rulerY + d.localPosition.dy - height / 2),
                onVerticalDragUpdate: (d) =>
                    onPositionChanged(rulerY + d.delta.dy),
                child: SizedBox(
                  height: height,
                  width: 120,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact icon-and-label button used inside [ReaderPage]'s custom
/// top bar. Mirrors the visual style of FeatureCanvas tiles.
class _AppBarAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _AppBarAction({
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
