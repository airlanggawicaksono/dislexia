import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/upload/data/datasources/pdf_extractor_service.dart';
import '../widgets/adaptive/adaptive.dart';
import '../widgets/feature_result_card.dart';
import '../widgets/history_panel.dart';

class FeaturePage extends StatelessWidget {
  final String title;
  final String resultTitle;
  final String heroTag;
  final TextEditingController controller;
  final String resultText;
  final String? viewResultText;
  final String? viewResultTitle;
  final bool hasResult;
  final bool isLoading;
  final VoidCallback onSubmit;
  final bool inputExpanded;
  final ValueChanged<bool> onToggleInput;
  final void Function(String text, String result)? onViewResult;

  const FeaturePage({
    super.key,
    required this.title,
    required this.resultTitle,
    required this.heroTag,
    required this.controller,
    required this.resultText,
    this.viewResultText,
    this.viewResultTitle,
    required this.hasResult,
    required this.isLoading,
    required this.onSubmit,
    required this.inputExpanded,
    required this.onToggleInput,
    this.onViewResult,
  });

  void _onPaste(BuildContext context) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!context.mounted) return;
    final t = data?.text?.trim() ?? '';
    if (t.isEmpty) {
      showAdaptiveFeedback(context, 'Nothing found in clipboard');
      return;
    }
    controller.text = t;
  }

  Future<void> _pickPdf(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
          type: FileType.custom, allowedExtensions: ['pdf'], withData: true);
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        if (!context.mounted) return;
        showAdaptiveFeedback(context, 'Could not read file data');
        return;
      }
      final text = await context.read<PdfExtractorService>().extractText(bytes);
      if (!context.mounted) return;
      if (text.trim().isEmpty) {
        showAdaptiveFeedback(
            context, 'PDF appears empty or contains only images');
        return;
      }
      controller.text = text;
    } catch (e) {
      if (!context.mounted) return;
      showAdaptiveFeedback(context, 'Failed to read PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = MediaQuery.of(context).size.width;
        final narrow = w < 800;
        final pad = w < 800 ? 12.0 : 24.0;

        return Scaffold(
          backgroundColor: theme.colorScheme.surface,
          floatingActionButton: narrow
              ? FloatingActionButton.small(
                  heroTag: heroTag,
                  backgroundColor: const Color(0xFF3D5A99),
                  onPressed: () => _showQuickActions(context),
                  child: const Icon(Icons.add_rounded, color: Colors.white),
                )
              : null,
          appBar: AppBar(
            backgroundColor: theme.colorScheme.surface,
            elevation: 0,
            centerTitle: false,
            title: Text(title, style: TextStyle(color: theme.colorScheme.onSurface)),
            actions: narrow
                ? [
                    _FeatureBarAction(
                        icon: Icons.history_rounded,
                        label: 'History',
                        color: theme.colorScheme.onSurface,
                        onTap: () => _showHistory(context)),
                    const SizedBox(width: 4),
                    _FeatureBarAction(
                        icon: Icons.auto_awesome,
                        label: title,
                        color: Colors.white,
                        backgroundColor: const Color(0xFF3D5A99),
                        onTap: onSubmit),
                    const SizedBox(width: 12),
                  ]
                : [
                    _FeatureBarAction(
                        icon: Icons.history_rounded,
                        label: 'History',
                        color: theme.colorScheme.onSurface,
                        onTap: () => _showHistory(context)),
                    const SizedBox(width: 4),
                    _FeatureBarAction(
                        icon: Icons.content_paste_rounded,
                        label: 'Paste',
                        color: theme.colorScheme.onSurface,
                        onTap: () => _onPaste(context)),
                    const SizedBox(width: 4),
                    _FeatureBarAction(
                        icon: Icons.upload_file_rounded,
                        label: 'PDF',
                        color: theme.colorScheme.onSurface,
                        onTap: () => _pickPdf(context)),
                    const SizedBox(width: 12),
                    _FeatureBarAction(
                        icon: Icons.auto_awesome,
                        label: title,
                        color: Colors.white,
                        backgroundColor: const Color(0xFF3D5A99),
                        onTap: onSubmit),
                    const SizedBox(width: 12),
                  ],
          ),
          body: Padding(
            padding: EdgeInsets.all(pad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: hasResult
                      ? Flex(
                          direction: narrow ? Axis.vertical : Axis.horizontal,
                          children: [
                            if (inputExpanded) ...[
                              Flexible(flex: 2, child: _inputField(theme)),
                              narrow
                                  ? const SizedBox(height: 12)
                                  : const SizedBox(width: 12),
                            ],
                            Flexible(
                                flex: 3,
                                child: isLoading
                                    ? const Center(
                                        child: CircularProgressIndicator())
                                    : FeatureResultCard(
                                        text: viewResultText ?? resultText,
                                        title: viewResultTitle ?? resultTitle,
                                        inputExpanded: inputExpanded,
                                        onToggleInput: () =>
                                            onToggleInput(!inputExpanded),
                                      )),
                          ],
                        )
                      : _inputField(theme),
                ),
              ],
            ),
          ),
        );
      },      );
  }

  Widget _inputField(ThemeData theme) => TextField(
        controller: controller,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Type text to ${title.toLowerCase()}…',
          hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
          fillColor: theme.colorScheme.onSurface.withValues(alpha: 0.06),
          filled: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.2))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.2))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.onSurface, width: 1.5)),
        ),
        onSubmitted: (_) => onSubmit(),
      );

  void _showHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => HistoryPanel(
        feature: title.toLowerCase(),
        onSelectInput: (text) {
          Navigator.pop(ctx);
          controller.text = text;
        },
        onSelectResult: (item) {
          Navigator.pop(ctx);
          controller.text = item.inputText;
          onViewResult?.call(item.inputText, item.outputText);
        },
      ),
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
              leading: const Icon(Icons.content_paste_rounded),
              title: const Text('Paste from clipboard'),
              onTap: () {
                Navigator.pop(ctx);
                _onPaste(context);
              }),
          ListTile(
              leading: const Icon(Icons.upload_file_rounded),
              title: const Text('Upload PDF'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPdf(context);
              }),
        ]),
      ),
    );
  }
}

class _FeatureBarAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  const _FeatureBarAction(
      {required this.icon,
      required this.label,
      required this.color,
      this.backgroundColor,
      this.onTap});
  @override
  Widget build(BuildContext context) => Material(
        color: backgroundColor ?? color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600, color: color)),
            ]),
          ),
        ),
      );
}
