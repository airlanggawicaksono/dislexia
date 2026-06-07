import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../configs/injector/injector_conf.dart';
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
  final _bloc = getIt<ProfessionalizeBloc>();
  final _controller = TextEditingController();
  bool _inputExpanded = true;

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _bloc,
    child: BlocBuilder<ProfessionalizeBloc, ProfessionalizeState>(
      builder: (ctx, state) {
        final hasResult = state is ProfessionalizeResultState;
        final isLoading = state is ProfessionalizeLoading;
        return FeaturePage(
          controller: _controller,
          title: 'Professionalize', resultTitle: 'Professionalized text', heroTag: 'professionalize',
          resultText: hasResult ? state.result : '',
          hasResult: hasResult || isLoading,
          isLoading: isLoading,
          inputExpanded: _inputExpanded,
          onToggleInput: (v) => setState(() => _inputExpanded = v),
          onSubmit: () {
            final t = _controller.text.trim();
            if (t.isNotEmpty) _bloc.add(ProfessionalizeTextEvent(t));
          },
        );
      },
    ),
  );
}
