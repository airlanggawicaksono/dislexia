import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/sidebar/presentation/bloc/sidebar/sidebar_bloc.dart';
import '../../features/sidebar/presentation/bloc/sidebar/sidebar_event.dart';
import '../../features/sidebar/domain/entities/sidebar_section.dart';
import '../../features/reader/presentation/bloc/reader_shell/reader_shell_bloc.dart';
import '../../features/reader/presentation/bloc/reader_shell/reader_shell_event.dart';

import '../widgets/level_slider.dart';
import '../themes/feature_accent.dart';

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
  
  // ✅ PARAMETER BARU: Untuk mengganti isi text box langsung tanpa result card
  final bool replaceInputWithResult;

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
  });

  @override
  State<FeaturePage> createState() => _FeaturePageState();
}

class _FeaturePageState extends State<FeaturePage> {
  @override
  void didUpdateWidget(covariant FeaturePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ✅ Saat hasil selesai diproses, langsung replace isi text box
    if (widget.replaceInputWithResult && widget.hasResult && !widget.isLoading) {
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
      showAdaptiveFeedback(context, 'Nothing found in clipboard');
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
        showAdaptiveFeedback(context, 'Could not read file data');
        return;
      }
      if (!context.mounted) return;
      final text = await getIt<PdfExtractorService>().extractText(bytes);
      if (!context.mounted) return;
      if (text.trim().isEmpty) {
        showAdaptiveFeedback(context, 'PDF appears empty or contains only images');
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

    // ✅ Jika replaceInputWithResult aktif, paksa tetap di input view
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
                decoration: const BoxDecoration(
                  color: Color(0xFFD7C8FC),
                  borderRadius: BorderRadius.only(
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
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFC9B8F0), Color(0xFFB596E5)],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
              ),
            ),
          ],
          
          Column(
            children: [
              _buildHeader(context, isMobile),
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
              child: const Center(
                child: Card(
                  color: Colors.white,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 40, height: 40,
                          child: CircularProgressIndicator(
                            color: Color(0xFFB596E5),
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Processing...',
                          style: TextStyle(
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

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.only(
        left: 24, 
        right: 24, 
        top: isMobile ? 48 : 16, 
        bottom: 24
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isMobile) ...[
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  tooltip: 'Back',
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
                  accent: featureAccent(widget.feature!),
                  icon: widget.feature!.materialIcon,
                  label: widget.title,
                ),
                const SizedBox(width: 12),
              ],
              
              Expanded(
                child: Text(
                  widget.title,
                  textAlign: isMobile ? TextAlign.start : TextAlign.center, 
                  style: TextStyle( // Dihapus const agar bisa inherit font global
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
                  tooltip: 'Reset input',
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
                  tooltip: 'History',
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
              accentColor: widget.feature != null
                  ? featureAccent(widget.feature!).strong
                  : const Color(0xFFB596E5),
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
            // The control region is plain widget.controls: the email-mode
            // switch and its TextFields are already fully semantic. Merging
            // them (MergeSemantics) would collapse the fields into a single
            // non-editable node, so we deliberately don't merge here.
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
          // Group the output region so assistive tech can focus the result
          // as a single scrollable block of text.
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
              minLines: 6,
              maxLines: null,
              textAlignVertical: TextAlignVertical.top,
              style: dyslexiaTextStyle(settings, Colors.black87),
              decoration: const InputDecoration(
                hintText: 'Type text here or insert from external source\nusing the "+" button.',
                hintStyle: TextStyle(
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
                  return Text(
                    '${value.text.length}/5000',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },
              ),
              FloatingActionButton(
                mini: true,
                tooltip: 'Add text from clipboard or PDF',
                onPressed: () => _showAddSourceDialog(context),
                backgroundColor: Colors.white,
                elevation: 2,
                child: const Icon(
                  Icons.add,
                  color: Colors.black87,
                  size: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ PERUBAHAN DI SINI: Layout tombol untuk Mobile dimaksimalkan
  Widget _buildActionButtons(BuildContext context, ThemeData theme, bool isMobile) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: widget.controller,
      builder: (context, value, child) {
        final isSubmitDisabled = widget.isLoading || value.text.trim().isEmpty;

        if (!isMobile) {
          // Desktop: Tetap di tengah dengan lebar maksimal yang rapi (300)
          return Center(
            child: SizedBox(
              width: 300, 
              child: FilledButton(
                onPressed: isSubmitDisabled ? null : widget.onSubmit,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFB596E5),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.white70,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Text(
                  'Submit',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }

        // ✅ MOBILE: Hapus Copy & Share. Gunakan SizedBox width: double.infinity 
        // agar tombol Submit memenuhi lebar area (yang sudah ada padding horizontal 24 dari parent)
        return SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: isSubmitDisabled ? null : widget.onSubmit,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB596E5),
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
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add Text From',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.content_paste),
              title: const Text('Paste from Clipboard'),
              onTap: () {
                Navigator.pop(ctx);
                _onPaste(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Upload PDF'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPdf(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Small icon + label chip that colour-codes a feature header. The icon and
/// text carry the meaning; the tint is a secondary (never the only) signal.
class _FeatureBadge extends StatelessWidget {
  final FeatureAccent accent;
  final IconData icon;
  final String label;

  const _FeatureBadge({
    required this.accent,
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
          color: accent.tint,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: accent.strong),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: accent.onTint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}