import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../configs/injector/injector_conf.dart';
import '../../../../core/widgets/feature_page.dart';
import '../bloc/summarize_bloc.dart';
import '../bloc/summarize_event.dart';
import '../bloc/summarize_state.dart';

class SummarizePage extends StatefulWidget {
  const SummarizePage({super.key});
  @override
  State<SummarizePage> createState() => _SummarizePageState();
}

class _SummarizePageState extends State<SummarizePage> {
  final _bloc = getIt<SummarizeBloc>();
  final _controller = TextEditingController();
  bool _inputExpanded = true;
  String? _viewResultText;
  String? _viewResultTitle;

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _bloc,
    child: BlocBuilder<SummarizeBloc, SummarizeState>(
      builder: (ctx, state) {
        final hasResult = state is SummarizeResultState;
        final isLoading = state is SummarizeLoading;
        return FeaturePage(
          controller: _controller,
          title: 'Summarize', resultTitle: 'Summary', heroTag: 'summarize',
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
            if (t.isNotEmpty) _bloc.add(SummarizeTextEvent(t));
          },
          onViewResult: (text, result) => setState(() {
            _controller.text = text;
            _viewResultText = result;
            _viewResultTitle = 'History';
          }),
        );
      },
    ),
  );
}
