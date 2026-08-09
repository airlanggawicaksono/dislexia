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
    // ✅ 1. BlocListener untuk menangkap hasil dan memaksa update text box
    return BlocListener<SummarizeBloc, SummarizeState>(
      listener: (ctx, state) {
        if (state is SummarizeResultState) {
          // 🔍 DEBUG: Cek di console apakah hasil benar-benar sampai
          debugPrint('🚀 SUMMARIZE RESULT RECEIVED: ${state.result}');
          
          if (state.result.isNotEmpty) {
            // ✅ 2. addPostFrameCallback memaksa update setelah frame selesai, 
            // mencegah Flutter mengabaikan perubahan controller
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _controller.text = state.result;
              _controller.selection = TextSelection.fromPosition(
                TextPosition(offset: _controller.text.length),
              );
              debugPrint('✅ TEXT CONTROLLER BERHASIL DI-UPDATE');
            });
          }
        }
      },
      child: BlocBuilder<SummarizeBloc, SummarizeState>(
        builder: (ctx, state) {
          final hasResult = state is SummarizeResultState;
          final isLoading = state is SummarizeLoading;

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
            inputExpanded: _inputExpanded,
            onToggleInput: (v) => setState(() => _inputExpanded = v),
            onSubmit: () {
              setState(() {
                _viewResultText = null;
                _viewResultTitle = null;
              });
              final t = _controller.text.trim();
              if (t.isNotEmpty) {
                debugPrint('📤 MENGIRIM EVENT SUMMARIZE UNTUK: $t');
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
            // ✅ 3. WAJIB: Mencegah FeatureResultCard muncul
            replaceInputWithResult: true, 
          );
        },
      ),
    );
  }
}