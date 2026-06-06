import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../configs/injector/injector_conf.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: const Text('Professionalize'),
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
                hintText: 'Type text to professionalize…',
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
                            .read<ProfessionalizeBloc>()
                            .add(ProfessionalizeTextEvent(text));
                      }
                    },
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Professionalize'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () async {
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
              child: BlocBuilder<ProfessionalizeBloc, ProfessionalizeState>(
                builder: (context, state) {
                  return switch (state) {
                    ProfessionalizeInitial() => const SizedBox(),
                    ProfessionalizeLoading() => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ProfessionalizeResultState(:final result) => _ResultCard(
                        text: result,
                        onClear: () => context
                            .read<ProfessionalizeBloc>()
                            .add(ClearProfessionalizeEvent()),
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
  }
}

class _ResultCard extends StatelessWidget {
  final String text;
  final VoidCallback onClear;
  const _ResultCard({required this.text, required this.onClear});

  @override
  Widget build(BuildContext context) {
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
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
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
                child: Text(text, style: const TextStyle(height: 1.6)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
