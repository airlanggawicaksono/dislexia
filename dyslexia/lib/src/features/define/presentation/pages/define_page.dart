import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../configs/injector/injector_conf.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../bloc/define_bloc.dart';
import '../bloc/define_event.dart';
import '../bloc/define_state.dart';

class DefinePage extends StatelessWidget {
  const DefinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DefineBloc>(),
      child: const _DefineBody(),
    );
  }
}

class _DefineBody extends StatefulWidget {
  const _DefineBody();
  @override
  State<_DefineBody> createState() => _DefineBodyState();
}

class _DefineBodyState extends State<_DefineBody> {
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
        title: const Text('Define'),
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
                hintText: 'Type text to define…',
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
                            .read<DefineBloc>()
                            .add(DefineTextEvent(text));
                      }
                    },
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Define'),
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
              child: BlocBuilder<DefineBloc, DefineState>(
                builder: (context, state) {
                  return switch (state) {
                    DefineInitial() => const SizedBox(),
                    DefineLoading() => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    DefineResultState(:final result) => _ResultCard(
                        text: result,
                        onClear: () => context
                            .read<DefineBloc>()
                            .add(ClearDefineEvent()),
                      ),
                    DefineErrorState(:final message) => Center(
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
