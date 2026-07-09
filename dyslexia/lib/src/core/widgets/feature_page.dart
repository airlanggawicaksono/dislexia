import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/display_settings/domain/entities/display_settings_entity.dart';
import '../../features/display_settings/presentation/bloc/display_settings/display_settings_bloc.dart';
import '../../features/upload/data/datasources/pdf_extractor_service.dart';
import '../utils/font_utils.dart';
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

  /// Clears the input + result. When null, no reset button is shown.
  final VoidCallback? onReset;

  /// Optional feature-specific knob controls (e.g. summarize level slider,
  /// professionalize email fields). Rendered above the input field.
  final Widget? controls;

  /// When true, [controls] always render inline above the input field (both
  /// widths) instead of moving into the mobile quick-actions sheet. Use for
  /// controls that belong next to the field — e.g. email recipient/sender.
  final bool controlsInline;

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
    this.onReset,
    this.controls,
    this.controlsInline = false,
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
      if (!context.mounted) return;
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
    // Display settings drive the input text style too — every text box.
    final settings = context.watch<DisplaySettingsBloc>().state.settings;

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
                    if (onReset != null) ...[
                      _FeatureBarAction(
                          icon: Icons.refresh_rounded,
                          label: 'Reset',
                          color: theme.colorScheme.onSurface,
                          onTap: onReset),
                      const SizedBox(width: 4),
                    ],
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
                    if (onReset != null) ...[
                      _FeatureBarAction(
                          icon: Icons.refresh_rounded,
                          label: 'Reset',
                          color: theme.colorScheme.onSurface,
                          onTap: onReset),
                      const SizedBox(width: 4),
                    ],
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
                              Flexible(flex: 2, child: _inputColumn(theme, narrow, settings)),
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
                      : _inputColumn(theme, narrow, settings),
                ),
              ],
            ),
          ),
        );
      },      );
  }

  // Input field with optional feature knob controls stacked above it.
  // On narrow (mobile) the controls live in the quick-actions sheet instead,
  // so we only stack them inline on wide layouts — unless controlsInline is
  // set, in which case they always sit above the field.
  Widget _inputColumn(ThemeData theme, bool narrow, DisplaySettingsEntity settings) {
    if (controls == null || (narrow && !controlsInline)) {
      return _inputField(theme, settings);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        controls!,
        const SizedBox(height: 12),
        Expanded(child: _inputField(theme, settings)),
      ],
    );
  }

  Widget _inputField(ThemeData theme, DisplaySettingsEntity settings) => TextField(
        controller: controller,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        style: dyslexiaTextStyle(settings, theme.colorScheme.onSurface),
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
    final theme = Theme.of(context);
    final fg = theme.colorScheme.onSurface;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.92,
        builder: (ctx, scrollController) => Container(
          decoration: BoxDecoration(
            // Same surface colour as the page.
            color: theme.colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Grip handle.
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: fg.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                // Fade content at the top/bottom edges as it scrolls under.
                child: ShaderMask(
                  shaderCallback: (rect) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black,
                      Colors.black,
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.05, 0.93, 1.0],
                  ).createShader(rect),
                  blendMode: BlendMode.dstIn,
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.fromLTRB(
                        16, 8, 16, 24 + MediaQuery.viewInsetsOf(ctx).bottom),
                    children: [
                      // Inline controls stay with the field; don't duplicate here.
                      if (controls != null && !controlsInline) ...[
                        controls!,
                        Divider(height: 28, color: fg.withValues(alpha: 0.1)),
                      ],
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.content_paste_rounded, color: fg),
                        title: Text('Paste from clipboard',
                            style: TextStyle(color: fg)),
                        onTap: () {
                          Navigator.pop(ctx);
                          _onPaste(context);
                        },
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.upload_file_rounded, color: fg),
                        title:
                            Text('Upload PDF', style: TextStyle(color: fg)),
                        onTap: () {
                          Navigator.pop(ctx);
                          _pickPdf(context);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
