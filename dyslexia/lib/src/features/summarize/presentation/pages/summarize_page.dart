import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/feature_page.dart';
import '../../../../core/widgets/level_slider.dart';
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
      // Clear any stale result on the singleton bloc so the seeded input is
      // what's shown (not a previous run's result card).
      context.read<SummarizeBloc>().add(ClearSummarizeEvent());
    }
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  Widget _levelControl() => LevelSlider(
        label: 'Summary length',
        valueLabels: _levelPct,
        initialIndex: _levels.indexOf(_level),
        onChanged: (i) => _level = _levels[i],
      );

  @override
  Widget build(BuildContext context) => BlocBuilder<SummarizeBloc, SummarizeState>(
    builder: (ctx, state) {
      final hasResult = state is SummarizeResultState;
      final isLoading = state is SummarizeLoading;
      return FeaturePage(
        controller: _controller,
        title: 'Summarize', resultTitle: 'Summary', heroTag: 'summarize',
        controls: _levelControl(),
        resultText: hasResult ? state.result : '',
        viewResultText: _viewResultText,
        viewResultTitle: _viewResultTitle,
        hasResult: hasResult || isLoading || _viewResultText != null,
        isLoading: isLoading,
        inputExpanded: _inputExpanded,
        onToggleInput: (v) => setState(() => _inputExpanded = v),
        onSubmit: () {
          setState(() { _viewResultText = null; _viewResultTitle = null; });
          final t = _controller.text.trim();
          if (t.isNotEmpty) {
            ctx.read<SummarizeBloc>().add(SummarizeTextEvent(t, level: _level));
          }
        },
        onReset: () {
          _controller.clear();
          setState(() { _viewResultText = null; _viewResultTitle = null; });
          ctx.read<SummarizeBloc>().add(ClearSummarizeEvent());
        },
        onViewResult: (text, result) => setState(() {
          _controller.text = text;
          _viewResultText = result;
          _viewResultTitle = 'History';
        }),
      );
    },
  );
}
