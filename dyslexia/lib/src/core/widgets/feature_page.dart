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

import '../../configs/injector/injector_conf.dart';
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
  final VoidCallback? onReset;
  final Widget? controls;
  final bool controlsInline;
  final List<String>? levelLabels;
  final int initialLevel;
  final ValueChanged<int>? onLevelChanged;

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
    this.levelLabels,
    this.initialLevel = 2,
    this.onLevelChanged,
  });

  // ... (Fungsi _onPaste, _pickPdf, _handleBack, _showHistory tetap sama) ...
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
      final text = await getIt<PdfExtractorService>().extractText(bytes);
      if (!context.mounted) return;
      if (text.trim().isEmpty) {
        showAdaptiveFeedback(context, 'PDF appears empty or contains only images');
        return;
      }
      controller.text = text;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<DisplaySettingsBloc>().state.settings;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white, 
      body: Stack(
        children: [
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
          
          Column(
            children: [
              _buildHeader(context), 
              Expanded(
                child: hasResult
                    ? _buildResultView(context, theme, settings, isMobile)
                    : _buildInputView(context, theme, settings, isMobile),
              ),
            ],
          ),

          if (isLoading)
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 48, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => _handleBack(context),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  fixedSize: const Size(40, 40),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              if (onReset != null)
                IconButton(
                  icon: const Icon(Icons.restart_alt, color: Colors.black),
                  onPressed: onReset,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    fixedSize: const Size(40, 40),
                  ),
                ),
              const SizedBox(width: 12),
              if (onViewResult != null)
                IconButton(
                  icon: const Icon(Icons.history_rounded, color: Colors.black),
                  onPressed: () => _showHistory(context),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    fixedSize: const Size(40, 40),
                  ),
                ),
            ],
          ),
          if (levelLabels != null && levelLabels!.isNotEmpty) ...[
            const SizedBox(height: 16),
            LevelSlider(
              label: title == 'Summarize' ? 'Summary Length' : 'Detail Level', 
              valueLabels: levelLabels!,
              initialIndex: initialLevel,
              onChanged: (index) {
                if (onLevelChanged != null) {
                  onLevelChanged!(index);
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
          if (controls != null && (controlsInline || !isMobile)) ...[
            controls!,
            const SizedBox(height: 16),
          ],
          _buildTextInputCard(context, theme, settings),
          const SizedBox(height: 24),
          _buildActionButtons(context, theme),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 24),
        ],
      ),
    );
  }

  // === PERBAIKAN UTAMA DI SINI ===
  Widget _buildResultView(BuildContext context, ThemeData theme, DisplaySettingsEntity settings, bool isMobile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min, // PENTING: Agar Column tidak memaksa tinggi
        children: [
          if (inputExpanded) ...[
            _buildTextInputCard(context, theme, settings),
            const SizedBox(height: 16),
          ],
          // HAPUS Flexible. Biarkan FeatureResultCard mengambil tinggi alaminya
          // sehingga SingleChildScrollView bisa men-scroll seluruh konten ke bawah.
          FeatureResultCard(
            text: viewResultText ?? resultText,
            title: viewResultTitle ?? resultTitle,
            inputExpanded: inputExpanded,
            onToggleInput: () => onToggleInput(!inputExpanded),
          ),
          const SizedBox(height: 24),
          _buildActionButtons(context, theme),
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
              controller: controller,
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
              Text(
                '${controller.text.length}/5000',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              FloatingActionButton(
                mini: true,
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

  Widget _buildActionButtons(BuildContext context, ThemeData theme) {
    final isSubmitDisabled = isLoading || controller.text.trim().isEmpty;

    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: isSubmitDisabled ? null : onSubmit,
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
        ),
        const SizedBox(width: 12),
        _circularButton(
          icon: Icons.content_copy_outlined,
          onTap: isLoading
              ? null
              : () {
                  if (controller.text.trim().isNotEmpty) {
                    Clipboard.setData(ClipboardData(text: controller.text));
                    showAdaptiveFeedback(context, 'Text copied to clipboard');
                  }
                },
        ),
        const SizedBox(width: 12),
        _circularButton(
          icon: Icons.share_outlined,
          onTap: isLoading
              ? null
              : () {
                  if (controller.text.trim().isNotEmpty) {
                    showAdaptiveFeedback(context, 'Share feature coming soon');
                  }
                },
        ),
      ],
    );
  }

  Widget _circularButton({required IconData icon, required VoidCallback? onTap}) {
    final isEnabled = onTap != null;
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: isEnabled ? const Color(0xFFB596E5) : Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Icon(
            icon,
            color: isEnabled ? Colors.white : Colors.white54,
            size: 24,
          ),
        ),
      ),
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
            const Text(
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