import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../configs/injector/injector_conf.dart';
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
  final _bloc = getIt<DefineBloc>();
  final _controller = TextEditingController();
  bool _inputExpanded = true;

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _bloc,
    child: BlocBuilder<DefineBloc, DefineState>(
      builder: (ctx, state) {
        final hasResult = state is DefineResultState;
        final isLoading = state is DefineLoading;
        return FeaturePage(
          controller: _controller,
          title: 'Define', resultTitle: 'Definition', heroTag: 'define',
          resultText: hasResult ? state.result : '',
          hasResult: hasResult || isLoading,
          isLoading: isLoading,
          inputExpanded: _inputExpanded,
          onToggleInput: (v) => setState(() => _inputExpanded = v),
          onSubmit: () {
            final t = _controller.text.trim();
            if (t.isNotEmpty) _bloc.add(DefineTextEvent(t));
          },
        );
      },
    ),
  );
}
