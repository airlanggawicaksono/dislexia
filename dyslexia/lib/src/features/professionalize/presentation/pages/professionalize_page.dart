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
import '../bloc/professionalize_bloc.dart';
import '../bloc/professionalize_event.dart';
import '../bloc/professionalize_state.dart';

class ProfessionalizePage extends StatelessWidget {
  const ProfessionalizePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProfessionalizeBloc>(),
      child: const _ProfessionalizeBody(),
    );
  }
}

class _ProfessionalizeBody extends StatefulWidget {
  const _ProfessionalizeBody();
  @override
  State<_ProfessionalizeBody> createState() => _ProfessionalizeBodyState();
}

class _ProfessionalizeBodyState extends State<_ProfessionalizeBody> {
  final _controller = TextEditingController();
  bool _inputExpanded = true;
  bool _isLoadingPdf = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickPdf(BuildContext context) async {
    setState(() => _isLoadingPdf = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['pdf'], withData: true,
      );
      if (result == null || result.files.isEmpty) {
        if (context.mounted) setState(() => _isLoadingPdf = false);
        return;
      }
      final file = result.files.first; final bytes = file.bytes;
      if (bytes == null) { if (!context.mounted) return; setState(() => _isLoadingPdf = false); showAdaptiveFeedback(context, 'Could not read file data'); return; }
      final text = await getIt<PdfExtractorService>().extractText(bytes);
      if (!context.mounted) return; setState(() => _isLoadingPdf = false);
      if (text.trim().isEmpty) { showAdaptiveFeedback(context, 'PDF appears to be empty or contains only images'); return; }
      _controller.text = text;
    } catch (e) {
      if (!context.mounted) return; setState(() => _isLoadingPdf = false);
      showAdaptiveFeedback(context, 'Failed to read PDF: $e');
    }
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) context.read<ProfessionalizeBloc>().add(ProfessionalizeTextEvent(text));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DisplaySettingsBloc, DisplaySettingsState>(
      builder: (context, ds) {
        final s = ds.settings; final bg = bgColor(s.colorTheme); final fg = fgColor(s.colorTheme);
        final narrow = MediaQuery.of(context).size.width < 700;
        return Scaffold(
          backgroundColor: bg,
          floatingActionButton: narrow
              ? FloatingActionButton.small(
                  heroTag: 'professionalize',
                  backgroundColor: const Color(0xFF3D5A99),
                  onPressed: () => _showQuickActions(context),
                  child: const Icon(Icons.add_rounded, color: Colors.white),
                )
              : null,
          appBar: AppBar(
            backgroundColor: bg, elevation: 0, centerTitle: false,
            title: Text('Professionalize', style: TextStyle(color: fg)),
            actions: narrow
                ? [
                    _FeatureBarAction(icon: Icons.auto_awesome, label: 'Professionalize', color: Colors.white, backgroundColor: const Color(0xFF3D5A99), onTap: _submit),
                    const SizedBox(width: 12),
                  ]
                : [
                    _FeatureBarAction(icon: Icons.content_paste_rounded, label: 'Paste', color: fg, onTap: () async {
                      final data = await Clipboard.getData(Clipboard.kTextPlain);
                      if (!context.mounted) return; final text = data?.text?.trim() ?? '';
                      if (text.isEmpty) { showAdaptiveFeedback(context, 'Nothing found in clipboard'); return; }
                      _controller.text = text;
                    }),
                    const SizedBox(width: 4),
                    _FeatureBarAction(icon: Icons.upload_file_rounded, label: 'PDF', color: fg, onTap: () => _pickPdf(context)),
                    const SizedBox(width: 12),
                    _FeatureBarAction(icon: Icons.auto_awesome, label: 'Professionalize', color: Colors.white, backgroundColor: const Color(0xFF3D5A99), onTap: _submit),
                    const SizedBox(width: 12),
                  ],
          ),
          body: Padding(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 12 : 24),
            child: BlocBuilder<ProfessionalizeBloc, ProfessionalizeState>(
              builder: (context, state) {
                final hasResult = state is ProfessionalizeResultState;
                if (hasResult) {
                  final showInput = _inputExpanded;
                  final resultCard = FeatureResultCard(
                    text: state.result, title: 'Summary',
                    inputExpanded: _inputExpanded,
                    onToggleInput: () => setState(() => _inputExpanded = !_inputExpanded),
                    onClear: () {
                      setState(() => _inputExpanded = true);
                      _controller.clear();
                      context.read<ProfessionalizeBloc>().add(ClearProfessionalizeEvent());
                    },
                  );
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 700;
                      return Flex(
                        direction: isNarrow ? Axis.vertical : Axis.horizontal,
                        children: [
                          if (showInput)
                            Flexible(
                              flex: 1,
                              child: TextField(
                                controller: _controller,
                                maxLines: null, expands: true,
                                textAlignVertical: TextAlignVertical.top,
                                style: TextStyle(color: fg, fontSize: 15),
                                decoration: InputDecoration(
                                  hintText: 'Type text to professionalize…',
                                  hintStyle: TextStyle(color: fg.withValues(alpha: 0.4)),
                                  fillColor: fg.withValues(alpha: 0.06), filled: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: fg.withValues(alpha: 0.2))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: fg.withValues(alpha: 0.2))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: fg, width: 1.5)),
                                ),
                                onSubmitted: (_) => _submit(),
                              ),
                            ),
                          if (showInput)
                            isNarrow
                                ? const SizedBox(height: 12)
                                : const SizedBox(width: 12),
                          Flexible(flex: 1, child: resultCard),
                        ],
                      );
                    },
                  );
                }
                return TextField(
                  controller: _controller,
                  maxLines: null, expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: TextStyle(color: fg, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Type text to professionalize…',
                    hintStyle: TextStyle(color: fg.withValues(alpha: 0.4)),
                    fillColor: fg.withValues(alpha: 0.06), filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: fg.withValues(alpha: 0.2))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: fg.withValues(alpha: 0.2))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: fg, width: 1.5)),
                  ),
                  onSubmitted: (_) => _submit(),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.content_paste_rounded), title: const Text('Paste from clipboard'), onTap: () async {
            Navigator.pop(ctx);
            final data = await Clipboard.getData(Clipboard.kTextPlain);
            if (!context.mounted) return; final text = data?.text?.trim() ?? '';
            if (text.isEmpty) { showAdaptiveFeedback(context, 'Nothing found in clipboard'); return; }
            _controller.text = text;
          }),
          ListTile(leading: const Icon(Icons.upload_file_rounded), title: const Text('Upload PDF'), onTap: () { Navigator.pop(ctx); _pickPdf(context); }),
        ]),
      ),
    );
  }
}

class _FeatureBarAction extends StatelessWidget {
  final IconData icon; final String label; final Color color; final Color? backgroundColor; final VoidCallback? onTap;
  const _FeatureBarAction({required this.icon, required this.label, required this.color, this.backgroundColor, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          ]),
        ),
      ),
    );
  }
}
