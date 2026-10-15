import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/widgets/feature_page.dart';
import '../../../sidebar/domain/entities/sidebar_section.dart';
import '../../domain/entities/define_level.dart';
import '../bloc/define_bloc.dart';
import '../bloc/define_event.dart';
import '../bloc/define_state.dart';

final _levels = [
  DefineLevel.pct10,
  DefineLevel.pct50,
  DefineLevel.pct90,
];

const List<String> _levelPctKeys = [
  'levelPct.simple',
  'levelPct.mid',
  'levelPct.perhaps',
];

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

  Future<void> _copyAll(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('feedback.copied'.tr()),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DefineBloc, DefineState>(
      builder: (ctx, state) {
        final hasResult = state is DefineResultState;
        final isLoading = state is DefineLoading;
        final isStreaming = hasResult && !isLoading && !state.streamComplete;
        final resultText = hasResult ? state.result : '';

        return Stack(
          children: [
            FeaturePage(
              controller: _controller,
              // ✅ PENTING: Tetap 'Define' agar palet warna benar DAN 
              // logika otomatis di FeaturePage bisa menyembunyikan judul besarnya.
              title: 'Define', 
              resultTitle: 'Definition',
              heroTag: 'define',
              feature: SidebarSection.define,
              
              // ✅ Terapkan translasi dengan benar menggunakan .map()
              levelLabels: _levelPctKeys.map((key) => key.tr()).toList(),
              initialLevel: _levels.indexOf(_level),
              onLevelChanged: (index) {
                setState(() {
                  _level = _levels[index];
                });
              },
              resultText: resultText,
              viewResultText: _viewResultText,
              viewResultTitle: _viewResultTitle,
              hasResult: hasResult || isLoading || _viewResultText != null,
              isLoading: isLoading,
              isStreaming: isStreaming,
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
                _controller.text = result;
                _viewResultText = null;
                _viewResultTitle = null;
              }),
              replaceInputWithResult: true,
            ),

            // ✅ Hanya menyisakan tombol "Copy All"
            if (hasResult)
              Positioned(
                top: 100,
                right: 16,
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _FloatingActionButton(
                        icon: Icons.copy_all,
                        label: 'action.copyText'.tr(),
                        onPressed: () => _copyAll(resultText),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Tombol floating dengan style konsisten untuk aksi output
class _FloatingActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _FloatingActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(24),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 6),
              // ✅ PERBAIKAN OVERFLOW: Bungkus Text dengan Flexible dan aktifkan softWrap
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  softWrap: true,      // Mengizinkan teks turun ke baris baru jika layar sempit
                  maxLines: 2,         // Batasi maksimal 2 baris
                  overflow: TextOverflow.ellipsis, // Tambahkan ... jika tetap kepanjangan
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}