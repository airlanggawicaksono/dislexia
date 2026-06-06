import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../configs/injector/injector_conf.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: const Text('Summarize'),
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
