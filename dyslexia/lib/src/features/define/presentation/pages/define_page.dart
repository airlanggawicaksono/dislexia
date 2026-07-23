import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/feature_page.dart';
import '../../domain/entities/define_level.dart';
import '../bloc/define_bloc.dart';
import '../bloc/define_event.dart';
import '../bloc/define_state.dart';

const _levels = DefineLevel.values;
const _levelPct = ['10%', '30%', '50%', '70%', '90%'];

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

  @override
  Widget build(BuildContext context) => BlocBuilder<DefineBloc, DefineState>(
        builder: (ctx, state) {
          final hasResult = state is DefineResultState;
          final isLoading = state is DefineLoading;

          return FeaturePage(
            controller: _controller,
            title: 'Define',
            resultTitle: 'Definition',
            heroTag: 'define',
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
              // ✅ Langsung tampilkan hasil di text box
              _controller.text = result;
              _viewResultText = null;
              _viewResultTitle = null;
            }),
            // ✅ Aktifkan mode replace input
            replaceInputWithResult: true,
          );
        },
      );
}