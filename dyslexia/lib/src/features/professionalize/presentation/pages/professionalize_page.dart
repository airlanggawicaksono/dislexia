import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/font_utils.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/feature_page.dart';
import '../../../display_settings/presentation/bloc/display_settings/display_settings_bloc.dart';
import '../bloc/professionalize_bloc.dart';
import '../bloc/professionalize_event.dart';
import '../bloc/professionalize_state.dart';

class ProfessionalizePage extends StatefulWidget {
  final String? initialText;
  const ProfessionalizePage({super.key, this.initialText});

  @override
  State<ProfessionalizePage> createState() => _ProfessionalizePageState();
}

class _ProfessionalizePageState extends State<ProfessionalizePage> {
  final _controller = TextEditingController();
  final _recipient = TextEditingController();
  final _sender = TextEditingController();
  bool _inputExpanded = true;
  bool _emailMode = false;
  String? _viewResultText;
  String? _viewResultTitle;

  @override
  void initState() {
    super.initState();
    if (widget.initialText?.isNotEmpty ?? false) {
      _controller.text = widget.initialText!;
      context.read<ProfessionalizeBloc>().add(ClearProfessionalizeEvent());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _recipient.dispose();
    _sender.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<ProfessionalizeBloc, ProfessionalizeState>(
        builder: (ctx, state) {
          final hasResult = state is ProfessionalizeResultState;
          final isLoading = state is ProfessionalizeLoading;
          
          return FeaturePage(
            controller: _controller,
            title: 'Professionalize',
            resultTitle: 'Professionalized text',
            heroTag: 'professionalize',
            controlsInline: true,
            controls: _EmailControls(
              recipient: _recipient,
              sender: _sender,
              initialOn: _emailMode,
              onModeChanged: (v) => setState(() => _emailMode = v),
            ),
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
              if (t.isEmpty) return;
              final rcp = _recipient.text.trim();
              final snd = _sender.text.trim();
              
              if (_emailMode && (rcp.isEmpty || snd.isEmpty)) {
                showAdaptiveFeedback(ctx, 'Enter both recipient and sender names');
                return;
              }
              ctx.read<ProfessionalizeBloc>().add(ProfessionalizeTextEvent(
                    t,
                    recipientName: _emailMode ? rcp : null,
                    senderName: _emailMode ? snd : null,
                  ));
            },
            onReset: () {
              _controller.clear();
              _recipient.clear();
              _sender.clear();
              setState(() {
                _viewResultText = null;
                _viewResultTitle = null;
              });
              ctx.read<ProfessionalizeBloc>().add(ClearProfessionalizeEvent());
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

class _EmailControls extends StatefulWidget {
  final TextEditingController recipient;
  final TextEditingController sender;
  final bool initialOn;
  final ValueChanged<bool> onModeChanged;

  const _EmailControls({
    required this.recipient,
    required this.sender,
    required this.initialOn,
    required this.onModeChanged,
  });

  @override
  State<_EmailControls> createState() => _EmailControlsState();
}

class _EmailControlsState extends State<_EmailControls> {
  late bool _on = widget.initialOn;

  Widget _nameField(TextEditingController c, String hint) {
    return TextField(
      controller: c,
      style: const TextStyle(color: Colors.black87, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500),
        fillColor: Colors.white,
        filled: true,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFB596E5), width: 1.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Email mode',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            Switch(
              value: _on,
              activeColor: const Color.fromARGB(255, 255, 255, 255),
              onChanged: (v) {
                setState(() => _on = v);
                widget.onModeChanged(v);
              },
            ),
          ],
        ),
        if (_on) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _nameField(widget.recipient, 'To (recipient)'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _nameField(widget.sender, 'From (you)'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}