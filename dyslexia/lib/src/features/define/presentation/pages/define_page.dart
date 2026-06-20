import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/feature_page.dart';
import '../bloc/define_bloc.dart';
import '../bloc/define_event.dart';
import '../bloc/define_state.dart';

class DefinePage extends StatefulWidget {
  const DefinePage({super.key});
  @override
  State<DefinePage> createState() => _DefinePageState();
}

class _DefinePageState extends State<DefinePage> {
  final _controller = TextEditingController();
  bool _inputExpanded = true;
  String? _viewResultText;
  String? _viewResultTitle;

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => BlocBuilder<DefineBloc, DefineState>(
    builder: (ctx, state) {
      final hasResult = state is DefineResultState;
      final isLoading = state is DefineLoading;
      return FeaturePage(
        controller: _controller,
        title: 'Define', resultTitle: 'Definition', heroTag: 'define',
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
          if (t.isNotEmpty) ctx.read<DefineBloc>().add(DefineTextEvent(t));
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
