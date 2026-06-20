import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/sample_text.dart';
import '../../../../core/widgets/reader_text_display.dart';
import '../../../display_settings/presentation/bloc/display_settings/display_settings_bloc.dart';
import '../../../display_settings/presentation/theme/display_colors.dart';
import '../../../upload/data/datasources/pdf_extractor_service.dart';
import '../bloc/reader/reader_bloc.dart';
import '../bloc/reader/reader_event.dart';
import '../bloc/reader_shell/reader_shell_bloc.dart';
import '../bloc/reader_shell/reader_shell_event.dart';

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
  final _topbarController = TextEditingController();
  final _topbarFocusNode = FocusNode();

  @override
  void dispose() {
    _topbarController.dispose();
    _topbarFocusNode.dispose();
    super.dispose();
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.content_paste_rounded),
              title: const Text('Paste from clipboard'),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
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
                        content: Text('Press Ctrl+V (or Cmd+V) to paste')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file_rounded),
              title: const Text('Upload PDF'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPdf(context);
              },
            ),
          ],
        ),
      ),
    );
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
      final text = await context.read<PdfExtractorService>().extractText(
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
          final theme = Theme.of(context);
          final bg = bgColor(s.colorTheme);
          final fg = fgColor(s.colorTheme);

          return Scaffold(
            backgroundColor: theme.colorScheme.surface,
            floatingActionButton: MediaQuery.of(context).size.width < 800
                ? FloatingActionButton.small(
                    heroTag: 'reader',
                    backgroundColor: const Color(0xFF3D5A99),
                    onPressed: () => _showQuickActions(context),
                    child: const Icon(Icons.add_rounded, color: Colors.white),
                  )
                : null,
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    bottom: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.08)),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    // Leading: back button (hidden for sample source)
                    if (widget.sourceName != 'Sample')
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
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
                            color: theme.colorScheme.onSurface),
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
                          style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface),
                          decoration: InputDecoration(
                            hintText: 'Type text here',
                            hintStyle: TextStyle(
                                fontSize: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                            filled: true,
                            fillColor: theme.colorScheme.onSurface.withValues(alpha: 0.06),
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
                    if (MediaQuery.of(context).size.width >= 800) ...[
                      const SizedBox(width: 4),
                      _AppBarAction(
                        icon: Icons.content_paste_rounded,
                        label: 'Paste',
                        color: theme.colorScheme.onSurface,
                        onTap: () async {
                          try {
                            final data =
                                await Clipboard.getData(Clipboard.kTextPlain);
                            if (!context.mounted) return;
                            final text = data?.text?.trim() ?? '';
                            if (text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Nothing found in clipboard')),
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
                        color: theme.colorScheme.onSurface,
                        onTap: () => _pickPdf(context),
                      ),
                      const SizedBox(width: 4),
                      _AppBarAction(
                        icon: Icons.menu_book_rounded,
                        label: 'Sample',
                        color: theme.colorScheme.onSurface,
                        onTap: () {
                          _topbarController.clear();
                          context.read<ReaderShellBloc>().add(
                                const LoadTextEvent(kDyslexiaSampleText,
                                    source: 'Sample'),
                              );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            body: ReaderTextDisplay(
              text: widget.text,
              settings: s,
              fgColor: fg,
              bgColor: bg,
            ),
          );
        },
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
