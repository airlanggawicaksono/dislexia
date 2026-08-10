import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/feature_page.dart';
import '../../../sidebar/domain/entities/sidebar_section.dart';
import '../../domain/entities/define_level.dart';
import '../bloc/define_bloc.dart';
import '../bloc/define_event.dart';
import '../bloc/define_state.dart';

final _levels = [
  DefineLevel.pct10,
  DefineLevel.pct50,
  DefineLevel.pct90,
];
const _levelPct = ['10%', '50%', '90%'];

class DefinePage extends StatefulWidget {
  final String? initialText;
  const DefinePage({super.key, this.initialText});

  @override
  State<DefinePage> createState() => _DefinePageState();
}

class _DefinePageState extends State<DefinePage> {
  final _controller = TextEditingController();
  bool _inputExpanded = true;
  String? _viewResultText;
  String? _viewResultTitle;
  DefineLevel _level = DefineLevel.defaultLevel;

  @override
  void initState() {
    super.initState();
    if (widget.initialText?.isNotEmpty ?? false) {
      _controller.text = widget.initialText!;
      context.read<DefineBloc>().add(ClearDefineEvent());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _copyAll(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Definition copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showSelectAllDialog(String text) {
    final dialogController = TextEditingController(text: text);
    final dialogFocusNode = FocusNode();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Full Definition'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: TextField(
            controller: dialogController,
            focusNode: dialogFocusNode,
            readOnly: true,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                ),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              // ✅ Auto-select all text di dialog
              dialogController.selection = TextSelection(
                baseOffset: 0,
                extentOffset: dialogController.text.length,
              );
              dialogFocusNode.requestFocus();
            },
            child: const Text('Select All'),
          ),
          FilledButton(
            onPressed: () async {
              await _copyAll(text);
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DefineBloc, DefineState>(
      builder: (ctx, state) {
        final hasResult = state is DefineResultState;
        final isLoading = state is DefineLoading;
        // True while SSE chunks are still arriving (result present but the
        // stream is not finished yet). The controller is only synced once the
        // stream completes.
        final isStreaming = hasResult && !isLoading && !state.streamComplete;
        final resultText = hasResult ? state.result : '';

        // ✅ Full screen layout dengan Stack
        return Stack(
          children: [
            // FeaturePage full screen (tanpa wrapper ListView/SizedBox)
            FeaturePage(
              controller: _controller,
              title: 'Define',
              resultTitle: 'Definition',
              heroTag: 'define',
              feature: SidebarSection.define,
              levelLabels: _levelPct,
              initialLevel: _levels.indexOf(_level),
              onLevelChanged: (index) {
                setState(() {
                  _level = _levels[index];
                });
              },
              resultText: resultText, // ✅ Tampilkan hasil di area default
              viewResultText: _viewResultText,
              viewResultTitle: _viewResultTitle,
              hasResult: hasResult || isLoading || _viewResultText != null,
              isLoading: isLoading,
              isStreaming: isStreaming,
              inputExpanded: _inputExpanded,
              onToggleInput: (v) => setState(() => _inputExpanded = v),
              onSubmit: () {
                setState(() {
                  _viewResultText = null;
                  _viewResultTitle = null;
                });
                final t = _controller.text.trim();
                if (t.isNotEmpty) {
                  ctx.read<DefineBloc>().add(DefineTextEvent(t, level: _level));
                }
              },
              onReset: () {
                _controller.clear();
                setState(() {
                  _viewResultText = null;
                  _viewResultTitle = null;
                });
                ctx.read<DefineBloc>().add(ClearDefineEvent());
              },
              onViewResult: (text, result) => setState(() {
                _controller.text = result;
                _viewResultText = null;
                _viewResultTitle = null;
              }),
              replaceInputWithResult: true,
            ),

            // ✅ Floating action buttons di pojok kanan atas
            if (hasResult)
              Positioned(
                top: 100, // cukup rendah untuk menghindari AppBar FeaturePage
                right: 16,
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _FloatingActionButton(
                        icon: Icons.select_all,
                        label: 'Select All',
                        onPressed: () => _showSelectAllDialog(resultText),
                      ),
                      const SizedBox(height: 8),
                      _FloatingActionButton(
                        icon: Icons.copy,
                        label: 'Copy All',
                        onPressed: () => _copyAll(resultText),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Tombol floating dengan style konsisten untuk aksi output
class _FloatingActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _FloatingActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(24),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}