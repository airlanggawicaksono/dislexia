import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';

import '../constants/sample_text.dart';
import '../../features/reader/presentation/bloc/reader_shell/reader_shell_bloc.dart';
import '../../features/reader/presentation/bloc/reader_shell/reader_shell_event.dart';
import '../../features/upload/data/datasources/pdf_extractor_service.dart';

/// Landing page shown when no text is loaded in the reader.
///
/// Displays a PDF drop zone (with native browser drag-and-drop via flutter_dropzone),
/// paste text card, and load sample card matching the web reference mockup layout.
class ReaderLandingView extends StatefulWidget {
  const ReaderLandingView({super.key});

  @override
  State<ReaderLandingView> createState() => _ReaderLandingViewState();
}

class _ReaderLandingViewState extends State<ReaderLandingView> {
  DropzoneViewController? _dropzoneController;
  bool _isDragOver = false;
  bool _isProcessing = false;

  Future<void> _processPdfBytes(Uint8List bytes, String fileName) async {
    if (!mounted) return;
    setState(() => _isProcessing = true);
    context
        .read<ReaderShellBloc>()
        .add(const SetPdfProgressEvent(current: 0, total: 1));
    try {
      final text = await context.read<PdfExtractorService>().extractText(
        bytes,
        onProgress: (current, total) {
          if (!mounted) return;
          context
              .read<ReaderShellBloc>()
              .add(SetPdfProgressEvent(current: current, total: total));
        },
      );
      if (!mounted) return;
      if (text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('PDF appears to be empty or contains only images')),
        );
        context
            .read<ReaderShellBloc>()
            .add(const SetPdfProgressEvent(current: 1, total: 1));
        return;
      }
      context
          .read<ReaderShellBloc>()
          .add(LoadTextEvent(text, source: fileName));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to read PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleDroppedFile(DropzoneFileInterface file) async {
    final name = await _dropzoneController!.getFilename(file);
    if (!name.toLowerCase().endsWith('.pdf')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Only PDF files are supported')),
        );
      }
      return;
    }
    final bytes = await _dropzoneController!.getFileData(file);
    // ignore: use_build_context_synchronously — mounted is checked inside _processPdfBytes
    await _processPdfBytes(bytes, name);
  }

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      if (result == null || result.files.isEmpty || !context.mounted) return;
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read file data')),
        );
        return;
      }
      await _processPdfBytes(bytes, file.name);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to read PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.5);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // PDF drop zone with native browser drag-and-drop
            GestureDetector(
              onTap: _isProcessing ? null : _pickPdf,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: SizedBox(
                  width: double.infinity,
                  height: 220,
                  child: Stack(
                    children: [
                      // DropzoneView in the background - handles native drag events (web only)
                      if (kIsWeb)
                        Positioned.fill(
                          child: DropzoneView(
                          operation: DragOperation.copy,
                          cursor: CursorType.grab,
                          mime: const ['application/pdf'],
                        onCreated: (ctrl) => _dropzoneController = ctrl,
                        onHover: () {
                          if (!_isDragOver && mounted) {
                            setState(() => _isDragOver = true);
                          }
                        },
                        onLeave: () {
                          if (mounted) {
                            setState(() => _isDragOver = false);
                          }
                        },
                          onDropFile: (DropzoneFileInterface file) async {
                            if (mounted) {
                              setState(() => _isDragOver = false);
                            }
                            await _handleDroppedFile(file);
                          },
                          ),
                        ),

                      // Visual UI in the foreground
                      IgnorePointer(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 560),
                          padding: const EdgeInsets.symmetric(
                              vertical: 40, horizontal: 32),
                          decoration: BoxDecoration(
                            color: _isDragOver
                                ? theme.colorScheme.primaryContainer
                                    .withValues(alpha: 0.4)
                                : theme.colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _isDragOver
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface
                                      .withValues(alpha: 0.15),
                              width: _isDragOver ? 2.5 : 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cloud_upload_rounded,
                                size: 48,
                                color: _isDragOver
                                    ? theme.colorScheme.primary
                                    : muted,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _isDragOver
                                    ? 'Release to upload'
                                    : 'Drop a PDF here',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: _isDragOver
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Drag and drop any PDF file to start\nreading with your preferred settings',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: muted,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'or browse your files',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Loading spinner overlay during PDF extraction
                      Positioned.fill(
                        child: AnimatedOpacity(
                          opacity: _isProcessing ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: IgnorePointer(
                            ignoring: !_isProcessing,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Paste Text and Load Sample cards
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.description_rounded,
                      label: 'Paste Text',
                      subtitle: 'From clipboard or type',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Type in the top bar or press Ctrl+V to paste'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.menu_book_rounded,
                      label: 'Load Sample',
                      subtitle: 'See how it looks first',
                      onTap: () {
                        context.read<ReaderShellBloc>().add(
                              const LoadTextEvent(
                                kDyslexiaSampleText,
                                source: 'Sample',
                              ),
                            );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card widget for landing page actions (Paste Text, Load Sample).
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
            children: [
              Icon(
                icon,
                size: 28,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
