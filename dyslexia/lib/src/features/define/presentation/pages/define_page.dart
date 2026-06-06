import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../configs/injector/injector_conf.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/feature_result_card.dart';
import '../../../display_settings/presentation/bloc/display_settings/display_settings_bloc.dart';
import '../../../display_settings/presentation/theme/display_colors.dart';
import '../../../upload/data/datasources/pdf_extractor_service.dart';
import '../bloc/define_bloc.dart';
import '../bloc/define_event.dart';
import '../bloc/define_state.dart';

class DefinePage extends StatelessWidget {
  const DefinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DefineBloc>(),
      child: const _DefineBody(),
    );
  }
}

class _DefineBody extends StatefulWidget {
  const _DefineBody();
  @override
  State<_DefineBody> createState() => _DefineBodyState();
}

class _DefineBodyState extends State<_DefineBody> {
  final _controller = TextEditingController();
  bool _inputExpanded = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickPdf(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        if (!context.mounted) return;
        showAdaptiveFeedback(context, 'Could not read file data');
        return;
      }
      final text = await getIt<PdfExtractorService>().extractText(bytes);
      if (text.trim().isEmpty) {
        if (!context.mounted) return;
        showAdaptiveFeedback(
            context, 'PDF appears to be empty or contains only images');
        return;
      }
      _controller.text = text;
    } catch (e) {
      if (!context.mounted) return;
      showAdaptiveFeedback(context, 'Failed to read PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DisplaySettingsBloc, DisplaySettingsState>(
      builder: (context, ds) {
        final s = ds.settings;
        final bg = bgColor(s.colorTheme);
        final fg = fgColor(s.colorTheme);
        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: bg,
            elevation: 0,
            title: Text('Define', style: TextStyle(color: fg)),
            actions: [
              _FeatureBarAction(
                icon: Icons.content_paste_rounded,
                label: 'Paste',
                color: fg,
                onTap: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (!context.mounted) return;
                  final text = data?.text?.trim() ?? '';
                  if (text.isEmpty) {
                    showAdaptiveFeedback(
                        context, 'Nothing found in clipboard');
                    return;
                  }
                  _controller.text = text;
                },
              ),
              const SizedBox(width: 4),
              _FeatureBarAction(
                icon: Icons.picture_as_pdf_rounded,
                label: 'PDF',
                color: fg,
                onTap: () => _pickPdf(context),
              ),
              const SizedBox(width: 4),
              _FeatureBarAction(
                icon: Icons.auto_awesome,
                label: 'Define',
                color: fg,
                onTap: () {
                  final text = _controller.text.trim();
                  if (text.isNotEmpty) {
                    context
                        .read<DefineBloc>()
                        .add(DefineTextEvent(text));
                  }
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: _inputExpanded
                      ? Column(
                          children: [
                            TextField(
                              controller: _controller,
                              maxLines: 8,
                              decoration: InputDecoration(
                                hintText: 'Type text to define…',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
                Expanded(
                  child: BlocBuilder<DefineBloc, DefineState>(
                    builder: (context, state) {
                      return switch (state) {
                        DefineInitial() => const SizedBox(),
                        DefineLoading() => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        DefineResultState(:final result) =>
                          FeatureResultCard(
                            text: result,
                            title: 'Summary',
                            inputExpanded: _inputExpanded,
                            onToggleInput: () => setState(
                                () => _inputExpanded = !_inputExpanded),
                          ),
                        DefineErrorState(:final message) => Center(
                            child: Text(message,
                                style:
                                    const TextStyle(color: Colors.red)),
                          ),
                        _ => const SizedBox(),
                      };
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FeatureBarAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _FeatureBarAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
