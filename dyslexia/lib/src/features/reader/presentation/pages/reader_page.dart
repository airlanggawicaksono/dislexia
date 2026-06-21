import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
                  context.read<ReaderShellBloc>().add(
                        LoadTextEvent(text, source: 'Clipboard'),
                      );
                } catch (_) {
                  if (!context.mounted) return;
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
                    // Back button
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
                      tooltip: 'Back',
                      onPressed: widget.onBack ??
                          () => Navigator.of(context).maybePop(),
                    ),
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
                    const Spacer(),
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
