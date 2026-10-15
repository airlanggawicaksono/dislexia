import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../utils/feature_l10n.dart';

import '../../features/sidebar/presentation/bloc/sidebar/sidebar_bloc.dart';
import '../../features/sidebar/presentation/bloc/sidebar/sidebar_event.dart';
import '../../features/sidebar/domain/entities/sidebar_section.dart';
import '../../features/reader/presentation/bloc/reader_shell/reader_shell_bloc.dart';
import '../../features/reader/presentation/bloc/reader_shell/reader_shell_event.dart';

import '../widgets/level_slider.dart';

import '../../configs/injector/injector_conf.dart';
import '../../features/display_settings/domain/entities/display_settings_entity.dart';
import '../../features/display_settings/presentation/bloc/display_settings/display_settings_bloc.dart';
import '../../features/upload/data/datasources/pdf_extractor_service.dart';
import '../utils/font_utils.dart';
import '../widgets/adaptive/adaptive.dart';
import '../widgets/feature_result_card.dart';
import '../widgets/history_panel.dart';

class FeaturePage extends StatefulWidget {
  final String title;
  final String resultTitle;
  final String heroTag;

  /// Identifies which feature this page belongs to so its accent colour
  /// (always paired with icon + text label) can be applied consistently.
  final SidebarSection? feature;

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
  final VoidCallback? onReset;
  final Widget? controls;
  final bool controlsInline;
  final List<String>? levelLabels;
  final int initialLevel;
  final ValueChanged<int>? onLevelChanged;

  /// Untuk mengganti isi text box langsung tanpa result card
  final bool replaceInputWithResult;

  /// True while an SSE stream is still delivering result chunks. During
  /// streaming the input controller must NOT be touched on every chunk
  /// (writing it per chunk fires listeners -> rebuilds -> didUpdateWidget
  /// -> write -> infinite loop / stack overflow). The controller is synced
  /// exactly once, when the stream finishes (isStreaming flips back to false).
  final bool isStreaming;

  const FeaturePage({
    super.key,
    required this.title,
    required this.resultTitle,
    required this.heroTag,
    this.feature,
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
    this.levelLabels,
    this.initialLevel = 2,
    this.onLevelChanged,
    this.replaceInputWithResult = false,
    this.isStreaming = false,
  });

  @override
  State<FeaturePage> createState() => _FeaturePageState();
}

class _FeaturePageState extends State<FeaturePage> {
  // Focus for the input field so "Select all" can highlight the text
  // visibly (a selection only paints on the focused field).
  final FocusNode _inputFocus = FocusNode();

  @override
  void dispose() {
    _inputFocus.dispose();
    super.dispose();
  }

  // Localized feature name for display. `widget.title` stays the English
  // logic key (palette switch, level-label check); only the shown text is
  // translated.
  String _displayTitle() =>
      widget.feature != null ? featureLabel(widget.feature!) : widget.title;

  // Highlight the entire input so the user can copy/replace without
  // dragging across a long passage.
  void _selectAll() {
    final len = widget.controller.text.length;
    if (len == 0) return;
    _inputFocus.requestFocus();
    widget.controller.selection =
        TextSelection(baseOffset: 0, extentOffset: len);
  }

  // ============================================================
  // 🎨 Helper: Dapatkan palette warna berdasarkan judul fitur
  // ============================================================
  _FeaturePalette _getPalette() {
    switch (widget.title.toLowerCase()) {
      case 'summarize':
        return const _FeaturePalette(
          tint: Color(0xFFFFE9D1),
          strong: Color(0xFFFFD4A0),
          onTint: Color(0xFF6B4423),
          gradientStart: Color(0xFFFFE9D1),
          gradientEnd: Color(0xFFFFD4A0),
          backgroundTint: Color(0xFFFFF2E3),
        );
      case 'professionalize':
        return const _FeaturePalette(
          tint: Color(0xFFCAE8FF),
          strong: Color(0xFF6CB6FF),
          onTint: Color(0xFF1E3A5F),
          gradientStart: Color(0xFFCAE8FF),
          gradientEnd: Color(0xFF6CB6FF),
          backgroundTint: Color(0xFFE3F1FF),
        );
      case 'define':
        return const _FeaturePalette(
          tint: Color(0xFFFBE5E0),
          strong: Color(0xFFEC8E7D),
          onTint: Color(0xFF5F2A1F),
          gradientStart: Color(0xFFFBE5E0),
          gradientEnd: Color(0xFFEC8E7D),
          backgroundTint: Color(0xFFFFEEE9),
        );
      case 'reader':
      default:
        return const _FeaturePalette(
          tint: Color(0xFFC9B8F0),
          strong: Color(0xFFB596E5),
          onTint: Color(0xFF4A2E7A),
          gradientStart: Color(0xFFC9B8F0),
          gradientEnd: Color(0xFFB596E5),
          backgroundTint: Color(0xFFD7C8FC),
        );
    }
  }

  @override
  void didUpdateWidget(covariant FeaturePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Saat hasil selesai diproses, langsung replace isi text box.
    // Hanya sinkronkan controller saat stream SELESAI (isStreaming false),
    // bukan per chunk: menulis controller per chunk memicu listener ->
    // rebuild -> didUpdateWidget -> tulis lagi (stack overflow).
    if (widget.replaceInputWithResult &&
        widget.hasResult &&
        !widget.isLoading &&
        !widget.isStreaming) {
      if (widget.resultText.isNotEmpty && widget.controller.text != widget.resultText) {
        widget.controller.text = widget.resultText;
        // Pindahkan kursor ke akhir teks agar user bisa langsung melanjutkan edit
        widget.controller.selection = TextSelection.fromPosition(
          TextPosition(offset: widget.controller.text.length),
        );
      }
    }
  }

  void _onPaste(BuildContext context) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!context.mounted) return;
    final t = data?.text?.trim() ?? '';
    if (t.isEmpty) {
      showAdaptiveFeedback(context, 'feedback.clipboardEmpty'.tr());
      return;
    }
    widget.controller.text = t;
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
        showAdaptiveFeedback(context, 'feedback.fileReadFail'.tr());
        return;
      }
      if (!context.mounted) return;
      final text = await getIt<PdfExtractorService>().extractText(bytes);
      if (!context.mounted) return;
      if (text.trim().isEmpty) {
        showAdaptiveFeedback(context, 'feedback.pdfEmpty'.tr());
        return;
      }
      widget.controller.text = text;
    } catch (e) {
      if (!context.mounted) return;
      showAdaptiveFeedback(context, 'Failed to read PDF: $e');
    }
  }

  void _handleBack(BuildContext context) {
    try {
      context.read<SidebarBloc>().add(
        SidebarSectionSelected(SidebarSection.reader),
      );
      context.read<ReaderShellBloc>().add(
        const ClearTextEvent(),
      );
    } catch (e) {
      Navigator.of(context).pop();
    }
  }

  void _showHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => HistoryPanel(
        feature: widget.title.toLowerCase(),
        onSelectInput: (text) {
          Navigator.pop(ctx);
          widget.controller.text = text;
        },
        onSelectResult: (item) {
          Navigator.pop(ctx);
          widget.onViewResult?.call(item.inputText, item.outputText);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<DisplaySettingsBloc>().state.settings;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;
    final screenHeight = MediaQuery.of(context).size.height;
    final palette = _getPalette();

    // Jika replaceInputWithResult aktif, paksa tetap di input view
    final showResultView = widget.hasResult && !widget.replaceInputWithResult;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ============================================================
          // 🎨 Background Gradient (Mobile only) - DINAMIS per fitur
          // ============================================================
          if (isMobile) ...[
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                height: screenHeight * 0.55,
                decoration: BoxDecoration(
                  color: palette.backgroundTint,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(48),
                    bottomRight: Radius.circular(48),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                height: screenHeight * 0.50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [palette.gradientStart, palette.gradientEnd],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
              ),
            ),
          ],

          Column(
            children: [
              _buildHeader(context, isMobile, palette),
              Expanded(
                child: showResultView
                    ? _buildResultView(context, theme, settings, isMobile)
                    : _buildInputView(context, theme, settings, isMobile),
              ),
            ],
          ),

          // ============================================================
          // ⏳ Loading Overlay (warna dinamis)
          // ============================================================
          if (widget.isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Card(
                  color: Colors.white,
                  elevation: 8,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 40, height: 40,
                          child: CircularProgressIndicator(
                            color: palette.strong,
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'status.processing'.tr(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile, _FeaturePalette palette) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: isMobile ? 48 : 16,
        bottom: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isMobile) ...[
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  tooltip: 'action.back'.tr(),
                  onPressed: () => _handleBack(context),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    fixedSize: const Size(40, 40),
                    elevation: 0,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (widget.feature != null) ...[
                _FeatureBadge(
                  palette: palette,
                  icon: widget.feature!.materialIcon,
                  label: _displayTitle(),
                ),
                const SizedBox(width: 12),
              ],

              Expanded(
                child: Text(
                  _displayTitle(),
                  textAlign: isMobile ? TextAlign.start : TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(width: 12),
              if (widget.onReset != null)
                IconButton(
                  icon: const Icon(Icons.restart_alt, color: Colors.black),
                  tooltip: 'action.resetInput'.tr(),
                  onPressed: widget.onReset,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    fixedSize: const Size(40, 40),
                    elevation: isMobile ? 0 : 2,
                  ),
                ),
              const SizedBox(width: 12),
              if (widget.onViewResult != null)
                IconButton(
                  icon: const Icon(Icons.history_rounded, color: Colors.black),
                  tooltip: 'action.history'.tr(),
                  onPressed: () => _showHistory(context),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    fixedSize: const Size(40, 40),
                    elevation: isMobile ? 0 : 2,
                  ),
                ),
            ],
          ),
          if (widget.levelLabels != null && widget.levelLabels!.isNotEmpty) ...[
            const SizedBox(height: 16),
            LevelSlider(
              label: widget.title == 'Summarize' ? 'Summary Length' : 'Detail Level',
              accentColor: palette.strong,
              valueLabels: widget.levelLabels!,
              initialIndex: widget.initialLevel,
              onChanged: (index) {
                if (widget.onLevelChanged != null) {
                  widget.onLevelChanged!(index);
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputView(BuildContext context, ThemeData theme, DisplaySettingsEntity settings, bool isMobile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.controls != null && (widget.controlsInline || !isMobile)) ...[
            widget.controls!,
            const SizedBox(height: 16),
          ],
          _buildTextInputCard(context, theme, settings),
          const SizedBox(height: 24),
          _buildActionButtons(context, theme, isMobile),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 24),
        ],
      ),
    );
  }

  Widget _buildResultView(BuildContext context, ThemeData theme, DisplaySettingsEntity settings, bool isMobile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.inputExpanded) ...[
            _buildTextInputCard(context, theme, settings),
            const SizedBox(height: 16),
          ],
          Semantics(
            container: true,
            label: '${widget.title} output',
            child: FeatureResultCard(
              text: widget.viewResultText ?? widget.resultText,
              title: widget.viewResultTitle ?? widget.resultTitle,
              inputExpanded: widget.inputExpanded,
              onToggleInput: () => widget.onToggleInput(!widget.inputExpanded),
            ),
          ),
          const SizedBox(height: 24),
          _buildActionButtons(context, theme, isMobile),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTextInputCard(BuildContext context, ThemeData theme, DisplaySettingsEntity settings) {
    final palette = _getPalette();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: 150,
              maxHeight: 400,
            ),
            child: TextField(
              controller: widget.controller,
              focusNode: _inputFocus,
              minLines: 6,
              maxLines: null,
              textAlignVertical: TextAlignVertical.top,
              style: dyslexiaTextStyle(settings, Colors.black87),
              decoration: InputDecoration(
                hintText: 'input.hint'.tr(),
                hintStyle: const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  height: 1.5,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                counterText: '',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: widget.controller,
                builder: (context, value, child) {
                  final palette = _getPalette();
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${value.text.length}/5000',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (value.text.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        TextButton.icon(
                          onPressed: _selectAll,
                          icon: Icon(Icons.select_all_rounded,
                              size: 18, color: palette.strong),
                          label: Text(
                            'action.selectAll'.tr(),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: palette.strong,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
              // ✅ FAB mini dengan warna dinamis sesuai fitur
              FloatingActionButton(
                mini: true,
                heroTag: null, // hindari hero conflict jika multiple FAB di tree
                tooltip: 'addSource.tooltip'.tr(),
                onPressed: () => _showAddSourceDialog(context),
                backgroundColor: palette.tint,
                elevation: 2,
                child: Icon(
                  Icons.add,
                  color: palette.strong,
                  size: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ThemeData theme, bool isMobile) {
    final palette = _getPalette();
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: widget.controller,
      builder: (context, value, child) {
        final isSubmitDisabled = widget.isLoading || value.text.trim().isEmpty;

        if (!isMobile) {
          return Center(
            child: SizedBox(
              width: 300,
              child: FilledButton(
                onPressed: isSubmitDisabled ? null : widget.onSubmit,
                style: FilledButton.styleFrom(
                  backgroundColor: palette.strong,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.white70,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Text(
                  'action.submit'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }

        return SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: isSubmitDisabled ? null : widget.onSubmit,
            style: FilledButton.styleFrom(
              backgroundColor: palette.strong,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              disabledForegroundColor: Colors.white70,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: const Text(
              'Submit',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAddSourceDialog(BuildContext context) {
    final palette = _getPalette();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar (mobile UX pattern)
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'addSource.title'.tr(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: palette.strong,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: palette.tint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.content_paste, color: palette.strong),
              ),
              title: Text('addSource.paste'.tr()),
              onTap: () {
                Navigator.pop(ctx);
                _onPaste(context);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: palette.tint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.upload_file, color: palette.strong),
              ),
              title: Text('addSource.uploadPdf'.tr()),
              onTap: () {
                Navigator.pop(ctx);
                _pickPdf(context);
              },
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 🎨 Feature Palette - Warna per fitur
// ============================================================
class _FeaturePalette {
  final Color tint;
  final Color strong;
  final Color onTint;
  final Color gradientStart;
  final Color gradientEnd;
  final Color backgroundTint;

  const _FeaturePalette({
    required this.tint,
    required this.strong,
    required this.onTint,
    required this.gradientStart,
    required this.gradientEnd,
    required this.backgroundTint,
  });
}

/// Small icon + label chip that colour-codes a feature header. The icon and
/// text carry the meaning; the tint is a secondary (never the only) signal.
class _FeatureBadge extends StatelessWidget {
  final _FeaturePalette palette;
  final IconData icon;
  final String label;

  const _FeatureBadge({
    required this.palette,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      image: true,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: palette.tint,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: palette.strong),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: palette.onTint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}