import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/feature_page.dart';
import '../../../sidebar/domain/entities/sidebar_section.dart';
import '../../domain/entities/summary_level.dart';
import '../bloc/summarize_bloc.dart';
import '../bloc/summarize_event.dart';
import '../bloc/summarize_state.dart';

const _levels = SummaryLevel.values;
const _levelPct = ['10%', '30%', '50%', '70%', '90%'];

class SummarizePage extends StatefulWidget {
  final String? initialText;
  const SummarizePage({super.key, this.initialText});

  @override
  State<SummarizePage> createState() => _SummarizePageState();
}

class _SummarizePageState extends State<SummarizePage> {
  final _controller = TextEditingController();
  bool _inputExpanded = true;
  String? _viewResultText;
  String? _viewResultTitle;
  SummaryLevel _level = SummaryLevel.defaultLevel;

  @override
  void initState() {
    super.initState();
    if (widget.initialText?.isNotEmpty ?? false) {
      _controller.text = widget.initialText!;
      context.read<SummarizeBloc>().add(ClearSummarizeEvent());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SummarizeBloc, SummarizeState>(
      builder: (ctx, state) {
        final hasResult = state is SummarizeResultState;
        final isLoading = state is SummarizeLoading;
        // True while SSE chunks are still arriving; the controller is only
        // synced once the stream completes (FeaturePage didUpdateWidget).
        final isStreaming = hasResult && !isLoading && !state.streamComplete;

        return FeaturePage(
          controller: _controller,
          title: 'Summarize',
          resultTitle: 'Summary',
          heroTag: 'summarize',
          feature: SidebarSection.summarize,
          levelLabels: _levelPct,
          initialLevel: _levels.indexOf(_level),
          onLevelChanged: (index) {
            setState(() {
              _level = _levels[index];
            });
          },
          resultText: hasResult ? state.result : '',
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
              ctx.read<SummarizeBloc>().add(SummarizeTextEvent(t, level: _level));
            }
          },
          onReset: () {
            _controller.clear();
            setState(() {
              _viewResultText = null;
              _viewResultTitle = null;
            });
            ctx.read<SummarizeBloc>().add(ClearSummarizeEvent());
          },
          onViewResult: (text, result) => setState(() {
            // Saat pilih dari history, masukkan HASIL ke text box
            _controller.text = result;
            _viewResultText = null;
            _viewResultTitle = null;
          }),
          // WAJIB: Mencegah FeatureResultCard muncul (input diganti hasil)
          replaceInputWithResult: true,
        );
        },
      );
  }
}