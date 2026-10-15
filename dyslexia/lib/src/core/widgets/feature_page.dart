import 'dart:typed_data';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

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

// ✅ PERBAIKAN 1: Path import disesuaikan agar menemukan getOcrService()
import 'package:dyslexia/services/ocr_service_locator.dart';

class FeaturePage extends StatefulWidget {
  final String title;
  final String resultTitle;
  final String heroTag;
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
  final bool replaceInputWithResult;
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
  final FocusNode _inputFocus = FocusNode();
  bool _isProcessingImage = false;

  @override
  void dispose() {
    _inputFocus.dispose();
    super.dispose();
  }

  String _displayTitle() =>
      widget.feature != null ? featureLabel(widget.feature!) : widget.title;

  Future<void> _copyAll() async {
    final text = widget.controller.text;
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      showAdaptiveFeedback(context, 'feedback.copied'.tr());
    }
  }

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
    if (widget.replaceInputWithResult &&
        widget.hasResult &&
        !widget.isLoading &&
        !widget.isStreaming) {
      if (widget.resultText.isNotEmpty && widget.controller.text != widget.resultText) {
        widget.controller.text = widget.resultText;
        widget.controller.selection = TextSelection.fromPosition(
          TextPosition(offset: widget.controller.text.length),
        );
        _inputFocus.unfocus();
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

  Future<void> _pickImageAndExtractText(ImageSource source) async {
    if (mounted) Navigator.pop(context);

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (image == null || !mounted) return;

    setState(() => _isProcessingImage = true);

    try {
      final Uint8List imageBytes = await image.readAsBytes();
      final String extractedText = await _performOCR(imageBytes);

      if (!mounted) return;

      if (extractedText.trim().isEmpty) {
        showAdaptiveFeedback(context, 'feedback.noTextFoundInImage'.tr());
      } else {
        final currentText = widget.controller.text;
        widget.controller.text = currentText.isEmpty 
            ? extractedText 
            : '$currentText\n\n$extractedText';
            
        widget.controller.selection = TextSelection.fromPosition(
          TextPosition(offset: widget.controller.text.length),
        );
        
        showAdaptiveFeedback(context, 'feedback.imageProcessedSuccess'.tr());
      }
    } catch (e) {
      if (mounted) {
        showAdaptiveFeedback(context, 'feedback.imageProcessingFailed'.tr());
      }
      print('OCR Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessingImage = false);
      }
    }
  }

  Future<String> _performOCR(Uint8List imageBytes) async {
    try {
      final ocrService = getOcrService();
      return await ocrService.recognizeText(imageBytes);
    } catch (e) {
      print('OCR Service Error: $e');
      rethrow;
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

    final showResultView = widget.hasResult && !widget.replaceInputWithResult;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
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

          if (_isProcessingImage)
            Container(
              color: Colors.black.withOpacity(0.4),
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
                          'status.extractingText'.tr(),
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
    final hideBigTitle = widget.title.toLowerCase() == 'define' || widget.title.toLowerCase() == 'summarize';

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
            crossAxisAlignment: CrossAxisAlignment.center,
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
                const SizedBox(width: 8),
              ],
              if (widget.feature != null) ...[
                _FeatureBadge(
                  palette: palette,
                  icon: widget.feature!.materialIcon,
                  label: _displayTitle(),
                ),
                const SizedBox(width: 8),
              ],

              if (!hideBigTitle)
                Expanded(
                  child: Text(
                    _displayTitle(),
                    maxLines: 1,
                    textAlign: isMobile ? TextAlign.start : TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              else
                const Spacer(),

              const SizedBox(width: 8),
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
              const SizedBox(width: 8),
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
            SizedBox(
              width: double.infinity,
              child: LevelSlider(
                label: widget.title.toLowerCase() == 'summarize' ? 'summarize.length'.tr() : 'define.level'.tr(),
                accentColor: palette.strong,
                valueLabels: widget.levelLabels!,
                initialIndex: widget.initialLevel,
                onChanged: (index) {
                  if (widget.onLevelChanged != null) {
                    widget.onLevelChanged!(index);
                  }
                },
              ),
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
              scrollPadding: EdgeInsets.zero,
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
              Flexible(
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: widget.controller,
                  builder: (context, value, child) {
                    final palette = _getPalette();
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${value.text.length}/15000',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (value.text.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Flexible(
                            child: TextButton.icon(
                              onPressed: _copyAll,
                              icon: Icon(Icons.copy_all_rounded,
                                  size: 18, color: palette.strong),
                              label: Text(
                                'action.copyText'.tr(),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: palette.strong,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: const Size(0, 32),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              FloatingActionButton(
                mini: true,
                heroTag: null,
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
            child: Text(
              'action.submit'.tr(),
              style: const TextStyle(
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
                child: Icon(Icons.camera_alt_rounded, color: palette.strong),
              ),
              title: Text('addSource.camera'.tr()),
              subtitle: Text('addSource.cameraSubtitle'.tr(), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              onTap: () => _pickImageAndExtractText(ImageSource.camera),
            ),
            const Divider(height: 1),

            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: palette.tint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.image_rounded, color: palette.strong),
              ),
              title: Text('addSource.image'.tr()),
              subtitle: Text('addSource.imageSubtitle'.tr(), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              onTap: () => _pickImageAndExtractText(ImageSource.gallery),
            ),
            const Divider(height: 1),

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
            const Divider(height: 1),

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
      // ✅ PERBAIKAN 2: Menghapus excludeSemantics: true untuk menghilangkan warning semantic node
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
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: palette.onTint,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}