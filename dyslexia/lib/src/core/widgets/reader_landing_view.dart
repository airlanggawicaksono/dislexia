import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../constants/sample_text.dart';
import '../../features/reader/presentation/bloc/reader_shell/reader_shell_bloc.dart';
import '../../features/reader/presentation/bloc/reader_shell/reader_shell_event.dart';
import '../../features/upload/data/datasources/pdf_extractor_service.dart';

/// Landing page shown when no text is loaded in the reader.
///
/// Displays a PDF drop zone, paste text card, and load sample card
/// matching the web reference mockup layout.
class ReaderLandingView extends StatelessWidget {
  const ReaderLandingView({super.key});

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
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.5);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        children: [
          const Spacer(),
          // PDF drop zone
          GestureDetector(
            onTap: () => _pickPdf(context),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 560),
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_upload_rounded,
                    size: 48,
                    color: muted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Drop a PDF here',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
                  GestureDetector(
                    onTap: () => _pickPdf(context),
                    child: Text(
                      'or browse your files',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
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
                      // Focus the topbar input — the user can type there
                      // or use Ctrl+V. We show a hint snackbar.
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
          const Spacer(),
        ],
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
