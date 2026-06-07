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
          hasResult: hasResult || isLoading,
          isLoading: isLoading,
          inputExpanded: _inputExpanded,
          onToggleInput: (v) => setState(() => _inputExpanded = v),
          onSubmit: () {
            final t = _controller.text.trim();
            if (t.isNotEmpty) _bloc.add(SummarizeTextEvent(t));
          },
        );
      },
    ),
  );
}
