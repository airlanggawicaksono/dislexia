import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/feature_page.dart';
import '../bloc/professionalize_bloc.dart';
import '../bloc/professionalize_event.dart';
import '../bloc/professionalize_state.dart';

class ProfessionalizePage extends StatefulWidget {
  const ProfessionalizePage({super.key});
  @override
  State<ProfessionalizePage> createState() => _ProfessionalizePageState();
}

class _ProfessionalizePageState extends State<ProfessionalizePage> {
  final _controller = TextEditingController();
  bool _inputExpanded = true;
  String? _viewResultText;
  String? _viewResultTitle;

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => BlocBuilder<ProfessionalizeBloc, ProfessionalizeState>(
    builder: (ctx, state) {
      final hasResult = state is ProfessionalizeResultState;
      final isLoading = state is ProfessionalizeLoading;
      return FeaturePage(
        controller: _controller,
        title: 'Professionalize', resultTitle: 'Professionalized text', heroTag: 'professionalize',
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
          if (t.isNotEmpty) ctx.read<ProfessionalizeBloc>().add(ProfessionalizeTextEvent(t));
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
